// Banco de pruebas del chat por decisiones (src/lib/chat/decision.js): el modelo solo
// elige entre opciones (se lee la probabilidad de cada letra con una pasada en Ollama) y
// el código hace el SQL y la respuesta. Misma batería que probar-modelo.mjs.
//
//   node tools/chat/probar-decision.mjs                                 -> decider-4b
//   node tools/chat/probar-decision.mjs --modelo qwen3:8b --catalogo <ruta> [--solo 3] [--ver]

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { DuckDBInstance } from '@duckdb/node-api';
import { crearIndice } from '../../src/lib/chat/herramientas.js';
import { responderPorDecisiones, promptDecision } from '../../src/lib/chat/decision.js';
import { crearDecisor, crearEmbebedor } from '../../src/lib/chat/locales.js';
import { PREGUNTAS as AJUSTE } from './preguntas.mjs';
import { PREGUNTAS as CONTROL } from './preguntas-control.mjs';
import { PREGUNTAS as VALIDACION } from './preguntas-validacion.mjs';

const args = process.argv.slice(2);
const valor = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const MODELO = valor('--modelo', 'hf.co/Mapika/decider-4b-GGUF:Q4_K_M');
const SOLO = valor('--solo', null);
const VER = args.includes('--ver');
const DATOS = '.evidence/template/static/data/mother';

const catalogo = JSON.parse(fs.readFileSync(valor('--catalogo', 'build/chat/catalogo.json'), 'utf8'));
const con = await (await DuckDBInstance.create(':memory:')).connect();
await con.run('CREATE SCHEMA mother');
for (const t of catalogo.tablas) {
	const f = path.join(DATOS, t.nombre, `${t.nombre}.parquet`).replace(/\\/g, '/');
	if (fs.existsSync(f)) await con.run(`CREATE VIEW mother."${t.nombre}" AS SELECT * FROM read_parquet('${f}')`);
}
const consultar = async (sql) => (await con.runAndReadAll(sql)).getRowObjectsJS();
const ctx = { catalogo, indice: crearIndice(catalogo), consultar };

// --embeddings: búsqueda híbrida con el mismo embebedor que el navegador
// --motor transformers: el decisor de Gemma 4 E2B con transformers.js (como en el navegador)
// Caché en ruta corta: onnxruntime no abre rutas de más de 260 caracteres en Windows
const cacheDir = path.join(os.homedir(), '.cache', 'tjs');
if (args.includes('--embeddings')) ctx.embeber = await crearEmbebedor({ ...catalogo.embeddings, cacheDir });
const decisorTransformers = valor('--motor', 'ollama') === 'transformers' ? await crearDecisor({ device: 'cpu', dtype: 'q4', cacheDir }) : null;

// Una pasada: probabilidad de cada letra en la posición de la respuesta
let llamadas = 0;
let msDecision = 0;
async function decidir(contexto, pregunta, opciones) {
	const inicio = Date.now();
	llamadas++;
	if (decisorTransformers) {
		const i = await decisorTransformers(contexto, pregunta, opciones);
		msDecision += Date.now() - inicio;
		return i;
	}
	const r = await fetch('http://localhost:11434/api/generate', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({
			model: MODELO,
			raw: true,
			prompt: promptDecision(contexto, pregunta, opciones),
			stream: false,
			logprobs: true,
			top_logprobs: 20,
			...(/qwen3/i.test(MODELO) ? { think: false } : {}),
			options: { num_predict: 1, temperature: 0, num_ctx: 8192 }
		})
	});
	if (!r.ok) throw new Error(`HTTP ${r.status} ${await r.text()}`);
	const j = await r.json();
	msDecision += Date.now() - inicio;
	const validas = new Set(opciones.map((_, i) => String.fromCharCode(65 + i)));
	const tops = j.logprobs?.[0]?.top_logprobs ?? [];
	const mejor = tops.filter((x) => validas.has(x.token.trim())).sort((a, b) => b.logprob - a.logprob)[0];
	const letra = mejor?.token.trim() ?? j.response.trim()[0];
	const i = letra.charCodeAt(0) - 65;
	return i >= 0 && i < opciones.length ? i : 0;
}

let bien = 0;
const inicioTotal = Date.now();
// --control: batería que no se usó para ajustar (ver preguntas-control.mjs)
const PREGUNTAS = args.includes('--validacion') ? VALIDACION : args.includes('--control') ? CONTROL : AJUSTE;
const lista = PREGUNTAS.map((p, i) => ({ ...p, i: i + 1 })).filter((p) => !SOLO || String(p.i) === SOLO);
for (const p of lista) {
	const inicio = Date.now();
	llamadas = 0;
	msDecision = 0;
	console.log(`\n=== ${p.i}. ${p.q}`);
	try {
		const r = await responderPorDecisiones({ pregunta: p.q, ctx, decidir });
		if (VER) for (const d of r.decisiones) console.log(`  · ${d.pregunta} -> ${d.eleccion}`);
		if (VER) console.log(`  SQL: ${r.sql}`);
		const ok = p.ok(r.texto.toLowerCase());
		if (ok) bien++;
		console.log(
			`  ${ok ? 'BIEN' : 'MAL '} (${((Date.now() - inicio) / 1000).toFixed(1)} s, ${llamadas} decisiones, ${Math.round(msDecision / Math.max(llamadas, 1))} ms/decisión): ${r.texto.replace(/\s+/g, ' ').slice(0, 260)}`
		);
	} catch (e) {
		console.log(`  ERROR: ${VER ? e.stack : String(e.message).split('\n')[0].slice(0, 300)}`);
	}
}
console.log(`\n${bien}/${lista.length} bien con ${decisorTransformers ? 'gemma-4-E2B (transformers.js)' : MODELO}${ctx.embeber ? ' + embeddings' : ''} (decisiones) en ${((Date.now() - inicioTotal) / 1000).toFixed(0)} s`);
