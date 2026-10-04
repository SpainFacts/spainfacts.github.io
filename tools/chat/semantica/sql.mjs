// Consulta rápida sobre los parquets publicados, con cada tabla como mother.<tabla>.
//   node tools/chat/semantica/sql.mjs "SELECT * FROM mother.ccaa_deuda LIMIT 5"

import fs from 'node:fs';
import { DuckDBInstance } from '@duckdb/node-api';

const DATOS = (process.env.SPAINFACTS_PARQUETS ? process.env.SPAINFACTS_PARQUETS.replace(/\\/g, '/') + '/mother' : '.evidence/template/static/data/mother');
const sql = process.argv.slice(2).join(' ');
const con = await (await DuckDBInstance.create(':memory:')).connect();
await con.run('CREATE SCHEMA mother');
for (const t of new Set([...sql.matchAll(/mother\.(\w+)/gi)].map((m) => m[1]))) {
	const p = `${DATOS}/${t}/${t}.parquet`;
	if (!fs.existsSync(p)) {
		console.error(`No existe la tabla ${t}`);
		process.exit(1);
	}
	await con.run(`CREATE VIEW mother.${t} AS SELECT * FROM read_parquet('${p}')`);
}
const filas = (await con.runAndReadAll(sql)).getRowObjectsJS();
console.table(filas.slice(0, 60));
if (filas.length > 60) console.log(`… ${filas.length} filas`);
