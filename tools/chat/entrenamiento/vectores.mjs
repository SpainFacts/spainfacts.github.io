// Vectores de EmbeddingGemma (768 dims, sin recortar) de preguntas etiquetadas con su tabla,
// con el mismo embebedor que el navegador (catalogo.embeddings), para entrenar el clasificador.
//
//   node <ruta>/vectores.mjs entrenamiento   -> datos/vectores-entrenamiento.json (gen-*.json + preguntas de las fichas)
//   node <ruta>/vectores.mjs <bateria.json> [<salida>]  -> vectores de una batería (solo para medir)

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { RAIZ, AQUI, importarDelRepo } from './raiz.mjs';

const { crearEmbebedor } = await importarDelRepo('src/lib/chat/locales.js');
const [qué, salidaArg] = process.argv.slice(2);
const catalogo = JSON.parse(fs.readFileSync(path.join(RAIZ, 'build/chat/catalogo.json'), 'utf8'));
const e = catalogo.embeddings;
const embebedor = await crearEmbebedor({ modelo: e.modelo, dtype: e.dtype, archivo: e.archivo, cacheDir: path.join(os.homedir(), '.cache', 'tjs') });

let items = [];
let salida;
if (qué === 'entrenamiento') {
	const dir = path.join(AQUI, 'datos');
	for (const f of fs.readdirSync(dir).filter((f) => /^gen-.*\.json$/.test(f)).sort())
		for (const [i, p] of JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')).entries())
			items.push({ id: `${f.replace('.json', '')}#${i}`, texto: p.pregunta, tablas: [p.tabla, ...(p.tablas_validas ?? [])], idioma: p.idioma ?? 'es', fuente: 'gen' });
	// Las preguntas de ejemplo de las fichas también son preguntas etiquetadas
	for (const t of catalogo.tablas)
		if (t.semantica?.usar) for (const q of t.semantica.preguntas ?? []) items.push({ id: `ficha:${t.nombre}`, texto: q, tablas: [t.nombre], idioma: 'es', fuente: 'ficha' });
	salida = path.join(dir, 'vectores-entrenamiento.json');
} else {
	const ruta = fs.existsSync(qué) ? qué : path.join(RAIZ, qué);
	items = JSON.parse(fs.readFileSync(ruta, 'utf8')).map((p) => ({ id: p.id, texto: p.pregunta, tablas: p.tablas_oro.map((x) => x.replace(/^mother\./, '')), tipo: p.tipo, fuente: path.basename(ruta) }));
	salida = salidaArg ?? path.join(AQUI, 'datos', `vectores-${path.basename(ruta, '.json')}.json`);
}

const vecs = new Float32Array(items.length * 768);
const t0 = Date.now();
for (const [i, it] of items.entries()) {
	const v = await embebedor(`${e.prefijo_consulta}${it.texto}`);
	vecs.set(v.slice(0, 768), i * 768);
	if ((i + 1) % 500 === 0) console.log(`${i + 1}/${items.length} · ${((Date.now() - t0) / 1000).toFixed(0)} s`);
}
fs.writeFileSync(salida, JSON.stringify({ dims: 768, items, vecs: Buffer.from(vecs.buffer).toString('base64') }));
console.log(`${items.length} vectores -> ${salida}`);
