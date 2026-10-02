// Prueba de humo de la web compilada con un navegador real (Playwright + Chromium).
// Abre una muestra de páginas (todas las secciones, los 5 idiomas, páginas dinámicas y
// casos que ya se rompieron alguna vez) y falla si encuentra:
//   - respuesta distinta de 200 o error de JavaScript no capturado
//   - cuadros de error de Evidence (consultas o gráficas que fallan)
//   - «undefined» o «NaN» visibles, o «Loading...» que no termina
//   - gráficas sin pintar o páginas sin título h1
//   - comprobaciones específicas (p. ej. municipios con ?m= muestra ese municipio)
//
//   node tools/pruebas/humo.mjs                      -> sirve build/ en un puerto local y lo prueba
//   node tools/pruebas/humo.mjs --base https://spainfacts.org   -> prueba la web publicada
//   node tools/pruebas/humo.mjs --solo /territorios/municipios/?m=41091 --solo /varios/mapas/
//   node tools/pruebas/humo.mjs --rapido             -> solo castellano y menos páginas
//   node tools/pruebas/humo.mjs --disponibles        -> solo las páginas que existan en build/
//                                                       (útil tras un build parcial)
import { createReadStream, existsSync, readdirSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, relative, sep } from 'node:path';
import { chromium } from 'playwright';

const args = process.argv.slice(2);
const valor = (n, def) => {
	const i = args.indexOf(n);
	return i >= 0 ? args[i + 1] : def;
};
const todos = (n) => args.flatMap((a, i) => (a === n ? [args[i + 1]] : []));
const BUILD = valor('--dir', 'build'); // --dir: otra carpeta compilada (p. ej. el artefacto descargado de GitHub)
const RAPIDO = args.includes('--rapido');
const DISPONIBLES = args.includes('--disponibles');
const CONCURRENCIA = Number(valor('--concurrencia', 4));
const ESPERA_MAX = Number(valor('--espera', 45000));

// ---------------------------------------------------------------------------
// Páginas a probar
// ---------------------------------------------------------------------------
const IDIOMAS = ['en', 'ca', 'gl', 'eu'];

/** Comprobaciones extra por ruta: { h2, texto } */
const ESPECIALES = {
	// Se rompió en producción: al entrar con ?m= la página mostraba «undefined»
	'/territorios/municipios/?m=41091': { h2: 'Sevilla' },
	'/territorios/municipios/?m=08019': { h2: 'Barcelona' },
	'/en/territorios/municipios/?m=41091': { h2: 'Sevilla' },
	'/territorios/andalucia/': { h1: 'Andalucía' },
	'/territorios/andalucia/sevilla/': { texto: 'Sevilla' }
};

// Todas las páginas estáticas en castellano (pages/**.md sin corchetes ni redirecciones)
function paginasCastellano(dir = 'pages', out = []) {
	for (const n of readdirSync(dir)) {
		const r = join(dir, n);
		if (statSync(r).isDirectory()) {
			if (dir === 'pages' && IDIOMAS.includes(n)) continue;
			if (n.startsWith('[')) continue;
			paginasCastellano(r, out);
		} else if (n.endsWith('.md') && !n.startsWith('[')) {
			const ruta = '/' + relative('pages', r).split(sep).join('/').replace(/(index)?\.md$/, '');
			out.push(ruta.endsWith('/') ? ruta : ruta + '/');
		}
	}
	return out;
}
const REDIRECCIONES = ['/indicadores/', '/varios/mapa-poblacion/'];

// Git Bash convierte '/ruta' en 'C:/Program Files/Git/ruta': se deshace, y se admite sin barra
const normalizar = (r) => '/' + r.replace(/^[A-Za-z]:\/.*?\/Git\//, '').replace(/^\/+/, '');
let rutas = todos('--solo').map(normalizar);
if (!rutas.length) {
	const es = paginasCastellano().filter((r) => !REDIRECCIONES.includes(r));
	const dinamicas = [
		'/territorios/andalucia/',
		'/territorios/madrid/',
		'/territorios/canarias/',
		'/territorios/andalucia/sevilla/',
		'/territorios/galicia/a-coruna/',
		'/varios/indicadores/tasa_paro/',
		'/varios/indicadores/sociedad_esperanza_vida/'
	];
	// en otros idiomas: la portada de cada apartado y unas cuantas páginas profundas
	const muestra = ['/', '/economia/', '/economia/paro/', '/sociedad/', '/sociedad/salud/', '/vivienda/', '/vivienda/vivienda-publica/', '/energia-clima/', '/movilidad/', '/demografia/', '/cuentas-publicas/', '/transparencia/', '/transparencia/decretos-ley/', '/territorios/', '/territorios/andalucia/', '/varios/', '/varios/mapas/'];
	const traducidas = RAPIDO ? [] : IDIOMAS.flatMap((l) => muestra.map((r) => `/${l}${r}`));
	rutas = [...new Set([...(RAPIDO ? es.slice(0, 25) : es), ...dinamicas, ...Object.keys(ESPECIALES), ...traducidas])];
}

// Tras un build parcial solo existen algunas páginas
const existeEnBuild = (ruta) => {
	const p = ruta.split('?')[0];
	return existsSync(join(BUILD, p, 'index.html')) || existsSync(join(BUILD, p.replace(/\/$/, '') + '.html'));
};
if (DISPONIBLES) rutas = rutas.filter(existeEnBuild);

// ---------------------------------------------------------------------------
// Servidor estático para build/ (si no se pasa --base)
// ---------------------------------------------------------------------------
const TIPOS = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.svg': 'image/svg+xml', '.png': 'image/png', '.wasm': 'application/wasm', '.parquet': 'application/octet-stream', '.arrow': 'application/octet-stream', '.geojson': 'application/geo+json', '.woff2': 'font/woff2', '.xml': 'application/xml' };
function servir(dir) {
	return new Promise((ok) => {
		const srv = createServer((req, res) => {
			let p = decodeURIComponent(req.url.split('?')[0]);
			let f = join(dir, p);
			if (existsSync(f) && statSync(f).isDirectory()) f = join(f, 'index.html');
			else if (!existsSync(f) && existsSync(f + '.html')) f = f + '.html';
			if (!existsSync(f)) {
				res.writeHead(404, { 'content-type': 'text/html' });
				return res.end('404');
			}
			// Peticiones por rangos, como GitHub Pages: DuckDB lee trozos de los parquet
			const tam = statSync(f).size;
			const tipo = TIPOS[extname(f)] ?? 'application/octet-stream';
			const rango = /bytes=(\d*)-(\d*)/.exec(req.headers.range ?? '');
			if (rango) {
				const ini = rango[1] === '' ? Math.max(0, tam - Number(rango[2])) : Number(rango[1]);
				const fin = rango[1] !== '' && rango[2] !== '' ? Math.min(Number(rango[2]), tam - 1) : tam - 1;
				res.writeHead(206, { 'content-type': tipo, 'accept-ranges': 'bytes', 'content-range': `bytes ${ini}-${fin}/${tam}`, 'content-length': fin - ini + 1 });
				if (req.method === 'HEAD') return res.end();
				return createReadStream(f, { start: ini, end: fin }).pipe(res);
			}
			res.writeHead(200, { 'content-type': tipo, 'accept-ranges': 'bytes', 'content-length': tam });
			if (req.method === 'HEAD') return res.end();
			createReadStream(f).pipe(res);
		});
		srv.listen(0, '127.0.0.1', () => ok(srv));
	});
}

// ---------------------------------------------------------------------------
// Prueba de una página
// ---------------------------------------------------------------------------
// Mensajes de consola que no indican un fallo de la web
const RUIDO = [/favicon/i, /fall back to full HTTP read/i, /\[ECharts\]/i, /was created (with unknown|without expected) prop/i, /service ?worker/i, /Download the React DevTools/i];

async function probar(navegador, base, ruta) {
	const pagina = await navegador.newPage({ viewport: { width: 1280, height: 900 } });
	const errores = [];
	const avisos = [];
	pagina.on('pageerror', (e) => errores.push(`JS: ${e.message.split('\n')[0]}`));
	pagina.on('console', (m) => {
		if (m.type() !== 'error') return;
		const t = m.text();
		if (RUIDO.some((r) => r.test(t))) return;
		// El Worker de datos en directo solo acepta el origen spainfacts.org: probando build/
		// en local (o en GitHub) el navegador lo bloquea por CORS y la página dice «No en directo»
		if (!base.includes('spainfacts.org') && /workers\.dev/.test(t) && /CORS|ERR_FAILED/.test(t)) return;
		// los 404 de recursos se anotan (se comprueban aparte en la prueba estática)
		if (/Failed to load resource/.test(t)) return avisos.push(t);
		errores.push(`consola: ${t.slice(0, 200)}`);
	});
	try {
		const resp = await pagina.goto(base + ruta, { waitUntil: 'load', timeout: 60000 });
		if (!resp || resp.status() !== 200) errores.push(`HTTP ${resp?.status()}`);
		// espera a que termine de cargar (sin «Loading...» y con la red en calma)
		const inicio = Date.now();
		await pagina.waitForLoadState('networkidle', { timeout: ESPERA_MAX }).catch(() => {});
		// hace falta un rato SIN «Loading...»: los inputs leídos de la URL relanzan consultas
		// justo después de la primera carga, y entonces vuelve a aparecer
		let quieto = 0;
		while (Date.now() - inicio < ESPERA_MAX && quieto < 3) {
			const cargando = await pagina.evaluate(() => /Loading\.\.\./.test(document.querySelector('main')?.innerText ?? ''));
			quieto = cargando ? 0 : quieto + 1;
			await pagina.waitForTimeout(1000);
		}
		await pagina.waitForTimeout(1500); // margen para consultas reactivas (inputs desde la URL)

		const r = await pagina.evaluate(() => {
			const main = document.querySelector('main');
			const texto = main?.innerText ?? '';
			const graficas = [...document.querySelectorAll('.chart[role=img]')];
			return {
				h1: document.querySelector('main h1')?.innerText?.trim() ?? '',
				h2: document.querySelector('main h2')?.innerText?.trim() ?? '',
				texto,
				cargando: /Loading\.\.\./.test(texto),
				erroresEvidence: [...document.querySelectorAll('[class*="bg-negative/10"]')].map((e) => e.innerText.trim().slice(0, 160)),
				undef: (texto.match(/[^\n]{0,40}\b(undefined|NaN)\b[^\n]{0,40}/g) ?? []).slice(0, 3),
				graficasSinPintar: graficas.filter((g) => g.offsetParent && !g.querySelector('canvas, svg')).length,
				graficas: graficas.length
			};
		});
		if (!r.h1) errores.push('sin h1');
		if (r.cargando) errores.push('se queda en «Loading...»');
		for (const e of r.erroresEvidence) errores.push(`error de Evidence: ${e.replace(/\s+/g, ' ')}`);
		for (const u of r.undef) errores.push(`texto con undefined/NaN: «${u.trim()}»`);
		if (r.graficasSinPintar) errores.push(`${r.graficasSinPintar} de ${r.graficas} gráficas sin pintar`);
		const esp = ESPECIALES[ruta];
		if (esp?.h1 && r.h1 !== esp.h1) errores.push(`h1 «${r.h1}», se esperaba «${esp.h1}»`);
		if (esp?.h2 && r.h2 !== esp.h2) errores.push(`primer h2 «${r.h2}», se esperaba «${esp.h2}»`);
		if (esp?.texto && !r.texto.includes(esp.texto)) errores.push(`no aparece «${esp.texto}»`);
	} catch (e) {
		errores.push(`no se pudo cargar: ${e.message.split('\n')[0]}`);
	} finally {
		await pagina.close();
	}
	return { ruta, errores, avisos };
}

// ---------------------------------------------------------------------------
const inicio = Date.now();
let servidor = null;
let base = valor('--base');
if (!base) {
	if (!existsSync(join(BUILD, 'index.html'))) {
		console.error('No hay build/ (ejecuta antes npm run build o build:parcial) o usa --base <url>.');
		process.exit(2);
	}
	servidor = await servir(BUILD);
	base = `http://127.0.0.1:${servidor.address().port}`;
}
base = base.replace(/\/$/, '');
// --servir: solo sirve build/ (con rangos, como GitHub Pages) para mirarlo en un navegador
if (args.includes('--servir')) {
	console.log(`Sirviendo build/ en ${base} (Ctrl+C para parar)`);
	await new Promise(() => {});
}
console.log(`Prueba de humo: ${rutas.length} páginas en ${base} (concurrencia ${CONCURRENCIA})`);

const navegador = await chromium.launch();
const resultados = [];
const cola = [...rutas];
await Promise.all(
	Array.from({ length: CONCURRENCIA }, async () => {
		while (cola.length) {
			const ruta = cola.shift();
			const r = await probar(navegador, base, ruta);
			resultados.push(r);
			console.log(`${r.errores.length ? '✗' : '✓'} ${ruta}${r.errores.length ? '\n    ' + r.errores.join('\n    ') : ''}`);
		}
	})
);
await navegador.close();
servidor?.close();

const fallos = resultados.filter((r) => r.errores.length);
const segundos = Math.round((Date.now() - inicio) / 1000);
console.log(`\n${resultados.length - fallos.length}/${resultados.length} páginas correctas en ${segundos} s`);
if (fallos.length) {
	console.log(`Fallan ${fallos.length}:`);
	for (const f of fallos) console.log(`  ${f.ruta}: ${f.errores[0]}${f.errores.length > 1 ? ` (+${f.errores.length - 1})` : ''}`);
}
process.exitCode = fallos.length ? 1 : 0;
