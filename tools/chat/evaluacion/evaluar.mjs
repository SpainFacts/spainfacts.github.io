// Evaluación del chat de datos con las baterías de tools/chat/evaluacion/*.json.
//
//   node tools/chat/evaluacion/evaluar.mjs busqueda  [--conjunto desarrollo|prueba] [--embeddings e5,gemma,minilm,qwen3]
//   node tools/chat/evaluacion/evaluar.mjs decision  --modelo gemma4:e2b [--embeddings e5] [--motor transformers]
//   node tools/chat/evaluacion/evaluar.mjs agente    --modelo qwen3:8b [--embeddings e5]
//   (todas admiten --catalogo <ruta> --salida <json> --solo <id>)
//
// Una respuesta es correcta si contiene, para cada grupo de "acepta.cifras" y "acepta.textos",
// al menos una de sus variantes. La búsqueda es correcta si alguna de "tablas_oro" sale entre
// las k primeras.
//
// La batería de prueba es la medida limpia: no ajustar el chat mirando sus fallos.

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { DuckDBInstance } from '@duckdb/node-api';
import { crearIndice, buscarTablas } from '../../../src/lib/chat/herramientas.js';
import { responderPorDecisiones } from '../../../src/lib/chat/decision.js';
import { responder, crearDecisorOllama } from '../../../src/lib/chat/agente.js';
import { crearDecisor } from '../../../src/lib/chat/locales.js';

const args = process.argv.slice(2);
const modo = args[0];
const valor = (n, d) => (args.includes(n) ? args[args.indexOf(n) + 1] : d);
const CONJUNTO = valor('--conjunto', 'desarrollo');
const MODELO = valor('--modelo', 'gemma4:e2b');
const SOLO = valor('--solo', null);
const aqui = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, '$1'));
const cacheDir = path.join(os.homedir(), '.cache', 'tjs'); // ruta corta (límite de 260 caracteres de Windows)

const preguntas = JSON.parse(fs.readFileSync(path.join(aqui, `preguntas-${CONJUNTO}.json`), 'utf8')).filter((p) => !SOLO || p.id === SOLO);
const catalogo = JSON.parse(fs.readFileSync(valor('--catalogo', 'build/chat/catalogo.json'), 'utf8'));

// ---------- Embeddings candidatos ----------
const EMBEDDINGS = {
	e5: { modelo: 'Xenova/multilingual-e5-small', dtype: 'q8', consulta: 'query: ', documento: 'passage: ', pooling: 'mean' },
	minilm: { modelo: 'Xenova/paraphrase-multilingual-MiniLM-L12-v2', dtype: 'q8', consulta: '', documento: '', pooling: 'mean' },
	gemma: {
		modelo: 'onnx-community/embeddinggemma-300m-ONNX',
		dtype: 'q4',
		consulta: 'task: search result | query: ',
		documento: 'title: none | text: ',
		pooling: 'mean'
	},
	gemma256: {
		modelo: 'onnx-community/embeddinggemma-300m-ONNX',
		dtype: 'q4',
		consulta: 'task: search result | query: ',
		documento: 'title: none | text: ',
		pooling: 'mean',
		dims: 256
	},
	qwen3: {
		modelo: 'onnx-community/Qwen3-Embedding-0.6B-ONNX',
		dtype: 'q8',
		consulta: 'Instruct: Given a question about Spanish public data, retrieve the data table that answers it\nQuery: ',
		documento: '',
		pooling: 'last_token'
	}
};
const textoTabla = (t) =>
	`${t.nombre.replace(/_/g, ' ')}. ${t.descripcion} ${t.paginas.map((p) => p.titulo).join('. ')}. Columnas: ${t.columnas
		.map((c) => c.nombre.replace(/_/g, ' '))
		.join(', ')}`.slice(0, 1500);

async function prepararEmbeddings(clave) {
	const cfg = EMBEDDINGS[clave];
	const { pipeline, env } = await import('@huggingface/transformers');
	env.cacheDir = cacheDir;
	const extraer = await pipeline('feature-extraction', cfg.modelo, { dtype: cfg.dtype });
	// Recorte Matryoshka (EmbeddingGemma admite 768/512/256/128): primeras dims y renormalizar
	const vector = async (texto) => {
		const v = (await extraer(texto, { pooling: cfg.pooling, normalize: true })).data;
		if (!cfg.dims) return v;
		const r = v.slice(0, cfg.dims);
		const norma = Math.hypot(...r);
		return r.map((x) => x / norma);
	};
	// Vectores de las tablas con este modelo (el catálogo solo trae los de e5)
	const cache = path.join(cacheDir, `vectores-${clave}-${catalogo.tablas.length}-${catalogo.generado}.json`.replace(/[:]/g, ''));
	let vecs;
	if (fs.existsSync(cache)) vecs = JSON.parse(fs.readFileSync(cache, 'utf8'));
	else {
		vecs = {};
		for (const t of catalogo.tablas) vecs[t.nombre] = Array.from(await vector(cfg.documento + textoTabla(t)));
		fs.writeFileSync(cache, JSON.stringify(vecs));
	}
	// Mismo formato que el catálogo: int8 en base64
	const cat = {
		...catalogo,
		tablas: catalogo.tablas.map((t) => ({
			...t,
			vec: Buffer.from(Int8Array.from(vecs[t.nombre], (x) => Math.max(-127, Math.min(127, Math.round(x * 127)))).buffer).toString('base64')
		}))
	};
	return { catalogo: cat, embeber: async (texto) => vector(cfg.consulta + texto) };
}

// ---------- Comprobación de respuestas ----------
const sinAcentos = (s) => String(s).toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
function correcta(texto, acepta) {
	const r = sinAcentos(texto);
	const grupos = [...(acepta?.cifras ?? []), ...(acepta?.textos ?? [])];
	return grupos.every((g) => g.some((v) => r.includes(sinAcentos(v))));
}

// ---------- DuckDB ----------
async function conectar(cat) {
	const con = await (await DuckDBInstance.create(':memory:')).connect();
	await con.run('CREATE SCHEMA mother');
	for (const t of cat.tablas) {
		const f = `.evidence/template/static/data/mother/${t.nombre}/${t.nombre}.parquet`;
		if (fs.existsSync(f)) await con.run(`CREATE VIEW mother."${t.nombre}" AS SELECT * FROM read_parquet('${f}')`);
	}
	return async (sql) => (await con.runAndReadAll(sql)).getRowObjectsJS();
}

// El mismo decisor de Ollama que usa la web (devuelve índice y probabilidades)
const decidirOllama = crearDecisorOllama({ modelo: MODELO });

// ---------- Modos ----------
const resultados = [];
const inicio = Date.now();

if (modo === 'busqueda') {
	const claves = valor('--embeddings', 'e5,minilm,gemma,qwen3').split(',');
	const variantes = [{ nombre: 'palabras', catalogo, embeber: null }];
	for (const c of claves) {
		try {
			const t0 = Date.now();
			variantes.push({ nombre: c, ...(await prepararEmbeddings(c)), carga: Date.now() - t0 });
		} catch (e) {
			console.log(`  ${c}: no se pudo cargar (${e.message.slice(0, 120)})`);
		}
	}
	console.log(`\nBúsqueda (${CONJUNTO}, ${preguntas.length} preguntas): ¿está la tabla correcta entre las k primeras?`);
	console.log('variante      @1    @3    @6    ms/consulta');
	for (const v of variantes) {
		const indice = crearIndice(v.catalogo);
		let a1 = 0, a3 = 0, a6 = 0, ms = 0;
		for (const p of preguntas) {
			const t0 = Date.now();
			const vec = v.embeber ? await v.embeber(p.pregunta) : null;
			ms += Date.now() - t0;
			const top = buscarTablas(indice, p.pregunta, 6, 0, vec).map((x) => x.tabla.toLowerCase());
			const oro = p.tablas_oro.map((x) => x.toLowerCase());
			const pos = top.findIndex((x) => oro.includes(x));
			if (pos === 0) a1++;
			if (pos >= 0 && pos < 3) a3++;
			if (pos >= 0) a6++;
			resultados.push({ variante: v.nombre, id: p.id, posicion: pos, top: top.slice(0, 6) });
		}
		const n = preguntas.length;
		console.log(`${v.nombre.padEnd(12)} ${(a1 / n * 100).toFixed(0).padStart(4)}% ${(a3 / n * 100).toFixed(0).padStart(4)}% ${(a6 / n * 100).toFixed(0).padStart(4)}%   ${(ms / n).toFixed(0)}`);
	}
} else {
	const emb = valor('--embeddings', null);
	const base = emb ? await prepararEmbeddings(emb) : { catalogo, embeber: null };
	const consultar = await conectar(base.catalogo);
	const ctx = { catalogo: base.catalogo, indice: crearIndice(base.catalogo), consultar, ...(base.embeber ? { embeber: base.embeber } : {}), ...(valor('--prior', null) !== null ? { priorBusqueda: Number(valor('--prior')) } : {}) };
	const decidir =
		modo === 'decision' && valor('--motor', 'ollama') === 'transformers' ? await crearDecisor({ device: 'cpu', dtype: 'q4', cacheDir }) : decidirOllama;
	let bien = 0;
	for (const p of preguntas) {
		const t0 = Date.now();
		let texto = '';
		let error = '';
		let sql = '';
		try {
			if (modo === 'decision') {
				const r = await responderPorDecisiones({ pregunta: p.pregunta, ctx, decidir });
				texto = r.texto;
				if (args.includes('--ver')) for (const d of r.decisiones) console.log(`    · ${d.pregunta.slice(0, 60)} -> ${String(d.eleccion).slice(0, 100)}`);
				if (args.includes('--ver')) console.log(`    SQL: ${r.sql}
    depuración: ${JSON.stringify(r.depuracion)}`);
				sql = r.sql ?? '';
			} else {
				const pasos = [];
				const r = await responder({
					proveedor: 'local',
					config: { url: 'http://localhost:11434/v1', modelo: MODELO },
					pregunta: p.pregunta,
					ctx,
					lang: 'es',
					alPaso: (s) => pasos.push(s)
				});
				texto = r.texto;
				sql = pasos.filter((s) => s.entrada?.sql).map((s) => s.entrada.sql).join('\n');
			}
		} catch (e) {
			error = String(e.message ?? e).slice(0, 300);
		}
		const ok = !error && correcta(texto, p.acepta);
		if (ok) bien++;
		resultados.push({ id: p.id, tipo: p.tipo, ok, segundos: (Date.now() - t0) / 1000, pregunta: p.pregunta, texto, sql, error });
		console.log(`${ok ? '✓' : '✗'} ${p.id} [${p.tipo}] ${((Date.now() - t0) / 1000).toFixed(1)}s ${(error || texto).replace(/\s+/g, ' ').slice(0, 150)}`);
	}
	const porTipo = {};
	for (const r of resultados) {
		porTipo[r.tipo] ??= [0, 0];
		porTipo[r.tipo][1]++;
		if (r.ok) porTipo[r.tipo][0]++;
	}
	console.log(
		`\n${bien}/${preguntas.length} bien · ${modo} · ${valor('--motor', 'ollama') === 'transformers' ? 'gemma-4-E2B (transformers.js)' : MODELO}${emb ? ` + ${emb}` : ''} · ${CONJUNTO} · ${((Date.now() - inicio) / 1000).toFixed(0)} s · ${Object.entries(porTipo)
			.map(([k, [b, n]]) => `${k} ${b}/${n}`)
			.join(', ')}`
	);
}

const salida = valor('--salida', null);
if (salida) fs.writeFileSync(salida, JSON.stringify(resultados, null, 1));
