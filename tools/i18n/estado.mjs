// Estado de las traducciones: compara cada página en castellano (pages/**.md, fuera
// de pages/en|ca|gl|eu) con sus traducciones y dice cuáles faltan o están desfasadas.
//
// Cada traducción lleva en su frontmatter `i18n_origen: <hash>`, el hash del .md en
// castellano del que se tradujo. Si el castellano cambia, el hash ya no coincide.
//
//   node tools/i18n/estado.mjs            -> resumen por idioma
//   node tools/i18n/estado.mjs --lista    -> además, las rutas pendientes
//   node tools/i18n/estado.mjs --hash pages/economia/paro.md   -> hash a poner en la traducción
import { createHash } from 'node:crypto';
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const IDIOMAS = ['en', 'ca', 'gl', 'eu'];
const PAGES = 'pages';

export const hashDe = (ruta) =>
	createHash('sha1').update(readFileSync(ruta, 'utf8').replace(/\r\n/g, '\n')).digest('hex').slice(0, 12);

function paginasCastellano(dir = PAGES, out = []) {
	for (const nombre of readdirSync(dir)) {
		const ruta = join(dir, nombre);
		if (statSync(ruta).isDirectory()) {
			if (dir === PAGES && IDIOMAS.includes(nombre)) continue;
			paginasCastellano(ruta, out);
		} else if (nombre.endsWith('.md')) out.push(ruta);
	}
	return out;
}

const args = process.argv.slice(2);
if (args[0] === '--hash') {
	console.log(hashDe(args[1]));
	process.exit(0);
}

const lista = args.includes('--lista');
const origen = paginasCastellano();
let pendientes = 0;
for (const lang of IDIOMAS) {
	const faltan = [];
	const desfasadas = [];
	for (const ruta of origen) {
		const rel = relative(PAGES, ruta);
		const traducida = join(PAGES, lang, rel);
		if (!existsSync(traducida)) {
			faltan.push(rel);
			continue;
		}
		const m = readFileSync(traducida, 'utf8').match(/^i18n_origen:\s*([0-9a-f]+)/m);
		if (!m || m[1] !== hashDe(ruta)) desfasadas.push(rel);
	}
	pendientes += faltan.length + desfasadas.length;
	console.log(`${lang}: ${origen.length - faltan.length - desfasadas.length}/${origen.length} al día · ${faltan.length} sin traducir · ${desfasadas.length} desfasadas`);
	if (lista) {
		for (const r of faltan) console.log(`   falta      ${r}`);
		for (const r of desfasadas) console.log(`   desfasada  ${r}`);
	}
}
process.exitCode = 0;
if (args.includes('--estricto') && pendientes) process.exitCode = 1;
