// Valida las fichas de la capa semántica (tools/chat/semantica/lote-*.json) contra los datos:
// que las columnas existan, que los valores citados (totales, España, filtros) existan en la
// tabla y que el formato sea el de LEEME.md.
//
//   node tools/chat/semantica/validar.mjs [lote-3.json ...]
//   node tools/chat/semantica/validar.mjs --db data/limpieza-1.duckdb [--tablas a,b]   (contra un DuckDB
//     local con los modelos ya reconstruidos, en vez de los parquets publicados)

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { DuckDBInstance } from '@duckdb/node-api';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const DATOS = (process.env.SPAINFACTS_PARQUETS ? process.env.SPAINFACTS_PARQUETS.replace(/\\/g, '/') + '/mother' : '.evidence/template/static/data/mother');
const TIPOS = new Set(['flujo', 'nivel', 'tasa', 'porcentaje', 'media', 'precio', 'indice', 'ratio']);
const GRANOS = new Set(['diario', 'semanal', 'mensual', 'trimestral', 'semestral', 'anual', 'curso', 'sin_tiempo']);

const args = process.argv.slice(2);
const opcion = (n) => (args.includes(n) ? args[args.indexOf(n) + 1] : null);
const DB = opcion('--db');
const SOLO = opcion('--tablas') ? new Set(opcion('--tablas').split(',')) : null;
const sueltos = args.filter((a, i) => a.endsWith('.json') && !['--db', '--tablas'].includes(args[i - 1]));
const ficheros = sueltos.length
	? sueltos.map((f) => (path.isAbsolute(f) ? f : path.join(aqui, path.basename(f))))
	: fs.readdirSync(aqui).filter((f) => /^lote-.*\.json$/.test(f)).map((f) => path.join(aqui, f));

const con = await (await DuckDBInstance.create(':memory:')).connect();
const q = async (sql) => (await con.runAndReadAll(sql)).getRowObjectsJS();
if (DB) {
	await con.run(`ATTACH '${DB.replace(/'/g, "''")}' AS datos (READ_ONLY)`);
	await con.run("SET search_path = 'datos.main'");
}
/** La tabla publicada: su sources/mother/<tabla>.sql sobre el DuckDB, o el parquet extraído */
function origen(tabla) {
	if (!DB) {
		const parquet = `${DATOS}/${tabla}/${tabla}.parquet`;
		return fs.existsSync(parquet) ? `read_parquet('${parquet}')` : null;
	}
	const f = `sources/mother/${tabla}.sql`;
	if (!fs.existsSync(f)) return null;
	const sql = fs.readFileSync(f, 'utf8').replace(/--[^\n]*/g, '').trim().replace(/;$/, '');
	return `(${sql})`;
}
const lit = (v) => `'${String(v).replace(/'/g, "''")}'`;

let errores = 0;
let fichas = 0;
const vistas = new Set();
for (const f of ficheros) {
	let lista;
	try {
		lista = JSON.parse(fs.readFileSync(f, 'utf8'));
	} catch (e) {
		console.log(`✗ ${path.basename(f)}: JSON no válido (${e.message})`);
		errores++;
		continue;
	}
	for (const s of lista) {
		fichas++;
		const mal = [];
		if (vistas.has(s.tabla)) mal.push('tabla repetida');
		vistas.add(s.tabla);
		if (SOLO && !SOLO.has(s.tabla)) continue;
		const fuente = origen(s.tabla);
		if (!fuente) {
			console.log(`✗ ${s.tabla}: no existe la tabla publicada`);
			errores++;
			continue;
		}
		const cols = new Map((await q(`DESCRIBE SELECT * FROM ${fuente}`)).map((c) => [c.column_name, c.column_type]));
		const existe = (c, donde) => {
			if (c !== null && c !== undefined && !cols.has(c)) mal.push(`${donde}: no existe la columna ${c}`);
		};
		const hayValor = async (c, v, donde) => {
			if (!cols.has(c)) return;
			const cond = typeof v === 'string' ? `CAST(${JSON.stringify(c)} AS VARCHAR) = ${lit(v)}` : `${JSON.stringify(c)} = ${v}`;
			const [{ n }] = await q(`SELECT count(*)::INTEGER AS n FROM ${fuente} WHERE ${cond}`);
			if (!n) mal.push(`${donde}: ${c} = '${v}' no aparece en los datos`);
		};
		if (typeof s.usar !== 'boolean') mal.push('usar debe ser true/false');
		if (s.usar) {
			if (!s.tema) mal.push('falta tema');
			if (!Array.isArray(s.preguntas) || s.preguntas.length < 2) mal.push('faltan preguntas (2-4)');
			if (!Array.isArray(s.medidas) || !s.medidas.length) mal.push('faltan medidas');
			const principales = (s.medidas ?? []).filter((m) => m.principal).length;
			if (principales !== 1) mal.push(`debe haber exactamente una medida principal (hay ${principales})`);
			for (const m of s.medidas ?? []) {
				existe(m.columna, 'medida');
				if (m.real) existe(m.real, 'medida.real');
				if (m.unidad_columna) existe(m.unidad_columna, 'medida.unidad_columna');
				if (m.escala !== undefined && typeof m.escala !== 'number') mal.push(`medida ${m.columna}: escala no numérica`);
				if (!TIPOS.has(m.tipo)) mal.push(`medida ${m.columna}: tipo «${m.tipo}» no válido`);
				if (!m.nombre) mal.push(`medida ${m.columna}: falta nombre`);
				if (cols.has(m.columna) && !/INT|DOUBLE|FLOAT|DECIMAL|REAL|NUMERIC/i.test(cols.get(m.columna))) mal.push(`medida ${m.columna}: no es numérica`);
			}
			if (s.tiempo) {
				existe(s.tiempo.columna, 'tiempo');
				if (!GRANOS.has(s.tiempo.grano)) mal.push(`tiempo: grano «${s.tiempo.grano}» no válido`);
			}
			if (s.territorio) {
				for (const k of ['nivel', 'codigo', 'nombre']) existe(s.territorio[k], `territorio.${k}`);
				if (s.territorio.espana) {
					existe(s.territorio.espana.columna, 'territorio.espana');
					await hayValor(s.territorio.espana.columna, s.territorio.espana.valor, 'territorio.espana');
				}
			}
			for (const d of s.dimensiones ?? []) {
				existe(d.columna, 'dimensión');
				if (d.total !== null && d.total !== undefined) await hayValor(d.columna, d.total, `dimensión ${d.columna}`);
				if (d.defecto !== null && d.defecto !== undefined) await hayValor(d.columna, d.defecto, `dimensión ${d.columna} (defecto)`);
			}
			for (const fl of s.filtros ?? []) {
				existe(fl.columna, 'filtro');
				if ('distinto' in fl) await hayValor(fl.columna, fl.distinto, 'filtro.distinto');
				else await hayValor(fl.columna, fl.valor, 'filtro');
			}
		}
		if (mal.length) {
			errores += mal.length;
			console.log(`✗ ${s.tabla}: ${mal.join(' · ')}`);
		}
	}
}
console.log(`${fichas} fichas, ${errores} errores`);
process.exitCode = errores ? 1 : 0;
