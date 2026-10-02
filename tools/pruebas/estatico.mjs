// Comprobación estática de la web compilada (sin navegador, rápida):
//   - cada página tiene <title> y el lang de su carpeta (es en la raíz; en/ca/gl/eu)
//   - los enlaces internos (href="/...") apuntan a páginas o ficheros que existen en build/
//   - el HTML prerenderizado no contiene «undefined» ni «NaN» visibles
//
//   node tools/pruebas/estatico.mjs              -> todo build/
//   node tools/pruebas/estatico.mjs --avisos     -> además lista los avisos (títulos «Evidence»...)
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

const BUILD = 'build';
const IDIOMAS = ['en', 'ca', 'gl', 'eu'];
const verAvisos = process.argv.includes('--avisos');

if (!existsSync(join(BUILD, 'index.html'))) {
	console.error('No hay build/ (ejecuta antes npm run build o build:parcial).');
	process.exit(2);
}

function html(dir = BUILD, out = []) {
	for (const n of readdirSync(dir)) {
		const r = join(dir, n);
		if (statSync(r).isDirectory()) {
			if (dir === BUILD && ['_app', 'api', 'data'].includes(n)) continue;
			html(r, out);
		} else if (n.endsWith('.html')) out.push(r);
	}
	return out;
}

const existe = (ruta) => {
	const p = decodeURIComponent(ruta.split(/[?#]/)[0]);
	if (p === '/' || p === '') return true;
	const f = join(BUILD, p);
	return existsSync(f) || existsSync(join(f, 'index.html')) || existsSync(f.replace(/\/$/, '') + '.html');
};

// Un build parcial deja fuera casi todo: los enlaces a páginas apartadas no cuentan
const parcial = existsSync('.pages-apartadas') || process.argv.includes('--parcial');

const errores = [];
const avisos = [];
const rotos = new Map();
const paginas = html();
for (const f of paginas) {
	const rel = '/' + relative(BUILD, f).split(sep).join('/');
	const doc = readFileSync(f, 'utf8');
	if (/window\.location\.replace|http-equiv="refresh"/.test(doc) && doc.length < 20000) continue; // redirecciones
	const lang = IDIOMAS.includes(rel.split('/')[1]) ? rel.split('/')[1] : 'es';
	const langHtml = doc.match(/<html lang="([a-z-]+)"/)?.[1];
	if (langHtml && langHtml !== lang && !doc.includes('Page not found')) errores.push(`${rel}: lang="${langHtml}", se esperaba "${lang}"`);
	const titulo = doc.match(/<title>([^<]*)<\/title>/)?.[1]?.trim() ?? '';
	if (!titulo) errores.push(`${rel}: sin <title>`);
	else if (titulo === 'Evidence') avisos.push(`${rel}: título genérico «Evidence»`);
	// texto visible del cuerpo (sin scripts ni estilos)
	const cuerpo = doc
		.replace(/<script[\s\S]*?<\/script>/g, '')
		.replace(/<style[\s\S]*?<\/style>/g, '')
		.replace(/<[^>]+>/g, ' ');
	const malos = cuerpo.match(/[^\s]{0,30}\s*\b(undefined|NaN)\b\s*[^\s]{0,30}/g);
	if (malos) errores.push(`${rel}: texto con undefined/NaN: ${malos.slice(0, 2).map((m) => `«${m.trim()}»`).join(' ')}`);
	if (!parcial)
		for (const m of doc.matchAll(/href="(\/[^"#]*)"/g)) {
			const destino = m[1];
			if (destino.startsWith('//') || /^\/(_app|api|data)\//.test(destino)) continue;
			if (!existe(destino)) {
				if (!rotos.has(destino)) rotos.set(destino, new Set());
				rotos.get(destino).add(rel);
			}
		}
}
for (const [destino, origenes] of rotos)
	errores.push(`enlace roto ${destino} (en ${[...origenes].slice(0, 3).join(', ')}${origenes.size > 3 ? ` y ${origenes.size - 3} más` : ''})`);

console.log(`Prueba estática: ${paginas.length} páginas HTML${parcial ? ' (build parcial: sin comprobar enlaces)' : ''}`);
for (const e of errores) console.log(`  ✗ ${e}`);
if (verAvisos) for (const a of avisos) console.log(`  ! ${a}`);
console.log(`${errores.length} errores, ${avisos.length} avisos`);
process.exitCode = errores.length ? 1 : 0;
