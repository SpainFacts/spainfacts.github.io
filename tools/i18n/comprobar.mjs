// Comprobación estructural de las traducciones frente al castellano:
//  - mismo número de bloques ```sql y de cada componente <Xxx
//  - imports relativos de src/ con un "../" más
//  - SQL idéntico salvo prefijos de idioma en rutas
//  - enlaces internos sin prefijo de idioma (href="/..." o ](/...))
//
//   node tools/i18n/comprobar.mjs            -> todos los idiomas
//   node tools/i18n/comprobar.mjs ca         -> solo catalán
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';

const PAGES = 'pages';
const IDIOMAS = process.argv[2] ? [process.argv[2]] : ['en', 'ca', 'gl', 'eu'];
const ESTATICOS = /^\/(geo|_app|data|api)\/|\.(geojson|svg|png|jpg|json|csv|xml|txt|ico)(\?|$)/;

function castellano(dir = PAGES, out = []) {
	for (const n of readdirSync(dir)) {
		const r = join(dir, n);
		if (statSync(r).isDirectory()) {
			if (dir === PAGES && ['en', 'ca', 'gl', 'eu'].includes(n)) continue;
			castellano(r, out);
		} else if (n.endsWith('.md')) out.push(r);
	}
	return out;
}

const contar = (arr) => arr.reduce((m, x) => ((m[x] = (m[x] ?? 0) + 1), m), {});
const componentes = (s) => contar(s.match(/<[A-Z][A-Za-z]*/g) ?? []);
const bloquesSql = (s) => [...s.matchAll(/```sql[^\n]*\n([\s\S]*?)```/g)].map((m) => m[1]);
const profundidades = (s) => [...s.matchAll(/['"]((?:\.\.\/)+)src\/lib\//g)].map((m) => m[1].length / 3);
// Se ignoran: finales de línea, comentarios, el prefijo de idioma en rutas y el alias
// "AS ruta" que se añade al prefijar (t.ruta -> '/en' || t.ruta AS ruta)
const normalizarSql = (sql, lang) =>
	sql
		.replace(/\r/g, '')
		.replace(/--[^\n]*/g, '')
		.replace(new RegExp(`'/${lang}' \\|\\| `, 'g'), '')
		.replace(new RegExp(`'/${lang}/`, 'g'), "'/")
		.replace(/\* REPLACE \((\w+) AS \1\)/g, '*')
		.replace(/\b(\w+\.)?(\w+) AS \2\b/g, '$1$2')
		.replace(/\s+/g, ' ')
		.trim();

// Anclas: id de un encabezado Markdown (mismo criterio que github-slugger, que usa mdsvex)
const slug = (t) =>
	t
		.toLowerCase()
		.replace(/<[^>]+>/g, '')
		.replace(/[^\p{L}\p{N}\s_-]/gu, '')
		.trim()
		.replace(/\s/g, '-');
const anclasDe = (fichero) =>
	new Set(
		[...readFileSync(fichero, 'utf8').replace(/```[\s\S]*?```/g, '').matchAll(/^#{1,6}\s+(.+)$/gm)].map((m) => slug(m[1]))
	);
function ficheroDeRuta(ruta) {
	const base = join(PAGES, ruta.replace(/^\//, '').replace(/\/$/, ''));
	for (const f of [base + '.md', join(base, 'index.md')]) if (existsSync(f)) return f;
	return null;
}

let problemas = 0;
for (const lang of IDIOMAS) {
	let ok = 0;
	const fallos = [];
	for (const ruta of castellano()) {
		const rel = relative(PAGES, ruta);
		const trad = join(PAGES, lang, rel);
		if (!existsSync(trad)) {
			fallos.push(`${rel}: sin traducir`);
			continue;
		}
		const a = readFileSync(ruta, 'utf8');
		const b = readFileSync(trad, 'utf8');
		const errores = [];
		const sa = bloquesSql(a);
		const sb = bloquesSql(b);
		if (sa.length !== sb.length) errores.push(`bloques sql ${sa.length}≠${sb.length}`);
		else
			sa.forEach((q, i) => {
				if (normalizarSql(q, lang) !== normalizarSql(sb[i], lang)) errores.push(`sql #${i + 1} cambiado`);
			});
		const ca = componentes(a);
		const cb = componentes(b);
		for (const k of new Set([...Object.keys(ca), ...Object.keys(cb)]))
			if ((ca[k] ?? 0) !== (cb[k] ?? 0)) errores.push(`${k} ${ca[k] ?? 0}≠${cb[k] ?? 0}`);
		const pa = profundidades(a);
		const pb = profundidades(b);
		if (pa.length !== pb.length || pa.some((d, i) => pb[i] !== d + 1)) errores.push(`imports ${pa.join(',')}→${pb.join(',')}`);
		// enlaces internos sin prefijo (fuera de bloques sql)
		const sinSql = b.replace(/```sql[\s\S]*?```/g, '');
		const enlaces = [...sinSql.matchAll(/(?:href=["']|\]\()(\/[^"')\s#?]*)/g)]
			.map((m) => m[1])
			.filter((u) => u !== '/' + lang && !u.startsWith(`/${lang}/`) && !ESTATICOS.test(u));
		if (enlaces.length) errores.push(`enlaces sin /${lang}: ${[...new Set(enlaces)].slice(0, 4).join(' ')}`);
		if (!/^i18n_origen:/m.test(b)) errores.push('sin i18n_origen');
		// enlaces con ancla a otras páginas (o a la misma) del idioma: el encabezado debe existir
		for (const m of sinSql.matchAll(/(?:href=["']|\]\()(\/[^"')\s?#]*)?#([^"')\s]+)/g)) {
			const destino = m[1] ? ficheroDeRuta(m[1]) : trad;
			if (!destino) continue;
			if (!anclasDe(destino).has(decodeURIComponent(m[2]))) errores.push(`ancla rota ${m[1] ?? ''}#${m[2]}`);
		}
		if (errores.length) fallos.push(`${rel}: ${errores.join(' · ')}`);
		else ok++;
	}
	problemas += fallos.length;
	console.log(`${lang}: ${ok} correctas, ${fallos.length} con avisos`);
	for (const f of fallos) console.log(`   ${f}`);
}
process.exitCode = problemas ? 1 : 0;
