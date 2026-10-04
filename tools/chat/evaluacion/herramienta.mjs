// Las tres herramientas del modo agente del chat, por línea de órdenes, para evaluar a un modelo
// grande (un agente) con lo mismo que ve el chat: el catálogo y los parquets publicados.
//
//   node tools/chat/evaluacion/herramienta.mjs buscar "pensiones por comunidad"
//   node tools/chat/evaluacion/herramienta.mjs describir mother.pensiones_territorio
//   node tools/chat/evaluacion/herramienta.mjs sql "SELECT ... FROM mother.tabla ..."
//   (CATALOGO=ruta.json para otro catálogo; por defecto build/chat/catalogo.json)

import fs from 'node:fs';
import { DuckDBInstance } from '@duckdb/node-api';
import { crearIndice, buscarTablas, describirTabla, validarSQL } from '../../../src/lib/chat/herramientas.js';

const [orden, ...resto] = process.argv.slice(2);
const arg = resto.join(' ');
const catalogo = JSON.parse(fs.readFileSync(process.env.CATALOGO ?? 'build/chat/catalogo.json', 'utf8'));
const DATOS = (process.env.SPAINFACTS_PARQUETS ? process.env.SPAINFACTS_PARQUETS.replace(/\\/g, '/') + '/mother' : '.evidence/template/static/data/mother');

if (orden === 'buscar') {
	const r = buscarTablas(crearIndice(catalogo), arg, 8, 1);
	console.log(JSON.stringify(r, null, 1));
} else if (orden === 'describir') {
	console.log(JSON.stringify(describirTabla(catalogo, arg), null, 1));
} else if (orden === 'sql') {
	const v = validarSQL(arg);
	if (v.error) {
		console.log(JSON.stringify({ error: v.error }));
		process.exit(0);
	}
	const sql = v.sql ?? arg;
	const con = await (await DuckDBInstance.create(':memory:')).connect();
	await con.run('CREATE SCHEMA mother');
	for (const t of new Set([...sql.matchAll(/mother\.(\w+)/gi)].map((m) => m[1]))) {
		const p = `${DATOS}/${t}/${t}.parquet`;
		if (fs.existsSync(p)) await con.run(`CREATE VIEW mother.${t} AS SELECT * FROM read_parquet('${p}')`);
	}
	try {
		const filas = (await con.runAndReadAll(sql)).getRowObjectsJS();
		console.log(JSON.stringify({ filas: filas.slice(0, 50), total: filas.length }, (k, x) => (typeof x === 'bigint' ? Number(x) : x), 1));
	} catch (e) {
		console.log(JSON.stringify({ error: String(e.message).split('\n')[0] }));
	}
} else {
	console.log('Órdenes: buscar <texto> | describir <tabla> | sql <consulta>');
}
