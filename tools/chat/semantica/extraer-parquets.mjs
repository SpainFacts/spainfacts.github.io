// Extrae las tablas publicadas (sources/mother/<tabla>.sql) de un DuckDB local a parquets, con
// la misma estructura que .evidence/template/static/data/mother, en otra carpeta: para probar el
// chat con unos datos sin pisar la extracción que usan otros (Evidence u otras sesiones).
//
//   node tools/chat/semantica/extraer-parquets.mjs --db data/integracion.duckdb --salida data/parquets-integracion
//   (luego SPAINFACTS_PARQUETS=data/parquets-integracion para catalogo.mjs, evaluar.mjs y herramienta.mjs)

import fs from 'node:fs';
import path from 'node:path';
import { DuckDBInstance } from '@duckdb/node-api';

const args = process.argv.slice(2);
const valor = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const DB = valor('--db', 'data/integracion.duckdb');
const SALIDA = valor('--salida', 'data/parquets-integracion');

const con = await (await DuckDBInstance.create(':memory:')).connect();
await con.run(`ATTACH '${DB.replace(/'/g, "''")}' AS datos (READ_ONLY)`);
await con.run("SET search_path = 'datos.main'");
let n = 0;
const fallos = [];
for (const f of fs.readdirSync('sources/mother').filter((x) => x.endsWith('.sql'))) {
	const tabla = f.replace(/\.sql$/, '');
	const sql = fs.readFileSync(`sources/mother/${f}`, 'utf8').replace(/--[^\n]*/g, '').trim().replace(/;$/, '');
	const dir = path.join(SALIDA, 'mother', tabla);
	fs.mkdirSync(dir, { recursive: true });
	try {
		await con.run(`COPY (${sql}) TO '${path.join(dir, `${tabla}.parquet`).replace(/\\/g, '/')}' (FORMAT parquet)`);
		n++;
	} catch (e) {
		fallos.push(`${tabla}: ${String(e.message).split('\n')[0].slice(0, 120)}`);
	}
}
console.log(`${n} tablas extraídas en ${SALIDA}${fallos.length ? `; fallan ${fallos.length}:\n  ${fallos.join('\n  ')}` : ''}`);
