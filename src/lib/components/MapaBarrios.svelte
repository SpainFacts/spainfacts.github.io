<script>
    // Mapa de un municipio por secciones censales sobre el callejero gris del IGN (Leaflet),
    // para la sección «Barrio a barrio» de la ficha de municipio. Las secciones van
    // semitransparentes para que se lean las calles y los nombres de debajo; se puede
    // ampliar y mover (la rueda solo hace zoom con Ctrl, para no atrapar el scroll).
    //
    // Mismas props que MapaEspana para estos mapas: data, geoJsonUrl, geoId, areaCol, value,
    // valueFmt, colorPalette, min, max, legendType ('categorical'), colorCol, intensidad,
    // intensidadRango, tooltip (con prefixCol), height y title.
    import { onMount, onDestroy } from 'svelte';
    import { page } from '$app/stores';
    import { fmt } from '@evidence-dev/component-utilities/formatting';
    import { idiomaDeRuta, t } from '../i18n.js';
    import 'leaflet/dist/leaflet.css';

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
    export let colorCol = undefined;
    export let intensidad = undefined;
    export let intensidadRango = [25, 60];
    export let tooltip = undefined;
    export let height = 520;
    export let title = undefined;
    // Modo puntos (mapa de puntos de suelos): cada fila es una celda con lat/long, dibujada como un
    // círculo de su tamaño real (0,45 × celdaKm de radio) sobre el callejero. El GeoJSON solo da el
    // contorno del municipio (filtroGeo elige sus polígonos, p. ej. {cod_mun: '41039'})
    export let lat = undefined;
    export let long = undefined;
    export let celdaKm = 1;
    export let filtroGeo = undefined;

    $: lang = idiomaDeRuta($page.url.pathname);
    const SIN_DATO = { es: 'Sin datos', en: 'No data', ca: 'Sense dades', gl: 'Sen datos', eu: 'Daturik ez' };
    const PISTA = {
        es: 'Ctrl + rueda para ampliar · arrastra para moverte',
        en: 'Ctrl + wheel to zoom · drag to move',
        ca: 'Ctrl + roda per ampliar · arrossega per moure’t',
        gl: 'Ctrl + roda para ampliar · arrastra para moverte',
        eu: 'Ktrl + gurpila handitzeko · arrastatu mugitzeko'
    };

    // ------------------------------------------------------------------ colores (como MapaEspana)
    $: modoPuntos = !!(lat && long);
    $: filas = Array.from(data ?? []);
    $: porId = new Map(filas.map((r) => [String(r?.[areaCol] ?? ''), r]));
    $: categorico = legendType === 'categorical';
    $: categorias = categorico ? [...new Set(filas.map((r) => r?.[value]).filter((v) => v !== null && v !== undefined))] : [];
    const ok = (v) => v !== null && v !== undefined && Number.isFinite(v);
    $: numeros = categorico ? [] : filas.map((r) => Number(r?.[value])).filter(ok);
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
    function interp(tt) {
        if (paleta.length === 0) return '#3b82f6';
        if (paleta.length === 1) return paleta[0];
        const x = Math.min(1, Math.max(0, tt)) * (paleta.length - 1);
        const i = Math.min(paleta.length - 2, Math.floor(x));
        const a = hex(paleta[i]), b = hex(paleta[i + 1]), f = x - i;
        return '#' + a.map((v, j) => Math.round(v + (b[j] - v) * f).toString(16).padStart(2, '0')).join('');
    }
    $: colorCategoria = (c, i) => (colorCol && filas.find((r) => r?.[value] === c)?.[colorCol]) || (paleta[i % Math.max(1, paleta.length)] ?? '#94a3b8');
    $: colorFila = (r) => {
        if (!r) return null;
        const v = r[value];
        if (categorico) {
            if (colorCol && r[colorCol]) return r[colorCol];
            const i = categorias.indexOf(v);
            return i < 0 ? null : colorCategoria(v, i);
        }
        const n = Number(v);
        if (v === null || v === undefined || !ok(n)) return null;
        return interp(vMax === vMin ? 0.5 : (n - vMin) / (vMax - vMin));
    };
    // Opacidad del relleno: fija, o graduada por `intensidad` (siempre algo transparente
    // para que se vea el callejero)
    $: opacidadFila = (r) => {
        if (!intensidad) return 0.62;
        const v = Number(r?.[intensidad]);
        if (!ok(v)) return 0.62;
        const [lo, hi] = intensidadRango;
        return 0.2 + 0.6 * Math.min(1, Math.max(0, (v - lo) / (hi - lo || 1)));
    };

    const formatear = (v, f) => {
        if (v === null || v === undefined || v === '') return '—';
        if (f) {
            try { return fmt(v, f); } catch (e) { /* formato desconocido */ }
        }
        if (typeof v === 'number') return v.toLocaleString(lang === 'en' ? 'en-GB' : 'es-ES', { maximumFractionDigits: 2 });
        return String(v);
    };
    const escapar = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]);
    function textoTooltip(r, id) {
        if (!r) return `<b>${escapar(id)}</b><br>${SIN_DATO[lang] ?? SIN_DATO.es}`;
        const lineas = tooltip ?? [{ id: areaCol, showColumnName: false, valueClass: 'font-semibold' }, { id: value, fmt: valueFmt }];
        return lineas
            .filter((l) => l.id)
            .map((l) => {
                const valor = escapar((l.prefixCol ? r[l.prefixCol] ?? '' : '') + formatear(r[l.id], l.fmt ?? (l.id === value ? valueFmt : undefined)));
                if (l.showColumnName === false) return `<b>${valor}</b>`;
                return `<span style="opacity:.7">${escapar(l.title ?? l.id)}:</span> ${valor}`;
            })
            .join('<br>');
    }

    // ------------------------------------------------------------------ Leaflet
    let caja;
    let L = null;
    let mapa = null;
    let capa = null;
    let geo = null;
    let cargada = '';
    let error = false;
    async function cargar(url) {
        // mientras cargan los datos la URL lleva «undefined»: se espera
        if (!url || url === cargada || url.includes('undefined')) return;
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
    $: if (typeof window !== 'undefined') cargar(geoJsonUrl);

    // Leaflet se carga aparte: si mientras tanto el componente se desmonta (cambio de capa o de
    // municipio), no hay contenedor y L.map fallaría con «Map container not found»
    let vivo = true;
    onMount(async () => {
        const modulo = (await import('leaflet')).default;
        if (!vivo || !caja?.isConnected) return;
        L = modulo;
        mapa = L.map(caja, { scrollWheelZoom: false, zoomSnap: 0.25, attributionControl: true });
        mapa.attributionControl.setPrefix(false);
        // Callejero gris del IGN (WMTS en la rejilla de Google/OSM: TileMatrix = z, TileCol = x, TileRow = y)
        L.tileLayer(
            'https://www.ign.es/wmts/ign-base?layer=IGNBase-gris&style=default&tilematrixset=GoogleMapsCompatible&Service=WMTS&Request=GetTile&Version=1.0.0&Format=image/jpeg&TileMatrix={z}&TileCol={x}&TileRow={y}',
            { maxZoom: 19, attribution: '© <a href="https://www.ign.es" target="_blank" rel="noopener">IGN</a> · INE', className: 'mapa-barrios-teselas' }
        ).addTo(mapa);
        // Ctrl + rueda amplía; la rueda sola sigue moviendo la página
        caja.addEventListener('wheel', (e) => {
            if (!e.ctrlKey) return;
            e.preventDefault();
            mapa.setZoomAround(mapa.mouseEventToContainerPoint(e), mapa.getZoom() + (e.deltaY < 0 ? 0.5 : -0.5));
        }, { passive: false });
    });
    onDestroy(() => {
        vivo = false;
        mapa?.remove();
        mapa = null;
    });

    // Al cambiar de municipio se encuadra de nuevo; al cambiar de capa solo se repinta
    let encuadrado = '';
    $: if (L && mapa && geo) dibujar(geo, porId, colorFila, opacidadFila, lang, filas, modoPuntos, filtroGeo, celdaKm);
    const cumple = (f) => !filtroGeo || Object.entries(filtroGeo).every(([k, v]) => String(f.properties?.[k] ?? '') === String(v));
    function dibujar(g) {
        if (capa) capa.remove();
        if (modoPuntos) return dibujarPuntos(g);
        // con cientos de secciones, bordes finos para que no laven el color
        const grosor = (g?.features?.length ?? 0) > 600 ? 0.3 : (g?.features?.length ?? 0) > 150 ? 0.5 : 0.9;
        capa = L.geoJSON(g, {
            style: (f) => {
                const r = porId.get(String(f.properties?.[geoId] ?? ''));
                const c = colorFila(r);
                return { color: '#ffffff', weight: grosor, fillColor: c ?? '#9ca3af', fillOpacity: c ? opacidadFila(r) : 0.15 };
            },
            onEachFeature: (f, l) => {
                const id = String(f.properties?.[geoId] ?? '');
                l.bindTooltip(() => textoTooltip(porId.get(id), id), { sticky: true, direction: 'top', className: 'mapa-barrios-tooltip' });
                l.on('mouseover', () => l.setStyle({ weight: 2.5, color: '#111827' }));
                l.on('mouseout', () => capa.resetStyle(l));
            }
        }).addTo(mapa);
        if (encuadrado !== cargada) {
            encuadrado = cargada;
            mapa.fitBounds(capa.getBounds(), { padding: [8, 8] });
        }
    }
    function dibujarPuntos(g) {
        const lienzo = L.canvas({ padding: 0.5 });
        capa = L.featureGroup();
        const contorno = L.geoJSON({ type: 'FeatureCollection', features: (g?.features ?? []).filter(cumple) }, {
            style: { color: '#111827', weight: 2, fill: false, opacity: 0.8 },
            interactive: false
        });
        contorno.addTo(capa);
        const centros = [];
        for (const r of filas) {
            const la = Number(r?.[lat]), lo = Number(r?.[long]);
            if (!ok(la) || !ok(lo)) continue;
            centros.push([la, lo]);
            const c = colorFila(r);
            // Sin borde y casi tocándose: con celdas pequeñas (250 m) el borde tapaba el color
            const p = L.circle([la, lo], {
                renderer: lienzo,
                radius: (Number(celdaKm) < 0.5 ? 0.55 : 0.45) * (Number(celdaKm) || 1) * 1000,
                stroke: false,
                color: '#111827',
                weight: 2,
                fillColor: c ?? '#9ca3af',
                fillOpacity: c ? 0.8 : 0.3
            });
            p.bindTooltip(() => textoTooltip(r, ''), { sticky: true, direction: 'top', className: 'mapa-barrios-tooltip' });
            p.on('mouseover', () => p.setStyle({ stroke: true }));
            p.on('mouseout', () => p.setStyle({ stroke: false }));
            p.addTo(capa);
        }
        capa.addTo(mapa);
        // Se encuadra al cambiar de municipio (contorno nuevo), no al cambiar de capa
        // (los círculos no tienen límites hasta que el mapa tiene vista: se usa el contorno o los centros)
        const clave = cargada + JSON.stringify(filtroGeo ?? {});
        const limites = contorno.getLayers().length ? contorno.getBounds() : L.latLngBounds(centros);
        if (encuadrado !== clave && limites.isValid()) {
            encuadrado = clave;
            encuadrar(limites);
        }
    }
    // Si el contenedor aún no tiene tamaño (se está pintando la página), Leaflet encuadraría con
    // el zoom máximo: se espera a que lo tenga
    function encuadrar(limites, intentos = 25) {
        if (!mapa) return;
        mapa.invalidateSize();
        const t = mapa.getSize();
        if ((!t.x || !t.y) && intentos > 0) return setTimeout(() => encuadrar(limites, intentos - 1), 200);
        mapa.fitBounds(limites, { padding: [8, 8] });
    }
</script>

<figure class="my-6 not-prose">
    {#if title}<figcaption class="mb-2 text-sm font-semibold text-gray-800 dark:text-gray-200">{title}</figcaption>{/if}
    {#if error}
        <p class="text-sm text-gray-500">{t('mapa.error', lang)}</p>
    {/if}
    <div bind:this={caja} class="mapa-barrios rounded-lg overflow-hidden border border-gray-200 dark:border-gray-800" style="height:{height}px" role="group" aria-label={title ?? t('mapa.aria', lang)}></div>
    <div class="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-600 dark:text-gray-400">
        {#if categorico}
            {#each categorias as c, i}
                <span class="inline-flex items-center gap-1"><span class="inline-block h-3 w-3 rounded-sm" style="background:{colorCategoria(c, i)}"></span>{c}</span>
            {/each}
        {:else if numeros.length}
            <span>{formatear(vMin, valueFmt)}</span>
            <span class="inline-block h-2.5 w-40 rounded-sm" style="background:linear-gradient(to right, {(paleta.length ? paleta : ['#eff6ff', '#1e3a8a']).join(', ')})"></span>
            <span>{formatear(vMax, valueFmt)}</span>
        {/if}
        {#if !modoPuntos}<span class="inline-flex items-center gap-1"><span class="inline-block h-3 w-3 rounded-sm bg-gray-300 dark:bg-gray-600"></span>{SIN_DATO[lang] ?? SIN_DATO.es}</span>{/if}
        <span class="ml-auto text-gray-400">{PISTA[lang] ?? PISTA.es}</span>
    </div>
</figure>

<style>
    .mapa-barrios {
        z-index: 0;
        background: #f3f4f6;
    }
    /* En modo oscuro el callejero se invierte para no deslumbrar */
    :global(html.theme-dark .mapa-barrios .mapa-barrios-teselas) {
        filter: invert(1) hue-rotate(180deg) brightness(0.85) contrast(0.9);
    }
    :global(html.theme-dark .mapa-barrios) {
        background: #111827;
    }
    :global(.mapa-barrios-tooltip) {
        font-size: 12px;
        line-height: 1.35;
    }
</style>
