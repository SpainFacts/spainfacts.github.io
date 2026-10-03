// Banco de pruebas del chat con un modelo real, sin navegador: mismo agente y mismas
// herramientas que /chat, con DuckDB en Node sobre los parquets locales.
//
//   node tools/chat/probar-modelo.mjs                       -> Ollama, qwen2.5:3b
//   node tools/chat/probar-modelo.mjs --modelo qwen2.5:7b --url http://localhost:11434/v1
//   node tools/chat/probar-modelo.mjs --solo 2              -> solo la pregunta 2
//
// Necesita build/chat/catalogo.json (node tools/chat/catalogo.mjs) y los parquets de
// .evidence/template/static/data/mother (npm run sources).

import fs from 'node:fs';
import path from 'node:path';
import { DuckDBInstance } from '@duckdb/node-api';
import { crearIndice } from '../../src/lib/chat/herramientas.js';
import { responder } from '../../src/lib/chat/agente.js';
import { PREGUNTAS as AJUSTE } from './preguntas.mjs';
import { PREGUNTAS as CONTROL } from './preguntas-control.mjs';
import { PREGUNTAS as VALIDACION } from './preguntas-validacion.mjs';

const args = process.argv.slice(2);
const valor = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const MODELO = valor('--modelo', 'qwen2.5:3b');
const URL = valor('--url', 'http://localhost:11434/v1');
const SOLO = valor('--solo', null);
const DATOS = '.evidence/template/static/data/mother';



const catalogo = JSON.parse(fs.readFileSync(valor('--catalogo', 'build/chat/catalogo.json'), 'utf8'));
const con = await (await DuckDBInstance.create(':memory:')).connect();
await con.run('CREATE SCHEMA mother');
const vistas = new Set();
async function consultar(sql) {
	for (const m of sql.matchAll(/mother\s*\.\s*"?([a-z0-9_]+)/gi)) {
		const n = m[1].toLowerCase();
		const f = path.join(DATOS, n, `${n}.parquet`).replace(/\\/g, '/');
		if (vistas.has(n) || !fs.existsSync(f)) continue;
		await con.run(`CREATE VIEW mother."${n}" AS SELECT * FROM read_parquet('${f}')`);
		vistas.add(n);
	}
	return (await con.runAndReadAll(sql)).getRowObjectsJS();
}
const ctx = { catalogo, indice: crearIndice(catalogo), consultar };

let bien = 0;
const inicioTotal = Date.now();
// --control: batería que no se usó para ajustar (ver preguntas-control.mjs)
const PREGUNTAS = args.includes('--validacion') ? VALIDACION : args.includes('--control') ? CONTROL : AJUSTE;
const lista = PREGUNTAS.map((p, i) => ({ ...p, i: i + 1 })).filter((p) => !SOLO || String(p.i) === SOLO);
for (const p of lista) {
	const inicio = Date.now();
	console.log(`\n=== ${p.i}. ${p.q}`);
	try {
		const r = await responder({
			proveedor: 'local',
			config: { url: URL, modelo: MODELO, prebusqueda: !args.includes('--sin-prebusqueda') },
			pregunta: p.q,
			ctx,
			lang: 'es',
			alPaso: (s) => console.log(`  · ${s.herramienta} ${JSON.stringify(s.entrada).slice(0, 220)}`),
			alGrafico: (g) => console.log(`  · gráfico ${g.tipo} (${g.filas.length} filas)`)
		});
		const ok = p.ok(r.texto.toLowerCase());
		if (ok) bien++;
		console.log(`  ${ok ? 'BIEN' : 'MAL '} (${((Date.now() - inicio) / 1000).toFixed(0)} s): ${r.texto.replace(/\s+/g, ' ').slice(0, 400)}`);
	} catch (e) {
		console.log(`  ERROR: ${e.message}`);
	}
}
const total = ((Date.now() - inicioTotal) / 1000).toFixed(0);
console.log(`\n${bien}/${lista.length} bien con ${MODELO}${args.includes('--sin-prebusqueda') ? ' (sin prebúsqueda)' : ''} en ${total} s`);
