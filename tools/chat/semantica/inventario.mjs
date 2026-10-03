// Inventario para limpiar el modelo de datos: por cada tabla publicada, su modelo dbt, las
// páginas que la usan (castellano y traducciones), las columnas que esas páginas citan y los
// problemas que la capa semántica tuvo que rodear.
//
//   node tools/chat/semantica/inventario.mjs [--salida ruta.json]

import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';

const args = process.argv.slice(2);
const SALIDA = args.includes('--salida') ? args[args.indexOf('--salida') + 1] : 'tools/chat/semantica/inventario.json';
const IDIOMAS = ['en', 'ca', 'gl', 'eu'];

function recorrer(dir, fuera = []) {
	for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
		const p = path.join(dir, e.name);
		if (e.isDirectory()) recorrer(p, fuera);
		else if (/\.(md|svelte|js)$/.test(e.name)) fuera.push(p.replace(/\\/g, '/'));
	}
	return fuera;
}
const paginas = recorrer('pages').map((p) => ({ ruta: p, texto: fs.readFileSync(p, 'utf8') }));
const componentes = recorrer('src/lib').map((p) => ({ ruta: p, texto: fs.readFileSync(p, 'utf8') }));

const fichas = new Map(
	fs
		.readdirSync('tools/chat/semantica')
		.filter((f) => /^lote-.*\.json$/.test(f))
		.flatMap((f) => JSON.parse(fs.readFileSync(`tools/chat/semantica/${f}`, 'utf8')))
		.map((s) => [s.tabla.toLowerCase(), s])
);

function problemas(s) {
	if (!s) return ['sin ficha'];
	if (!s.usar) return ['no usable (auxiliar, duplicada o sin cifras)'];
	const p = [];
	if (s.territorio && !s.territorio.nombre && s.territorio.codigo) p.push('territorio solo con código');
	if (s.medidas.some((m) => m.unidad_columna) || /mezcla/i.test(s.notas ?? '')) p.push('unidades mezcladas');
	if (s.medidas.some((m) => m.escala)) p.push('proporción 0-1 en vez de %');
	if ((s.filtros ?? []).length || (s.dimensiones ?? []).some((d) => d.defecto)) p.push('filtro fijo o valor por defecto');
	if (s.medidas.some((m) => /€/.test(m.unidad ?? '')) && !s.medidas.some((m) => /hab|real/.test(m.columna))) p.push('euros sin por habitante ni reales');
	if (s.tiempo && !/^(anio|fecha|mes|periodo|trimestre)$/.test(s.tiempo.columna)) p.push('tiempo en columna no estándar');
	if (/duplic|no se suma|no sumar|filtrar|solapan|anómal/i.test(s.notas ?? '')) p.push('trampa en notas');
	return p;
}

const tablas = [];
for (const f of fs.readdirSync('sources/mother').filter((x) => x.endsWith('.sql'))) {
	const nombre = f.replace(/\.sql$/, '');
	const sqlFuente = fs.readFileSync(`sources/mother/${f}`, 'utf8').trim();
	const origen = sqlFuente.match(/\bfrom\s+([a-z0-9_.]+)/i)?.[1]?.split('.').at(-1) ?? nombre;
	const modelo = ['marts', 'staging'].map((d) => `transform/models/${d}/${origen}.sql`).find((p) => fs.existsSync(p)) ?? null;
	const re = new RegExp(`mother\\.${nombre}\\b`, 'i');
	const usos = paginas.filter((p) => re.test(p.texto));
	const es = usos.filter((p) => !IDIOMAS.some((i) => p.ruta.startsWith(`pages/${i}/`))).map((p) => p.ruta);
	const traducciones = usos.length - es.length;
	const enComponentes = componentes.filter((p) => re.test(p.texto)).map((p) => p.ruta);
	// Columnas citadas en el SQL de las páginas en castellano (aproximado: palabras que son columnas)
	const s = fichas.get(nombre.toLowerCase());
	let ultimo = null;
	if (modelo) {
		try {
			ultimo = execSync(`git log -1 --format=%cs -- "${modelo}"`, { encoding: 'utf8' }).trim() || null;
		} catch {}
	}
	tablas.push({
		tabla: nombre,
		sql_fuente: sqlFuente.length > 120 ? sqlFuente.slice(0, 120) + '…' : sqlFuente,
		modelo,
		modelo_modificado: ultimo,
		paginas_es: es,
		paginas_traducciones: traducciones,
		componentes: enComponentes,
		problemas: problemas(s),
		notas_ficha: s?.notas ?? null
	});
}
const sinUso = tablas.filter((t) => !t.paginas_es.length && !t.componentes.length).map((t) => t.tabla);
fs.writeFileSync(SALIDA, JSON.stringify({ generado: new Date().toISOString(), tablas, sin_uso: sinUso }, null, 1));
const conProblemas = tablas.filter((t) => t.problemas.length);
console.log(`${tablas.length} tablas; ${conProblemas.length} con problemas; ${sinUso.length} sin uso en páginas ni componentes; ${tablas.filter((t) => !t.modelo).length} sin modelo dbt localizado`);
const cuenta = {};
for (const t of tablas) for (const p of t.problemas) cuenta[p] = (cuenta[p] ?? 0) + 1;
console.log(cuenta);
