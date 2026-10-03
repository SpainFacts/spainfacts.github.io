<script>
    import { localeActual } from "../utils.js";
    import { page } from "$app/stores";
    import { idiomaDeRuta, t, tf } from "../i18n.js";
    // "El sistema eléctrico, ahora": mapa de los sistemas eléctricos (total
    // nacional, Península, Baleares, Canarias, Ceuta y Melilla) con intercambios internacionales como
    // flechas, tabla con demanda / % renovable / gCO2/kWh, precio y mix de 24 h.
    //
    // Datos: consulta el Cloudflare Worker `spainfacts-ree-directo` cada 5 min.
    // Si no está configurado o falla, usa las filas horneadas en el build
    // (`fallback`, consulta mother.electricidad_ultimas_24h) con el mismo esquema.
    import { onMount, onDestroy } from 'svelte';
    import { REE_DIRECTO_URL, REE_DIRECTO_INTERVALO_MS } from '../config/directo.js';

    /** Filas de mother.electricidad_ultimas_24h (una por sistema y 5 min). */
    export let fallback = [];
    /** URL del Worker; por defecto la de src/lib/config/directo.js. */
    export let workerUrl = REE_DIRECTO_URL;
    export let geoUrl = '/geo/ccaa.geojson';
    export let intervaloMs = REE_DIRECTO_INTERVALO_MS;

    $: lang = idiomaDeRuta($page.url.pathname);
    // Los nombres se traducen solo al pintar; id/k siguen siendo las claves de datos del Worker.
    $: nomSis = (id) => t('directo.sis.' + id, lang);
    $: nomTec = (k) => t('directo.tec.' + k, lang);
    $: nomPais = (cod) => t('pais.' + cod, lang);

    const SISTEMAS = [
        { id: 'nacional', nombre: 'España (total)' },
        { id: 'peninsula', nombre: 'Península' },
        { id: 'baleares', nombre: 'Baleares' },
        { id: 'canarias', nombre: 'Canarias' },
        { id: 'ceuta', nombre: 'Ceuta' },
        { id: 'melilla', nombre: 'Melilla' },
    ];

    // Tecnologías del gráfico apilado (orden de abajo arriba) y sus colores.
    const TECNOLOGIAS = [
        { k: 'nuclear', n: 'Nuclear', c: '#7c3aed' },
        { k: 'carbon', n: 'Carbón', c: '#44403c' },
        { k: 'ciclo_combinado', n: 'Ciclo combinado', c: '#f59e0b' },
        { k: 'cogeneracion_residuos', n: 'Cogeneración y residuos', c: '#c084fc' },
        { k: 'diesel', n: 'Motores diésel', c: '#b91c1c' },
        { k: 'turbina_gas', n: 'Turbina de gas', c: '#ef4444' },
        { k: 'motores_vapor', n: 'Turbina de vapor', c: '#a16207' },
        { k: 'otras_no_renovables', n: 'Otras no renovables', c: '#94a3b8' },
        { k: 'hidraulica', n: 'Hidráulica', c: '#0ea5e9' },
        { k: 'turbinacion_bombeo', n: 'Turbinación bombeo', c: '#1d4ed8' },
        { k: 'baterias_descarga', n: 'Baterías', c: '#0f766e' },
        { k: 'otras_renovables', n: 'Otras renovables', c: '#65a30d' },
        { k: 'eolica', n: 'Eólica', c: '#16a34a' },
        { k: 'solar_termica', n: 'Solar térmica', c: '#ea580c' },
        { k: 'solar_fv', n: 'Solar fotovoltaica', c: '#facc15' },
    ];

    // ------------------------------------------------------------------ datos
    const num = (v) => {
        if (v === null || v === undefined || v === '') return null;
        const x = typeof v === 'bigint' ? Number(v) : Number(v);
        return Number.isFinite(x) ? x : null;
    };
    const iso = (v) => {
        if (!v) return null;
        const d = v instanceof Date ? v : new Date(typeof v === 'string' && !/[zZ]|[+-]\d\d:?\d\d$/.test(v) ? v.replace(' ', 'T') + 'Z' : v);
        return Number.isNaN(d.getTime()) ? null : d.toISOString();
    };

    /** Convierte las filas del build (una por sistema y ts) al mismo formato que el Worker. */
    function desdeFilas(filas) {
        let arr = [];
        try {
            arr = Array.from(filas ?? []);
        } catch {
            arr = [];
        }
        const sistemas = {};
        let maxTs = null;
        for (const s of SISTEMAS) {
            const serie = arr
                .filter((r) => String(r?.sistema ?? '').toLowerCase() === s.id)
                .map((r) => ({ ...r, ts_utc: iso(r.ts_utc) }))
                .filter((r) => r.ts_utc)
                .sort((a, b) => (a.ts_utc < b.ts_utc ? -1 : 1));
            if (!serie.length) {
                sistemas[s.id] = null;
                continue;
            }
            const ultimo = serie[serie.length - 1];
            sistemas[s.id] = { ultimo, serie24h: serie };
            if (!maxTs || ultimo.ts_utc > maxTs) maxTs = ultimo.ts_utc;
        }
        return { actualizado: maxTs, sistemas, precios: null };
    }

    $: datosBuild = desdeFilas(fallback);

    let directo = null; // respuesta del Worker
    let errorDirecto = null;
    // El Worker no contesta (fallo de red o tiempo agotado). Es lo que pasa en España
    // cuando LaLiga hace bloquear IPs de Cloudflare durante los partidos; si contesta
    // con un error HTTP es otro problema y no se muestra el aviso.
    let sinRespuesta = false;
    let cargando = false;
    let temporizador;

    async function consultar() {
        if (!workerUrl) return;
        cargando = true;
        try {
            const ctrl = new AbortController();
            const t = setTimeout(() => ctrl.abort(), 15000);
            let r;
            try {
                r = await fetch(`${workerUrl}/snapshot`, { signal: ctrl.signal, cache: 'no-cache' });
            } catch (e) {
                sinRespuesta = true;
                throw e;
            } finally {
                clearTimeout(t);
            }
            sinRespuesta = false;
            if (!r.ok) throw new Error(`HTTP ${r.status}`);
            const j = await r.json();
            if (!j?.sistemas || !Object.values(j.sistemas).some(Boolean)) throw new Error('respuesta sin datos');
            directo = j;
            errorDirecto = null;
        } catch (e) {
            errorDirecto = e?.message || String(e);
        } finally {
            cargando = false;
        }
    }

    // Combina: el Worker manda; si le falta un sistema, se rellena con el del build.
    $: datos = (() => {
        if (!directo) return { ...datosBuild, modo: datosBuild.actualizado ? 'build' : 'vacio' };
        const sistemas = {};
        for (const s of SISTEMAS) sistemas[s.id] = directo.sistemas?.[s.id] ?? datosBuild.sistemas[s.id] ?? null;
        return { actualizado: directo.actualizado, sistemas, precios: directo.precios, modo: 'directo' };
    })();

    // ------------------------------------------------------------------ formato
    const nf = (dec) => new Intl.NumberFormat(localeActual(), { maximumFractionDigits: dec, minimumFractionDigits: dec });
    const fmt = (v, dec = 0) => (num(v) === null ? '—' : nf(dec).format(num(v)));
    const hora = (isoTs) =>
        isoTs ? new Date(isoTs).toLocaleTimeString(localeActual(), { timeZone: 'Europe/Madrid', hour: '2-digit', minute: '2-digit' }) : '—';
    const fechaHora = (isoTs) =>
        isoTs
            ? new Date(isoTs).toLocaleString(localeActual(), { timeZone: 'Europe/Madrid', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })
            : '—';

    // Minutos transcurridos desde el último dato (se refresca cada minuto).
    let ahora = Date.now();
    $: retrasoMin = datos.actualizado ? Math.round((ahora - Date.parse(datos.actualizado)) / 60000) : null;

    // ------------------------------------------------------------------ escalas de color
    let modoColor = 'renovables'; // 'renovables' | 'co2'
    const ESC_REN = ['#f1f5f9', '#d9f99d', '#86efac', '#22c55e', '#15803d', '#14532d'];
    const ESC_CO2 = ['#15803d', '#84cc16', '#facc15', '#f97316', '#b45309', '#57280b'];
    function interp(escala, t) {
        const x = Math.min(1, Math.max(0, t)) * (escala.length - 1);
        const i = Math.min(escala.length - 2, Math.floor(x));
        const f = x - i;
        const a = escala[i].match(/\w\w/g).map((h) => parseInt(h, 16));
        const b = escala[i + 1].match(/\w\w/g).map((h) => parseInt(h, 16));
        return '#' + a.map((v, j) => Math.round(v + (b[j] - v) * f).toString(16).padStart(2, '0')).join('');
    }
    function colorSistema(u) {
        if (!u) return null;
        if (modoColor === 'renovables') {
            const p = num(u.pct_renovable);
            return p === null ? null : interp(ESC_REN, p / 100);
        }
        const g = num(u.intensidad_gco2_kwh);
        return g === null ? null : interp(ESC_CO2, g / 800);
    }
    const textoSobre = (hex) => {
        if (!hex) return '#111827';
        const [r, g, b] = hex.match(/\w\w/g).map((h) => parseInt(h, 16));
        return 0.299 * r + 0.587 * g + 0.114 * b > 150 ? '#111827' : '#ffffff';
    };

    // ------------------------------------------------------------------ mapa
    const LON_MIN = -11.2, LON_MAX = 5.6, LAT_MIN = 34.9, LAT_MAX = 44.5;
    const COS = Math.cos((40 * Math.PI) / 180);
    const ANCHO = 760;
    const ESC = ANCHO / ((LON_MAX - LON_MIN) * COS);
    const ALTO = Math.round((LAT_MAX - LAT_MIN) * ESC);
    const px = (lon) => (lon - LON_MIN) * COS * ESC;
    const py = (lat) => (LAT_MAX - lat) * ESC;

    // Recuadro de Canarias (abajo a la izquierda), a escala reducida.
    const CAN = { lonMin: -18.3, lonMax: -13.3, latMin: 27.55, latMax: 29.5, esc: ESC * 0.72, x0: 8, cos: Math.cos((28.5 * Math.PI) / 180) };
    const CAN_W = (CAN.lonMax - CAN.lonMin) * CAN.cos * CAN.esc;
    const CAN_H = (CAN.latMax - CAN.latMin) * CAN.esc;
    const CAN_Y0 = ALTO - CAN_H - 26;
    const cx = (lon) => CAN.x0 + (lon - CAN.lonMin) * CAN.cos * CAN.esc;
    const cy = (lat) => CAN_Y0 + 18 + (CAN.latMax - lat) * CAN.esc;

    let formas = { peninsula: '', baleares: '', canarias: '', ceuta: '', melilla: '' };

    function camino(geom, fx, fy) {
        const polys = geom.type === 'Polygon' ? [geom.coordinates] : geom.coordinates;
        return polys
            .map((p) => p.map((anillo) => anillo.map(([lon, lat], i) => `${i ? 'L' : 'M'}${fx(lon).toFixed(1)},${fy(lat).toFixed(1)}`).join('') + 'Z').join(''))
            .join('');
    }

    // ------------------------------------------------------------------ flechas
    // Punto de la frontera (lon, lat) y dirección "hacia fuera" en pantalla.
    const FRONTERAS = [
        { id: 'francia', cod: 'FRA', nombre: 'Francia', lon: -0.9, lat: 43.0, dx: 0, dy: -1, etq: 'arriba' },
        { id: 'andorra', cod: 'AND', nombre: 'Andorra', lon: 1.55, lat: 42.52, dx: 0.35, dy: -1, etq: 'arriba' },
        { id: 'portugal', cod: 'PRT', nombre: 'Portugal', lon: -7.0, lat: 40.2, dx: -1, dy: 0, etq: 'izquierda' },
        { id: 'marruecos', cod: 'MAR', nombre: 'Marruecos', lon: -5.6, lat: 35.95, dx: 0, dy: 1, etq: 'abajo' },
    ];
    const LARGO = 46;

    function flecha(x1, y1, x2, y2, grosor) {
        const L = Math.hypot(x2 - x1, y2 - y1) || 1;
        const ux = (x2 - x1) / L, uy = (y2 - y1) / L;
        const cabeza = Math.max(9, grosor * 2.2);
        const bx = x2 - ux * cabeza, by = y2 - uy * cabeza;
        const nx = -uy, ny = ux;
        const g = grosor / 2, h = cabeza * 0.7;
        return [
            `M${(x1 + nx * g).toFixed(1)},${(y1 + ny * g).toFixed(1)}`,
            `L${(bx + nx * g).toFixed(1)},${(by + ny * g).toFixed(1)}`,
            `L${(bx + nx * h).toFixed(1)},${(by + ny * h).toFixed(1)}`,
            `L${x2.toFixed(1)},${y2.toFixed(1)}`,
            `L${(bx - nx * h).toFixed(1)},${(by - ny * h).toFixed(1)}`,
            `L${(bx - nx * g).toFixed(1)},${(by - ny * g).toFixed(1)}`,
            `L${(x1 - nx * g).toFixed(1)},${(y1 - ny * g).toFixed(1)}Z`,
        ].join('');
    }
    const grosorMw = (mw) => Math.min(14, 2.5 + Math.sqrt(Math.abs(mw)) / 5);

    $: pen = datos.sistemas.peninsula?.ultimo ?? null;
    $: bal = datos.sistemas.baleares?.ultimo ?? null;
    $: can = datos.sistemas.canarias?.ultimo ?? null;
    $: ceu = datos.sistemas.ceuta?.ultimo ?? null;
    $: mel = datos.sistemas.melilla?.ultimo ?? null;
    $: nacional = datos.sistemas.nacional?.ultimo ?? null;

    // Saldo por frontera: > 0 = España importa. Se usa |valor| para no depender del signo con que se guarden las exportaciones.
    const saldo = (u, pais) => {
        const imp = num(u?.[`imp_${pais}`]);
        const exp = num(u?.[`exp_${pais}`]);
        if (imp === null && exp === null) return null;
        return Math.abs(imp ?? 0) - Math.abs(exp ?? 0);
    };

    $: flechas = FRONTERAS.map((f) => {
        const mw = saldo(pen, f.id);
        const x = px(f.lon), y = py(f.lat);
        const L = Math.hypot(f.dx, f.dy);
        const ox = x + (f.dx / L) * LARGO, oy = y + (f.dy / L) * LARGO;
        let d = null;
        if (mw !== null && Math.abs(mw) >= 1) d = mw > 0 ? flecha(ox, oy, x, y, grosorMw(mw)) : flecha(x, y, ox, oy, grosorMw(mw));
        const tx = x + (f.dx / L) * (LARGO + 12), ty = y + (f.dy / L) * (LARGO + 12);
        return { ...f, mw, d, x, y, tx, ty, importa: mw > 0 };
    });

    // Enlace Península–Baleares: > 0 = de la Península a Baleares. Se prefiere el dato de Baleares.
    $: enlace = num(bal?.enlace_baleares) ?? num(pen?.enlace_baleares);
    const EA = { x: px(0.05), y: py(39.62) }, EB = { x: px(2.3), y: py(39.62) };
    $: flechaBaleares =
        enlace === null || Math.abs(enlace) < 1
            ? null
            : enlace > 0
              ? flecha(EA.x, EA.y, EB.x, EB.y, grosorMw(enlace))
              : flecha(EB.x, EB.y, EA.x, EA.y, grosorMw(enlace));

    // Etiquetas de sistema sobre el mapa.
    $: etiquetas = [
        { id: 'peninsula', nombre: 'Península', u: pen, x: px(-3.7), y: py(40.1) },
        { id: 'baleares', nombre: 'Baleares', u: bal, x: px(3.1), y: py(38.75) },
        { id: 'canarias', nombre: 'Canarias', u: can, x: CAN.x0 + 58, y: CAN_Y0 - 52 },
        { id: 'nacional', nombre: 'España (total)', u: nacional, x: px(4.3), y: py(41.55) },
    ];
    // Ceuta y Melilla: etiqueta compacta junto a su contorno (son muy pequeñas a esta escala)
    $: etiquetasCiudades = [
        { id: 'ceuta', nombre: 'Ceuta', u: ceu, x: px(-5.32), y: py(35.89), dx: 12, anchor: 'start' },
        { id: 'melilla', nombre: 'Melilla', u: mel, x: px(-2.94), y: py(35.29), dx: 8, anchor: 'start' },
    ];
    $: valorModo = (u, m) =>
        !u ? '—' : m === 'renovables' ? `${fmt(u.pct_renovable, 0)} % ${t('directo.renovAbr', lang)}` : `${fmt(u.intensidad_gco2_kwh, 0)} g/kWh`;

    // ------------------------------------------------------------------ gráfico 24 h
    let seleccion = 'peninsula';
    const GW = 720, GH = 230, GM = { l: 48, r: 10, t: 10, b: 24 };
    $: serie = (datos.sistemas[seleccion]?.serie24h ?? []).filter((r) => r?.ts_utc);
    $: tecnologiasVisibles = TECNOLOGIAS.filter((t) => serie.some((r) => (num(r[t.k]) ?? 0) > 0.5));
    $: t0 = serie.length ? Date.parse(serie[0].ts_utc) : 0;
    $: t1 = serie.length ? Date.parse(serie[serie.length - 1].ts_utc) : 1;
    $: yMax = Math.max(1, ...serie.map((r) => Math.max(num(r.demanda_mw) ?? 0, tecnologiasVisibles.reduce((s, t) => s + Math.max(0, num(r[t.k]) ?? 0), 0))));
    $: gx = (ts) => GM.l + ((Date.parse(ts) - t0) / Math.max(1, t1 - t0)) * (GW - GM.l - GM.r);
    $: gy = (v) => GH - GM.b - (v / yMax) * (GH - GM.t - GM.b);
    $: capas = (() => {
        const base = serie.map(() => 0);
        return tecnologiasVisibles.map((t) => {
            const arriba = serie.map((r, i) => base[i] + Math.max(0, num(r[t.k]) ?? 0));
            const d =
                serie.map((r, i) => `${i ? 'L' : 'M'}${gx(r.ts_utc).toFixed(1)},${gy(arriba[i]).toFixed(1)}`).join('') +
                serie
                    .map((r, i) => [r, i])
                    .reverse()
                    .map(([r, i]) => `L${gx(r.ts_utc).toFixed(1)},${gy(base[i]).toFixed(1)}`)
                    .join('') +
                'Z';
            arriba.forEach((v, i) => (base[i] = v));
            return { ...t, d };
        });
    })();
    $: lineaDemanda = serie
        .filter((r) => num(r.demanda_mw) !== null)
        .map((r, i) => `${i ? 'L' : 'M'}${gx(r.ts_utc).toFixed(1)},${gy(num(r.demanda_mw)).toFixed(1)}`)
        .join('');
    $: ticksY = (() => {
        const paso = [50, 100, 200, 250, 500, 1000, 2000, 2500, 5000, 10000].find((p) => yMax / p <= 5) ?? 10000;
        const out = [];
        for (let v = 0; v <= yMax; v += paso) out.push(v);
        return out;
    })();
    $: ticksX = (() => {
        if (!serie.length) return [];
        const out = [];
        const inicio = Math.ceil(t0 / (3 * 3600000)) * 3 * 3600000;
        for (let t = inicio; t <= t1; t += 3 * 3600000) out.push(new Date(t).toISOString());
        return out;
    })();

    let hoverIdx = null;
    function moverRaton(ev) {
        if (!serie.length) return;
        const svg = ev.currentTarget;
        const r = svg.getBoundingClientRect();
        const x = ((ev.clientX - r.left) / r.width) * GW;
        let mejor = 0, dist = Infinity;
        serie.forEach((s, i) => {
            const d = Math.abs(gx(s.ts_utc) - x);
            if (d < dist) (dist = d), (mejor = i);
        });
        hoverIdx = mejor;
    }
    $: puntoHover = hoverIdx !== null ? serie[hoverIdx] : null;
    $: filaMix = puntoHover ?? datos.sistemas[seleccion]?.ultimo ?? null;
    $: mixAhora = filaMix
        ? TECNOLOGIAS.map((t) => ({ ...t, v: num(filaMix[t.k]) ?? 0 }))
              .filter((t) => t.v > 0.5)
              .sort((a, b) => b.v - a.v)
        : [];
    $: totalMix = mixAhora.reduce((s, t) => s + t.v, 0) || 1;

    // ------------------------------------------------------------------ ciclo de vida
    let reloj;
    onMount(async () => {
        try {
            const geo = await (await fetch(geoUrl)).json();
            const f = { peninsula: [], baleares: [], canarias: [], ceuta: [], melilla: [] };
            for (const ft of geo.features || []) {
                const cod = ft.properties?.cod_ccaa;
                if (cod === '05') f.canarias.push(camino(ft.geometry, cx, cy));
                else if (cod === '04') f.baleares.push(camino(ft.geometry, px, py));
                else if (cod === '18') f.ceuta.push(camino(ft.geometry, px, py));
                else if (cod === '19') f.melilla.push(camino(ft.geometry, px, py));
                else f.peninsula.push(camino(ft.geometry, px, py));
            }
            formas = { peninsula: f.peninsula.join(''), baleares: f.baleares.join(''), canarias: f.canarias.join(''), ceuta: f.ceuta.join(''), melilla: f.melilla.join('') };
        } catch {
            /* sin contorno: se ven igualmente flechas, etiquetas y tabla */
        }
        if (workerUrl) {
            consultar();
            temporizador = setInterval(consultar, intervaloMs);
        }
        reloj = setInterval(() => (ahora = Date.now()), 60000);
    });
    onDestroy(() => {
        clearInterval(temporizador);
        clearInterval(reloj);
    });
</script>

<div class="not-prose my-4">
    <!-- Cabecera: estado del dato y selector de color -->
    <div class="flex flex-wrap items-center justify-between gap-3 mb-3">
        <div class="flex items-center gap-2 text-sm">
            {#if datos.modo === 'directo'}
                <span class="inline-flex items-center gap-1.5 rounded-full bg-green-100 dark:bg-green-950/60 text-green-800 dark:text-green-300 px-2.5 py-0.5 font-semibold">
                    <span class="relative flex h-2 w-2" aria-hidden="true"><span class="absolute inline-flex h-full w-full rounded-full bg-green-500 opacity-75 animate-ping"></span><span class="relative inline-flex h-2 w-2 rounded-full bg-green-600"></span></span>
                    {t('directo.envivo', lang)}
                </span>
                <span class="text-gray-600 dark:text-gray-400">
                    {t('directo.datos.pre', lang)} <b>{hora(datos.actualizado)}</b> {t('directo.datos.hora', lang)}{#if retrasoMin !== null && retrasoMin > 30}&nbsp;· {tf('directo.retraso', lang, { n: retrasoMin })}{/if}
                </span>
            {:else if datos.modo === 'build'}
                <span class="inline-flex items-center rounded-full bg-amber-100 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300 px-2.5 py-0.5 font-semibold">{t('directo.noDirecto', lang)}</span>
                <span class="text-gray-600 dark:text-gray-400">{t('directo.datos.pre', lang)} <b>{fechaHora(datos.actualizado)}</b> {t('directo.datos.build', lang)}</span>
            {:else}
                <span class="inline-flex items-center rounded-full bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 px-2.5 py-0.5 font-semibold">{cargando ? t('cargando', lang) : t('sin.datos', lang)}</span>
            {/if}
        </div>
        {#if sinRespuesta}
            <p class="w-full order-last rounded-md border border-amber-300 dark:border-amber-800 bg-amber-50 dark:bg-amber-950/40 text-amber-900 dark:text-amber-200 px-3 py-2 text-sm" role="status">
                {t('directo.bloqueoLaliga', lang)}
            </p>
        {/if}
        <div class="inline-flex rounded-md border border-gray-300 dark:border-gray-700 overflow-hidden text-sm" role="group" aria-label={t('directo.colorear', lang)}>
            {#each [['renovables', t('directo.renovables', lang)], ['co2', t('directo.co2', lang)]] as [v, etq]}
                <button
                    type="button"
                    class="px-3 py-1 {modoColor === v ? 'bg-teal-800 text-white' : 'bg-white dark:bg-gray-900 text-gray-700 dark:text-gray-300'}"
                    aria-pressed={modoColor === v}
                    on:click={() => (modoColor = v)}>{etq}</button>
            {/each}
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-5 gap-4">
        <!-- Mapa -->
        <div class="lg:col-span-3 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-2">
            <svg viewBox="0 0 {ANCHO} {ALTO}" class="w-full h-auto" role="img" aria-label={t('directo.mapa.aria', lang)}>
                <defs>
                    <pattern id="sse-sin-dato" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
                        <line x1="0" y1="0" x2="0" y2="6" stroke="#94a3b8" stroke-width="2" />
                    </pattern>
                </defs>

                <!-- Nombres de países vecinos -->
                <g class="fill-gray-400 dark:fill-gray-500" font-size="12" letter-spacing="2" font-weight="600">
                    <text x={px(0.9)} y={py(44.15)} text-anchor="middle">{nomPais('FRA').toLocaleUpperCase(localeActual())}</text>
                    <text x={px(-10.4)} y={py(41.3)} text-anchor="middle" transform="rotate(-90 {px(-10.4)} {py(41.3)})">{nomPais('PRT').toLocaleUpperCase(localeActual())}</text>
                    <text x={px(1.0)} y={py(35.2)} text-anchor="middle">{nomPais('MAR').toLocaleUpperCase(localeActual())}</text>
                </g>

                {#if formas.peninsula}
                    <path d={formas.peninsula} fill={colorSistema(pen) ?? 'url(#sse-sin-dato)'} class="stroke-white dark:stroke-gray-900" stroke-width="0.5" on:click={() => (seleccion = 'peninsula')} role="presentation" style="cursor:pointer" />
                    <path d={formas.baleares} fill={colorSistema(bal) ?? 'url(#sse-sin-dato)'} class="stroke-gray-500 dark:stroke-gray-400" stroke-width="0.5" on:click={() => (seleccion = 'baleares')} role="presentation" style="cursor:pointer" />
                    <path d={formas.ceuta} fill={colorSistema(ceu) ?? 'url(#sse-sin-dato)'} class="stroke-gray-600 dark:stroke-gray-300" stroke-width="1.5" on:click={() => (seleccion = 'ceuta')} role="presentation" style="cursor:pointer" />
                    <path d={formas.melilla} fill={colorSistema(mel) ?? 'url(#sse-sin-dato)'} class="stroke-gray-600 dark:stroke-gray-300" stroke-width="1.5" on:click={() => (seleccion = 'melilla')} role="presentation" style="cursor:pointer" />
                {/if}

                <!-- Recuadro de Canarias -->
                <rect x={CAN.x0 - 4} y={CAN_Y0} width={CAN_W + 8} height={CAN_H + 24} rx="6" class="fill-slate-50 dark:fill-gray-950 stroke-gray-300 dark:stroke-gray-700" stroke-width="1" />
                <text x={CAN.x0 + 2} y={CAN_Y0 + 13} font-size="10" class="fill-gray-500 dark:fill-gray-400">{t('directo.canarias.nota', lang)}</text>
                {#if formas.canarias}
                    <path d={formas.canarias} fill={colorSistema(can) ?? 'url(#sse-sin-dato)'} class="stroke-gray-500 dark:stroke-gray-400" stroke-width="0.5" on:click={() => (seleccion = 'canarias')} role="presentation" style="cursor:pointer" />
                {/if}

                <!-- Flechas de intercambio -->
                {#each flechas as f (f.id)}
                    {#if f.d}
                        <path d={f.d} class={f.importa ? 'fill-sky-600 dark:fill-sky-400' : 'fill-rose-600 dark:fill-rose-400'} stroke="white" stroke-width="0.8" opacity="0.95" />
                    {:else}
                        <circle cx={f.x} cy={f.y} r="3.5" class="fill-gray-400" />
                    {/if}
                    <text
                        x={f.tx}
                        y={f.etq === 'abajo' ? f.ty + 8 : f.etq === 'arriba' ? f.ty - 2 : f.ty + 4}
                        text-anchor={f.etq === 'izquierda' ? 'end' : 'middle'}
                        font-size="12"
                        font-weight="700"
                        class="fill-gray-900 dark:fill-gray-100 stroke-white dark:stroke-gray-900"
                        paint-order="stroke"
                        stroke-width="3"
                       
                    >{f.mw === null ? '—' : `${fmt(Math.abs(f.mw), 0)} MW`}</text>
                    <text
                        x={f.tx}
                        y={f.etq === 'abajo' ? f.ty + 21 : f.etq === 'arriba' ? f.ty - 15 : f.ty + 17}
                        text-anchor={f.etq === 'izquierda' ? 'end' : 'middle'}
                        font-size="10"
                        class="fill-gray-600 dark:fill-gray-400"
                    >{nomPais(f.cod)}{f.mw === null || Math.abs(f.mw) < 1 ? '' : f.importa ? ` → ${t('directo.espana', lang)}` : ` ← ${t('directo.espana', lang)}`}</text>
                {/each}

                <!-- Enlace Península–Baleares -->
                {#if flechaBaleares}
                    <path d={flechaBaleares} class="fill-violet-600 dark:fill-violet-400" stroke="white" stroke-width="0.8" opacity="0.95" />
                {/if}
                <text x={(EA.x + EB.x) / 2} y={EA.y - 12} text-anchor="middle" font-size="11" font-weight="700" class="fill-gray-900 dark:fill-gray-100 stroke-white dark:stroke-gray-900" paint-order="stroke" stroke-width="3" stroke-linejoin="round">
                    {enlace === null ? '—' : `${fmt(Math.abs(enlace), 0)} MW`}
                </text>

                <!-- Etiquetas de sistema -->
                {#each etiquetas as e (e.id)}
                    <g on:click={() => (seleccion = e.id)} role="presentation" style="cursor:pointer">
                        <rect x={e.x - 56} y={e.y - 2} width="112" height="46" rx="6" class="fill-white/90 dark:fill-gray-900/90 {seleccion === e.id ? 'stroke-teal-700 dark:stroke-teal-400' : 'stroke-gray-300 dark:stroke-gray-700'}" stroke-width={seleccion === e.id ? 2 : 1} />
                        <text x={e.x} y={e.y + 12} text-anchor="middle" font-size="11.5" font-weight="700" class="fill-gray-900 dark:fill-gray-100">{nomSis(e.id)}</text>
                        <text x={e.x} y={e.y + 26} text-anchor="middle" font-size="10.5" class="fill-gray-700 dark:fill-gray-300">{e.u ? `${fmt(e.u.demanda_mw, 0)} MW` : t('directo.sinDatosMin', lang)}</text>
                        <text x={e.x} y={e.y + 39} text-anchor="middle" font-size="10.5" font-weight="600" class="fill-gray-700 dark:fill-gray-300">{valorModo(e.u, modoColor)}</text>
                    </g>
                {/each}
                {#each etiquetasCiudades as e (e.id)}
                    <g on:click={() => (seleccion = e.id)} role="presentation" style="cursor:pointer">
                        <text x={e.x + e.dx} y={e.y - 2} text-anchor={e.anchor} font-size="10.5" font-weight="700" class="{seleccion === e.id ? 'fill-teal-700 dark:fill-teal-400' : 'fill-gray-900 dark:fill-gray-100'} stroke-white dark:stroke-gray-900" paint-order="stroke" stroke-width="3">{nomSis(e.id)}</text>
                        <text x={e.x + e.dx} y={e.y + 10} text-anchor={e.anchor} font-size="9.5" class="fill-gray-700 dark:fill-gray-300 stroke-white dark:stroke-gray-900" paint-order="stroke" stroke-width="3">{e.u ? `${fmt(e.u.demanda_mw, 0)} MW · ${valorModo(e.u, modoColor)}` : t('directo.sinDatosMin', lang)}</text>
                    </g>
                {/each}
            </svg>

            <!-- Leyenda -->
            <div class="flex flex-wrap items-end justify-between gap-3 px-2 pb-1 text-xs text-gray-600 dark:text-gray-400">
                <div>
                    {#if modoColor === 'renovables'}
                        <p class="font-semibold mb-1">{t('directo.leyenda.ren', lang)}</p>
                        <div class="h-3 w-48 rounded" style="background:linear-gradient(90deg,{ESC_REN.join(',')})"></div>
                        <div class="flex justify-between w-48"><span>0 %</span><span>50 %</span><span>100 %</span></div>
                    {:else}
                        <p class="font-semibold mb-1">{t('directo.leyenda.co2', lang)}</p>
                        <div class="h-3 w-48 rounded" style="background:linear-gradient(90deg,{ESC_CO2.join(',')})"></div>
                        <div class="flex justify-between w-48"><span>0</span><span>400</span><span>800+</span></div>
                    {/if}
                </div>
                <div class="flex flex-col gap-0.5">
                    <span><span class="inline-block w-3 h-2 bg-sky-600 dark:bg-sky-400 mr-1"></span>{t('directo.importa', lang)}</span>
                    <span><span class="inline-block w-3 h-2 bg-rose-600 dark:bg-rose-400 mr-1"></span>{t('directo.exporta', lang)}</span>
                    <span><span class="inline-block w-3 h-2 bg-violet-600 dark:bg-violet-400 mr-1"></span>{t('directo.enlace', lang)}</span>
                </div>
            </div>
        </div>

        <!-- Tabla + precio -->
        <div class="lg:col-span-2 flex flex-col gap-4">
            <div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 overflow-hidden">
                <div class="overflow-x-auto"><table class="w-full text-sm whitespace-nowrap">
                    <caption class="sr-only">{t('directo.tabla.caption', lang)}</caption>
                    <thead class="bg-gray-50 dark:bg-gray-800/60 text-gray-600 dark:text-gray-300 text-xs uppercase tracking-wide">
                        <tr>
                            <th scope="col" class="text-left px-2 sm:px-3 py-2">{t('directo.sistema', lang)}</th>
                            <th scope="col" class="text-right px-2 py-2">{t('directo.demanda', lang)}</th>
                            <th scope="col" class="text-right px-2 py-2"><abbr title={t('directo.renovable', lang)} class="no-underline">{t('directo.renov', lang)}</abbr></th>
                            <th scope="col" class="text-right px-2 sm:px-3 py-2">gCO₂/kWh</th>
                        </tr>
                    </thead>
                    <tbody>
                        {#each SISTEMAS as s (s.id)}
                            {@const u = datos.sistemas[s.id]?.ultimo}
                            <tr
                                class="border-t border-gray-100 dark:border-gray-800 cursor-pointer {s.id === 'nacional' ? 'border-b-2 border-b-gray-200 dark:border-b-gray-700' : ''} {seleccion === s.id ? 'bg-teal-50 dark:bg-teal-950/40' : 'hover:bg-gray-50 dark:hover:bg-gray-800/40'}"
                                on:click={() => (seleccion = s.id)}
                            >
                                <td class="px-2 sm:px-3 py-2 font-semibold text-gray-900 dark:text-gray-100">
                                    <span class="inline-block w-2.5 h-2.5 rounded-sm mr-1.5 align-middle" style="background:{colorSistema(u) ?? '#cbd5e1'}"></span>{nomSis(s.id)}
                                </td>
                                <td class="px-2 py-2 text-right tabular-nums text-gray-800 dark:text-gray-200">{u ? `${fmt(u.demanda_mw, 0)} MW` : '—'}</td>
                                <td class="px-2 py-2 text-right tabular-nums text-gray-800 dark:text-gray-200">{u ? `${fmt(u.pct_renovable, 1)} %` : '—'}</td>
                                <td class="px-2 sm:px-3 py-2 text-right tabular-nums text-gray-800 dark:text-gray-200">{u ? fmt(u.intensidad_gco2_kwh, 0) : '—'}</td>
                            </tr>
                        {/each}
                    </tbody>
                </table></div>
                <p class="px-2 sm:px-3 py-2 text-xs text-gray-500 dark:text-gray-400 border-t border-gray-100 dark:border-gray-800 mb-0">
                    {t('directo.pulsa', lang)}
                    {#if pen && num(pen.intercambio_neto) !== null}
                        {t('directo.saldo', lang)} <b>{num(pen.intercambio_neto) >= 0 ? t('directo.importaV', lang) : t('directo.exportaV', lang)} {fmt(Math.abs(num(pen.intercambio_neto)), 0)} MW</b>.
                    {/if}
                </p>
            </div>

            <div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4">
                <p class="text-xs uppercase tracking-wide text-gray-500 dark:text-gray-400 font-semibold mb-2">{t('directo.precio', lang)}</p>
                {#if datos.precios && (num(datos.precios.spot_eur_mwh) !== null || num(datos.precios.pvpc_eur_mwh) !== null)}
                    <div class="grid grid-cols-2 gap-3">
                        <div>
                            <p class="text-2xl font-bold text-gray-900 dark:text-white mb-0 tabular-nums">{fmt(datos.precios.spot_eur_mwh, 1)} <span class="text-sm font-normal text-gray-500 dark:text-gray-400">€/MWh</span></p>
                            <p class="text-xs text-gray-600 dark:text-gray-400 mb-0">{t('directo.omie', lang)}{#if datos.precios.spot_ts}{t('directo.cuarto', lang)} {hora(datos.precios.spot_ts)}{/if}</p>
                        </div>
                        <div>
                            <p class="text-2xl font-bold text-gray-900 dark:text-white mb-0 tabular-nums">{fmt(datos.precios.pvpc_eur_mwh, 1)} <span class="text-sm font-normal text-gray-500 dark:text-gray-400">€/MWh</span></p>
                            <p class="text-xs text-gray-600 dark:text-gray-400 mb-0">{t('directo.pvpc', lang)}{#if datos.precios.pvpc_ts}{t('directo.horaDe', lang)} {hora(datos.precios.pvpc_ts)}{/if}</p>
                        </div>
                    </div>
                    <p class="text-xs text-gray-500 dark:text-gray-400 mt-2 mb-0">{t('directo.precioUnico', lang)}</p>
                {:else}
                    <p class="text-sm text-gray-600 dark:text-gray-400 mb-0">{t('directo.soloDirecto', lang)} <a class="underline" href="https://www.omie.es/" target="_blank" rel="noopener noreferrer">OMIE<span class="sr-only"> {t('nueva.pestana', lang)}</span></a>.</p>
                {/if}
            </div>

            <!-- Mix del sistema seleccionado (último dato o punto señalado) -->
            <div class="rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-4">
                <p class="text-xs uppercase tracking-wide text-gray-500 dark:text-gray-400 font-semibold mb-2">
                    {t('directo.mixDe', lang)} {nomSis(seleccion)} · {filaMix ? hora(iso(filaMix.ts_utc)) : '—'}
                </p>
                {#each mixAhora.slice(0, 8) as t (t.k)}
                    <div class="flex items-center gap-2 text-xs mb-1">
                        <span class="w-32 truncate text-gray-700 dark:text-gray-300">{nomTec(t.k)}</span>
                        <span class="flex-1 h-2.5 rounded bg-gray-100 dark:bg-gray-800 overflow-hidden"><span class="block h-full" style="width:{((t.v / totalMix) * 100).toFixed(1)}%;background:{t.c}"></span></span>
                        <span class="w-20 text-right tabular-nums text-gray-800 dark:text-gray-200">{fmt(t.v, 0)} MW</span>
                    </div>
                {:else}
                    <p class="text-sm text-gray-500 mb-0">{t('directo.sinDatosSistema', lang)}</p>
                {/each}
            </div>
        </div>
    </div>

    <!-- Gráfico apilado de 24 h -->
    <div class="mt-4 rounded-xl border border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 p-3">
        <div class="flex flex-wrap items-center justify-between gap-2 mb-1">
            <p class="font-semibold text-gray-900 dark:text-white text-sm mb-0">{t('directo.gen24', lang)} · {nomSis(seleccion)} (MW)</p>
            <div class="inline-flex flex-wrap rounded-md border border-gray-300 dark:border-gray-700 overflow-hidden text-xs" role="group" aria-label={t('directo.sistemaElectrico', lang)}>
                {#each SISTEMAS as s (s.id)}
                    <button type="button" aria-pressed={seleccion === s.id} class="min-h-6 px-2.5 py-1 {seleccion === s.id ? 'bg-teal-800 text-white' : 'bg-white dark:bg-gray-900 text-gray-700 dark:text-gray-300'}" on:click={() => (seleccion = s.id)}>{nomSis(s.id)}</button>
                {/each}
            </div>
        </div>
        {#if serie.length > 1}
            <svg viewBox="0 0 {GW} {GH}" class="w-full h-auto" role="img" aria-label={t('directo.gen24.aria', lang)} on:mousemove={moverRaton} on:mouseleave={() => (hoverIdx = null)}>
                {#each ticksY as v}
                    <line x1={GM.l} x2={GW - GM.r} y1={gy(v)} y2={gy(v)} class="stroke-gray-200 dark:stroke-gray-800" stroke-width="1" />
                    <text x={GM.l - 6} y={gy(v) + 3.5} text-anchor="end" font-size="10" class="fill-gray-500 dark:fill-gray-400">{fmt(v, 0)}</text>
                {/each}
                {#each capas as c (c.k)}
                    <path d={c.d} fill={c.c} opacity="0.9" />
                {/each}
                <path d={lineaDemanda} fill="none" class="stroke-gray-900 dark:stroke-white" stroke-width="1.5" stroke-dasharray="4 3" />
                {#each ticksX as t}
                    <text x={gx(t)} y={GH - 6} text-anchor="middle" font-size="10" class="fill-gray-500 dark:fill-gray-400">{hora(t)}</text>
                {/each}
                {#if puntoHover}
                    <line x1={gx(puntoHover.ts_utc)} x2={gx(puntoHover.ts_utc)} y1={GM.t} y2={GH - GM.b} class="stroke-gray-700 dark:stroke-gray-300" stroke-width="1" />
                    <text x={Math.min(GW - 120, gx(puntoHover.ts_utc) + 6)} y={GM.t + 12} font-size="10.5" font-weight="600" class="fill-gray-900 dark:fill-gray-100 stroke-white dark:stroke-gray-900" paint-order="stroke" stroke-width="3" stroke-linejoin="round">
                        {hora(puntoHover.ts_utc)} · {t('directo.demandaMin', lang)} {fmt(puntoHover.demanda_mw, 0)} MW · {fmt(puntoHover.pct_renovable, 0)} % {t('directo.renovAbr', lang)}
                    </text>
                {/if}
            </svg>
            <div class="flex flex-wrap gap-x-3 gap-y-1 text-xs text-gray-600 dark:text-gray-400 mt-1">
                {#each [...tecnologiasVisibles].reverse() as t (t.k)}
                    <span class="inline-flex items-center"><span class="inline-block w-3 h-3 rounded-sm mr-1" style="background:{t.c}"></span>{nomTec(t.k)}</span>
                {/each}
                <span class="inline-flex items-center"><span class="inline-block w-4 border-t-2 border-dashed border-gray-900 dark:border-white mr-1"></span>{t('directo.demanda', lang)}</span>
            </div>
        {:else}
            <p class="text-sm text-gray-500 dark:text-gray-400 my-6 text-center">{t('directo.sinSerie', lang)}</p>
        {/if}
    </div>

    <p class="text-xs text-gray-500 dark:text-gray-400 mt-2 mb-0">
        {t('directo.fuente', lang)}
        {#if datos.modo === 'directo'}{t('directo.seActualiza', lang)}{:else if workerUrl && errorDirecto}{t('directo.error.pre', lang)} ({errorDirecto}){t('directo.error.post', lang)}{/if}
    </p>
</div>

