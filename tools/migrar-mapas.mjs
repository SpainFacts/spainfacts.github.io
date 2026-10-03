// Migración única (oct. 2026): sustituye AreaMap, BubbleMap y PointMap de Evidence (con teselas
// de Esri, que pintan el Sáhara Occidental como parte de Marruecos) por el componente propio
// src/lib/components/MapaEspana.svelte en todas las páginas y traducciones. Añade el import y,
// en las traducciones que estaban al día, actualiza i18n_origen con el hash nuevo del castellano.
//
//   node tools/migrar-mapas.mjs
import { createHash } from 'node:crypto';
import { readdirSync, readFileSync, statSync, writeFileSync, existsSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

const PAGES = 'pages';
const IDIOMAS = ['en', 'ca', 'gl', 'eu'];
const hash = (txt) => createHash('sha1').update(txt.replace(/\r\n/g, '\n')).digest('hex').slice(0, 12);

function todas(dir = PAGES, out = []) {
	for (const n of readdirSync(dir)) {
		const r = join(dir, n);
		if (statSync(r).isDirectory()) todas(r, out);
		else if (n.endsWith('.md')) out.push(r);
	}
	return out;
}

// Prefijo relativo hasta la raíz del repo desde la página compilada por Evidence
// (.evidence/template/src/pages/<ruta>/+page.md): 4 + nº de segmentos de la ruta
function prefijo(rel) {
	const partes = rel.split(sep).join('/').replace(/\.md$/, '').split('/').filter((p) => p !== 'index');
	return '../'.repeat(4 + partes.length);
}

function migrar(ruta) {
	let s = readFileSync(ruta, 'utf8');
	if (!/<(AreaMap|BubbleMap|PointMap|MapaEspana)\b/.test(s)) return false;
	const antes = s;
	s = s.replace(/<(AreaMap|BubbleMap|PointMap)\b/g, '<MapaEspana');
	if (!s.includes('MapaEspana.svelte')) {
		const rel = relative(PAGES, ruta);
		const lang = IDIOMAS.includes(rel.split(sep)[0]) ? rel.split(sep)[0] : 'es';
		const p = prefijo(rel);
		const linea = `    import MapaEspana from '${p}src/lib/components/MapaEspana.svelte';`;
		const nl = s.includes('\r\n') ? '\r\n' : '\n';
		if (/<script[^>]*>\r?\n/.test(s)) s = s.replace(/(<script[^>]*>\r?\n)/, `$1${linea}${nl}`);
		else {
			// sin <script>: se añade tras el frontmatter
			const m = s.match(/^---\n[\s\S]*?\n---\n/);
			const bloque = `\n<script>\n${linea}\n</script>\n`;
			s = m ? s.slice(0, m[0].length) + bloque + s.slice(m[0].length) : bloque + s;
		}
		void lang;
	}
	if (s === antes) return false;
	writeFileSync(ruta, s);
	return true;
}

const archivos = todas().map((r) => r);
const castellano = archivos.filter((r) => !IDIOMAS.includes(relative(PAGES, r).split(sep)[0]));

// Hash del castellano antes de tocar nada, para saber qué traducciones estaban al día
const alDia = new Set();
for (const es of castellano) {
	const rel = relative(PAGES, es);
	const h = hash(readFileSync(es, 'utf8'));
	for (const lang of IDIOMAS) {
		const tr = join(PAGES, lang, rel);
		if (!existsSync(tr)) continue;
		const m = readFileSync(tr, 'utf8').match(/^i18n_origen:\s*([0-9a-f]+)/m);
		if (m && m[1] === h) alDia.add(tr);
	}
}

let n = 0;
for (const r of archivos) if (migrar(r)) n++;

let rehash = 0;
for (const es of castellano) {
	const rel = relative(PAGES, es);
	const h = hash(readFileSync(es, 'utf8'));
	for (const lang of IDIOMAS) {
		const tr = join(PAGES, lang, rel);
		if (!alDia.has(tr)) continue;
		const t = readFileSync(tr, 'utf8');
		const nuevo = t.replace(/^(i18n_origen:\s*)[0-9a-f]+/m, `$1${h}`);
		if (nuevo !== t) {
			writeFileSync(tr, nuevo);
			rehash++;
		}
	}
}
console.log(`${n} páginas migradas; ${rehash} traducciones con i18n_origen actualizado`);
