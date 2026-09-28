/**
 * spainfacts-ree-directo — Cloudflare Worker (sintaxis de módulos, sin dependencias).
 *
 * Proxy "en directo" del sistema eléctrico español para https://spainfacts.org.
 * En cada petición (con caché de 5 minutos en el borde de Cloudflare):
 *   1. Descarga de Red Eléctrica (REE) la curva de demanda y generación cada
 *      5 minutos de Península, Baleares y Canarias (hoy y ayer, para tener 24 h),
 *      los coeficientes de emisión de CO2 de cada sistema (caché 24 h) y los
 *      precios del mercado spot y del PVPC de hoy.
 *   2. Quita el envoltorio JSONP, normaliza los campos a los MISMOS nombres que la
 *      tabla del pipeline `electricidad_5min` / consulta `mother.electricidad_ultimas_24h`
 *      y calcula generación total, % renovable, t CO2/h y gCO2/kWh.
 *   3. Devuelve un JSON compacto con CORS solo para los orígenes permitidos.
 *
 * Si falla un sistema, los demás se devuelven igualmente (campo `errores`).
 *
 * Fuente: Red Eléctrica (REE). Los servicios de demanda.ree.es no están
 * documentados oficialmente: se usan "en la medida de lo posible".
 */

const REE_DEMANDA = 'https://demanda.ree.es';
const REE_APIDATOS = 'https://apidatos.ree.es';
const TIMEOUT_MS = 8000;
const TTL_SNAPSHOT = 300; // 5 min
const TTL_PARCIAL = 60; // si algo ha fallado, reintentar antes
const TTL_COEF = 86400; // coeficientes CO2: 24 h
const PASO_SERIE_MIN = 15; // resolución de serie24h (la última lectura va siempre completa en `ultimo`)

const ORIGENES_POR_DEFECTO = [
    'https://spainfacts.org',
    'https://www.spainfacts.org',
    'https://spainfacts.github.io',
    'http://localhost:3000',
    'http://localhost:3100',
    'http://localhost:3200',
    'http://localhost:3300',
];

export const SISTEMAS = {
    peninsula: { servicio: 'Peninsula', curva: 'DEMANDAAU', tz: 'Europe/Madrid' },
    baleares: { servicio: 'Baleares', curva: 'BALEARESAU', tz: 'Europe/Madrid' },
    canarias: { servicio: 'Canarias', curva: 'CANARIASAU', tz: 'Atlantic/Canary' },
};

// Coeficientes (t CO2/MWh) de respaldo por si el servicio de REE no responde.
// Valores publicados por el propio servicio coeficientesCO2 con curva=<CURVA> (comprobados el
// 28/09/2026); mantener en sincronía con la tabla raw ree_coeficientes_co2 del pipeline.
// Como en el SQL (coalesce(f, 0)), un factor que no venga en la respuesta cuenta como 0.
const COEF_RESPALDO = {
    peninsula: { cc: 0.37, car: 0.95, vap: 0.56, gf: 0.7, cogenResto: 0.28, aut: 0.27, cogen: 0.38, tnr: 0.38, resid: 0.24 },
    baleares: { cc: 0.41, car: 1.05, genAux: 0.68, residNr: 0.24, tnr: 0.37, gas: 0.95, cogen: 0.38, die: 0.68, resid: 0.24 },
    canarias: { cc: 0.6, cogen: 0.41, vap: 0.9, die: 0.68, gas: 1.12 },
};

// Campos de la serie24h (subconjunto para aligerar la respuesta).
const CAMPOS_SERIE = [
    'ts_utc', 'ts_local', 'demanda_mw', 'eolica', 'solar_fv', 'solar_termica', 'hidraulica', 'nuclear', 'carbon',
    'ciclo_combinado', 'cogeneracion_residuos', 'turbinacion_bombeo', 'consumo_bombeo', 'baterias_descarga',
    'baterias_carga', 'diesel', 'turbina_gas', 'motores_vapor', 'otras_renovables', 'otras_no_renovables',
    'intercambio_neto', 'enlace_baleares', 'generacion_total_mw', 'renovable_mw', 'pct_renovable', 'co2_t_h',
    'intensidad_gco2_kwh',
];

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

/** Quita el envoltorio JSONP `cb({...});` y parsea el JSON. */
export function quitarJsonp(texto) {
    const t = (texto || '').trim();
    const i = t.indexOf('(');
    const j = t.lastIndexOf(')');
    const cuerpo = t.startsWith('{') || t.startsWith('[') ? t : i >= 0 && j > i ? t.slice(i + 1, j) : t;
    return JSON.parse(cuerpo);
}

async function pedir(url, { ttl = TTL_SNAPSHOT, fetchImpl = fetch } = {}) {
    const ctrl = new AbortController();
    const temporizador = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
    try {
        const r = await fetchImpl(url, {
            signal: ctrl.signal,
            headers: { 'User-Agent': 'spainfacts-ree-directo/1.0 (+https://spainfacts.org)', Accept: 'application/json, text/javascript, */*' },
            // Solo tiene efecto dentro de Cloudflare: caché de la subpetición en el borde.
            cf: { cacheTtl: ttl, cacheEverything: true },
        });
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        const texto = await r.text();
        if (!texto) throw new Error('respuesta vacía');
        return texto;
    } finally {
        clearTimeout(temporizador);
    }
}

const redondear = (v, d = 1) => (v === null || v === undefined || !Number.isFinite(v) ? null : Math.round(v * 10 ** d) / 10 ** d);

/** Diferencia (minutos) entre la hora local de `tz` y UTC en el instante `ms`. */
function desfaseMin(ms, tz) {
    const partes = new Intl.DateTimeFormat('en-US', {
        timeZone: tz, hourCycle: 'h23', year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit',
    }).formatToParts(new Date(ms));
    const p = Object.fromEntries(partes.map((x) => [x.type, x.value]));
    const comoUtc = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour % 24, +p.minute);
    return Math.round((comoUtc - Math.floor(ms / 60000) * 60000) / 60000);
}

/**
 * "YYYY-MM-DD HH:MM" en hora local de `tz` → milisegundos UTC. Acepta también la hora
 * repetida del cambio de horario de octubre como la da REE ("2026-10-25 2A:05" = primera
 * vez, horario de verano; "2B:05" = segunda, horario de invierno), igual que la ingesta.
 */
export function localAUtc(s, tz) {
    const m = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{1,2})([AB]?):(\d{2})/.exec(s);
    if (!m) return NaN;
    const ingenuo = Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[6]);
    if (m[5]) {
        // desfases antes y después del cambio: A usa el mayor (verano), B el menor (invierno)
        const d1 = desfaseMin(ingenuo - 3 * 3600000, tz);
        const d2 = desfaseMin(ingenuo + 3 * 3600000, tz);
        return ingenuo - (m[5] === 'A' ? Math.max(d1, d2) : Math.min(d1, d2)) * 60000;
    }
    let utc = ingenuo - desfaseMin(ingenuo, tz) * 60000;
    const d2 = desfaseMin(utc, tz);
    utc = ingenuo - d2 * 60000;
    return utc;
}

/** "2026-10-25 2A:05" → "2026-10-25 02:05" (mismo formato de ts_local que el pipeline). */
function tsLocal(s) {
    const m = /^(\d{4}-\d{2}-\d{2})[ T](\d{1,2})[AB]?:(\d{2})/.exec(s);
    return m ? `${m[1]} ${m[2].padStart(2, '0')}:${m[3]}` : s.slice(0, 16);
}

/** Fecha local (YYYY-MM-DD) en Madrid para un instante. */
function fechaMadrid(ms) {
    return new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Madrid', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date(ms));
}

// ---------------------------------------------------------------------------
// Normalización (campos REE → nombres del contrato)
// ---------------------------------------------------------------------------

/**
 * Convierte una fila cruda de REE al esquema común. Réplica EXACTA del modelo dbt
 * transform/models/staging/stg_ree_visiona_5min.sql + marts/electricidad_5min.sql
 * (el SQL es la referencia: si cambia, cambiar también esto).
 * Convenciones: MW medios del intervalo de 5 min; todas las tecnologías (también consumos
 * y exportaciones) en MW >= 0, salvo intercambio_neto (+ = la península importa) y
 * enlace_baleares (+ = de la península hacia Baleares). Los campos que el pipeline deja
 * en null (fronteras sin desglose coherente, bombeo sin desglose, intercambio en islas)
 * también van null aquí.
 */
export function normalizarFila(sistema, raw, coef) {
    // coalesce(x, 0)
    const n = (k) => {
        const v = raw[k] === null || raw[k] === undefined ? NaN : Number(raw[k]);
        return Number.isFinite(v) ? v : 0;
    };
    // valor crudo o null (para las comparaciones del SQL con nulls)
    const crudo = (k) => {
        const v = raw[k] === null || raw[k] === undefined ? NaN : Number(raw[k]);
        return Number.isFinite(v) ? v : null;
    };
    // coalesce(f_x, 0) con los factores del propio sistema
    const f = (k) => {
        const v = Number(coef?.[k]);
        return Number.isFinite(v) ? v : 0;
    };
    const pen = sistema === 'peninsula';
    const bal = sistema === 'baleares';

    const eol = n('eol'), nuc = n('nuc'), gf = n('gf'), car = n('car'), cc = n('cc'), vap = n('vap');
    const hid = n('hid'), gnhd = n('gnhd'), turb = n('turb'), conb = n('conb');
    const aut = n('aut'), bio = n('bio'), cogenResto = n('cogenResto');
    const sol = n('sol'), solFot = n('solFot'), solTer = n('solTer');
    const bat = n('bat'), consBat = n('consBat'), inter = n('inter'), icb = n('icb');
    const die = n('die'), gas = n('gas'), cb = n('cb'), fot = n('fot'), tnr = n('tnr'), trn = n('trn');
    const otrRen = n('otrRen'), resid = n('resid'), genAux = n('genAux'), cogen = n('cogen');
    const residNr = n('residNr'), residRen = n('residRen');

    // desglose de bombeo (península ~2022+, Canarias) y solar (península 2016+)
    const hayBombeo = gnhd !== 0 || conb !== 0 || turb !== 0;
    const haySolar = solFot !== 0 || solTer !== 0;
    // desglose por frontera coherente con el saldo total (Andorra invertida en REE)
    const iFra = crudo('impFra'), iPor = crudo('impPor'), iMar = crudo('impMar');
    const netoFronteras =
        Math.abs(n('impFra')) + Math.abs(n('impPor')) + Math.abs(n('impMar')) + Math.abs(n('expAnd')) -
        Math.abs(n('expFra')) - Math.abs(n('expPor')) - Math.abs(n('expMar')) - Math.abs(n('impAnd'));
    // not (coalesce(imp_fra,0) <> 0 and imp_fra = imp_por and imp_por = imp_mar), con la lógica
    // ternaria de SQL: si alguna comparación es null (dato ausente) el resultado es null → falso
    let repetidas;
    if (n('impFra') === 0) repetidas = false;
    else if (iPor === null || iMar === null) repetidas = null;
    else repetidas = iFra === iPor && iPor === iMar;
    const hayFronteras =
        (n('impTot') !== 0 || n('expTot') !== 0) && Math.abs(inter - netoFronteras) <= 300 && repetidas === false;

    const bombeoTurbNeto = hid - gnhd - conb;
    // aut solo cuando de verdad contiene bio + cogenResto (2012-2018 y abril de 2026 en adelante)
    const cogenPen = pen && aut > 0 && aut >= 0.95 * (bio + cogenResto) ? aut - bio : cogenResto;
    // autoconsumo FV estimado por REE que la curva DEMANDAAU suma a dem y a solFot
    const autoconsumo = pen && haySolar && sol > 0 ? Math.max(solFot + solTer - sol, 0) : 0;
    const frontera = (k) => (pen && hayFronteras ? Math.abs(n(k)) : null);

    const fila = {
        sistema,
        demanda_mw: n('dem') - autoconsumo,
        eolica: eol,
        solar_fv: pen ? (haySolar ? solFot - autoconsumo : sol) : fot,
        solar_termica: pen ? (haySolar ? solTer : 0) : bal ? trn : 0,
        hidraulica: bal ? 0 : hayBombeo ? gnhd : hid,
        nuclear: pen ? nuc : 0,
        carbon: car,
        ciclo_combinado: cc,
        cogeneracion_residuos: pen ? cogenPen : bal ? cogen + residNr + resid : 0,
        turbinacion_bombeo: bal || !hayBombeo ? null : Math.max(bombeoTurbNeto, 0),
        consumo_bombeo: bal || !hayBombeo ? null : -conb + Math.max(-bombeoTurbNeto, 0),
        baterias_descarga: pen ? bat : 0,
        baterias_carga: pen ? -Math.min(consBat, 0) : 0,
        diesel: pen ? 0 : die,
        turbina_gas: pen ? 0 : gas,
        motores_vapor: vap,
        otras_renovables: pen ? bio : bal ? otrRen + residRen : 0,
        otras_no_renovables: pen ? gf : bal ? tnr + genAux : 0,
        intercambio_neto: pen ? inter : null,
        imp_francia: frontera('impFra'), exp_francia: frontera('expFra'),
        imp_portugal: frontera('impPor'), exp_portugal: frontera('expPor'),
        imp_marruecos: frontera('impMar'), exp_marruecos: frontera('expMar'),
        // Andorra invertida: en REE 'impAnd' es lo que SALE hacia Andorra
        imp_andorra: frontera('expAnd'), exp_andorra: frontera('impAnd'),
        // + = hacia Baleares (icb es negativo cuando sale de la península)
        enlace_baleares: pen ? -icb : bal ? cb : null,
    };

    // emisiones (t CO2/h): campos originales × factores del propio sistema
    const co2 =
        car * f('car') + cc * f('cc') + vap * f('vap') + gf * f('gf') + die * f('die') + gas * f('gas') +
        genAux * f('genAux') + cogen * f('cogen') + tnr * f('tnr') + resid * f('resid') + residNr * f('residNr') +
        (pen ? cogenPen * f(bio === 0 && cogenResto === 0 ? 'aut' : 'cogenResto') : 0);

    const gen =
        fila.eolica + fila.solar_fv + fila.solar_termica + fila.hidraulica + fila.nuclear + fila.carbon +
        fila.ciclo_combinado + fila.cogeneracion_residuos + (fila.turbinacion_bombeo ?? 0) + fila.baterias_descarga +
        fila.diesel + fila.turbina_gas + fila.motores_vapor + fila.otras_renovables + fila.otras_no_renovables;
    const ren = fila.eolica + fila.solar_fv + fila.solar_termica + fila.hidraulica + fila.otras_renovables;

    fila.generacion_total_mw = gen;
    fila.renovable_mw = ren;
    fila.pct_renovable = gen > 0 ? Math.min(Math.max((100 * ren) / gen, 0), 100) : null;
    fila.co2_t_h = co2;
    fila.intensidad_gco2_kwh = gen > 0 ? (1000 * co2) / gen : null; // t/MWh × 1000 = g/kWh

    for (const k of Object.keys(fila)) if (typeof fila[k] === 'number') fila[k] = redondear(fila[k], k === 'pct_renovable' ? 2 : 1);
    return fila;
}

// ---------------------------------------------------------------------------
// Descarga
// ---------------------------------------------------------------------------

const cacheCoef = {}; // memoria del isolate: { sistema: { t, valor } }

async function coeficientes(sistema, fecha, fetchImpl) {
    const c = cacheCoef[sistema];
    if (c && Date.now() - c.t < TTL_COEF * 1000) return c.valor;
    const { servicio, curva } = SISTEMAS[sistema];
    try {
        const url = `${REE_DEMANDA}/WSvisionaMoviles${servicio}Rest/resources/coeficientesCO2?callback=cb&curva=${curva}&fecha=${fecha}`;
        const bruto = quitarJsonp(await pedir(url, { ttl: TTL_COEF, fetchImpl }));
        const valor = {};
        for (const [k, v] of Object.entries(bruto || {})) valor[k.replace('factorEmisionCO2_', '')] = Number(v);
        if (!Object.keys(valor).length) throw new Error('sin coeficientes');
        cacheCoef[sistema] = { t: Date.now(), valor };
        return valor;
    } catch {
        return COEF_RESPALDO[sistema];
    }
}

async function curva(sistema, fecha, fetchImpl) {
    const { servicio, curva: c } = SISTEMAS[sistema];
    const url = `${REE_DEMANDA}/WSvisionaMoviles${servicio}Rest/resources/demandaGeneracion${servicio}?callback=cb&curva=${c}&fecha=${fecha}`;
    const j = quitarJsonp(await pedir(url, { fetchImpl }));
    const filas = Array.isArray(j?.valoresHorariosGeneracion) ? j.valoresHorariosGeneracion : [];
    // Como la ingesta: solo las filas del día pedido (los solapes los trae su propia petición).
    return filas.filter((r) => typeof r?.ts === 'string' && r.ts.startsWith(fecha));
}

/** Una fila está completa si la generación (más lo que entra por los enlaces) cubre
 *  al menos la mitad de la demanda; Baleares importa buena parte por el enlace. */
export function filaCompleta(sistema, fila) {
    const entrada = Math.max(fila.intercambio_neto ?? 0, 0) + Math.max(sistema === 'baleares' ? fila.enlace_baleares ?? 0 : 0, 0);
    const minimo = sistema === 'baleares' ? 0.35 : 0.5;
    return fila.generacion_total_mw + entrada >= minimo * fila.demanda_mw;
}

async function datosSistema(sistema, ahora, fetchImpl) {
    const hoy = fechaMadrid(ahora);
    const ayer = fechaMadrid(ahora - 86400000);
    const [filasHoy, filasAyer, coef] = await Promise.all([
        curva(sistema, hoy, fetchImpl),
        curva(sistema, ayer, fetchImpl).catch(() => []), // ayer es opcional
        coeficientes(sistema, hoy, fetchImpl),
    ]);
    const { tz } = SISTEMAS[sistema];
    const porTs = new Map();
    for (const lote of [filasAyer, filasHoy]) {
        let previo = -Infinity;
        for (const raw of lote) {
            if (!raw?.ts || !(Number(raw.dem) > 0)) continue;
            let utc = localAUtc(raw.ts, tz);
            if (!Number.isFinite(utc)) continue;
            // hora repetida del cambio de horario de octubre sin marca A/B (por si REE la da así)
            if (!/ \d{1,2}[AB]:/.test(raw.ts) && utc <= previo) utc = previo + 5 * 60000;
            previo = Math.max(previo, utc);
            if (utc > ahora + 10 * 60000) continue; // filas futuras (no debería haberlas)
            if (porTs.has(utc)) continue; // como la ingesta: se queda la primera
            porTs.set(utc, { ...normalizarFila(sistema, raw, coef), ts_utc: new Date(utc).toISOString(), ts_local: tsLocal(raw.ts) });
        }
    }
    const filas = [...porTs.entries()].sort((a, b) => a[0] - b[0]).map(([, v]) => v);
    // REE publica los últimos cinco minutos a medias (demanda y solar ya, el resto de
    // tecnologías a 0): se descartan las filas finales que no cubren la demanda.
    while (filas.length > 1 && !filaCompleta(sistema, filas[filas.length - 1])) filas.pop();
    if (!filas.length) throw new Error('sin filas');
    const ultimo = filas[filas.length - 1];
    const limite = Date.parse(ultimo.ts_utc) - 24 * 3600000;
    const serie24h = filas
        .filter((r) => {
            const t = Date.parse(r.ts_utc);
            return t > limite && (Math.round(t / 60000) % PASO_SERIE_MIN === 0 || r === ultimo);
        })
        .map((r) => Object.fromEntries(CAMPOS_SERIE.map((k) => [k, r[k]])));
    return { ultimo, serie24h };
}

async function precios(ahora, fetchImpl) {
    const hoy = fechaMadrid(ahora);
    const url = `${REE_APIDATOS}/es/datos/mercados/precios-mercados-tiempo-real?start_date=${hoy}T00:00&end_date=${hoy}T23:59&time_trunc=hour`;
    const j = JSON.parse(await pedir(url, { fetchImpl }));
    const serie = (re) => (j.included || []).find((x) => re.test(x.type || x.attributes?.title || ''))?.attributes?.values || [];
    const vigente = (vals) => {
        let mejor = null;
        for (const v of vals) if (Date.parse(v.datetime) <= ahora && (!mejor || Date.parse(v.datetime) > Date.parse(mejor.datetime))) mejor = v;
        return mejor;
    };
    const spot = vigente(serie(/spot/i));
    const pvpc = vigente(serie(/pvpc/i));
    return {
        spot_eur_mwh: spot ? redondear(Number(spot.value), 2) : null,
        pvpc_eur_mwh: pvpc ? redondear(Number(pvpc.value), 2) : null,
        ts: spot?.datetime ? new Date(spot.datetime).toISOString() : pvpc?.datetime ? new Date(pvpc.datetime).toISOString() : null,
        spot_ts: spot?.datetime ? new Date(spot.datetime).toISOString() : null,
        pvpc_ts: pvpc?.datetime ? new Date(pvpc.datetime).toISOString() : null,
    };
}

/** Construye la instantánea completa. Exportada para poder probarla con Node. */
export async function construirSnapshot({ ahora = Date.now(), fetchImpl = fetch } = {}) {
    const nombres = Object.keys(SISTEMAS);
    const resultados = await Promise.allSettled([...nombres.map((s) => datosSistema(s, ahora, fetchImpl)), precios(ahora, fetchImpl)]);
    const sistemas = {};
    const errores = [];
    nombres.forEach((s, i) => {
        const r = resultados[i];
        if (r.status === 'fulfilled') sistemas[s] = r.value;
        else {
            sistemas[s] = null;
            errores.push(`${s}: ${r.reason?.message || r.reason}`);
        }
    });
    const rp = resultados[nombres.length];
    const precio = rp.status === 'fulfilled' ? rp.value : { spot_eur_mwh: null, pvpc_eur_mwh: null, ts: null };
    if (rp.status !== 'fulfilled') errores.push(`precios: ${rp.reason?.message || rp.reason}`);

    const tsUltimos = Object.values(sistemas).filter(Boolean).map((s) => Date.parse(s.ultimo.ts_utc));
    return {
        actualizado: tsUltimos.length ? new Date(Math.max(...tsUltimos)).toISOString() : null,
        generado: new Date(ahora).toISOString(),
        fuente: 'Red Eléctrica (REE)',
        sistemas,
        precios: precio,
        errores,
    };
}

// ---------------------------------------------------------------------------
// Handler HTTP
// ---------------------------------------------------------------------------

function cabecerasCors(request, env) {
    const permitidos = (env?.ORIGENES_PERMITIDOS ? String(env.ORIGENES_PERMITIDOS).split(',') : ORIGENES_POR_DEFECTO).map((s) => s.trim());
    const origen = request.headers.get('Origin');
    const h = { Vary: 'Origin' };
    if (origen && permitidos.includes(origen)) {
        h['Access-Control-Allow-Origin'] = origen;
        h['Access-Control-Allow-Methods'] = 'GET, OPTIONS';
        h['Access-Control-Allow-Headers'] = 'Content-Type';
        h['Access-Control-Max-Age'] = '86400';
    }
    return h;
}

function conCabeceras(resp, extra) {
    const r = new Response(resp.body, resp);
    for (const [k, v] of Object.entries(extra)) r.headers.set(k, v);
    return r;
}

export default {
    async fetch(request, env, ctx) {
        const url = new URL(request.url);
        const cors = cabecerasCors(request, env);

        if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
        if (request.method !== 'GET' && request.method !== 'HEAD') return new Response('Método no permitido', { status: 405, headers: cors });

        if (url.pathname === '/salud') return new Response('ok', { headers: { ...cors, 'Content-Type': 'text/plain' } });
        if (url.pathname !== '/' && url.pathname !== '/snapshot' && url.pathname !== '/v1/snapshot') {
            return new Response('No encontrado. Usa /snapshot', { status: 404, headers: cors });
        }

        // La caché se guarda sin cabeceras CORS (se añaden por petición según el Origin).
        const clave = new Request(`${url.origin}/v1/snapshot`, { method: 'GET' });
        const cache = caches.default;
        let resp = await cache.match(clave);
        if (!resp) {
            let cuerpo, estado, ttl;
            try {
                const datos = await construirSnapshot();
                const alguno = Object.values(datos.sistemas).some(Boolean);
                estado = alguno ? 200 : 502;
                ttl = alguno && datos.errores.length === 0 ? TTL_SNAPSHOT : TTL_PARCIAL;
                cuerpo = JSON.stringify(datos);
            } catch (e) {
                estado = 502;
                ttl = TTL_PARCIAL;
                cuerpo = JSON.stringify({ error: String(e?.message || e) });
            }
            resp = new Response(cuerpo, {
                status: estado,
                headers: {
                    'Content-Type': 'application/json; charset=utf-8',
                    'Cache-Control': `public, max-age=${ttl}`,
                    'X-Fuente': 'Red Electrica (REE)',
                },
            });
            if (estado === 200) ctx.waitUntil(cache.put(clave, resp.clone()));
        }
        return conCabeceras(resp, cors);
    },
};
