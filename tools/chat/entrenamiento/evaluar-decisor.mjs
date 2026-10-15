// Mide el modo decisión con distintos decisores sobre una o varias baterías (mismo bucle y
// misma corrección que tools/chat/evaluacion/evaluar.mjs decision --embeddings catalogo).
//
//   node <ruta>/evaluar-decisor.mjs --bateria tools/chat/evaluacion/preguntas-validacion5.json --decisor ollama:gemma4:e2b
//   --decisor http://127.0.0.1:8765      servidor de servir.py (modelos de Hugging Face y afinados)
//   --decisor onnx:<carpeta o id de HF>  transformers.js en Node (lo que correría en el navegador, en CPU) [--dtype q4]
//   --decisor oro                        la tabla correcta forzada (techo del traductor; el resto con Gemma 4 E2B de Ollama)
//   --clasificador <json>                clasificador de tabla (entrenar-clasificador.py; sin él, ninguno aunque el catálogo lo traiga)
//     [--peso-clasificador 1] [--candidatas-clasificador 3] [--peso-busqueda 0.5] [--tabla-sin-modelo]
//   --sin-vectores                       sin EmbeddingGemma: búsqueda solo por palabras
//   --salida <json> --ver
// Desde la raíz del repo con datos, o con SPAINFACTS_RAIZ (ver raiz.mjs).

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { RAIZ, AQUI, importarDelRepo, importarPaquete, rutaParquet } from './raiz.mjs';
import { crearClasificador } from './clasificador.mjs';

const args = process.argv.slice(2);
const valor = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const { crearIndice } = await importarDelRepo('src/lib/chat/herramientas.js');
const { responderPorDecisiones, promptDecision } = await importarDelRepo('src/lib/chat/decision.js');
const { crearDecisorOllama } = await importarDelRepo('src/lib/chat/agente.js');
const { crearEmbebedor } = await importarDelRepo('src/lib/chat/locales.js');
const { correcta } = await importarDelRepo('tools/chat/evaluacion/correccion.mjs');
const { DuckDBInstance } = await importarPaquete('@duckdb/node-api');

const cacheDir = path.join(os.homedir(), '.cache', 'tjs');
const catalogo = JSON.parse(fs.readFileSync(path.resolve(RAIZ, valor('--catalogo', 'build/chat/catalogo.json')), 'utf8'));
const baterias = valor('--bateria', 'tools/chat/evaluacion/preguntas-validacion5.json').split(',');
const DECISOR = valor('--decisor', 'ollama:gemma4:e2b');

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
// --sin-vectores: sin EmbeddingGemma (búsqueda solo por palabras y columnas por léxico)
const ctx = { catalogo, indice: crearIndice(catalogo), consultar, embeber: args.includes('--sin-vectores') ? undefined : embeber, clasificador: null };
if (args.includes('--clasificador')) {
	ctx.clasificador = crearClasificador(JSON.parse(fs.readFileSync(valor('--clasificador'), 'utf8')));
	ctx.pesoClasificador = Number(valor('--peso-clasificador', 1));
	ctx.candidatasClasificador = Number(valor('--candidatas-clasificador', 3));
	ctx.pesoBusqueda = Number(valor('--peso-busqueda', 0.5));
}
if (valor('--prior', null) !== null) ctx.priorBusqueda = Number(valor('--prior'));

// ---------- Decisores ----------
async function crearDecisorDe(spec) {
	if (spec.startsWith('ollama:')) return crearDecisorOllama({ modelo: spec.slice(7) });
	if (spec === 'oro') return crearDecisorOllama({ modelo: 'gemma4:e2b' });
	if (spec.startsWith('http')) {
		return async (contexto, pregunta, opciones) => {
			const r = await fetch(`${spec.replace(/\/$/, '')}/decidir`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ prompt: promptDecision(contexto, pregunta, opciones), n: opciones.length })
			});
			const j = await r.json();
			return { indice: j.probs.indexOf(Math.max(...j.probs)), probs: j.probs };
		};
	}
	if (spec.startsWith('onnx:')) {
		const { crearDecisorONNX } = await import('./decisor-onnx.mjs');
		return crearDecisorONNX({ modelo: spec.slice(5), dtype: ((d) => (d.startsWith('{') ? JSON.parse(d) : d))(valor('--dtype', 'q4')), cacheDir });
	}
	throw new Error(`Decisor desconocido: ${spec}`);
}
const decidirModelo = await crearDecisorDe(DECISOR);
// --tabla-sin-modelo: la tabla la decide solo la información previa (búsqueda + clasificador)
const decidir = args.includes('--tabla-sin-modelo')
	? async (contexto, q, opciones) => (/^Which data table/.test(q) ? { indice: 0, probs: opciones.map(() => 1 / opciones.length) } : decidirModelo(contexto, q, opciones))
	: decidirModelo;

// ---------- Bucle ----------
const resultados = [];
let total = 0;
let bien = 0;
let tablaBien = 0;
const resumen = [];
const t0 = Date.now();
for (const bateria of baterias) {
	const ruta = [path.resolve(bateria), path.resolve(RAIZ, bateria), path.resolve(AQUI, '../../..', bateria)].find((r) => fs.existsSync(r));
	const preguntas = JSON.parse(fs.readFileSync(ruta, 'utf8')).filter((p) => !valor('--solo', null) || p.id === valor('--solo'));
	let bienB = 0;
	let tablaB = 0;
	for (const p of preguntas) {
		const t1 = Date.now();
		let texto = '';
		let error = '';
		let tabla = '';
		const oro = p.tablas_oro.map((x) => x.replace(/^mother\./, ''));
		try {
			const c = DECISOR === 'oro' ? { ...ctx, tablaForzada: oro[0] } : ctx;
			const r = await responderPorDecisiones({ pregunta: p.pregunta, ctx: c, decidir });
			texto = r.texto;
			tabla = DECISOR === 'oro' ? oro[0] : (r.decisiones.find((d) => /data table/.test(d.pregunta))?.eleccion?.split(':')[0] ?? r.sql?.match(/mother\."?(\w+)/)?.[1] ?? '');
			if (args.includes('--ver')) for (const d of r.decisiones) console.log(`    · ${d.pregunta.slice(0, 50)} -> ${String(d.eleccion).slice(0, 90)}`);
		} catch (err) {
			error = String(err.message ?? err).slice(0, 300);
		}
		const ok = !error && correcta(texto, p.acepta);
		const tablaOk = oro.includes(tabla);
		total++;
		if (ok) (bien++, bienB++);
		if (tablaOk) (tablaBien++, tablaB++);
		resultados.push({ bateria: path.basename(bateria), id: p.id, tipo: p.tipo, ok, tablaOk, tabla, texto, error });
		console.log(`${ok ? '✓' : '✗'}${tablaOk ? ' ' : 't'} ${p.id} [${p.tipo}] ${((Date.now() - t1) / 1000).toFixed(1)}s ${(error || texto).replace(/\s+/g, ' ').slice(0, 120)}`);
	}
	resumen.push(`${path.basename(bateria, '.json').replace('preguntas-', '')} ${bienB}/${preguntas.length} (tabla ${tablaB})`);
}
console.log(`\n${bien}/${total} bien · tabla ${tablaBien}/${total} · ${resumen.join(' · ')} · ${DECISOR}${ctx.clasificador ? ` + clasificador (peso ${ctx.pesoClasificador}, candidatas ${ctx.candidatasClasificador})` : ''}${args.includes('--tabla-sin-modelo') ? ' · tabla sin modelo' : ''} · ${((Date.now() - t0) / 1000).toFixed(0)} s`);
const salida = valor('--salida', null);
if (salida) fs.writeFileSync(salida, JSON.stringify(resultados, null, 1));
