// Prueba de DuckDB-NSQL (modelo que solo escribe SQL de DuckDB) en un esquema de dos pasos:
//   1. buscar_tablas (sin modelo) elige las tablas candidatas para la pregunta
//   2. DuckDB-NSQL escribe el SQL viendo su esquema como CREATE TABLE comentado
// y se comprueba si el resultado de la consulta trae la cifra correcta.
//
//   node tools/chat/probar-nsql.mjs [--modelo duckdb-nsql] [--tablas 2]

import fs from 'node:fs';
import path from 'node:path';
import { DuckDBInstance } from '@duckdb/node-api';
import { crearIndice, buscarTablas, buscarFicha, validarSQL } from '../../src/lib/chat/herramientas.js';

const args = process.argv.slice(2);
const valor = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const MODELO = valor('--modelo', 'duckdb-nsql');
const N_TABLAS = Number(valor('--tablas', 2));
const DATOS = '.evidence/template/static/data/mother';

// Misma batería que probar-modelo.mjs; se comprueba el resultado de la consulta
const PREGUNTAS = [
	{ q: '¿Qué comunidad autónoma tiene más deuda en porcentaje del PIB?', ok: (r) => r[0]?.includes('valenciana') && /\b40\b/.test(r[0]) },
	{ q: '¿Cuál es la tasa de paro actual en España?', ok: (r) => r[0]?.includes('9.87') },
	{ q: '¿Cuántos habitantes tiene España?', ok: (r) => r[0]?.includes('49114494') },
	{ q: '¿Cuál es la inflación interanual más reciente?', ok: (r) => /\b4\.9\b/.test(r[0] ?? '') },
	{ q: '¿Cuál es la tasa de paro de los menores de 25 años ahora mismo?', ok: (r) => r[0]?.includes('23.77') },
	{ q: '¿Qué comunidad tenía más deuda sobre el PIB a finales de 2010?', ok: (r) => r[0]?.includes('valenciana') && r[0]?.includes('19.7') }
];

const catalogo = JSON.parse(fs.readFileSync('build/chat/catalogo.json', 'utf8'));
const indice = crearIndice(catalogo);

// Esquema como lo entrenaron: CREATE TABLE, con comentarios de rangos y valores válidos
function ddl(t) {
	const cols = t.columnas.map((c) => {
		let com = '';
		if (c.min !== undefined) com = `de ${c.min} a ${c.max}`;
		else if (c.valores) com = `valores: ${c.valores.slice(0, 20).map((v) => `'${v}'`).join(', ')}`;
		else if (c.ejemplos) com = `p. ej. ${c.ejemplos.slice(0, 3).map((v) => `'${v}'`).join(', ')}`;
		return `  ${c.nombre} ${c.tipo}${com ? ` -- ${com}` : ''}`;
	});
	return `-- ${t.descripcion}\nCREATE TABLE mother.${t.nombre} (\n${cols.join(',\n')}\n);`;
}

const con = await (await DuckDBInstance.create(':memory:')).connect();
await con.run('CREATE SCHEMA mother');
for (const t of catalogo.tablas) {
	const f = path.join(DATOS, t.nombre, `${t.nombre}.parquet`).replace(/\\/g, '/');
	if (fs.existsSync(f)) await con.run(`CREATE VIEW mother."${t.nombre}" AS SELECT * FROM read_parquet('${f}')`);
}

async function generarSQL(esquema, pregunta) {
	const r = await fetch('http://localhost:11434/api/generate', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ model: MODELO, system: esquema, prompt: pregunta, stream: false, options: { temperature: 0, num_ctx: 8192 } })
	});
	if (!r.ok) throw new Error(`HTTP ${r.status} ${await r.text()}`);
	return (await r.json()).response.trim().replace(/^```sql\s*|```$/g, '');
}

let bien = 0;
for (const [i, p] of PREGUNTAS.entries()) {
	const inicio = Date.now();
	const candidatas = buscarTablas(indice, p.q, N_TABLAS).map((x) => buscarFicha(catalogo, x.tabla));
	const esquema = candidatas.map(ddl).join('\n\n');
	console.log(`\n=== ${i + 1}. ${p.q}\n  tablas: ${candidatas.map((t) => t.nombre).join(', ')}`);
	try {
		const sql = await generarSQL(esquema, p.q);
		console.log(`  SQL: ${sql.replace(/\s+/g, ' ')}`);
		const v = validarSQL(sql, 20);
		if (v.error) throw new Error(v.error);
		const filas = (await con.runAndReadAll(v.sql)).getRowObjectsJS();
		const texto = filas.map((f) => JSON.stringify(f, (k, x) => (typeof x === 'bigint' ? Number(x) : x)).toLowerCase());
		const ok = p.ok(texto);
		if (ok) bien++;
		console.log(`  ${ok ? 'BIEN' : 'MAL '} (${((Date.now() - inicio) / 1000).toFixed(0)} s): ${texto.slice(0, 2).join(' | ').slice(0, 300)}`);
	} catch (e) {
		console.log(`  MAL  ERROR: ${String(e.message).split('\n')[0].slice(0, 200)}`);
	}
}
console.log(`\n${bien}/${PREGUNTAS.length} bien con ${MODELO} (${N_TABLAS} tablas candidatas)`);
