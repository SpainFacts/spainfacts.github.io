// Comprueba que los cambios de SQL de las páginas en castellano (respecto a un commit, HEAD por
// defecto) también se han hecho en sus traducciones: por cada consulta que cambió, se añadió o
// se quitó en castellano, la misma consulta tiene que haber cambiado (o aparecido / desaparecido)
// en pages/en|ca|gl|eu. No compara el texto exacto (las traducciones anteponen el idioma a las
// rutas), solo que el cambio esté hecho.
//
//   node tools/i18n/sql-propagado.mjs [--desde <commit>]

import fs from 'node:fs';
import { execSync } from 'node:child_process';

const args = process.argv.slice(2);
const DESDE = args.includes('--desde') ? args[args.indexOf('--desde') + 1] : 'HEAD';
const IDIOMAS = ['en', 'ca', 'gl', 'eu'];
const RE_SQL = /```sql\s+([\w-]+)[^\n]*\n([\s\S]*?)```/g;
const bloques = (t) => new Map([...t.matchAll(RE_SQL)].map((m) => [m[1], m[2].replace(/\r/g, '').trim()]));
const enGit = (ruta) => {
	try {
		return execSync(`git show ${DESDE}:"${ruta}"`, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], maxBuffer: 64 * 1024 * 1024 });
	} catch {
		return '';
	}
};
const ahora = (ruta) => (fs.existsSync(ruta) ? fs.readFileSync(ruta, 'utf8') : '');

const cambiadas = execSync(`git diff --name-only ${DESDE} -- pages`, { encoding: 'utf8' })
	.split('\n')
	.filter((p) => p.endsWith('.md') && !/^pages\/(en|ca|gl|eu)\//.test(p));
let faltan = 0;
for (const es of cambiadas) {
	const antes = bloques(enGit(es));
	const despues = bloques(ahora(es));
	const tocadas = [...new Set([...antes.keys(), ...despues.keys()])].filter((n) => antes.get(n) !== despues.get(n));
	if (!tocadas.length) continue;
	for (const idioma of IDIOMAS) {
		const tr = es.replace(/^pages\//, `pages/${idioma}/`);
		if (!enGit(tr) && !fs.existsSync(tr)) continue;
		const trAntes = bloques(enGit(tr));
		const trDespues = bloques(ahora(tr));
		const sinHacer = tocadas.filter((n) => {
			const cambioEs = `${antes.has(n)}${despues.has(n)}`;
			const cambioTr = `${trAntes.has(n)}${trDespues.has(n)}`;
			if (cambioEs !== cambioTr) return true; // añadida/quitada en uno y no en otro
			return despues.has(n) && antes.has(n) && trAntes.get(n) === trDespues.get(n); // cambió en castellano, no en la traducción
		});
		if (sinHacer.length) {
			faltan++;
			console.log(`${tr}: falta propagar ${sinHacer.join(', ')}`);
		}
	}
}
console.log(`${cambiadas.length} páginas en castellano cambiadas; ${faltan} traducciones con cambios de SQL sin propagar`);
process.exitCode = faltan ? 1 : 0;
