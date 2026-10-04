// Ejecuta las consultas SQL de páginas de Evidence contra un DuckDB local (sin build), para
// comprobar tras cambiar un modelo dbt que las páginas que lo usan siguen funcionando.
// Cada mother.<tabla> se crea como vista con su sources/mother/<tabla>.sql sobre la base.
//
//   node tools/chat/semantica/probar-paginas.mjs --db data/agente-1.duckdb pages/territorios/index.md [...]
//   node tools/chat/semantica/probar-paginas.mjs --db ... --tabla ccaa_deuda   (todas las páginas que la usan, en castellano)
//
// Las consultas con ${inputs...} se prueban con el primer valor de su desplegable si se puede
// deducir; si no, se saltan (se avisa). Una consulta que no devuelve filas se marca como aviso.

import fs from 'node:fs';
import path from 'node:path';
import { DuckDBInstance } from '@duckdb/node-api';

const args = process.argv.slice(2);
const valor = (n) => (args.includes(n) ? args[args.indexOf(n) + 1] : null);
const DB = valor('--db') ?? 'data/spainfacts.duckdb';
const TABLA = valor('--tabla');
const IDIOMAS = /^pages\/(en|ca|gl|eu)\//;

function recorrer(dir, fuera = []) {
	for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
		const p = path.join(dir, e.name);
		if (e.isDirectory()) recorrer(p, fuera);
		else if (e.name.endsWith('.md')) fuera.push(p.replace(/\\/g, '/'));
	}
	return fuera;
}
let paginas = args.filter((a, i) => a.endsWith('.md') && !['--db', '--tabla'].includes(args[i - 1]));
if (TABLA) paginas = recorrer('pages').filter((p) => !IDIOMAS.test(p) && new RegExp(`mother\\.${TABLA}\\b`, 'i').test(fs.readFileSync(p, 'utf8')));
if (!paginas.length) {
	console.log('Sin páginas que probar.');
	process.exit(0);
}

// Base en memoria con el fichero adjunto en solo lectura: las vistas mother.* viven en memoria
const con = await (await DuckDBInstance.create(':memory:')).connect();
await con.run(`ATTACH '${DB.replace(/'/g, "''")}' AS datos (READ_ONLY)`);
await con.run('CREATE SCHEMA memory.mother');
await con.run("SET search_path = 'datos.main'");
const vistas = new Set();
async function vista(t) {
	if (vistas.has(t)) return;
	vistas.add(t);
	const f = `sources/mother/${t}.sql`;
	if (!fs.existsSync(f)) throw new Error(`no existe sources/mother/${t}.sql`);
	const sql = fs.readFileSync(f, 'utf8').replace(/--[^\n]*/g, '').trim().replace(/;$/, '');
	// Tablas sin esquema -> datos.main (si no, la vista mother.x «SELECT * FROM x» se lee a sí misma);
	// los nombres de CTE se dejan como están
	const ctes = new Set([...sql.matchAll(/\b(\w+)\s+AS\s*\(/gi)].map((m) => m[1].toLowerCase()));
	const cuerpo = sql.replace(/\b(FROM|JOIN)\s+([a-z_]\w*)\b(?!\s*[.(])/gi, (m, k, n) => (ctes.has(n.toLowerCase()) ? m : `${k} datos.main.${n}`));
	await con.run(`CREATE OR REPLACE VIEW memory.mother.${t} AS ${cuerpo}`);
}

let errores = 0;
let avisos = 0;
for (const pagina of paginas) {
	const texto = fs.readFileSync(pagina, 'utf8');
	const bloques = new Map([...texto.matchAll(/```sql\s+([\w-]+)[^\n]*\n([\s\S]*?)```/g)].map((m) => [m[1], m[2]]));
	console.log(`\n${pagina} (${bloques.size} consultas)`);
	// ${nombre} -> (sql de esa consulta), recursivo
	const expandir = (sql, prof = 0) =>
		prof > 8
			? sql
			: sql.replace(/\$\{\s*([\w-]+)\s*\}/g, (m, n) => (bloques.has(n) ? `(${expandir(bloques.get(n), prof + 1)})` : m));
	for (const [nombre, sqlBruto] of bloques) {
		let sql = expandir(sqlBruto);
		// Parámetros de la página (${params...}, ${inputs...}): valores ficticios; la consulta se
		// comprueba (columnas, tipos) pero sus filas no cuentan
		const conParametros = /\$\{/.test(sql);
		if (conParametros) sql = sql.replace(/'\$\{[^}]+\}'/g, "'x'").replace(/\$\{[^}]+\}/g, 'NULL');
		sql = sql.replace(/mother\.("?)(\w+)\1/gi, (m, q, t) => `memory.mother.${t}`);
		try {
			for (const t of new Set([...sql.matchAll(/memory\.mother\.(\w+)/g)].map((m) => m[1]))) await vista(t);
			const filas = (await con.runAndReadAll(sql)).getRowObjectsJS();
			if (!filas.length && !conParametros) {
				avisos++;
				console.log(`  ⚠ ${nombre}: 0 filas`);
			}
		} catch (e) {
			// Con valores ficticios, solo cuenta lo que apunta a una columna o tabla que no existe
			if (conParametros && !/not found|does not exist|Referenced column|Catalog Error/i.test(String(e.message))) continue;
			errores++;
			console.log(`  ✗ ${nombre}: ${String(e.message).split('\n')[0].slice(0, 200)}`);
		}
	}
}
console.log(`\n${paginas.length} páginas: ${errores} errores, ${avisos} consultas sin filas`);
process.exitCode = errores ? 1 : 0;
