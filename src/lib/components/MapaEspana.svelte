<script>
    // Mapa de coropletas de España en SVG, sin mapa base de teselas (las teselas de Esri pintaban
    // el Sáhara Occidental como parte de Marruecos). Canarias va en un recuadro abajo a la izquierda
    // y Ceuta y Melilla, ampliadas en sus propios recuadros. Si el GeoJSON es solo de una parte
    // (p. ej. los municipios de una comunidad), se ajusta a su extensión sin recuadros.
    //
    // Acepta las mismas props que el AreaMap de Evidence que sustituye (data, geoJsonUrl, geoId,
    // areaCol, value, valueFmt, colorPalette, min, max, legendType, tooltip, link, height, title);
    // basemap y attribution se aceptan y se ignoran.
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';
    import { page } from '$app/stores';
    import { fmt } from '@evidence-dev/component-utilities/formatting';
    import { idiomaDeRuta, enlace } from '../i18n.js';

    export let data = [];
    export let geoJsonUrl;
    export let geoId = 'id';
    export let areaCol;
    export let value;
    export let valueFmt = undefined;
    export let colorPalette = ['#eff6ff', '#3b82f6', '#1e3a8a'];
    export let min = undefined;
    export let max = undefined;
    export let legendType = undefined;
    export let tooltip = undefined;
    export let link = undefined;
    export let height = 440;
    export let title = undefined;
    // Modo puntos (sustituye a BubbleMap y PointMap): lat, long y, opcionalmente, size
    export let lat = undefined;
    export let long = undefined;
    export let size = undefined;
    export let sizeFmt = undefined;
    export let maxSize = 20;
    export let opacity = 0.8;
    export let pointName = undefined;
    export let basemap = undefined;
    export let attribution = undefined;
    $: basemap, attribution; // compatibilidad con AreaMap

    $: lang = idiomaDeRuta($page.url.pathname);
    const SIN_DATO = { es: 'Sin datos', en: 'No data', ca: 'Sense dades', gl: 'Sen datos', eu: 'Daturik ez' };

    // ------------------------------------------------------------------ geometría
    let geo = null;
    let error = false;
    let cargada = '';
    async function cargar(url) {
        if (!url || url === cargada) return;
        cargada = url;
        try {
            const r = await fetch(url);
            if (!r.ok) throw new Error(r.status);
            geo = await r.json();
            error = false;
        } catch (e) {
            error = true;
        }
    }
    $: modoPuntos = !!(lat && long);
    $: urlGeo = geoJsonUrl ?? (modoPuntos ? '/geo/ccaa.geojson' : undefined);
    onMount(() => cargar(urlGeo));
    $: if (typeof window !== 'undefined') cargar(urlGeo);

    const anillos = (g) => (g?.type === 'Polygon' ? [g.coordinates] : g?.type === 'MultiPolygon' ? g.coordinates : []);
    function caja(features) {
        let b = [Infinity, Infinity, -Infinity, -Infinity];
        for (const f of features)
            for (const p of anillos(f.geometry))
                for (const [lon, lat] of p[0]) {
                    if (lon < b[0]) b[0] = lon;
                    if (lat < b[1]) b[1] = lat;
                    if (lon > b[2]) b[2] = lon;
                    if (lat > b[3]) b[3] = lat;
                }
        return b;
    }
    // Zona de cada polígono según su centro: Canarias, Ceuta, Melilla o el resto
    function zona(p) {
        let lon = 0, la = 0;
        for (const c of p[0]) { lon += c[0]; la += c[1]; }
        return zonaPunto(lon / p[0].length, la / p[0].length);
    }
    function zonaPunto(lon, lat) {
        if (lat < 30) return 'canarias';
        if (lat < 36.05 && lat > 35.1 && lon > -5.5 && lon < -5.2) return 'ceuta';
        if (lat < 35.5 && lat > 35.1 && lon > -3.1 && lon < -2.8) return 'melilla';
        return 'principal';
    }

    const ANCHO = 760;
    const M = 4; // margen
    $: idDe = (f) => String(f.properties?.[geoId] ?? f.id ?? '');

    // Reparte los polígonos por zona; si solo hay una zona, todo es «principal»
    $: piezas = (() => {
        if (!geo?.features) return [];
        const out = [];
        for (const f of geo.features) for (const p of anillos(f.geometry)) out.push({ id: idDe(f), p, z: zona(p) });
        const hayPrincipal = out.some((o) => o.z === 'principal');
        if (!hayPrincipal) out.forEach((o) => (o.z = 'principal'));
        return out;
    })();

    function proyeccion(polys, x0, y0, w, h) {
        const b = caja(polys.map((p) => ({ geometry: { type: 'Polygon', coordinates: p } })));
        const cos = Math.cos((((b[1] + b[3]) / 2) * Math.PI) / 180);
        const esc = Math.min(w / ((b[2] - b[0]) * cos || 1), h / (b[3] - b[1] || 1));
        const ow = (w - (b[2] - b[0]) * cos * esc) / 2, oh = (h - (b[3] - b[1]) * esc) / 2;
        return { esc, cos, fx: (lon) => x0 + ow + (lon - b[0]) * cos * esc, fy: (lat) => y0 + oh + (b[3] - lat) * esc };
    }
    const camino = (p, pr) => p.map((a) => a.map(([lon, lat], i) => `${i ? 'L' : 'M'}${pr.fx(lon).toFixed(1)},${pr.fy(lat).toFixed(1)}`).join('') + 'Z').join('');

    $: dibujo = (() => {
        if (!piezas.length) return null;
        const prin = piezas.filter((o) => o.z === 'principal');
        const b = caja(prin.map((o) => ({ geometry: { type: 'Polygon', coordinates: o.p } })));
        const cos = Math.cos((((b[1] + b[3]) / 2) * Math.PI) / 180);
        const w = ANCHO - 2 * M;
        const altoPrin = Math.round(((b[3] - b[1]) / ((b[2] - b[0]) * cos)) * w);
        const pr = proyeccion(prin.map((o) => o.p), M, M, w, altoPrin);
        const formas = prin.map((o) => ({ id: o.id, d: camino(o.p, pr) }));
        const recuadros = [];
        const proy = { principal: pr };
        let alto = altoPrin + 2 * M;
        const can = piezas.filter((o) => o.z === 'canarias');
        const ceu = piezas.filter((o) => o.z === 'ceuta');
        const mel = piezas.filter((o) => o.z === 'melilla');
        if (can.length || ceu.length || mel.length) {
            const y0 = altoPrin + 2 * M + 6;
            let altoFila = 0;
            if (can.length) {
                // Canarias a ~80 % de la escala de la Península
                const bc = caja(can.map((o) => ({ geometry: { type: 'Polygon', coordinates: o.p } })));
                const cc = Math.cos((28.5 * Math.PI) / 180);
                const cw = (bc[2] - bc[0]) * cc * pr.esc * 0.8 + 12, ch = (bc[3] - bc[1]) * pr.esc * 0.8 + 12;
                const prc = proyeccion(can.map((o) => o.p), M + 6, y0 + 6, cw - 12, ch - 12);
                proy.canarias = prc;
                recuadros.push({ nombre: 'Canarias', x: M, y: y0, w: cw, h: ch, formas: can.map((o) => ({ id: o.id, d: camino(o.p, prc) })) });
                altoFila = ch;
            }
            // Ceuta y Melilla, ampliadas en recuadros cuadrados bajo su posición real
            const lado = 64;
            for (const [nombre, grupo, lon] of [['Ceuta', ceu, -5.32], ['Melilla', mel, -2.94]]) {
                if (!grupo.length) continue;
                let x = Math.min(ANCHO - M - lado, Math.max(M, pr.fx(lon) - lado / 2));
                const ultimo = recuadros[recuadros.length - 1];
                if (ultimo && x < ultimo.x + ultimo.w + 8) x = ultimo.x + ultimo.w + 8;
                const prx = proyeccion(grupo.map((o) => o.p), x + 8, y0 + 14, lado - 16, lado - 20);
                proy[nombre.toLowerCase()] = prx;
                recuadros.push({ nombre, x, y: y0, w: lado, h: lado, formas: grupo.map((o) => ({ id: o.id, d: camino(o.p, prx) })) });
                altoFila = Math.max(altoFila, lado);
            }
            alto = y0 + altoFila + M;
        }
        return { formas, recuadros, alto, proy };
    })();

    // ------------------------------------------------------------------ datos y colores
    $: filas = Array.from(data ?? []);
    $: porId = modoPuntos ? new Map() : new Map(filas.map((r) => [String(r?.[areaCol] ?? ''), r]));
    $: categorico = legendType === 'categorical';
    $: categorias = categorico ? [...new Set(filas.map((r) => r?.[value]).filter((v) => v !== null && v !== undefined))] : [];
    $: numeros = categorico ? [] : filas.map((r) => Number(r?.[value])).filter((v) => r_ok(v));
    function r_ok(v) { return v !== null && v !== undefined && !Number.isNaN(v) && Number.isFinite(v); }
    $: vMin = min ?? (numeros.length ? Math.min(...numeros) : 0);
    $: vMax = max ?? (numeros.length ? Math.max(...numeros) : 1);
    $: paleta = (colorPalette ?? []).filter(Boolean);

    function hex(c) {
        const m = String(c).trim().match(/^#?([0-9a-f]{3}|[0-9a-f]{6})$/i);
        if (!m) return [148, 163, 184];
        let h = m[1];
        if (h.length === 3) h = h.split('').map((x) => x + x).join('');
        return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16));
    }
    function interp(t) {
        if (paleta.length === 0) return '#3b82f6';
        if (paleta.length === 1) return paleta[0];
        const x = Math.min(1, Math.max(0, t)) * (paleta.length - 1);
        const i = Math.min(paleta.length - 2, Math.floor(x));
        const a = hex(paleta[i]), b = hex(paleta[i + 1]), f = x - i;
        return '#' + a.map((v, j) => Math.round(v + (b[j] - v) * f).toString(16).padStart(2, '0')).join('');
    }
    function colorDe(id) {
        return colorFila(porId.get(id));
    }
    function colorFila(r) {
        if (!r) return null;
        if (!value) return paleta[0] ?? '#3b82f6';
        const v = r[value];
        if (categorico) {
            const i = categorias.indexOf(v);
            return i < 0 ? null : paleta[i % Math.max(1, paleta.length)] ?? '#94a3b8';
        }
        const n = Number(v);
        if (v === null || v === undefined || !r_ok(n)) return null;
        return interp(vMax === vMin ? 0.5 : (n - vMin) / (vMax - vMin));
    }
    let colores = new Map();
    $: { porId, vMin, vMax, paleta, categorias; colores = dibujo ? new Map([...dibujo.formas, ...dibujo.recuadros.flatMap((r) => r.formas)].map((f) => [f.id, colorDe(f.id)])) : new Map(); }

    // Puntos proyectados en la zona (Península, Canarias, Ceuta o Melilla) en la que caen
    $: tamMax = size ? Math.max(1e-9, ...filas.map((r) => Math.abs(Number(r?.[size])) || 0)) : 1;
    $: puntos = modoPuntos && dibujo
        ? filas
              .map((r, i) => {
                  const lo = Number(r?.[long]), la = Number(r?.[lat]);
                  if (!r_ok(lo) || !r_ok(la)) return null;
                  const pr = dibujo.proy[zonaPunto(lo, la)] ?? dibujo.proy.principal;
                  const rad = size ? Math.max(1.5, Math.sqrt((Math.abs(Number(r[size])) || 0) / tamMax) * (maxSize / 2)) : 3;
                  return { i, x: pr.fx(lo), y: pr.fy(la), r: rad, c: colorFila(r) ?? '#94a3b8' };
              })
              .filter(Boolean)
              .sort((a, b) => b.r - a.r)
        : [];
    let puntoActivo = null;

    const formatear = (v, f) => {
        if (v === null || v === undefined || v === '') return '—';
        if (f) {
            try { return fmt(v, f); } catch (e) { /* formato desconocido */ }
        }
        if (typeof v === 'number') return v.toLocaleString(lang === 'en' ? 'en-GB' : 'es-ES', { maximumFractionDigits: 2 });
        return String(v);
    };

    // ------------------------------------------------------------------ interacción
    let activo = null;
    let pos = { x: 0, y: 0 };
    let caja_el;
    function mover(ev, id) {
        activo = id;
        const r = caja_el?.getBoundingClientRect();
        if (r) pos = { x: ev.clientX - r.left, y: ev.clientY - r.top };
    }
    $: filaActiva = puntoActivo !== null ? filas[puntoActivo] : activo !== null ? porId.get(activo) : null;
    $: lineas = filaActiva
        ? (tooltip ?? [{ id: modoPuntos ? pointName : areaCol, showColumnName: false, valueClass: 'font-semibold' }, { id: value, fmt: valueFmt }, ...(size ? [{ id: size, fmt: sizeFmt }] : [])]).filter((t) => t.id).map((t) => ({
              titulo: t.showColumnName === false ? null : t.title ?? t.id,
              valor: formatear(filaActiva[t.id], t.fmt ?? (t.id === value ? valueFmt : undefined)),
              clase: t.valueClass ?? '',
          }))
        : [];
    function pulsar(id) {
        if (!link) return;
        const r = porId.get(id);
        const href = r?.[link];
        if (href) goto(enlace(href, lang));
    }
</script>

<figure class="my-6 not-prose">
    {#if title}<figcaption class="mb-2 text-sm font-semibold text-gray-800 dark:text-gray-200">{title}</figcaption>{/if}
    <div class="relative" bind:this={caja_el} data-mapa-espana>
        {#if error}
            <p class="text-sm text-gray-500">No se pudo cargar el mapa.</p>
        {:else if !dibujo}
            <div class="animate-pulse rounded-lg bg-gray-100 dark:bg-gray-800" style="height:{height}px"></div>
        {:else}
            <svg viewBox="0 0 {ANCHO} {dibujo.alto}" class="w-full h-auto" style="max-height:{Math.max(height, 280)}px" role="img" aria-label={title ?? 'Mapa'} on:mouseleave={() => { activo = null; puntoActivo = null; }}>
                {#each dibujo.formas as f (f.id + f.d.length)}
                    <path
                        d={f.d}
                        fill={colores.get(f.id) ?? 'currentColor'}
                        class="{colores.get(f.id) ? '' : 'text-gray-200 dark:text-gray-700'} stroke-white dark:stroke-gray-900 {activo === f.id ? 'opacity-80' : ''}"
                        stroke-width="0.6"
                        style={link && porId.get(f.id)?.[link] ? 'cursor:pointer' : ''}
                        role="presentation"
                        on:mousemove={(e) => mover(e, f.id)}
                        on:click={() => pulsar(f.id)}
                    />
                {/each}
                {#each dibujo.recuadros as r}
                    <rect x={r.x} y={r.y} width={r.w} height={r.h} rx="4" fill="none" class="stroke-gray-300 dark:stroke-gray-600" stroke-width="1" />
                    <text x={r.x + 5} y={r.y + 11} class="fill-gray-500 dark:fill-gray-400" font-size="10">{r.nombre}</text>
                    {#each r.formas as f}
                        <path
                            d={f.d}
                            fill={colores.get(f.id) ?? 'currentColor'}
                            class="{colores.get(f.id) ? '' : 'text-gray-200 dark:text-gray-700'} stroke-white dark:stroke-gray-900 {activo === f.id ? 'opacity-80' : ''}"
                            stroke-width="0.6"
                            style={link && porId.get(f.id)?.[link] ? 'cursor:pointer' : ''}
                            role="presentation"
                            on:mousemove={(e) => mover(e, f.id)}
                            on:click={() => pulsar(f.id)}
                        />
                    {/each}
                {/each}
                {#each puntos as pt (pt.i)}
                    <circle
                        cx={pt.x.toFixed(1)}
                        cy={pt.y.toFixed(1)}
                        r={pt.r.toFixed(1)}
                        fill={pt.c}
                        fill-opacity={opacity}
                        class="stroke-white dark:stroke-gray-900"
                        stroke-width="0.4"
                        role="presentation"
                        on:mousemove={(e) => { puntoActivo = pt.i; mover(e, null); }}
                        on:mouseleave={() => (puntoActivo = null)}
                    />
                {/each}
            </svg>
            {#if filaActiva}
                <div
                    class="pointer-events-none absolute z-10 rounded-md border border-gray-200 dark:border-gray-700 bg-white/95 dark:bg-gray-900/95 px-3 py-2 text-xs shadow-md text-gray-800 dark:text-gray-100"
                    style="left:{Math.min(pos.x + 14, (caja_el?.clientWidth ?? 600) - 200)}px; top:{pos.y + 14}px; max-width:240px"
                >
                    {#each lineas as l}
                        <div class={l.clase}>{#if l.titulo}<span class="text-gray-500 dark:text-gray-400">{l.titulo}:</span> {/if}{l.valor}</div>
                    {/each}
                </div>
            {/if}
            <div class="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-600 dark:text-gray-400">
                {#if categorico}
                    {#each categorias as c, i}
                        <span class="inline-flex items-center gap-1"><span class="inline-block h-3 w-3 rounded-sm" style="background:{paleta[i % Math.max(1, paleta.length)] ?? '#94a3b8'}"></span>{c}</span>
                    {/each}
                {:else if numeros.length}
                    <span>{formatear(vMin, valueFmt)}</span>
                    <span class="inline-block h-2.5 w-40 rounded-sm" style="background:linear-gradient(to right, {(paleta.length ? paleta : ['#eff6ff', '#1e3a8a']).join(', ')})"></span>
                    <span>{formatear(vMax, valueFmt)}</span>
                {/if}
                {#if !modoPuntos}<span class="inline-flex items-center gap-1"><span class="inline-block h-3 w-3 rounded-sm bg-gray-200 dark:bg-gray-700"></span>{SIN_DATO[lang] ?? SIN_DATO.es}</span>{/if}
            </div>
        {/if}
    </div>
</figure>
