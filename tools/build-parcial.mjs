// Build parcial para probar cambios sin esperar el build completo (~80 min con 5 idiomas).
// Aparta temporalmente las páginas que no se piden a .pages-apartadas/, compila solo
// las elegidas y SIEMPRE las devuelve a su sitio (también si falla o se corta con Ctrl+C).
//
//   node tools/build-parcial.mjs economia/paro vivienda      -> portada + esas páginas/carpetas (solo castellano)
//   node tools/build-parcial.mjs economia --idiomas en       -> además su versión en inglés
//   node tools/build-parcial.mjs --solo-es                   -> todo el castellano, sin traducciones (~30 min)
//   node tools/build-parcial.mjs economia --estricto         -> build:strict en vez de build
//   npm run build:parcial -- economia/paro
//
// Las rutas son relativas a pages/ (sin .md). La portada (pages/index.md) y el layout se
// conservan siempre. Si un build anterior se cortó de golpe, este script restaura primero
// lo que quedó en .pages-apartadas/.
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, renameSync, rmSync, statSync } from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';

const PAGES = 'pages';
const APARTADAS = '.pages-apartadas';
const IDIOMAS = ['en', 'ca', 'gl', 'eu'];

const args = process.argv.slice(2);
const opcion = (n) => args.includes(n);
const valor = (n) => {
	const i = args.indexOf(n);
	return i >= 0 ? args[i + 1] : undefined;
};
const idiomasPedidos = (valor('--idiomas') ?? '').split(',').filter(Boolean);
const soloEs = opcion('--solo-es');
const pedidas = args.filter((a, i) => !a.startsWith('--') && args[i - 1] !== '--idiomas').map((a) => a.replace(/\\/g, '/').replace(/^\/|\/$|\.md$/g, ''));

if (!soloEs && !pedidas.length) {
	console.error('Indica qué páginas compilar (p. ej. economia/paro) o usa --solo-es.');
	process.exit(1);
}

// Devuelve a pages/ todo lo apartado (y limpia carpetas vacías)
function restaurar() {
	if (!existsSync(APARTADAS)) return;
	const mover = (dir) => {
		for (const n of readdirSync(dir)) {
			const origen = join(dir, n);
			const destino = join(PAGES, relative(APARTADAS, origen));
			if (statSync(origen).isDirectory()) mover(origen);
			else {
				mkdirSync(dirname(destino), { recursive: true });
				renameSync(origen, destino);
			}
		}
	};
	mover(APARTADAS);
	rmSync(APARTADAS, { recursive: true, force: true });
	console.log('Páginas restauradas.');
}

function todas(dir = PAGES, out = []) {
	for (const n of readdirSync(dir)) {
		const r = join(dir, n);
		if (statSync(r).isDirectory()) todas(r, out);
		else if (n.endsWith('.md')) out.push(relative(PAGES, r).split(sep).join('/'));
	}
	return out;
}

// ¿Se conserva esta página? (ruta relativa a pages/, con .md)
function seQueda(rel) {
	if (rel === 'index.md') return true;
	const partes = rel.split('/');
	const lang = IDIOMAS.includes(partes[0]) ? partes[0] : 'es';
	const sinIdioma = (lang === 'es' ? partes : partes.slice(1)).join('/').replace(/\.md$/, '');
	if (lang !== 'es' && !idiomasPedidos.includes(lang)) return false;
	if (lang !== 'es' && sinIdioma === 'index') return true; // portada del idioma
	if (soloEs && lang === 'es' && !pedidas.length) return true;
	return pedidas.some((p) => sinIdioma === p || sinIdioma === `${p}/index` || sinIdioma.startsWith(`${p}/`));
}

restaurar(); // por si quedó algo de una ejecución cortada
for (const s of ['SIGINT', 'SIGTERM', 'SIGHUP'])
	process.on(s, () => {
		restaurar();
		process.exit(130);
	});

let apartadas = 0;
try {
	for (const rel of todas()) {
		if (seQueda(rel)) continue;
		const destino = join(APARTADAS, rel);
		mkdirSync(dirname(destino), { recursive: true });
		renameSync(join(PAGES, rel), destino);
		apartadas++;
	}
	const quedan = todas();
	console.log(`Compilando ${quedan.length} páginas (${apartadas} apartadas):\n  ${quedan.join('\n  ')}`);
	const script = opcion('--estricto') ? 'build:strict' : 'build';
	// BUILD_PARCIAL=1: svelte.config.js convierte en avisos los 404 de enlaces a páginas apartadas
	rmSync('build', { recursive: true, force: true });
	const r = spawnSync('npm', ['run', script], { stdio: 'inherit', shell: true, env: { ...process.env, BUILD_PARCIAL: '1' } });
	process.exitCode = r.status ?? 1;
} finally {
	restaurar();
}
