// Herramientas del chat de datos, compartidas por la web (src/lib/components/Chat.svelte)
// y el servidor MCP (tools/mcp/servidor.mjs). JavaScript puro, sin dependencias: quien
// las usa inyecta `consultar(sql)` (DuckDB-WASM en el navegador, DuckDB en Node).
//
// La idea para que funcione con modelos pequeños: el modelo no ve las 270 tablas. Busca
// por palabras (buscar_tablas, sin modelo), lee la ficha de 1-3 tablas (describir_tabla)
// y escribe un SELECT sencillo sobre ellas (consultar_sql).

export const URL_WEB = 'https://spainfacts.org';
const MAX_FILAS_MODELO = 60; // filas que se le devuelven al modelo
const MAX_FILAS_GRAFICO = 5000;

// ---------- Búsqueda (BM25 sobre el catálogo) ----------

const VACIAS = new Set(
	'de la el los las del en y a por con para que un una al o lo se su sus es como mas más cuanto cuanta cuantos cuantas cual cuales cuál qué que dime dame espana españa españoles datos dato evolucion evolución hay sobre entre desde hasta tiene tienen tenia tenian actual actualmente ahora mismo cuesta cuestan reciente recientes ultimo ultima ultimos ultimas han ha sido era fue esta este'.split(
		' '
	)
);

const normalizar = (s) =>
	String(s ?? '')
		.toLowerCase()
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '');

// Raíz muy simple: quita plurales y algunas terminaciones frecuentes
const raiz = (p) => p.replace(/(iones|ion|es|s)$/, '').slice(0, 7);

const palabras = (s) =>
	normalizar(s)
		.split(/[^a-z0-9]+/)
		.filter((p) => p.length > 1 && !VACIAS.has(p))
		.map(raiz);

/** Vector int8 del catálogo (base64) */
function deBase64(b64) {
	const bin = atob(b64);
	const v = new Int8Array(bin.length);
	for (let i = 0; i < bin.length; i++) v[i] = (bin.charCodeAt(i) << 24) >> 24;
	return v;
}

export function crearIndice(catalogo) {
	const docs = catalogo.tablas.map((t) => {
		// Nombre, descripción y páginas pesan más que las columnas
		const texto = [
			t.nombre.replace(/_/g, ' '),
			t.nombre.replace(/_/g, ' '),
			t.descripcion,
			t.descripcion,
			...t.paginas.map((p) => `${p.titulo} ${p.titulo} ${p.ruta.replace(/[/-]/g, ' ')}`),
			...t.columnas.map((c) => `${c.nombre.replace(/_/g, ' ')} ${c.descripcion ?? ''}`)
		].join(' ');
		const tf = new Map();
		const ps = palabras(texto);
		for (const p of ps) tf.set(p, (tf.get(p) ?? 0) + 1);
		return { tabla: t, tf, largo: ps.length, enNombre: new Set(palabras(t.nombre.replace(/_/g, ' '))), vec: t.vec ? deBase64(t.vec) : null };
	});
	const df = new Map();
	for (const d of docs) for (const p of d.tf.keys()) df.set(p, (df.get(p) ?? 0) + 1);
	const media = docs.reduce((s, d) => s + d.largo, 0) / Math.max(docs.length, 1);
	return { docs, df, media, n: docs.length, catalogo };
}

// Cómo pregunta la gente -> cómo se llaman las tablas
const SINONIMOS = {
	habitantes: 'poblacion',
	habitante: 'poblacion',
	gente: 'poblacion',
	personas: 'poblacion',
	desempleo: 'paro',
	parados: 'paro',
	inflacion: 'ipc',
	precios: 'ipc',
	sueldo: 'salarios',
	sueldos: 'salarios',
	salario: 'salarios',
	coches: 'vehiculos turismos',
	alquileres: 'alquiler',
	pisos: 'vivienda',
	casas: 'vivienda',
	luz: 'electricidad',
	extranjeros: 'extranjeros inmigracion',
	inmigrantes: 'extranjeros inmigracion',
	delitos: 'criminalidad',
	crimen: 'criminalidad',
	ayuntamientos: 'municipios',
	alcaldes: 'alcaldes',
	jubilados: 'pensiones',
	hectareas: 'ha incendios',
	murieron: 'defunciones',
	muertes: 'defunciones',
	muertos: 'defunciones',
	fallecidos: 'defunciones',
	fallecimientos: 'defunciones',
	nacieron: 'nacimientos',
	bebes: 'nacimientos',
	quemado: 'incendios quemadas',
	quemadas: 'incendios quemadas',
	quemaron: 'incendios quemadas',
	co2: 'emisiones co2',
	contaminacion: 'emisiones',
	metro: 'm2 precio',
	metros: 'm2 precio',
	cuadrado: '',
	cuadrados: '',
	comunidades: 'ccaa comunidades',
	autonomias: 'ccaa'
};

const TERRITORIOS = new Set(
	'andalucia aragon asturias principado baleares balears illes canarias cantabria castilla leon mancha cataluna catalunya valenciana valencia comunitat extremadura galicia madrid murcia navarra foral vasco euskadi rioja ceuta melilla barcelona sevilla malaga zaragoza bilbao bizkaia alicante'.split(
		' '
	)
);

/**
 * @param {any} indice
 * @param {string} texto
 * @param {number} [n]
 * @param {number} [conFicha] cuántas de las primeras llevan su ficha compacta
 * @param {Float32Array|null} [vector] vector de la pregunta (crearEmbebedor): si llega, el
 *   ranking por palabras se combina con el semántico por fusión de rangos (RRF)
 */
export function buscarTablas(indice, texto, n = 8, conFicha = 1, vector = null) {
	// El sinónimo sustituye a la palabra: «habitantes» sale en muchas tablas, «población» no.
	// Años y territorios dicen cuándo y dónde, no de qué tema: solo meten ruido.
	const traducido = normalizar(texto)
		.split(/[^a-z0-9]+/)
		.filter((p) => !/^(19|20)\d\d$/.test(p) && !TERRITORIOS.has(p))
		.map((p) => SINONIMOS[p] ?? p)
		.join(' ');
	const consulta = [...new Set(palabras(traducido))];
	const k1 = 1.2;
	const b = 0.75;
	const puntuadas = indice.docs.map((d) => {
		let s = 0;
		for (const p of consulta) {
			const f = d.tf.get(p);
			if (!f) continue;
			const idf = Math.log(1 + (indice.n - indice.df.get(p) + 0.5) / (indice.df.get(p) + 0.5));
			s += (idf * f * (k1 + 1)) / (f + k1 * (1 - b + (b * d.largo) / indice.media));
			// El nombre de la tabla dice de qué va mejor que cualquier otro campo
			if (d.enNombre.has(p)) s += idf * 1.5;
		}
		// Desempate: entre tablas igual de relevantes, la más corta de nombre es la general
		s -= d.tabla.nombre.length * 0.001;
		return { d, s };
	});
	let ordenadas = puntuadas.filter((x) => x.s > 0).sort((a, b) => b.s - a.s);
	if (vector && indice.docs[0]?.vec) {
		// Fusión de rangos: palabras + significado. Una tabla sin palabras en común puede
		// entrar por el significado («murieron» -> defunciones)
		const rangoPalabras = new Map(ordenadas.map((x, i) => [x.d, i]));
		const semanticas = indice.docs
			.map((d) => {
				let dot = 0;
				for (let i = 0; i < d.vec.length; i++) dot += d.vec[i] * vector[i];
				return { d, s: dot };
			})
			.sort((a, b) => b.s - a.s);
		const rrf = (r) => (r === undefined ? 0 : 1 / (60 + r));
		ordenadas = semanticas
			.map((x, i) => ({ d: x.d, s: rrf(i) + rrf(rangoPalabras.get(x.d)) }))
			.sort((a, b) => b.s - a.s);
	}
	return ordenadas
		.slice(0, n)
		.map(({ d }, i) =>
			// La mejor va con su ficha compacta: los modelos pequeños no suelen pedirla
			i < conFicha
				? { tabla: d.tabla.tabla, descripcion: d.tabla.descripcion, ficha: fichaCompacta(d.tabla) }
				: {
						tabla: d.tabla.tabla,
						descripcion: d.tabla.descripcion,
						...(periodo(d.tabla) ? { periodo: periodo(d.tabla) } : {}),
						columnas: d.tabla.columnas.map((c) => c.nombre).join(', ')
					}
		);
}

/** Ficha corta en texto: una línea por columna con tipo, rango y valores válidos */
export function fichaCompacta(t) {
	const corto = (v) => String(v).replace(/\.0$/, '');
	const lineas = t.columnas.map((c) => {
		let l = `${c.nombre} (${c.tipo.toLowerCase()})`;
		if (c.min !== undefined) l += ` de ${corto(c.min)} a ${corto(c.max)}`;
		if (c.valores) l += `, valores: ${c.valores.slice(0, 20).map((v) => `'${v}'`).join(', ')}${c.valores.length > 20 ? '…' : ''}`;
		else if (c.ejemplos) l += `, ${c.distintos} valores distintos, p. ej.: ${c.ejemplos.slice(0, 4).map((v) => `'${v}'`).join(', ')}`;
		return l;
	});
	const ultimo = columnasTiempo(t).filter((c) => c.max !== undefined).map((c) => `${c.nombre} = ${corto(c.max)}`);
	const codigos = t.codigos ? `\n${t.codigos.nota}\nComunidades: ${t.codigos.ccaa}.` : '';
	return `${t.tabla} (${t.filas} filas).${ultimo.length ? ` Último periodo con datos: ${ultimo.join(', ')}.` : ''} Columnas:\n${lineas.join('\n')}${codigos}`;
}

const columnasTiempo = (t) => t.columnas.filter((c) => c.temporal);

/** "anio: 1994 – 2026" con la primera columna de tiempo que tenga rango */
function periodo(t) {
	const c = columnasTiempo(t).find((c) => c.min !== undefined);
	if (!c) return '';
	const corto = (v) => String(v).replace(/\.0$/, '').replace(/ 00:00:00$/, '');
	return `${c.nombre}: ${corto(c.min)} – ${corto(c.max)}`;
}

const tablasDeSQL = (catalogo, sql) =>
	[...new Set([...normalizar(sql).matchAll(/mother\s*\.\s*"?([a-z0-9_]+)/g)].map((m) => m[1]))]
		.map((n) => catalogo.tablas.find((x) => normalizar(x.nombre) === n))
		.filter(Boolean);

const fichasDeSQL = (catalogo, sql) => tablasDeSQL(catalogo, sql).map(fichaCompacta).join('\n\n') || 'La consulta no usa ninguna tabla mother.<nombre> que exista: usa buscar_tablas.';

const ES_TOTAL = /^(total|ambos sexos|todos|todas|total nacional|nacional)$/i;

/** Aviso si la consulta usa una tabla con filas de total o de varios niveles sin filtrarlas: suma dos veces */
function avisoTotales(catalogo, sql) {
	const texto = normalizar(sql);
	for (const t of tablasDeSQL(catalogo, sql)) {
		for (const c of t.columnas) {
			const mencionada = new RegExp(`\\b${c.nombre}\\b`).test(texto);
			if (mencionada) continue;
			if (c.nombre === 'nivel' && c.valores?.length > 1) {
				return `La tabla ${t.tabla} mezcla niveles (${c.valores.join(', ')}) y la consulta no filtra por nivel: cada persona o euro cuenta varias veces. Filtra, p. ej., nivel = 'pais' para España o nivel = 'ccaa' para comunidades.`;
			}
			const total = c.valores?.find((v) => ES_TOTAL.test(String(v).trim()));
			if (total && c.valores.length > 1) {
				return `La columna ${c.nombre} de ${t.tabla} tiene una fila '${total}' además del desglose (${c.valores.filter((v) => v !== total).slice(0, 4).join(', ')}) y la consulta no la filtra: suma dos veces. Filtra ${c.nombre} = '${total}' para el total.`;
			}
		}
	}
	return '';
}

/** Varias filas y ninguna columna que diga qué es cada una: el modelo cogería la primera */
function avisoSinIdentificar(filas) {
	if (filas.length < 2) return '';
	const cols = Object.keys(filas[0]);
	const identifica = cols.some(
		(c) => /^(anio|año|ano|year|fecha|mes|trimestre|periodo|date|dia)$/i.test(c) || filas.some((f) => typeof f[c] === 'string' || f[c] instanceof Date)
	);
	if (identifica) return '';
	return `Salen ${filas.length} filas y ninguna columna dice a qué corresponde cada una (${cols.join(', ')}). Añade al SELECT la columna que las distingue (fecha, comunidad, país...) o filtra para quedarte con la fila que se pregunta (p. ej. el último periodo y España).`;
}

/** Aviso si la consulta usa tablas con varios periodos y no menciona ninguna columna de tiempo */
function avisoPeriodo(catalogo, sql) {
	const texto = normalizar(sql);
	const nombres = new Set([...texto.matchAll(/mother\s*\.\s*"?([a-z0-9_]+)/g)].map((m) => m[1]));
	for (const n of nombres) {
		const t = catalogo.tablas.find((x) => normalizar(x.nombre) === n);
		if (!t) continue;
		const tiempo = columnasTiempo(t).filter((c) => c.min === undefined || c.min !== c.max);
		if (!tiempo.length) continue;
		if (tiempo.some((c) => new RegExp(`\\b${c.nombre}\\b`).test(texto))) continue;
		return `La tabla ${t.tabla} tiene varios periodos (${periodo(t) || tiempo.map((c) => c.nombre).join(', ')}) y la consulta no filtra ni agrupa por ${tiempo.map((c) => c.nombre).join(' / ')}: mezcla años. Para el dato actual filtra el último periodo, p. ej. WHERE ${tiempo[0].nombre} = (SELECT max(${tiempo[0].nombre}) FROM ${t.tabla}); para la evolución agrupa por ${tiempo[0].nombre}. Repite la consulta.`;
	}
	return '';
}

// ---------- Ficha de una tabla ----------

export function buscarFicha(catalogo, nombre) {
	// Sin distinguir mayúsculas: hay tablas como totalAnoProvincia
	const limpio = normalizar(nombre).replace(/^mother\./, '').trim();
	return catalogo.tablas.find((t) => normalizar(t.nombre) === limpio);
}

export function describirTabla(catalogo, nombre) {
	const t = buscarFicha(catalogo, nombre);
	if (!t) return { error: `No existe la tabla ${nombre}. Usa buscar_tablas para encontrar el nombre exacto.` };
	const nombres = new Set(t.columnas.map((c) => c.nombre));
	return {
		tabla: t.tabla,
		descripcion: t.descripcion,
		filas: t.filas,
		...(t.codigos ? { codigos_territorio: t.codigos } : {}),
		ultimo_periodo: Object.fromEntries(columnasTiempo(t).filter((c) => c.max !== undefined).map((c) => [c.nombre, c.max])),
		columnas: t.columnas.map((c) => {
			const o = { nombre: c.nombre, tipo: c.tipo };
			if (c.descripcion) o.descripcion = c.descripcion;
			if (c.min !== undefined) o.rango = `${c.min} – ${c.max}`;
			// Los códigos con su columna de nombre al lado no aportan: se omiten sus valores
			const conNombre = /^cod_/.test(c.nombre) && nombres.has(c.nombre.replace(/^cod_/, '') + '_nombre');
			if (c.valores && !conNombre) o.valores = c.valores;
			if (c.ejemplos) o.ejemplos = c.ejemplos;
			return o;
		}),
		ejemplo: t.ejemplo,
		paginas: t.paginas.map((p) => ({ titulo: p.titulo, url: URL_WEB + p.ruta }))
	};
}

// ---------- SQL de solo lectura ----------

const PROHIBIDO =
	/\b(copy|attach|detach|install|load|pragma|set|reset|create|insert|update|delete|drop|alter|export|import|call|checkpoint|vacuum|use|begin|commit|rollback|grant|truncate)\b/i;
const FUNCIONES_PROHIBIDAS =
	/\b(read_\w+|glob|parquet_\w+|sniff_csv|getenv|current_setting|query_table|query|duckdb_\w+|pragma_\w+|delta_scan|iceberg_scan)\s*\(/i;

/** Valida que sea una sola consulta de lectura sobre mother.* y le pone un tope de filas */
export function validarSQL(sql, limite = 1000) {
	let s = String(sql ?? '')
		.trim()
		.replace(/;\s*$/, '');
	// Fuera comentarios para que no escondan nada
	s = s.replace(/--[^\n]*/g, ' ').replace(/\/\*[\s\S]*?\*\//g, ' ');
	if (!/^(select|with)\b/i.test(s)) return { error: 'Solo se permiten consultas SELECT (o WITH ... SELECT).' };
	const sinTextos = s.replace(/'(?:[^']|'')*'/g, "''");
	if (sinTextos.includes(';')) return { error: 'Solo una consulta cada vez.' };
	if (PROHIBIDO.test(sinTextos)) return { error: 'La consulta contiene una orden no permitida: solo lectura.' };
	if (FUNCIONES_PROHIBIDAS.test(sinTextos)) return { error: 'No se pueden leer ficheros ni URLs: usa las tablas mother.*.' };
	// FROM 'fichero' o FROM "ruta/..."
	if (/\b(from|join)\s+['"]/i.test(s)) return { error: 'Usa las tablas mother.<nombre>, no rutas de ficheros.' };
	return { sql: `SELECT * FROM (\n${s}\n) AS consulta LIMIT ${limite}` };
}

// JSON seguro: BigInt y fechas a texto, números con decimales razonables
function limpiarValor(v) {
	if (typeof v === 'bigint') return Number(v);
	if (v instanceof Date) return v.toISOString().slice(0, 10);
	if (typeof v === 'number' && !Number.isInteger(v)) return Math.round(v * 1e4) / 1e4;
	return v;
}
const limpiarFilas = (filas) =>
	filas.map((f) => Object.fromEntries(Object.entries(f).map(([k, v]) => [k, limpiarValor(v)])));

// ---------- Definición de herramientas ----------

export const HERRAMIENTAS = [
	{
		name: 'buscar_tablas',
		description:
			'Busca en el catálogo de SpainFacts las tablas relacionadas con un tema (por palabras: "paro juvenil", "precio vivienda alquiler", "deuda comunidades"). Devuelve nombre, descripción, columnas y páginas de la web. Úsala primero.',
		input_schema: {
			type: 'object',
			properties: { texto: { type: 'string', description: 'Palabras clave del tema, en castellano' } },
			required: ['texto'],
			additionalProperties: false
		}
	},
	{
		name: 'describir_tabla',
		description:
			'Ficha completa de una tabla: columnas con tipo, rangos, valores posibles de las columnas de texto, filas de ejemplo y páginas de la web que la usan. Léela antes de escribir SQL sobre ella.',
		input_schema: {
			type: 'object',
			properties: { tabla: { type: 'string', description: 'Nombre de la tabla, p. ej. mother.ccaa_deuda' } },
			required: ['tabla'],
			additionalProperties: false
		}
	},
	{
		name: 'consultar_sql',
		description:
			'Ejecuta una consulta SELECT de DuckDB sobre las tablas mother.<nombre> y devuelve las filas (como mucho 60 al modelo). Agrega y filtra en SQL en vez de pedir tablas enteras.',
		input_schema: {
			type: 'object',
			properties: { sql: { type: 'string', description: 'Una sola consulta SELECT de DuckDB' } },
			required: ['sql'],
			additionalProperties: false
		}
	},
	{
		name: 'crear_grafico',
		description:
			'Muestra al usuario un gráfico o una tabla con el resultado de una consulta. Úsala cuando una serie temporal, una comparación o un ranking se entienda mejor viéndolo.',
		input_schema: {
			type: 'object',
			properties: {
				tipo: { type: 'string', enum: ['linea', 'barras', 'tabla'] },
				sql: { type: 'string', description: 'Consulta SELECT que devuelve los datos del gráfico' },
				x: { type: 'string', description: 'Columna del eje X (año, fecha o categoría)' },
				y: { type: 'string', description: 'Columna numérica del eje Y' },
				serie: { type: 'string', description: 'Columna opcional que separa varias líneas o barras (p. ej. ccaa). Cadena vacía si no hay.' },
				titulo: { type: 'string', description: 'Título con la unidad, p. ej. "Deuda por habitante (€ de 2025)"' }
			},
			required: ['tipo', 'sql', 'x', 'y', 'serie', 'titulo'],
			additionalProperties: false
		}
	}
];

// ---------- Ejecución ----------

/**
 * Ejecuta una herramienta y devuelve { resultado (texto para el modelo), grafico?, sql? }.
 * @param {string} nombre
 * @param {Record<string, any>} entrada
 * @param {{ catalogo: any, indice: any, consultar: (sql: string) => Promise<Record<string, unknown>[]> }} ctx
 */
export async function ejecutarHerramienta(nombre, entrada, ctx) {
	const json = (o) => JSON.stringify(o);
	try {
		if (nombre === 'buscar_tablas') {
			const r = buscarTablas(ctx.indice, entrada.texto ?? '');
			return { resultado: r.length ? json(r) : 'Ninguna tabla coincide. Prueba con otras palabras (sinónimos, tema más general).' };
		}
		if (nombre === 'describir_tabla') return { resultado: json(describirTabla(ctx.catalogo, entrada.tabla ?? '')) };
		if (nombre === 'consultar_sql') {
			const v = validarSQL(entrada.sql);
			if (v.error) return { resultado: json({ error: v.error }) };
			let filas;
			try {
				filas = limpiarFilas(await ctx.consultar(v.sql));
			} catch (e) {
				// Con el error va la ficha de las tablas usadas para que pueda corregir
				return { sql: entrada.sql, resultado: json({ error: String(e?.message ?? e).slice(0, 400), fichas: fichasDeSQL(ctx.catalogo, entrada.sql) }) };
			}
			if (!filas.length) {
				return {
					sql: entrada.sql,
					resultado: json({
						filas: 0,
						atencion: 'La consulta no devuelve filas: algún filtro usa un valor que no existe. Usa exactamente los valores de la ficha (o LIKE) y repite.',
						fichas: fichasDeSQL(ctx.catalogo, entrada.sql)
					})
				};
			}
			const recorte = filas.slice(0, MAX_FILAS_MODELO);
			const aviso = avisoPeriodo(ctx.catalogo, entrada.sql) || avisoTotales(ctx.catalogo, entrada.sql) || avisoSinIdentificar(filas);
			// Con el aviso no van los datos: si van, los modelos pequeños los usan e ignoran
			// el aviso. Así tienen que corregir la consulta para tener cifras.
			// Solo con modelos pequeños (ctx.estricto): los grandes (Claude por MCP o con clave)
			// reciben el aviso junto a los datos, porque a veces la consulta es legítima (count(*))
			if (aviso && ctx.estricto) return { sql: entrada.sql, resultado: json({ atencion: aviso, datos: 'No se muestran hasta que corrijas la consulta.' }) };
			return {
				sql: entrada.sql,
				resultado: json({
					...(aviso ? { atencion: aviso } : {}),
					filas: filas.length,
					...(filas.length > recorte.length ? { aviso: `Se muestran ${recorte.length} de ${filas.length} filas: agrega o filtra más en SQL.` } : {}),
					datos: recorte
				})
			};
		}
		if (nombre === 'crear_grafico') {
			const v = validarSQL(entrada.sql, MAX_FILAS_GRAFICO);
			if (v.error) return { resultado: json({ error: v.error }) };
			const filas = limpiarFilas(await ctx.consultar(v.sql));
			if (!filas.length) return { resultado: json({ error: 'La consulta no devuelve filas: no hay nada que dibujar.' }) };
			const cols = Object.keys(filas[0]);
			const serie = entrada.serie || '';
			for (const c of [entrada.x, entrada.y, serie].filter(Boolean)) {
				if (!cols.includes(c)) return { resultado: json({ error: `La columna ${c} no está en el resultado. Columnas: ${cols.join(', ')}` }) };
			}
			const tipo = ['linea', 'barras', 'tabla'].includes(entrada.tipo) ? entrada.tipo : 'tabla';
			return {
				sql: entrada.sql,
				grafico: { tipo, x: entrada.x, y: entrada.y, serie, titulo: entrada.titulo ?? '', filas, sql: entrada.sql },
				resultado: json({ ok: true, filas: filas.length, nota: 'Gráfico mostrado al usuario. No repitas todos los valores en el texto.' })
			};
		}
		return { resultado: json({ error: `Herramienta desconocida: ${nombre}` }) };
	} catch (e) {
		return { resultado: json({ error: String(e?.message ?? e).slice(0, 500) }) };
	}
}

// ---------- Instrucciones ----------

const NOMBRE_IDIOMA = { es: 'castellano', en: 'English', ca: 'català', gl: 'galego', eu: 'euskara' };

export function promptSistema(catalogo, lang = 'es', { graficos = true } = {}) {
	return `Eres el asistente de datos de SpainFacts (${URL_WEB}), una web con datos públicos oficiales de España (INE, Hacienda, Banco de España, REE, DGT, Eurostat...). Respondes preguntas consultando esos datos con las herramientas.

Cómo trabajar:
1. buscar_tablas con las palabras clave del tema.
2. describir_tabla de las 1-3 tablas más prometedoras.
3. consultar_sql con un SELECT de DuckDB sobre mother.<tabla>: filtra y agrega en SQL, usa los valores exactos que da la ficha.
${graficos ? `4. Si ayuda a entenderlo, crear_grafico.
5. ` : '4. '}Responde en ${NOMBRE_IDIOMA[lang] ?? 'castellano'}, breve, con las cifras clave y el periodo.

Reglas:
- No inventes cifras: todo número de la respuesta sale de una consulta. Si los datos no lo cubren, dilo.
- Casi todas las tablas tienen muchos años o trimestres: para «cuál tiene más», «cuánto es» o «ahora», filtra el último periodo; para la evolución, agrupa por año. Di siempre a qué periodo se refiere la cifra.
- Si un resultado trae "atencion" o "error", corrige la consulta y repítela; no le pidas ayuda al usuario.
- Compara por habitante y en euros reales (descontada la inflación) siempre que se pueda; los totales, solo como dato secundario.
- El año en curso suele estar incompleto en las sumas anuales: no lo presentes como una caída.
- ${catalogo?.notas?.[3] ?? ''}
- Al final cita la fuente: la tabla y, si la ficha la trae, la página de la web con su URL completa. Nunca inventes una URL.

Patrones de SQL:
- Dato más reciente: WHERE <columna de fecha> = (SELECT max(<columna de fecha>) FROM mother.<tabla>), o ORDER BY <columna de fecha> DESC LIMIT 1 si solo hay una serie.
- Un año concreto: WHERE anio = 2010; si la tabla es trimestral o mensual y piden «a finales de», quédate con el último trimestre o mes de ese año.
- «Cuál tiene más/menos X»: ORDER BY la columna que mide exactamente X (si preguntan por % del PIB, la columna en %, no la de euros).
- Si la tabla tiene columnas como nivel, sexo o territorio, filtra lo que piden (p. ej. nivel = 'pais', sexo = 'Total' para España).
- En la respuesta da la cifra con su unidad y el periodo exacto que sale del resultado (p. ej. «2.º trimestre de 2026», «septiembre de 2026»).`;
}

// ---------- Protocolo JSON para modelos pequeños (sin llamadas a herramientas nativas) ----------

export function promptProtocoloJSON() {
	const lista = HERRAMIENTAS.map((h) => {
		const props = Object.entries(h.input_schema.properties)
			.map(([k, v]) => `"${k}": ${v.enum ? v.enum.map((e) => `"${e}"`).join('|') : '"..."'}`)
			.join(', ');
		return `{"accion": "${h.name}", ${props}}  -> ${h.description}`;
	}).join('\n');
	return `
Responde SIEMPRE con un único objeto JSON, sin texto alrededor. Acciones posibles:
${lista}
{"accion": "responder", "texto": "..."}  -> respuesta final al usuario (solo cuando ya tengas los datos).
Tras cada acción recibirás su resultado y elegirás la siguiente.`;
}

/** Interpreta la respuesta JSON de un modelo pequeño: { accion, entrada } o { error } */
export function leerAccionJSON(texto) {
	const m = String(texto ?? '').match(/\{[\s\S]*\}/);
	if (!m) return { error: 'No has respondido con un objeto JSON.' };
	let o;
	try {
		o = JSON.parse(m[0]);
	} catch {
		return { error: 'El JSON no es válido.' };
	}
	const accion = o.accion;
	if (accion === 'responder') return { accion, texto: String(o.texto ?? '') };
	if (!HERRAMIENTAS.some((h) => h.name === accion)) return { error: `Acción desconocida: ${accion}` };
	const { accion: _, ...entrada } = o;
	return { accion, entrada };
}
