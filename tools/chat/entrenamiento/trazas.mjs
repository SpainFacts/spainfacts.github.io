// Ejemplos de entrenamiento para el decisor a partir de las preguntas generadas
// (datos/gen-*.json): cada pregunta pasa por el modo decisión real (src/lib/chat/decision.js)
// con un «decisor oráculo» que conoce la respuesta correcta (tabla, cifra, lugar, valores).
// Cada vez que el traductor pregunta algo al modelo se guarda la decisión tal cual la vería
// el modelo en producción: contexto, pregunta, opciones y cuál es la buena.
//
//   node <ruta>/trazas.mjs [--catalogo build/chat/catalogo.json] [--salida <jsonl>] [--limite N]
//   (desde la raíz del repo, o con SPAINFACTS_RAIZ=<repo con datos>; ver raiz.mjs)
//
// Si la tabla correcta no sale entre las candidatas de la búsqueda, se repite con un índice
// de solo esas candidatas más la buena (en lugar de la última): el modelo aprende a
// reconocerla con la misma descripción que vería en producción.

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { RAIZ, AQUI, importarDelRepo, importarPaquete, rutaParquet } from './raiz.mjs';

const { crearIndice, buscarTablas, buscarFicha } = await importarDelRepo('src/lib/chat/herramientas.js');
const { responderPorDecisiones } = await importarDelRepo('src/lib/chat/decision.js');
const { crearEmbebedor } = await importarDelRepo('src/lib/chat/locales.js');
const { DuckDBInstance } = await importarPaquete('@duckdb/node-api');

const args = process.argv.slice(2);
const valor = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const cacheDir = path.join(os.homedir(), '.cache', 'tjs');
const catalogo = JSON.parse(fs.readFileSync(path.resolve(RAIZ, valor('--catalogo', 'build/chat/catalogo.json')), 'utf8'));
const salida = valor('--salida', path.join(AQUI, 'datos', 'trazas.jsonl'));
const LIMITE = Number(valor('--limite', 0));
const PATRON = new RegExp(valor('--ficheros', '^gen-.*\\.json$'));

const normalizar = (s) =>
	String(s ?? '')
		.toLowerCase()
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.trim();

// Preguntas generadas (todas las partes de todos los lotes)
const dirDatos = path.join(AQUI, 'datos');
let preguntas = [];
for (const f of fs.readdirSync(dirDatos).filter((f) => PATRON.test(f)).sort()) {
	const lista = JSON.parse(fs.readFileSync(path.join(dirDatos, f), 'utf8'));
	lista.forEach((p, i) => preguntas.push({ ...p, id: `${f.replace('.json', '')}#${i}` }));
}
// Las que citan una tabla que no existe o que el chat no usa no sirven
const usables = new Set(catalogo.tablas.filter((t) => t.semantica?.usar !== false).map((t) => t.nombre));
const descartadas = preguntas.filter((p) => !usables.has(p.tabla)).length;
preguntas = preguntas.filter((p) => usables.has(p.tabla));
if (LIMITE) preguntas = preguntas.slice(0, LIMITE);
console.log(`${preguntas.length} preguntas (${descartadas} descartadas por tabla desconocida)`);

// Embebedor y DuckDB, como en tools/chat/evaluacion/evaluar.mjs
const e = catalogo.embeddings;
const embebedor = await crearEmbebedor({ modelo: e.modelo, dtype: e.dtype, archivo: e.archivo, dims: e.dims, cacheDir });
const conPrefijo = (prefijo, texto) => (texto.startsWith(prefijo) ? texto : prefijo + texto);
const embeber = async (texto) => embebedor(conPrefijo(e.prefijo_consulta ?? '', texto));
const con = await (await DuckDBInstance.create(':memory:')).connect();
await con.run('CREATE SCHEMA mother');
for (const t of catalogo.tablas) {
	const f = rutaParquet(t.nombre);
	if (fs.existsSync(f)) await con.run(`CREATE VIEW mother."${t.nombre}" AS SELECT * FROM read_parquet('${f}')`);
}
const consultar = async (sql) => (await con.runAndReadAll(sql)).getRowObjectsJS();
const indice = crearIndice(catalogo);
const ctxBase = { catalogo, indice, consultar, embeber };

const NIVELES = {
	'autonomous communities': ['ccaa', 'comunidad', 'comunidades', 'comunidad autonoma'],
	provinces: ['provincia', 'provincias'],
	municipalities: ['municipio', 'municipios'],
	'spain as a whole': ['pais', 'espana']
};

/** Decisor que conoce la respuesta: devuelve la opción buena y guarda la decisión */
function oraculo(p, registro) {
	const oroTablas = new Set([p.tabla, ...(p.tablas_validas ?? [])]);
	return async (contexto, q, opciones) => {
		let oro = -1;
		let tipo = 'otro';
		const tablaDelContexto = contexto.match(/\nTabla: ([a-z0-9_]+)\./)?.[1];
		if (/^Which data table/.test(q)) {
			tipo = 'tabla';
			oro = opciones.findIndex((o) => oroTablas.has(o.slice(0, o.indexOf(':'))));
		} else if (tablaDelContexto && !oroTablas.has(tablaDelContexto)) {
			tipo = 'fuera'; // ya se eligió otra tabla: lo que siga no tiene respuesta conocida
		} else if (/^Which column/.test(q)) {
			tipo = 'cifra';
			const ficha = buscarFicha(catalogo, tablaDelContexto ?? p.tabla)?.semantica;
			const m = ficha?.medidas.find((x) => x.columna === p.medida);
			const etiqueta = m ? `${m.nombre}${m.unidad ? ` (${m.unidad})` : ''}` : null;
			oro = etiqueta ? opciones.findIndex((o) => o === etiqueta) : -1;
		} else if (/^Which place/.test(q)) {
			tipo = 'lugar';
			const nombre = normalizar(p.territorio?.nombre);
			if (nombre) oro = opciones.findIndex((o) => normalizar(o.replace(/ \([^)]*\)$/, '')) === nombre);
		} else if (/^Which territorial level/.test(q)) {
			tipo = 'nivel';
			const pedido = normalizar(p.ranking?.sobre ?? p.territorio?.nivel ?? '');
			oro = opciones.findIndex((o) => (NIVELES[o] ?? [normalizar(o)]).includes(pedido));
		} else if (/^Which value of "/.test(q)) {
			tipo = 'valor';
			const col = q.match(/^Which value of "([^"]+)"/)[1];
			const v = p.filtros?.[col];
			if (v !== undefined && v !== null) oro = opciones.findIndex((o) => normalizar(o) === normalizar(v));
			// La columna del territorio («municipio») elegida como valor: el lugar de la pregunta
			else if (p.territorio?.nombre) oro = opciones.findIndex((o) => normalizar(o) === normalizar(p.territorio.nombre));
		}
		registro.push({ tipo, contexto, pregunta: q, opciones, oro });
		const i = oro >= 0 ? oro : 0;
		return { indice: i, probs: opciones.map((_, k) => (k === i ? 1 : 0)) };
	};
}

const fd = fs.openSync(salida, 'w');
const cuenta = {};
let sinTabla = 0;
const t0 = Date.now();
for (const [n, p] of preguntas.entries()) {
	let registro = [];
	try {
		await responderPorDecisiones({ pregunta: p.pregunta, ctx: ctxBase, decidir: oraculo(p, registro) });
		const decTabla = registro.find((d) => d.tipo === 'tabla');
		if (decTabla && decTabla.oro < 0) {
			// La buena no estaba entre las candidatas: se repite con esas candidatas y la buena
			sinTabla++;
			const vec = await embeber(p.pregunta);
			const top = buscarTablas(indice, p.pregunta, 6, 0, vec).map((x) => x.tabla.replace(/^mother\./, ''));
			const sub = new Set([...top.slice(0, 5), p.tabla]);
			const indice2 = crearIndice({ ...catalogo, tablas: catalogo.tablas.filter((t) => sub.has(t.nombre)) });
			registro = [];
			await responderPorDecisiones({ pregunta: p.pregunta, ctx: { ...ctxBase, indice: indice2 }, decidir: oraculo(p, registro) });
			for (const d of registro) d.inyectada = true;
		}
	} catch (err) {
		registro.push({ tipo: 'error', error: String(err.message ?? err).slice(0, 200), oro: -1 });
	}
	for (const d of registro) {
		cuenta[d.tipo] ??= [0, 0];
		cuenta[d.tipo][1]++;
		if (d.oro >= 0) cuenta[d.tipo][0]++;
		if (d.oro >= 0 && d.tipo !== 'fuera') fs.writeSync(fd, JSON.stringify({ id: p.id, idioma: p.idioma ?? 'es', tabla: p.tabla, ...d }) + '\n');
		else if (args.includes('--depurar') && d.tipo !== 'fuera') console.log(`  sin oro [${d.tipo}] ${p.pregunta} | ${d.pregunta} | ${JSON.stringify(d.opciones).slice(0, 200)} | oro: ${JSON.stringify({ medida: p.medida, territorio: p.territorio, filtros: p.filtros })}`);
	}
	if ((n + 1) % 100 === 0) console.log(`${n + 1}/${preguntas.length} · ${((Date.now() - t0) / 1000).toFixed(0)} s · ${JSON.stringify(cuenta)}`);
}
fs.closeSync(fd);
console.log(`Hecho: ${JSON.stringify(cuenta)} (decisiones con respuesta / total) · tabla buena fuera de las candidatas: ${sinTabla}`);
