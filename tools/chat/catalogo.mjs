// Catálogo de datos para el chat y el servidor MCP.
//
// Describe cada tabla que publica la web (una por consulta de sources/mother) para que
// un modelo, incluso uno pequeño, encuentre la tabla adecuada y escriba el SQL sin
// adivinar: descripción (de los .yml de dbt), columnas con tipo, filas, rango de años,
// valores posibles de las columnas de texto con pocas categorías y páginas que la usan.
//
//   node tools/chat/catalogo.mjs                      -> build/chat/catalogo.json
//   node tools/chat/catalogo.mjs --salida ruta.json
//   node tools/chat/catalogo.mjs --datos <carpeta>    -> carpeta con <tabla>/<tabla>.parquet
//
// Se ejecuta en el deploy después de `evidence sources` (necesita los parquets).

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { parse as parseYaml } from 'yaml';
import { DuckDBInstance } from '@duckdb/node-api';

const args = process.argv.slice(2);
const valor = (n, porDefecto) => {
	const i = args.indexOf(n);
	return i >= 0 ? args[i + 1] : porDefecto;
};
const SALIDA = valor('--salida', 'build/chat/catalogo.json');
const DATOS = valor('--datos', '.evidence/template/static/data/mother');
const FUENTES = 'sources/mother';
const MARTS = 'transform/models/marts';
const PAGINAS = 'pages';
const IDIOMAS = new Set(['en', 'ca', 'gl', 'eu']);

// Columnas de texto con hasta este número de valores distintos: se listan todos
const MAX_CATEGORIAS = 40;

// ---------- Descripciones de dbt ----------
const descripciones = new Map(); // modelo -> { descripcion, columnas: {col: desc} }
for (const f of fs.readdirSync(MARTS).filter((f) => f.endsWith('.yml'))) {
	const doc = parseYaml(fs.readFileSync(path.join(MARTS, f), 'utf8')) ?? {};
	for (const m of doc.models ?? []) {
		const columnas = {};
		for (const c of m.columns ?? []) if (c.description) columnas[c.name] = c.description;
		descripciones.set(m.name, { descripcion: m.description ?? '', columnas });
	}
}

// ---------- Páginas que usan cada tabla ----------
function recorrer(dir, fuera = []) {
	for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
		const p = path.join(dir, e.name);
		if (e.isDirectory()) {
			if (dir === PAGINAS && IDIOMAS.has(e.name)) continue;
			recorrer(p, fuera);
		} else if (e.name.endsWith('.md')) fuera.push(p);
	}
	return fuera;
}
const paginasPorTabla = new Map();
for (const f of recorrer(PAGINAS)) {
	const texto = fs.readFileSync(f, 'utf8');
	const titulo = texto.match(/^title:\s*["']?(.+?)["']?\s*$/m)?.[1] ?? '';
	const ruta =
		'/' +
		path
			.relative(PAGINAS, f)
			.replace(/\\/g, '/')
			.replace(/(^|\/)index\.md$/, '')
			.replace(/\.md$/, '');
	for (const t of new Set(texto.match(/mother\.[a-z0-9_]+/gi) ?? [])) {
		const nombre = t.slice('mother.'.length).toLowerCase();
		if (!paginasPorTabla.has(nombre)) paginasPorTabla.set(nombre, []);
		paginasPorTabla.get(nombre).push({ ruta, titulo });
	}
}

// ---------- Tablas ----------
const instancia = await DuckDBInstance.create(':memory:');
const con = await instancia.connect();
const filas = async (sql) => (await con.runAndReadAll(sql)).getRowObjectsJson();
const id = (s) => `"${String(s).replace(/"/g, '""')}"`;
const esAnio = (c) => /^(anio|año|ano|year|ejercicio)$/i.test(c);
const esFecha = (c) => /^(fecha|fecha_\w+|periodo|mes|dia|date|ts_utc|ts|trimestre)$/i.test(c);
// Rangos legibles: 62.099999999999994 -> 62.1
const redondear = (v) => (v !== null && v !== '' && !isNaN(v) ? String(Number(Number(v).toPrecision(6))) : v);

const tablas = [];
const sinDatos = [];
const excluidas = [];
for (const f of fs.readdirSync(FUENTES).filter((f) => f.endsWith('.sql')).sort()) {
	const nombre = f.slice(0, -4);
	const sql = fs.readFileSync(path.join(FUENTES, f), 'utf8').trim();
	const parquet = path.join(DATOS, nombre, `${nombre}.parquet`);
	if (!fs.existsSync(parquet)) {
		sinDatos.push(nombre);
		continue;
	}
	// Importaciones antiguas sin limpiar (columnas como Year, Provincias) que ninguna página
	// usa: duplican tablas buenas y confunden al chat (totalAno*, de la primera versión)
	if (!paginasPorTabla.has(nombre.toLowerCase())) {
		const cabecera = await filas(`DESCRIBE SELECT * FROM read_parquet('${parquet.replace(/\\/g, '/').replace(/'/g, "''")}')`);
		if (cabecera.some((c) => !/^[a-z0-9_ñ]+$/.test(c.column_name))) {
			excluidas.push(nombre);
			continue;
		}
	}
	const origen = sql.match(/\bfrom\s+([a-z0-9_.]+)/i)?.[1]?.split('.').at(-1) ?? nombre;
	const dbt = descripciones.get(origen) ?? descripciones.get(nombre) ?? { descripcion: '', columnas: {} };
	const lectura = `read_parquet('${parquet.replace(/\\/g, '/').replace(/'/g, "''")}')`;

	const [{ n }] = await filas(`SELECT count(*)::INTEGER AS n FROM ${lectura}`);
	const esquema = await filas(`DESCRIBE SELECT * FROM ${lectura}`);
	const columnas = [];
	for (const { column_name: col, column_type: tipo } of esquema) {
		const c = { nombre: col, tipo };
		if (dbt.columnas[col]) c.descripcion = dbt.columnas[col];
		const numerico = /INT|DOUBLE|FLOAT|DECIMAL|REAL|NUMERIC/i.test(tipo);
		if (numerico || /DATE|TIME/i.test(tipo)) {
			const [r] = await filas(`SELECT min(${id(col)})::VARCHAR AS min, max(${id(col)})::VARCHAR AS max FROM ${lectura}`);
			c.min = numerico ? redondear(r.min) : r.min?.replace(/ 00:00:00$/, '');
			c.max = numerico ? redondear(r.max) : r.max?.replace(/ 00:00:00$/, '');
		} else if (/VARCHAR|TEXT|STRING/i.test(tipo) && (esAnio(col) || esFecha(col))) {
			// Periodos en texto ('2026-T2', '2026-09'): se ordenan bien como texto; el rango
			// dice cuál es el último, cosa que unos ejemplos sueltos no dicen
			const [r] = await filas(`SELECT min(${id(col)}) AS min, max(${id(col)}) AS max FROM ${lectura}`);
			c.min = r.min;
			c.max = r.max;
		} else if (/VARCHAR|TEXT|STRING/i.test(tipo)) {
			const [{ d }] = await filas(`SELECT count(DISTINCT ${id(col)})::INTEGER AS d FROM ${lectura}`);
			c.distintos = d;
			const lim = d <= MAX_CATEGORIAS ? MAX_CATEGORIAS : 5;
			const vals = await filas(
				`SELECT ${id(col)}::VARCHAR AS v FROM ${lectura} WHERE ${id(col)} IS NOT NULL GROUP BY 1 ORDER BY count(*) DESC, 1 LIMIT ${lim}`
			);
			c[d <= MAX_CATEGORIAS ? 'valores' : 'ejemplos'] = vals.map((x) => x.v);
		}
		if (esAnio(col) || esFecha(col) || /DATE|TIMESTAMP/i.test(tipo)) c.temporal = true;
		columnas.push(c);
	}
	const ejemplo = await filas(`SELECT * FROM ${lectura} LIMIT 2`);

	tablas.push({
		nombre,
		tabla: `mother.${nombre}`,
		descripcion: dbt.descripcion,
		filas: n,
		columnas,
		ejemplo,
		paginas: paginasPorTabla.get(nombre) ?? []
	});
}
// Tablas que identifican el territorio solo con (nivel, cod): sin la equivalencia un modelo
// no sabe que Andalucía es la 01. Los códigos son los del INE, los de mother.territorios
// (comprobado que coinciden en todas las tablas con nombre; Hacienda usa otros, pero esas
// tablas traen el nombre al lado y no entran aquí).
const refTerritorios = path.join(DATOS, 'territorios', 'territorios.parquet');
if (fs.existsSync(refTerritorios)) {
	const ref = await filas(
		`SELECT nivel, cod, any_value(nombre) AS nombre FROM read_parquet('${refTerritorios.replace(/\\/g, '/')}') WHERE nivel IN ('ccaa', 'provincia') GROUP BY 1, 2 ORDER BY 1, 2`
	);
	const lista = (nivel) => ref.filter((r) => r.nivel === nivel).map((r) => `${r.cod} ${r.nombre}`).join(', ');
	for (const t of tablas) {
		const cols = new Set(t.columnas.map((c) => c.nombre));
		if (cols.has('nivel') && cols.has('cod') && !cols.has('nombre')) {
			t.codigos = {
				ccaa: lista('ccaa'),
				provincia: lista('provincia'),
				nota: `cod son códigos del INE: con nivel = 'ccaa', de comunidad; con nivel = 'provincia', de provincia. Para los nombres: JOIN mother.territorios USING (nivel, cod).`
			};
		} else if (!cols.has('nivel')) {
			// Columnas de código sin nombre al lado: cod_ccaa, cod_prov, o un cod con valores de
			// comunidad (00-19). columnas = { columna: nivel } para que el chat los traduzca
			const codigosCcaa = new Set(ref.filter((r) => r.nivel === 'ccaa').map((r) => r.cod).concat('00'));
			const columnas = {};
			const conNombre = ['ccaa', 'ccaa_nombre', 'nombre', 'comunidad', 'territorio'].some((n) => cols.has(n));
			if (cols.has('cod_ccaa') && !conNombre) columnas.cod_ccaa = 'ccaa';
			if (cols.has('cod_prov') && !['provincia', 'nombre_provincia', 'nombre'].some((n) => cols.has(n))) columnas.cod_prov = 'provincia';
			const cod = t.columnas.find((c) => c.nombre === 'cod');
			if (cod && !conNombre && cod.valores?.length && cod.valores.every((v) => codigosCcaa.has(v))) columnas.cod = 'ccaa';
			if (Object.keys(columnas).length) {
				const con00 = Object.keys(columnas).filter((c) => t.columnas.find((x) => x.nombre === c)?.valores?.includes('00'));
				t.codigos = {
					ccaa: lista('ccaa'),
					provincia: lista('provincia'),
					columnas,
					nota: `${Object.entries(columnas)
						.map(([c, n]) => `${c} son códigos de ${n === 'ccaa' ? 'comunidad' : 'provincia'} del INE`)
						.join('; ')}.${con00.length ? ` El código 00 es el total de España.` : ''}`
				};
			}
		}
	}
}
con.closeSync?.();

// ---------- Vectores para la búsqueda semántica ----------
// Con un modelo pequeño de embeddings (el mismo que carga el navegador en /chat) se guarda
// un vector por tabla, así «murieron» encuentra «defunciones» sin listas de sinónimos.
// Modelo elegido con tools/chat/evaluacion (2026-10-03): EmbeddingGemma 300M pone la tabla
// correcta entre las 6 primeras en el 90-100 % de las preguntas (e5-small 78-95 %, solo
// palabras 68-95 %). Recortado a 256 dimensiones (Matryoshka) rinde igual y pesa un tercio.
// Se guardan cuantizados a int8 en base64 (256 bytes por tabla).
const EMBEDDINGS = {
	modelo: 'onnx-community/embeddinggemma-300m-ONNX',
	dtype: 'q4',
	dims: 256,
	prefijo_consulta: 'task: search result | query: ',
	prefijo_documento: 'title: none | text: '
};
let embeddings = null;
if (!args.includes('--sin-vectores')) {
	const { pipeline, env } = await import('@huggingface/transformers');
	// Ruta corta (onnxruntime no abre rutas de más de 260 caracteres en Windows); en el deploy
	// esta carpeta va en la caché de Actions para no descargar el modelo cada vez
	env.cacheDir = process.env.SPAINFACTS_MODELOS ?? path.join(os.homedir(), '.cache', 'tjs');
	const extraer = await pipeline('feature-extraction', EMBEDDINGS.modelo, { dtype: EMBEDDINGS.dtype });
	const textoTabla = (t) =>
		`${EMBEDDINGS.prefijo_documento}${t.nombre.replace(/_/g, ' ')}. ${t.descripcion} ${t.paginas.map((p) => p.titulo).join('. ')}. Columnas: ${t.columnas
			.map((c) => c.nombre.replace(/_/g, ' '))
			.join(', ')}`.slice(0, 1500);
	for (const t of tablas) {
		const v = (await extraer(textoTabla(t), { pooling: 'mean', normalize: true })).data.slice(0, EMBEDDINGS.dims);
		const norma = Math.hypot(...v);
		t.vec = Buffer.from(Int8Array.from(v, (x) => Math.max(-127, Math.min(127, Math.round((x / norma) * 127)))).buffer).toString('base64');
	}
	embeddings = { ...EMBEDDINGS, escala: 127 };
}

const catalogo = {
	generado: new Date().toISOString(),
	...(embeddings ? { embeddings } : {}),
	notas: [
		'Las tablas se consultan como mother.<nombre> con SQL de DuckDB.',
		'Principio de la web: comparar siempre por habitante y en euros reales; los totales solo como dato secundario.',
		'Las sumas anuales del año en curso están incompletas: no presentarlas como caída.',
		'Códigos de comunidad autónoma: Hacienda y el INE usan numeraciones distintas; unir por nombre o por la tabla de equivalencias, nunca por el código a ciegas.'
	],
	tablas
};

fs.mkdirSync(path.dirname(SALIDA), { recursive: true });
fs.writeFileSync(SALIDA, JSON.stringify(catalogo));
const kb = Math.round(fs.statSync(SALIDA).size / 1024);
console.log(`Catálogo: ${tablas.length} tablas, ${kb} KB -> ${SALIDA}`);
if (sinDatos.length) console.log(`  Sin parquet (no incluidas): ${sinDatos.join(', ')}`);
if (excluidas.length) console.log(`  Excluidas (sin página y columnas sin normalizar): ${excluidas.join(", ")}`);
