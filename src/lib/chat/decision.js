// Chat por decisiones: el modelo no escribe SQL ni texto. Responde preguntas cerradas
// (qué tabla, qué cifra, qué territorio...) eligiendo entre opciones que existen en el
// catálogo, y el código traduce esas decisiones a un SQL siempre válido y redacta la
// respuesta con una plantilla. Patrón de los "modelos de decisión" tipo Jev: una pasada por
// pregunta, sin generación, sin alucinaciones.
//
// Lo que se puede deducir de la pregunta sin modelo (años, mes, «más/menos», «desde»,
// «récord», qué nivel territorial) se deduce con reglas; el modelo solo decide lo ambiguo.
//
// Quien lo usa inyecta:
//   decidir(contexto, pregunta, opciones) -> Promise<índice | { indice, probs }>
//   ctx.consultar(sql) -> Promise<filas>
//   ctx.embeber(texto) -> Promise<vector>   (opcional: búsqueda y columnas por significado)

import { buscarTablas, buscarFicha, URL_WEB } from './herramientas.js';

const MAX_OPCIONES = 26; // una letra por opción
const MAX_MEDIDAS = 8; // columnas candidatas que ve el modelo
const PRIOR_BUSQUEDA = 0.6; // peso del puesto en la búsqueda al elegir tabla (log-probabilidad)
const ES_TOTAL = /^(total|ambos sexos|todos|todas|total nacional|nacional|españa|es)$/i;
const MESES = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

const normalizar = (s) =>
	String(s ?? '')
		.toLowerCase()
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '');

// Palabras que no identifican un valor: «¿qué comunidad...?» no nombra la Comunidad Valenciana
const NO_NOMBRAN = new Set(
	'que cual cuales cuanto cuanta cuantos cuantas como donde cuando quien del las los una unos unas por para con sin sobre entre tiene tienen tenia hay son esta estan este esa ese fue han ha mas menos mayor menor gente personas cada media medio total comunidad comunidades autonoma autonomas autonomia autonomias region regiones provincia provincias municipio municipios ciudad ciudades capital pueblo pueblos pais paises territorio territorios zona espanol espanoles actual actualmente ahora hoy dato datos ultimo ultima ultimos ultimas gran grande grandes pequeno pequena marca marcas tipo tipos grupo grupos sector sectores partido partidos ano anos'.split(
		' '
	)
);
const palabras = (s) => new Set(normalizar(s).split(/[^a-z0-9]+/).filter((p) => p.length > 2 && !NO_NOMBRAN.has(p) && !/^(19|20)\d\d$/.test(p)));
const id = (c) => `"${String(c).replace(/"/g, '""')}"`;
const esCodigo = (c) => /^cod(_\w+)?$/.test(c); // columnas de código: en el texto va el nombre, no el código
const lit = (v) => (typeof v === 'number' ? String(v) : `'${String(v).replace(/'/g, "''")}'`);

// ---------- Intención (sin modelo) ----------

/** Lo que la pregunta dice por sí misma: periodo pedido, orden, si compara territorios... */
export function leerIntencion(pregunta) {
	const q = normalizar(pregunta);
	const anios = [...q.matchAll(/\b(19|20)\d\d\b/g)].map((m) => Number(m[0]));
	if (/antes de la pandemia|antes del covid|prepandemia/.test(q)) anios.push(2019);
	const mes = MESES.findIndex((m) => new RegExp(`\\b${m}\\b`).test(q));
	const cambio =
		/\bdesde\b|\bque en\b|\bque antes\b|\brespecto\b|comparad|diferencia|\b(ha|han|habia|habian) (subido|bajado|crecido|caido|aumentado|disminuido|cambiado|mejorado|empeorado)\b/.test(q);
	const serie = /evolucion|como ha (ido|evolucionado|cambiado)|a lo largo|tendencia|ultimos \d+ anos|ano a ano/.test(q);
	const historico = /registrad|de la historia|nunca|record|historic|jamas|de siempre/.test(q);
	const nivel = /\b(municipio|municipios|ciudad|ciudades|pueblo|pueblos|ayuntamiento|ayuntamientos)\b/.test(q)
		? 'municipio'
		: /\b(provincia|provincias)\b/.test(q)
			? 'provincia'
			: /\b(comunidad|comunidades|autonomia|autonomias|autonomica|region|regiones)\b/.test(q)
				? 'ccaa'
				: null;
	// Ranking: el sustantivo va detrás del interrogativo («¿qué comunidad...?», «¿cuál es la
	// provincia...?»); «la Comunidad de Madrid» dentro de la frase es un nombre, no un ranking
	const ranking =
		/\b(que|cual|cuales)\s+(es\s+|son\s+|ha sido\s+|fue\s+)?(el\s+|la\s+|los\s+|las\s+)?(\w+\s+)?(comunidad|comunidades|autonomia|autonomias|region|regiones|provincia|provincias|municipio|municipios|ciudad|ciudades|pais|paises|partido|partidos|marca|marcas|sector|sectores)\b/.test(
			q
		) || /\bdonde\b/.test(q);
	// «peor/mejor» no invierten el orden: el peor año de incendios es el de más hectáreas
	const menos = /\b(menos|menor|menores|minim[oa]s?|mas baj[oa]s?)\b/.test(q) && !/\bmenores de\b/.test(q);
	// «¿Cuál ha sido el peor año...?», «¿en qué año hubo más...?»: ranking de años, no cambio
	const rankingAnios = /\b(que|cual|en que)\s+(ha sido\s+|fue\s+|es\s+)?(el\s+)?(\w+\s+)?ano\b/.test(q) || /\b(peor|mejor)\s+ano\b/.test(q);
	let modo = 'ultimo';
	if (rankingAnios) modo = 'historico';
	else if (cambio && anios.length) modo = 'cambio';
	else if (serie) modo = 'evolucion';
	else if (anios.length && mes >= 0) modo = 'mes';
	else if (anios.length) modo = 'anio';
	else if (historico) modo = 'historico';
	// «desde 2000» en un ranking de años: solo desde ese año
	const desde = rankingAnios && /\bdesde\b/.test(q) && anios.length ? Math.min(...anios) : null;
	return { anios, mes, modo, nivel, ranking, orden: menos ? 'ASC' : 'DESC', desde };
}

// ---------- Columnas ----------

const esTemporal = (c) => c.temporal;
const esNumerica = (c) => /INT|DOUBLE|FLOAT|DECIMAL|REAL|NUMERIC/i.test(c.tipo);
const NO_MEDIDA = /^(cod|cod_\w+|id|anio|año|ano|trim|trimestre|mes|mes_num|semana|dia|anio_\w+|orden|lat|lon|latitud|longitud)$/i;

/** Columna de tiempo principal: la de fecha más fina; si no hay, el año o el periodo */
function columnaTiempo(t) {
	// Solo columnas con nombre de tiempo: una fecha de metadato (ultima_fecha) no es el periodo
	const tiempo = t.columnas.filter(esTemporal).filter((c) => /^(fecha|mes|trimestre|semana|date|dia|periodo|anio|año|ano|year|ejercicio)$/i.test(c.nombre));
	return (
		tiempo.find((c) => /DATE|TIMESTAMP/i.test(c.tipo)) ??
		tiempo.find((c) => /^periodo$/i.test(c.nombre)) ??
		tiempo.find((c) => /^(anio|año|ano|year|ejercicio)$/i.test(c.nombre)) ??
		tiempo[0]
	);
}

// Abreviaturas de los nombres de columna en palabras: el modelo y el embebedor entienden
// «variación anual» mejor que «var_anual»
const ABREVIATURAS = {
	var: 'variación',
	pct: 'porcentaje',
	eur: 'euros',
	meur: 'millones de euros',
	mrd: 'miles de millones de euros',
	mt: 'millones de toneladas',
	hab: 'por habitante',
	n: 'número de',
	num: 'número de',
	real: 'en euros reales',
	tmax: 'temperatura máxima',
	tmin: 'temperatura mínima',
	pib: 'del PIB',
	bev: 'eléctricos de batería',
	phev: 'híbridos enchufables',
	ccaa: 'comunidad autónoma'
};
const humanizar = (nombre) =>
	nombre
		.split('_')
		.map((p) => ABREVIATURAS[p] ?? p)
		.join(' ');
const etiqueta = (c) => (c.descripcion ? `${humanizar(c.nombre)}: ${c.descripcion}` : humanizar(c.nombre));

// Cómo se pregunta -> cómo se llaman los valores en los datos
const SINONIMOS_VALORES = {
	inflacion: 'indice general variacion anual',
	ipc: 'indice general',
	interanual: 'variacion anual',
	jovenes: 'menores 25',
	juvenil: 'menores 25',
	extranjeros: 'extranjera',
	consumo: 'demanda consumo',
	coches: 'turismo turismos',
	coche: 'turismo turismos',
	pisos: 'vivienda viviendas',
	electrico: 'demanda',
	espana: 'nacional total espana'
};
const TERRITORIO = /andaluc|aragon|asturias|balear|canaria|cantabr|castilla|catalu|valencia|extremad|galicia|madrid|murcia|navarra|vasco|rioja|ceuta|melilla|provincia|municipio|comunidad/;

/** Valores de una columna puntuados por las palabras que la pregunta nombra */
function puntuarValores(valores, pregunta) {
	const base = normalizar(pregunta);
	const q = palabras(base + ' ' + [...palabras(base)].map((p) => SINONIMOS_VALORES[p] ?? '').join(' '));
	const sinTerritorio = !TERRITORIO.test(base);
	return valores.map((v) => {
		let s = [...palabras(v)].filter((p) => q.has(p)).length;
		// Si no se nombra territorio, lo nacional es lo que se pregunta
		if (sinTerritorio && /^(nacional|espana|total)\b/.test(normalizar(v))) s += 0.5;
		return { v, s };
	});
}

// ---------- Formato de la respuesta ----------

function formatoPeriodo(v, col) {
	if (v === null || v === undefined) return '';
	const d = v instanceof Date ? v : /^\d{4}-\d\d-\d\d/.test(String(v)) ? new Date(String(v).slice(0, 10) + 'T00:00:00Z') : null;
	if (d && !isNaN(d)) {
		const m = d.getUTCMonth();
		if (/trimestre/i.test(col.nombre)) return `${Math.floor(m / 3) + 1}.º trimestre de ${d.getUTCFullYear()}`;
		if (d.getUTCDate() === 1 && !/^fecha$/i.test(col.nombre)) return `${MESES[m]} de ${d.getUTCFullYear()}`;
		if (m === 11 && d.getUTCDate() === 31) return `${d.getUTCFullYear()}`;
		if ([2, 5, 8, 11].includes(m) && d.getUTCDate() >= 30) return `${Math.floor(m / 3) + 1}.º trimestre de ${d.getUTCFullYear()}`;
		return `${d.getUTCDate()} de ${MESES[m]} de ${d.getUTCFullYear()}`;
	}
	return String(v).replace(/^(\d{4})-T(\d)$/, '$2.º trimestre de $1').replace(/\.0$/, '');
}

// Decimales solo donde cuentan: 1.181,73 M€ sí, 49.114.494 habitantes no
const numero = (v) =>
	typeof v === 'number' ? new Intl.NumberFormat('es-ES', { maximumFractionDigits: Math.abs(v) >= 100000 ? 0 : 2 }).format(v) : v ?? '—';

/** Unidad deducida del nombre de la columna (solo cuando es inequívoca) */
function unidadDe(nombre) {
	const n = `_${nombre.toLowerCase()}_`;
	if (/_(por_)?(1000|1000hab|mil)_/.test(n)) return ' por cada 1.000 habitantes';
	if (/_(100k|100000)_/.test(n)) return ' por cada 100.000 habitantes';
	if (/_meur_/.test(n)) return ' millones de €';
	if (/_mrd_/.test(n)) return ' mil millones de €';
	if (/_(eur|euros)_/.test(n)) return ' €';
	if (/_(pct|porcentaje|cuota)_/.test(n) || (/^_tasa_/.test(n) && !/_(1000|100k)_/.test(n))) return ' %';
	if (/^_ha_/.test(n)) return ' ha';
	if (/_mw_/.test(n)) return ' MW';
	if (/_gwh_/.test(n)) return ' GWh';
	if (/_twh_/.test(n)) return ' TWh';
	if (/_mt_/.test(n)) return ' Mt';
	return '';
}

const coseno = (a, b) => {
	let s = 0;
	for (let i = 0; i < a.length; i++) s += a[i] * b[i];
	return s;
};

// Vectores de las etiquetas de columna (se calculan una vez por sesión)
const vectoresColumna = new Map();

// ---------- Bucle de decisiones ----------

/**
 * @param {object} o
 * @param {string} o.pregunta
 * @param {{ catalogo, indice, consultar, embeber? }} o.ctx
 * @param {(contexto: string, pregunta: string, opciones: string[]) => Promise<number | { indice: number, probs: number[] }>} o.decidir
 * @param {(paso: {herramienta: string, entrada: any}) => void} [o.alPaso]
 * @returns {Promise<{ texto: string, sql?: string, filas?: any[], decisiones: any[], grafico?: any }>}
 */
export async function responderPorDecisiones({ pregunta, ctx, decidir, alPaso }) {
	const decisiones = [];
	const intencion = leerIntencion(pregunta);
	/** Pide al modelo una elección; con `prior` (log-probabilidades extra por opción) las combina */
	const elegir = async (contexto, q, opciones, prior = null) => {
		if (opciones.length === 1) return 0;
		const lista = opciones.slice(0, MAX_OPCIONES);
		const r = await decidir(contexto, q, lista);
		let i = typeof r === 'number' ? r : r.indice;
		if (prior && typeof r === 'object' && r.probs) {
			const puntos = lista.map((_, k) => Math.log(Math.max(r.probs[k] ?? 0, 1e-9)) + (prior[k] ?? 0));
			i = puntos.indexOf(Math.max(...puntos));
		}
		decisiones.push({ pregunta: q, opciones: lista, eleccion: lista[i] });
		alPaso?.({ herramienta: 'decidir', entrada: { pregunta: q, eleccion: lista[i] } });
		return i;
	};
	const contexto = `Pregunta del usuario: ${pregunta}`;
	// Preguntas al decisor; ctx.idiomaDecision = 'es' para hacerlas en castellano
	const PREGUNTAS_DECISOR = {
		en: {
			tabla: 'Which data table answers the user question?',
			contiene: 'Does this data table contain the figure the user asks for?',
			cifra: 'Which column is the figure the user asks for?',
			lugar: 'Which place does the user ask about?',
			nivel: 'Which territorial level does the user want to compare?',
			valor: (c) => `Which value of "${c}" does the user ask about?`
		},
		es: {
			tabla: '¿Qué tabla de datos responde a la pregunta del usuario?',
			contiene: '¿Contiene esta tabla la cifra que pregunta el usuario?',
			cifra: '¿Qué columna es la cifra que pregunta el usuario?',
			lugar: '¿Por qué lugar pregunta el usuario?',
			nivel: '¿Qué nivel territorial quiere comparar el usuario?',
			valor: (c) => `¿Qué valor de "${c}" pregunta el usuario?`
		}
	};
	const Q = (clave, extra) => {
		const p = PREGUNTAS_DECISOR[ctx.idiomaDecision ?? 'en'][clave];
		return typeof p === 'function' ? p(extra) : p;
	};

	// 1. Tabla: candidatas de la búsqueda (palabras + significado) y el modelo elige; su
	//    puesto en la búsqueda cuenta como información previa
	const prefijo = ctx.catalogo.embeddings?.prefijo_consulta ?? '';
	const vector = ctx.embeber ? await ctx.embeber(prefijo + pregunta) : null;
	const candidatas = buscarTablas(ctx.indice, pregunta, 6, 0, vector).map((x) => buscarFicha(ctx.catalogo, x.tabla));
	if (!candidatas.length) return { texto: 'No he encontrado datos sobre eso en SpainFacts.', decisiones };
	const describirCandidata = (t) => {
		const tc = columnaTiempo(t);
		const periodo = tc?.min !== undefined ? ` Periodo: ${String(tc.min).slice(0, 10)} a ${String(tc.max).slice(0, 10)}.` : '';
		const cols = t.columnas.map((c) => c.nombre).slice(0, 14).join(', ');
		// Los títulos de las páginas que la usan dicen el tema en lenguaje llano
		const pags = [...new Set((t.paginas ?? []).map((p) => p.titulo).filter(Boolean))].slice(0, 3).join(' / ');
		return `${t.nombre}: ${t.descripcion.slice(0, 200)}${periodo}${pags ? ` Páginas: ${pags}.` : ''} Columnas: ${cols}`;
	};
	// Modo de elegir tabla (ctx.eleccionTabla):
	//   'lista'   -> el modelo ve las 6 y elige una
	//   'puntual' -> por cada una, «¿contiene la cifra que se pide? sí/no»; gana la de más «sí»
	//   'ambos'   -> suma de las log-probabilidades de los dos
	const modoTabla = ctx.eleccionTabla ?? 'lista';
	let iTabla;
	if (modoTabla === 'lista') {
		iTabla = await elegir(contexto, Q('tabla'), candidatas.map(describirCandidata), candidatas.map((_, k) => -(ctx.priorBusqueda ?? PRIOR_BUSQUEDA) * k));
	} else {
		const puntos = [];
		for (const c of candidatas) {
			const r = await decidir(`${contexto}\nTabla: ${describirCandidata(c)}`, Q('contiene'), ['yes', 'no']);
			const pSi = typeof r === 'object' && r.probs ? r.probs[0] : r === 0 ? 1 : 0;
			puntos.push(Math.log(Math.max(pSi, 1e-9)));
		}
		if (modoTabla === 'ambos') {
			const r = await decidir(contexto, Q('tabla'), candidatas.map(describirCandidata));
			if (typeof r === 'object' && r.probs) r.probs.forEach((p, k) => (puntos[k] += Math.log(Math.max(p, 1e-9))));
		}
		iTabla = puntos.indexOf(Math.max(...puntos));
		decisiones.push({ pregunta: `${Q('tabla')} (${modoTabla})`, opciones: candidatas.map((c) => c.nombre), eleccion: candidatas[iTabla].nombre });
		alPaso?.({ herramienta: 'decidir', entrada: { pregunta: Q('tabla'), eleccion: candidatas[iTabla].nombre } });
	}
	const t = candidatas[iTabla];
	const ctxTabla = `${contexto}\nTabla: ${t.nombre}. ${t.descripcion}`;
	const nombres = new Set(t.columnas.map((c) => c.nombre));

	// 2. Cifra: columnas ordenadas por significado (si hay embebedor) y palabras
	const medidas = t.columnas.filter((c) => esNumerica(c) && !esTemporal(c) && !NO_MEDIDA.test(c.nombre));
	if (!medidas.length) return { texto: `La tabla ${t.tabla} no tiene cifras que consultar.`, decisiones };
	const lexico = puntuarValores(medidas.map(etiqueta), pregunta).map((x) => x.s);
	let puntosMedida = lexico.map((s) => 0.3 * s);
	if (vector) {
		const prefDoc = ctx.catalogo.embeddings?.prefijo_documento ?? '';
		for (const c of medidas) {
			const clave = `${t.nombre}.${c.nombre}`;
			if (!vectoresColumna.has(clave)) vectoresColumna.set(clave, await ctx.embeber(`${prefDoc}${etiqueta(c)}`));
		}
		puntosMedida = medidas.map((c, k) => coseno(vector, vectoresColumna.get(`${t.nombre}.${c.nombre}`)) + 0.05 * lexico[k]);
	}
	const ordenMedidas = medidas.map((c, k) => ({ c, s: puntosMedida[k], l: lexico[k] })).sort((a, b) => b.s - a.s).slice(0, MAX_MEDIDAS);
	// Una columna nombrada claramente por la pregunta («turistas», «variación anual») gana
	// sin preguntar al modelo
	const porPalabras = [...ordenMedidas].sort((a, b) => b.l - a.l);
	const medida =
		porPalabras[0].l >= 1 && porPalabras[0].l - (porPalabras[1]?.l ?? 0) >= 1
			? porPalabras[0].c
			: ordenMedidas[await elegir(ctxTabla, Q('cifra'), ordenMedidas.map((x) => etiqueta(x.c)))].c;

	// 3. Periodo: lo dice la pregunta (años, mes, «desde», «evolución», «récord»)
	const tcol = columnaTiempo(t);
	const modo = tcol ? intencion.modo : 'ultimo';
	// Flujos (se suman: matriculaciones de un año, solicitudes de todas las nacionalidades)
	// frente a niveles, tasas y precios (no se suman nunca)
	const esFlujo =
		/^(matricul|solicitud|llegad|nacimiento|defuncion|venta|compraventa|turistas|pernoct|delito|infraccion|constituid|disuelt|hipoteca|incendio|n_incendio|ha_|hectarea|personas|visitantes|viajeros|pasajeros|condenad|votos|exportacion|importacion)/.test(
			medida.nombre
		) && !/(tasa|pct|porcentaje|media|medio|indice|precio|por_|_hab|1000|100k|interanual|var_|_real_hab)/.test(medida.nombre);
	const sumarEntre = []; // columnas sin total cuyo desglose se suma

	// 4. Territorio. Tres formas de guardarlo en las tablas:
	//   a) nivel + nombre/territorio            (vivienda_precio_tasado...)
	//   b) nivel + cod (códigos INE, sin nombre) (poblacion_territorios...)
	//   c) cod_ccaa sin nombre, con 00 = España  (crimen_condenados...)
	const filtros = [];
	const comparar = [];
	const totalesFuera = []; // [columna, valor Total] que se excluyen al comparar
	let nivelElegido = null;
	let unirTerritorios = null; // { col, nivel } para traer el nombre de mother.territorios
	const codigoANombre = new Map();
	const usadas = new Set(['nivel']);
	const NIVEL = { pais: 'Spain as a whole', ccaa: 'autonomous communities', provincia: 'provinces', municipio: 'municipalities' };
	const paresDe = (lista) => (lista ?? '').split(', ').filter(Boolean).map((s) => [s.slice(0, s.indexOf(' ')), s.slice(s.indexOf(' ') + 1)]);

	/** De candidatos {nivel, nombre, filtro} se queda con los nombrados en la pregunta */
	async function territorioNombrado(candidatos) {
		const puntos = puntuarValores(candidatos.map((c) => c.nombre), pregunta)
			.map((p, i) => ({ ...candidatos[i], s: p.s }))
			.filter((c) => c.s >= 1 && !ES_TOTAL.test(c.nombre));
		if (!puntos.length) return null;
		const max = Math.max(...puntos.map((p) => p.s));
		let empatados = puntos.filter((p) => p.s === max);
		// Si la pregunta dice el nivel («Valladolid capital», «la provincia de...»), manda
		if (intencion.nivel && empatados.some((p) => p.nivel === intencion.nivel)) empatados = empatados.filter((p) => p.nivel === intencion.nivel);
		empatados = empatados.slice(0, MAX_OPCIONES);
		if (empatados.length === 1) return empatados[0];
		const i = await elegir(ctxTabla, Q('lugar'), empatados.map((c) => `${c.nombre} (${NIVEL[c.nivel] ?? c.nivel})`));
		return empatados[i];
	}

	/** Nivel a comparar: el que dice la pregunta; si no, lo decide el modelo */
	async function nivelAComparar(niveles) {
		const opciones = niveles.filter((n) => n !== 'pais');
		if (intencion.nivel && opciones.includes(intencion.nivel)) return intencion.nivel;
		return opciones[await elegir(ctxTabla, Q('nivel'), opciones.map((v) => NIVEL[v] ?? v))];
	}

	if (nombres.has('nivel')) {
		const niveles = t.columnas.find((c) => c.nombre === 'nivel').valores ?? ['pais', 'ccaa', 'provincia'];
		const colNombre = ['nombre', 'territorio'].find((n) => nombres.has(n));
		let candidatos = [];
		if (colNombre) {
			usadas.add(colNombre);
			const filas = await ctx.consultar(`SELECT DISTINCT nivel, ${id(colNombre)} AS nombre FROM ${t.tabla} WHERE ${id(colNombre)} IS NOT NULL LIMIT 20000`);
			candidatos = filas.map((f) => ({ nivel: f.nivel, nombre: String(f.nombre), filtro: [colNombre, String(f.nombre)] }));
		} else if (t.codigos) {
			usadas.add('cod');
			for (const nivel of niveles) for (const [cod, nombre] of paresDe(t.codigos[nivel])) {
				candidatos.push({ nivel, nombre, filtro: ['cod', cod] });
				codigoANombre.set(cod, nombre);
			}
		}
		const elegido = await territorioNombrado(candidatos);
		if (elegido) {
			nivelElegido = elegido.nivel;
			filtros.push(['nivel', nivelElegido], elegido.filtro);
		} else if (!intencion.ranking && niveles.includes('pais')) {
			nivelElegido = 'pais';
			filtros.push(['nivel', 'pais']);
		} else {
			nivelElegido = await nivelAComparar(niveles);
			filtros.push(['nivel', nivelElegido]);
			if (colNombre) comparar.push(colNombre);
			else if (t.codigos) {
				comparar.push('cod');
				unirTerritorios = { col: 'cod', nivel: null };
			}
		}
	} else if (t.codigos) {
		// Columnas de código sin nombre (cod_ccaa, cod_prov, cod): se traducen con la lista del
		// INE. La más fina que nombre la pregunta filtra; si no se nombra ninguna, España (00)
		// o, en un ranking, se compara al nivel que pida la pregunta.
		const columnas = t.codigos.columnas ?? (nombres.has('cod_ccaa') ? { cod_ccaa: 'ccaa' } : {});
		const entradas = Object.entries(columnas).filter(([c]) => nombres.has(c));
		for (const [c] of entradas) usadas.add(c);
		const candidatos = entradas.flatMap(([c, nivel]) => paresDe(t.codigos[nivel]).map(([cod, nombre]) => ({ nivel, nombre, filtro: [c, cod] })));
		for (const k of candidatos) codigoANombre.set(k.filtro[1], k.nombre);
		const elegido = await territorioNombrado(candidatos);
		if (elegido) filtros.push(elegido.filtro);
		else {
			const nivelRanking = intencion.nivel && entradas.some(([, n]) => n === intencion.nivel) ? intencion.nivel : entradas[0]?.[1];
			const [colRanking] = entradas.find(([, n]) => n === nivelRanking) ?? [];
			for (const [c] of entradas) {
				const hay00 = t.columnas.find((x) => x.nombre === c)?.valores?.includes('00');
				if (intencion.ranking && c === colRanking) {
					comparar.push(c);
					unirTerritorios = { col: c, nivel: nivelRanking };
				} else if (hay00) filtros.push([c, '00']);
			}
		}
	}

	// 5. Columnas de texto: sexo, serie, indicador, país, partido, municipio...
	//    Se estrechan en cadena: primero la que mejor encaja con la pregunta, y las siguientes
	//    solo pueden tomar valores que existan con los filtros ya puestos (en tablas largas,
	//    indicador_id, nombre, nombre_corto y unidad describen lo mismo y deben cuadrar).
	const categoricas = t.columnas.filter(
		(c) =>
			/VARCHAR/i.test(c.tipo) &&
			!esTemporal(c) &&
			!usadas.has(c.nombre) &&
			!/^(cod|cod_\w+|clave|id|url\w*|ruta\w*|slug\w*|enlace\w*|fuente|nota|notas|color\w*|\w+_color|\w+_orden|\w+_id)$/i.test(c.nombre)
	);
	// Columnas de código sin nombre al lado (cod_ccaa sin tabla de códigos...): España (00)
	for (const c of t.columnas) {
		if (/^cod_\w+$/.test(c.nombre) && !usadas.has(c.nombre) && c.valores?.includes('00') && !intencion.ranking) filtros.push([c.nombre, '00']);
	}
	const condicionFiltros = () => filtros.map(([c, v]) => `${id(c)} = ${lit(v)}`).join(' AND ') || 'TRUE';
	/** Valores posibles de una columna con los filtros ya puestos (y, si son muchos, solo los nombrados) */
	async function valoresPosibles(c) {
		const base = `SELECT DISTINCT ${id(c.nombre)} AS v FROM ${t.tabla} WHERE ${condicionFiltros()} AND ${id(c.nombre)} IS NOT NULL`;
		let filas = await ctx.consultar(`${base} LIMIT 401`);
		if (filas.length > 400) {
			// Muchos valores (municipios, países...): se buscan las palabras de la pregunta
			const buscadas = [...palabras(pregunta)].filter((p) => p.length >= 4);
			if (!buscadas.length) return { valores: [], muchos: true };
			const como = buscadas.map((p) => `strip_accents(lower(${id(c.nombre)})) LIKE ${lit(`%${p}%`)}`).join(' OR ');
			filas = await ctx.consultar(`${base} AND (${como}) LIMIT 40`);
			return { valores: filas.map((f) => String(f.v)), muchos: true };
		}
		return { valores: filas.map((f) => String(f.v)), muchos: false };
	}
	const pendientes = [...categoricas];
	// Orden: primero las columnas cuyo mejor valor encaja más con la pregunta
	const mejorEncaje = (c) => Math.max(0, ...puntuarValores(c.valores ?? c.ejemplos ?? [], pregunta).map((x) => x.s));
	pendientes.sort((a, b) => mejorEncaje(b) - mejorEncaje(a));
	for (const c of pendientes) {
		const { valores, muchos } = await valoresPosibles(c);
		// Con todos los valores a la vista, uno solo es que no hay nada que elegir; con una
		// búsqueda (muchos valores), uno solo es justo el nombrado
		// Muchos valores y ninguno nombrado: en un ranking («¿qué marca...?») se compara entre todos
		if (muchos && !valores.length) {
			if (intencion.ranking) comparar.push(c.nombre);
			continue;
		}
		if (!valores.length || (valores.length === 1 && !muchos)) continue;
		// Texto libre (notas largas) o copias en minúsculas de otra columna (slugs): fuera
		if (valores.reduce((s, v) => s + v.length, 0) / valores.length > 80) continue;
		if (valores.every((v) => /^[a-z0-9_-]+$/.test(v)) && categoricas.length > 1) continue;
		const total = valores.find((v) => ES_TOTAL.test(v.trim()));
		const puntos = puntuarValores(valores, pregunta);
		const nombrados = puntos.filter((x) => x.s >= 1).sort((a, b) => b.s - a.s);
		const nacional = puntos.find((x) => x.s === 0.5)?.v;

		if (!nombrados.length) {
			// No nombra ningún valor: el total (o lo nacional) salvo que pida un ranking; sin
			// total, si la cifra es un flujo (solicitudes, llegadas...) se suma entre todos; si
			// no, se compara entre todos (si no son miles)
			const porDefecto = total ?? nacional;
			if (porDefecto && !intencion.ranking) filtros.push([c.nombre, porDefecto]);
			else if (!porDefecto && !intencion.ranking && esFlujo) sumarEntre.push(c.nombre);
			else if (!muchos || intencion.ranking) {
				comparar.push(c.nombre);
				if (total) totalesFuera.push([c.nombre, total]); // en un ranking, la fila Total sobra
			} else if (porDefecto) filtros.push([c.nombre, porDefecto]);
			continue;
		}
		// Un valor gana con claridad por las palabras de la pregunta: no hace falta modelo
		if (nombrados.length === 1 || nombrados[0].s - nombrados[1].s >= 1) {
			filtros.push([c.nombre, nombrados[0].v]);
			continue;
		}
		// Varios valores parecidos: el modelo elige entre ellos
		const opciones = nombrados.slice(0, MAX_OPCIONES).map((x) => x.v);
		filtros.push([c.nombre, opciones[await elegir(ctxTabla, Q('valor', c.nombre), opciones)]]);
	}

	// ---------- Traductor determinista ----------
	// Condiciones como funciones del alias: la consulta principal (t0) y las subconsultas de
	// periodo (t1) usan las mismas, y nada queda ambiguo al cruzar con territorios
	const col = (a, c) => `${a}.${id(c)}`;
	const condiciones = [...filtros.map(([c, v]) => (a) => `${col(a, c)} = ${lit(v)}`), (a) => `${col(a, medida.nombre)} IS NOT NULL`];
	if (unirTerritorios?.nivel) condiciones.push((a) => `${col(a, unirTerritorios.col)} <> '00'`); // al comparar, fuera España
	for (const [c, v] of totalesFuera) condiciones.push((a) => `${col(a, c)} <> ${lit(v)}`);
	// Tablas anuales: el año en curso está incompleto (suma unos meses) y parecería una caída;
	// no cuenta como «último dato» salvo que se pida ese año
	const anioActual = new Date(ctx.catalogo.generado ?? Date.now()).getUTCFullYear();
	const anual = tcol && /^(anio|año|ano|year|ejercicio)$/i.test(tcol.nombre);
	// Solo si la tabla marca que el año está a medias (columnas meses*, es_anio_actual): un
	// dato «a 1 de enero» del año en curso está completo
	const marcaParcial = t.columnas.some((c) => /^(meses\w*|n_meses|es_anio_actual|parcial|es_parcial)$/i.test(c.nombre));
	let anioIncompleto = false;
	if (anual && marcaParcial && Number(tcol.max) >= anioActual && !intencion.anios.includes(anioActual) && modo !== 'evolucion') {
		condiciones.push((a) => `${col(a, tcol.nombre)} < ${anioActual}`);
		anioIncompleto = true;
	}
	const esFecha = tcol && /DATE|TIMESTAMP/i.test(tcol.tipo);
	/** Condición «dentro del año y» (y del mes m) según cómo guarde el tiempo la tabla */
	const enAnio = (a, y, m = -1) => {
		const partes = [];
		if (nombres.has('anio') && tcol.nombre !== 'anio') partes.push(`${col(a, 'anio')} = ${y}`);
		else if (esFecha) partes.push(`year(${col(a, tcol.nombre)}) = ${y}`);
		else if (/^periodo$/i.test(tcol.nombre)) partes.push(`${col(a, tcol.nombre)} LIKE '${y}%'`);
		else partes.push(`${col(a, tcol.nombre)} = ${y}`);
		if (m >= 0) {
			if (esFecha) partes.push(`month(${col(a, tcol.nombre)}) = ${m + 1}`);
			else if (nombres.has('mes')) partes.push(`${col(a, 'mes')} = ${m + 1}`);
		}
		return partes.join(' AND ');
	};
	/** Último periodo con dato que cumple las condiciones (y la extra, si la hay) */
	const ultimoPeriodo = (extra = null) =>
		`(SELECT max(${col('t1', tcol.nombre)}) FROM ${t.tabla} AS t1 WHERE ${[...condiciones.map((f) => f('t1')), ...(extra ? [extra('t1')] : [])].join(' AND ')})`;

	const donde = condiciones.map((f) => f('t0'));
	let periodos = null; // en modo cambio: [inicial, final]
	// Un flujo en una tabla mensual o trimestral y se pide un año: se suma el año entero
	const sumaAnual = esFlujo && modo === 'anio' && tcol && !anual;
	// Y si se comparan dos años («en 2025 que en 2019»), se suma cada año entero
	const cambioAnual = esFlujo && modo === 'cambio' && tcol && !anual && /DATE|TIMESTAMP/i.test(tcol.tipo);
	const agregar = sumaAnual || cambioAnual || sumarEntre.length > 0;
	// Expresión del periodo en la consulta agregada: el año si se suma por años
	const exprTiempo = tcol ? (cambioAnual ? `year(${col('t0', tcol.nombre)})` : col('t0', tcol.nombre)) : null;
	if (tcol) {
		if (modo === 'ultimo') donde.push(`${col('t0', tcol.nombre)} = ${ultimoPeriodo()}`);
		else if (sumaAnual) donde.push(enAnio('t0', intencion.anios[0]));
		else if (modo === 'anio') donde.push(`${col('t0', tcol.nombre)} = ${ultimoPeriodo((a) => enAnio(a, intencion.anios[0]))}`);
		else if (modo === 'mes') donde.push(`${col('t0', tcol.nombre)} = ${ultimoPeriodo((a) => enAnio(a, intencion.anios[0], intencion.mes))}`);
		else if (modo === 'cambio') {
			// «desde 2019» -> 2019 frente al último; «en 2024 que en 2008» -> 2008 frente a 2024
			const [a, b] = [...new Set(intencion.anios)].sort();
			if (cambioAnual) donde.push(`${exprTiempo} IN (${a}, ${b ?? anioActual - 1})`); // años enteros; sin segundo año, el último completo
			else {
				periodos = [ultimoPeriodo((x) => enAnio(x, a)), b ? ultimoPeriodo((x) => enAnio(x, b)) : ultimoPeriodo()];
				donde.push(`${col('t0', tcol.nombre)} IN (${periodos.join(', ')})`);
			}
		} else if (modo === 'historico' && intencion.desde) donde.push(anual ? `${col('t0', tcol.nombre)} >= ${intencion.desde}` : `year(${col('t0', tcol.nombre)}) >= ${intencion.desde}`);
	}
	const nombreCod = unirTerritorios ? ', ter.nombre AS territorio' : '';
	const unir = unirTerritorios
		? ` LEFT JOIN mother.territorios AS ter ON ter.nivel = ${unirTerritorios.nivel ? lit(unirTerritorios.nivel) : 't0.nivel'} AND ter.cod = t0.${id(unirTerritorios.col)}`
		: '';
	let ordenSQL = '';
	let limite = 30;
	if ((modo === 'evolucion' || modo === 'cambio') && tcol) ordenSQL = `ORDER BY ${col('t0', tcol.nombre)}`;
	else if (comparar.length || modo === 'historico') ordenSQL = `ORDER BY ${col('t0', medida.nombre)} ${intencion.orden}`;
	if (modo === 'evolucion') limite = 400;
	if (modo === 'historico' && !comparar.length) limite = 1;
	let sql;
	if (agregar) {
		// Suma por grupo (lo que se compara); el periodo se conserva (el año pedido o el último)
		const grupo = [...(tcol && !sumaAnual ? [exprTiempo] : []), ...comparar.map((c) => col('t0', c))];
		const sel = [
			...(sumaAnual ? [`${intencion.anios[0]} AS ${id(tcol.nombre)}`] : []),
			...grupo.map((g) => (g === exprTiempo && cambioAnual ? `${g} AS ${id(tcol.nombre)}` : g)),
			...(unirTerritorios ? ['ter.nombre AS territorio'] : []),
			`sum(${col('t0', medida.nombre)}) AS ${id(medida.nombre)}`
		];
		const agrupar = [...grupo, ...(unirTerritorios ? ['ter.nombre'] : [])];
		const ordenAgregado =
			(modo === 'cambio' || modo === 'evolucion') && tcol && !sumaAnual
				? `ORDER BY ${exprTiempo}`
				: comparar.length
					? `ORDER BY ${id(medida.nombre)} ${intencion.orden}`
					: '';
		sql = `SELECT ${sel.join(', ')} FROM ${t.tabla} AS t0${unir} WHERE ${donde.join(' AND ')}${agrupar.length ? ` GROUP BY ${agrupar.join(', ')}` : ''} ${ordenAgregado} LIMIT ${limite}`;
	} else {
		const seleccion = [...new Set([...(tcol ? [tcol.nombre] : []), ...comparar, medida.nombre])].map((c) => col('t0', c));
		sql = `SELECT ${seleccion.join(', ')}${nombreCod} FROM ${t.tabla} AS t0${unir} WHERE ${donde.join(' AND ')} ${ordenSQL} LIMIT ${limite}`;
	}

	alPaso?.({ herramienta: 'consultar_sql', entrada: { sql } });
	const filas = await ctx.consultar(sql);

	// ---------- Respuesta con plantilla ----------
	const pagina = [...(t.paginas ?? [])].sort((a, b) => b.ruta.length - a.ruta.length)[0]; // la más específica, no la portada
	const fuente = `${anioIncompleto ? `(${anioActual} aún está incompleto, así que no se usa como último dato.)\n` : ''}Fuente: tabla ${t.tabla}${pagina ? ` (${pagina.titulo}: ${URL_WEB}${pagina.ruta})` : ''}.`;
	const nombreMedida = medida.descripcion || medida.nombre.replace(/_/g, ' ');
	if (!filas.length) return { texto: `No hay datos para esa combinación en ${t.tabla}. ${fuente}`, sql, filas, decisiones };

	const quien = (f) => [f.territorio, ...comparar.filter((c) => !esCodigo(c)).map((c) => f[c])].filter(Boolean).join(', ');
	const unidad = unidadDe(medida.nombre);
	const describirFila = (f) => `${quien(f) ? `${quien(f)}: ` : ''}${numero(f[medida.nombre])}${unidad}`;
	// Lo que se ha filtrado, en palabras: el nombre del territorio en vez de su código
	const filtroTexto = filtros
		.filter(([c]) => c !== 'nivel')
		.map(([c, v]) => (esCodigo(c) ? codigoANombre.get(v) : v))
		.filter((v) => v && !ES_TOTAL.test(String(v)))
		.join(', ');
	const conFiltro = filtroTexto ? ` (${filtroTexto})` : '';
	const per = (f) => (tcol ? formatoPeriodo(f[tcol.nombre], tcol) : '');

	let texto;
	let grafico;
	if (modo === 'cambio' && tcol) {
		// Diferencia entre el periodo inicial y el final, por grupo si se compara
		const grupos = new Map();
		for (const f of filas) {
			const g = quien(f);
			if (!grupos.has(g)) grupos.set(g, []);
			grupos.get(g).push(f);
		}
		const lineas = [...grupos.entries()]
			.filter(([, fs]) => fs.length >= 2)
			.map(([g, fs]) => {
				const [i, f] = [fs[0], fs.at(-1)];
				const dif = f[medida.nombre] - i[medida.nombre];
				const pct = i[medida.nombre] ? ` (${dif >= 0 ? '+' : ''}${numero((dif / Math.abs(i[medida.nombre])) * 100)} %)` : '';
				return { g, dif, texto: `${g ? `${g}: ` : ''}de ${numero(i[medida.nombre])}${unidad} en ${per(i)} a ${numero(f[medida.nombre])}${unidad} en ${per(f)}, ${dif >= 0 ? "+" : ""}${numero(dif)}${unidad}${pct}` };
			})
			.sort((a, b) => (intencion.orden === 'ASC' ? a.dif - b.dif : b.dif - a.dif));
		// Sin el periodo inicial (la cifra ya es un cambio, como «subida desde 2019»): el dato final
		texto = lineas.length
			? `${nombreMedida}${conFiltro}: ${lineas.length === 1 ? lineas[0].texto : `\n${lineas.slice(0, 5).map((l) => `- ${l.texto}`).join('\n')}`}.`
			: `${nombreMedida}${conFiltro}: ${describirFila(filas.at(-1))}${per(filas.at(-1)) ? `, ${per(filas.at(-1))}` : ''}.`;
	} else if (modo === 'evolucion' && tcol) {
		const ultima = filas.at(-1);
		texto = `${nombreMedida}${conFiltro}: de ${numero(filas[0][medida.nombre])}${unidad} en ${per(filas[0])} a ${numero(ultima[medida.nombre])}${unidad} en ${per(ultima)}.`;
		grafico = { tipo: 'linea', x: tcol.nombre, y: medida.nombre, serie: comparar.find((c) => !esCodigo(c)) ?? (unirTerritorios ? 'territorio' : ''), titulo: nombreMedida, filas, sql };
	} else if (filas.length === 1) {
		texto = `${nombreMedida}${conFiltro}: ${describirFila(filas[0])}${per(filas[0]) ? `, ${per(filas[0])}` : ''}.`;
	} else {
		texto = `${nombreMedida}${per(filas[0]) && modo !== 'historico' ? `, ${per(filas[0])}` : ''}${conFiltro}:\n${filas
			.slice(0, 5)
			.map((f) => `- ${describirFila(f)}${modo === 'historico' && per(f) ? ` (${per(f)})` : ''}`)
			.join('\n')}${filas.length > 5 ? `\n- (${filas.length - 5} más)` : ''}`;
		const x = unirTerritorios ? 'territorio' : comparar[0];
		if (x && modo !== 'historico') grafico = { tipo: 'barras', x, y: medida.nombre, serie: '', titulo: `${nombreMedida}${per(filas[0]) ? `, ${per(filas[0])}` : ''}`, filas, sql };
	}
	return { texto: `${texto}\n\n${fuente}`, sql, filas, decisiones, grafico, depuracion: { intencion, filtros, comparar, totalesFuera } };
}

// ---------- Prompt de decisión (formato de los modelos tipo decider) ----------

export function promptDecision(contexto, pregunta, opciones) {
	const letras = opciones.map((o, i) => `(${String.fromCharCode(65 + i)}) ${o}`).join('\n');
	return `Context:\n${contexto}\n\nQuestion: ${pregunta}\nOptions:\n${letras}\nAnswer: (`;
}

/** Probabilidades por opción a partir de log-probabilidades por letra (las que falten, ~0) */
export function probabilidadesDeLetras(logprobPorLetra, n) {
	const lp = [...Array(n)].map((_, i) => logprobPorLetra.get(String.fromCharCode(65 + i)) ?? -30);
	const max = Math.max(...lp);
	const e = lp.map((x) => Math.exp(x - max));
	const s = e.reduce((a, b) => a + b, 0);
	return e.map((x) => x / s);
}
