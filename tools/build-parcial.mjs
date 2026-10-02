// Build parcial para probar cambios sin esperar el build completo (~80 min con 5 idiomas).
// Aparta temporalmente las páginas que no se piden a .pages-apartadas/, compila solo
// las elegidas y SIEMPRE las devuelve a su sitio (también si falla o se corta con Ctrl+C).
//
//   node tools/build-parcial.mjs economia/paro vivienda      -> portada + esas páginas/carpetas (solo castellano)
//   node tools/build-parcial.mjs economia --idiomas en       -> además su versión en inglés
//   node tools/build-parcial.mjs --solo-es                   -> todo el castellano, sin traducciones (~30 min)
//   node tools/build-parcial.mjs economia --estricto         -> build:strict en vez de build
//   node tools/build-parcial.mjs economia --probar           -> y luego pruebas estática y de humo
//   npm run build:parcial -- economia/paro
//
// Las rutas son relativas a pages/ (sin .md). La portada (pages/index.md) y el layout se
// conservan siempre. Si un build anterior se cortó de golpe, este script restaura primero
// lo que quedó en .pages-apartadas/.
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, renameSync, rmSync, statSync, writeFileSync } from 'node:fs';
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

// Cerrojo: dos builds parciales a la vez se pisarían las páginas apartadas. Si hay otro
// en marcha (su proceso sigue vivo), se espera; si el cerrojo es de un proceso muerto, se ignora.
const CERROJO = '.build-parcial.lock';
const vivo = (pid) => {
	try {
		process.kill(pid, 0);
		return true;
	} catch {
		return false;
	}
};
const esperar = (ms) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
for (;;) {
	try {
		writeFileSync(CERROJO, String(process.pid), { flag: 'wx' });
		break;
	} catch {
		const otro = Number(readFileSync(CERROJO, 'utf8'));
		if (!vivo(otro)) {
			rmSync(CERROJO, { force: true });
			continue;
		}
		console.log(`Otro build parcial en marcha (pid ${otro}); esperando…`);
		esperar(20000);
	}
}
const soltar = () => rmSync(CERROJO, { force: true });
process.on('exit', soltar);

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
	// Se borra el build anterior para no confundir páginas viejas con las nuevas; si algo
	// tiene ficheros abiertos (p. ej. un servidor de vista previa sobre build/), se sigue igual
	try {
		rmSync('build', { recursive: true, force: true });
	} catch (e) {
		console.warn(`No se pudo borrar build/ (${e.code}); quedarán páginas de builds anteriores.`);
	}
	const r = spawnSync('npm', ['run', script], { stdio: 'inherit', shell: true, env: { ...process.env, BUILD_PARCIAL: '1' } });
	process.exitCode = r.status ?? 1;
} finally {
	restaurar();
}

// --probar: pasa las pruebas estática y de humo a las páginas que se acaban de compilar
if (opcion('--probar') && process.exitCode === 0) {
	for (const prueba of [['tools/pruebas/estatico.mjs', '--parcial'], ['tools/pruebas/humo.mjs', '--disponibles']]) {
		const p = spawnSync('node', prueba, { stdio: 'inherit', shell: true });
		if (p.status) process.exitCode = p.status;
	}
}
