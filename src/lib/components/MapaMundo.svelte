<script>
    // Mapa de coropletas de países en SVG (mundo o Europa), sin teselas ni librerías de mapas.
    // Fronteras de GISCO (Eurostat) simplificadas por tools/geo/paises_mundo.py en
    // static/geo/mundo.json y static/geo/europa.json, con el nombre de cada país en los cinco
    // idiomas. Proyecciones: Equal Earth para el mundo (áreas reales) y Lambert azimutal
    // equivalente centrada en Europa (la de los mapas de Eurostat).
    //
    // Colores por quintiles de los países con dato (los agregados no cuentan), para que unos
    // pocos extremos no dejen a todos los demás del mismo color. España va con borde grueso.
    // Los países demasiado pequeños para verse (Malta, Luxemburgo...) llevan un círculo.
    //
    // Uso:
    //   <MapaMundo data={filas} vista="europa" decimales={1} unidad="% de la población activa" sentido="negativo" />
    // con filas { cod_pais, pais, valor } (y opcionalmente anio, que sale en el tooltip).
    //
    // Modo puntos (ciudades): <MapaMundo puntos data={filas} id="cod_ciudad" ... /> con filas
    // { cod_ciudad, ciudad, lat, lon, valor, poblacion?, es_espana? }: cada fila es un círculo del
    // color de su quintil, con área proporcional a la población; los países van en gris, las
    // ciudades españolas con borde oscuro y la de `destacar`, más gruesa.
    import { page } from '$app/stores';
    import { IDIOMAS, idiomaDeRuta } from '../i18n.js';

    export let data = [];
    export let vista = 'mundo'; // 'mundo' | 'europa' | 'espana' (Península, Baleares y Canarias)
    export let id = 'cod_pais';
    export let value = 'valor';
    export let decimales = 1;
    export let unidad = '';
    /** 'positivo' (más es mejor), 'negativo' (más es peor) o 'neutro': solo cambia la paleta */
    export let sentido = 'neutro';
    export let destacar = 'ES';
    export let title = undefined;
    export let height = 460;
    export let puntos = false;
    /** columna con el nombre de cada punto (modo puntos) */
    export let nombre = 'ciudad';
    /** columna que da el tamaño de los puntos (modo puntos) */
    export let size = 'poblacion';

    $: lang = idiomaDeRuta($page.url.pathname);
    const TEXTOS = {
        es: { sin: 'Sin datos', aria: 'Mapa de países', error: 'No se pudo cargar el mapa.' },
        en: { sin: 'No data', aria: 'Map of countries', error: 'The map could not be loaded.' },
        ca: { sin: 'Sense dades', aria: 'Mapa de països', error: 'No s’ha pogut carregar el mapa.' },
        gl: { sin: 'Sen datos', aria: 'Mapa de países', error: 'Non se puido cargar o mapa.' },
        eu: { sin: 'Daturik ez', aria: 'Herrialdeen mapa', error: 'Ezin izan da mapa kargatu.' },
    };
    $: tx = TEXTOS[lang] ?? TEXTOS.es;

    // ------------------------------------------------------------------ geometría
    let geo = null;
    let error = false;
    let cargada = '';
    async function cargar(url) {
        if (url === cargada) return;
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
    $: if (typeof window !== 'undefined') cargar(vista === 'mundo' ? '/geo/mundo.json' : '/geo/europa.json');

    const RAD = Math.PI / 180;
    // Equal Earth (Šavrič, Patterson y Jenny, 2018)
    const A1 = 1.340264, A2 = -0.081106, A3 = 0.000893, A4 = 0.003796, MM = Math.sqrt(3) / 2;
    function equalEarth(lon, lat) {
        const l = lon * RAD, th = Math.asin(MM * Math.sin(lat * RAD));
        const t2 = th * th, t6 = t2 * t2 * t2;
        return [
            (2 * Math.sqrt(3) * l * Math.cos(th)) / (3 * (9 * A4 * t6 * t2 + 7 * A3 * t6 + 3 * A2 * t2 + A1)),
            -(A4 * t6 * t2 * th + A3 * t6 * th + A2 * t2 * th + A1 * th),
        ];
    }
    // Lambert azimutal equivalente centrada en 10° E, 52° N (como la ETRS89-LAEA de Eurostat)
    const L0 = 10 * RAD, F0 = 52 * RAD;
    function laea(lon, lat) {
        const l = lon * RAD - L0, f = lat * RAD;
        const k = Math.sqrt(2 / (1 + Math.sin(F0) * Math.sin(f) + Math.cos(F0) * Math.cos(f) * Math.cos(l)));
        return [k * Math.cos(f) * Math.sin(l), -k * (Math.cos(F0) * Math.sin(f) - Math.sin(F0) * Math.cos(f) * Math.cos(l))];
    }
    // Lo que se ve de Europa: de Islandia y Canarias a Chipre, el Cáucaso y el cabo Norte
    const VENTANA_ESPANA = [[-18.6, 27.3], [4.6, 44], [-9.6, 44], [4.6, 35.6]];
    const VENTANA_EUROPA = [[-24.5, 63.3], [-18.2, 27.6], [-10, 36], [35, 34.5], [44.8, 41], [44, 56], [30, 71.2], [-5, 59]];

    const ANCHO = 960;
    $: dibujo = (() => {
        if (!geo?.features) return null;
        const proy = vista === 'mundo' ? equalEarth : laea;
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
        const ampliar = ([x, y]) => { if (x < x0) x0 = x; if (y < y0) y0 = y; if (x > x1) x1 = x; if (y > y1) y1 = y; };
        const paises = geo.features.map((f) => ({
            id: f.properties.id,
            nombres: f.properties,
            anillos: f.geometry.coordinates.map((p) => p[0].map(([lon, lat]) => proy(lon, lat))),
        }));
        if (vista !== 'mundo') (vista === 'espana' ? VENTANA_ESPANA : VENTANA_EUROPA).forEach(([lon, lat]) => ampliar(proy(lon, lat)));
        else paises.forEach((p) => p.anillos.forEach((a) => a.forEach(ampliar)));
        const esc = ANCHO / (x1 - x0);
        const alto = Math.round((y1 - y0) * esc);
        const formas = paises.map((p) => {
            let bx0 = Infinity, by0 = Infinity, bx1 = -Infinity, by1 = -Infinity, sx = 0, sy = 0, n = 0;
            const d = p.anillos
                .map((a) =>
                    a.map(([x, y], i) => {
                        const px = (x - x0) * esc, py = (y - y0) * esc;
                        if (px < bx0) bx0 = px; if (py < by0) by0 = py; if (px > bx1) bx1 = px; if (py > by1) by1 = py;
                        sx += px; sy += py; n++;
                        return `${i ? 'L' : 'M'}${px.toFixed(1)},${py.toFixed(1)}`;
                    }).join('') + 'Z'
                )
                .join('');
            const visible = bx1 > 0 && by1 > 0 && bx0 < ANCHO && by0 < alto;
            const diminuto = visible && Math.max(bx1 - bx0, by1 - by0) < 7;
            return { id: p.id, nombres: p.nombres, d, visible, diminuto, cx: sx / n, cy: sy / n };
        }).filter((f) => f.visible);
        const pr = (lon, lat) => { const [x, y] = proy(lon, lat); return [(x - x0) * esc, (y - y0) * esc]; };
        return { formas, alto, pr };
    })();

    // ------------------------------------------------------------------ datos y colores
    const ok = (v) => v !== null && v !== undefined && v !== '' && Number.isFinite(Number(v));
    $: filas = Array.from(data ?? []);
    $: porId = new Map(filas.filter((r) => ok(r?.[value])).map((r) => [String(r[id]), r]));
    $: valores = filas.filter((r) => ok(r?.[value]) && !r.es_agregado && (puntos || String(r[id]).length === 2)).map((r) => Number(r[value])).sort((a, b) => a - b);
    // cortes de los quintiles
    $: cortes = valores.length >= 5 ? [0.2, 0.4, 0.6, 0.8].map((q) => valores[Math.floor(q * (valores.length - 1))]) : [];
    // azules (más alto = más oscuro); en los indicadores con sentido, verde = mejor y rojo = peor
    const AZUL = ['#dbeafe', '#93c5fd', '#3b82f6', '#1d4ed8', '#1e3a8a'];
    const MEJOR_ARRIBA = ['#b91c1c', '#f59e0b', '#fde68a', '#86efac', '#15803d'];
    $: paleta = sentido === 'positivo' ? MEJOR_ARRIBA : sentido === 'negativo' ? [...MEJOR_ARRIBA].reverse() : AZUL;
    function clase(v) {
        if (!cortes.length) return 2;
        let i = 0;
        while (i < cortes.length && v > cortes[i]) i++;
        return i;
    }
    $: colorDe = (pid) => {
        if (puntos) return null;
        const r = porId.get(pid);
        return r ? paleta[clase(Number(r[value]))] : null;
    };

    $: locale = IDIOMAS[lang]?.locale ?? 'es-ES';
    $: num = (v) => Number(v).toLocaleString(locale, { minimumFractionDigits: decimales, maximumFractionDigits: decimales });
    const nombreDe = (f, l) => f?.nombres?.[l] ?? f?.nombres?.es ?? f?.id;

    // ------------------------------------------------------------------ interacción
    let activo = null;
    let pos = { x: 0, y: 0 };
    let caja_el;
    function mover(ev, f) {
        activo = f;
        const r = caja_el?.getBoundingClientRect();
        if (r) pos = { x: ev.clientX - r.left, y: ev.clientY - r.top };
    }
    function enfocar(ev, f) {
        activo = f;
        const mapa = caja_el?.getBoundingClientRect();
        const forma = ev.currentTarget?.getBoundingClientRect();
        if (mapa && forma) pos = { x: forma.left - mapa.left + forma.width / 2, y: forma.top - mapa.top + forma.height / 2 };
    }
    $: filaActiva = activo ? porId.get(activo.id) : null;
    // puesto como en internacional_resumen: 1 = el mejor (en los neutros, el más alto)
    $: puestoActivo = filaActiva && !filaActiva.es_agregado && (puntos || String(filaActiva[id]).length === 2)
        ? 1 + valores.filter((v) => (sentido === 'negativo' ? v < Number(filaActiva[value]) : v > Number(filaActiva[value]))).length
        : null;
    const etiqueta = (f, r) => `${nombreDe(f, lang)}: ${r ? num(r[value]) : ''}`;
    $: espana = puntos ? null : dibujo?.formas.find((f) => f.id === destacar);
    // círculos del modo puntos, los grandes debajo
    $: tamMax = Math.max(1, ...filas.map((r) => Number(r?.[size]) || 0));
    $: circulos = puntos && dibujo
        ? filas
              .filter((r) => ok(r?.lat) && ok(r?.lon) && ok(r?.[value]))
              .map((r) => {
                  const [x, y] = dibujo.pr(Number(r.lon), Number(r.lat));
                  const rad = 2 + Math.sqrt((Number(r[size]) || 0) / tamMax) * 11;
                  return { r, x, y, rad, color: paleta[clase(Number(r[value]))], f: { id: String(r[id]), nombres: { es: r[nombre] } } };
              })
              .filter((c) => c.x > 0 && c.y > 0 && c.x < ANCHO && c.y < dibujo.alto)
              .sort((a, b) => b.rad - a.rad)
        : [];
</script>

<figure class="my-6 not-prose">
    {#if title}<figcaption class="mb-2 text-sm font-semibold text-gray-800 dark:text-gray-200">{title}</figcaption>{/if}
    <div class="relative" bind:this={caja_el} data-mapa-mundo>
        {#if error}
            <p class="text-sm text-gray-500">{tx.error}</p>
        {:else if !dibujo}
            <div class="animate-pulse rounded-lg bg-gray-100 dark:bg-gray-800" style="height:{height}px"></div>
        {:else}
            <svg viewBox="0 0 {ANCHO} {dibujo.alto}" class="w-full h-auto" style="max-height:{height}px" role="group" aria-label={title ?? tx.aria} on:mouseleave={() => (activo = null)}>
                <defs>
                    <clipPath id="recorte-{vista}"><rect x="0" y="0" width={ANCHO} height={dibujo.alto} /></clipPath>
                </defs>
                <g clip-path="url(#recorte-{vista})">
                    {#each dibujo.formas as f (f.id)}
                        <path
                            d={f.d}
                            fill={colorDe(f.id) ?? 'currentColor'}
                            class="{colorDe(f.id) ? '' : 'text-gray-200 dark:text-gray-700'} stroke-white dark:stroke-gray-900 {activo?.id === f.id ? 'opacity-75' : ''}"
                            stroke-width="0.5"
                            role="button"
                            tabindex={porId.has(f.id) ? 0 : -1}
                            aria-label={etiqueta(f, porId.get(f.id))}
                            on:mousemove={(e) => !puntos && mover(e, f)}
                            on:focus={(e) => enfocar(e, f)}
                            on:blur={() => (activo = null)}
                            on:click={(e) => mover(e, f)}
                            on:keydown={(e) => (e.key === 'Enter' || e.key === ' ') && enfocar(e, f)}
                        />
                    {/each}
                    {#each dibujo.formas.filter((f) => f.diminuto && porId.has(f.id)) as f (f.id)}
                        <circle cx={f.cx.toFixed(1)} cy={f.cy.toFixed(1)} r="4" fill={colorDe(f.id)} class="stroke-gray-500 dark:stroke-gray-300" stroke-width="0.6"
                            role="button" tabindex="-1" aria-label={etiqueta(f, porId.get(f.id))}
                            on:mousemove={(e) => mover(e, f)} on:click={(e) => mover(e, f)} />
                    {/each}
                    {#each circulos as c (c.f.id)}
                        <circle cx={c.x.toFixed(1)} cy={c.y.toFixed(1)} r={c.rad.toFixed(1)} fill={c.color} fill-opacity="0.9"
                            class={c.f.id === destacar ? 'stroke-gray-900 dark:stroke-white' : c.r.es_espana ? 'stroke-gray-700 dark:stroke-gray-200' : 'stroke-white dark:stroke-gray-900'}
                            stroke-width={c.f.id === destacar ? 2.5 : c.r.es_espana ? 1 : 0.5}
                            role="button" tabindex="-1" aria-label="{c.r[nombre]}: {num(c.r[value])}"
                            on:mousemove={(e) => mover(e, c.f)} on:click={(e) => mover(e, c.f)} />
                    {/each}
                    {#if espana}
                        <path d={espana.d} fill="none" class="stroke-gray-900 dark:stroke-white pointer-events-none" stroke-width="1.6" />
                    {/if}
                </g>
            </svg>
            {#if activo}
                <div
                    class="pointer-events-none absolute z-10 rounded-md border border-gray-200 dark:border-gray-700 bg-white/95 dark:bg-gray-900/95 px-3 py-2 text-xs shadow-md text-gray-800 dark:text-gray-100"
                    style="left:{Math.max(0, Math.min(pos.x + 14, (caja_el?.clientWidth ?? 600) - 230))}px; top:{pos.y + 14}px; max-width:230px"
                >
                    <div class="font-semibold">{nombreDe(activo, lang)}</div>
                    {#if filaActiva}
                        <div>{num(filaActiva[value])} <span class="text-gray-500 dark:text-gray-400">{unidad}</span></div>
                        {#if filaActiva.anio}<div class="text-gray-500 dark:text-gray-400">{filaActiva.anio}{#if puestoActivo} · {puestoActivo}.º / {valores.length}{/if}</div>{/if}
                    {:else}
                        <div class="text-gray-500 dark:text-gray-400">{tx.sin}</div>
                    {/if}
                </div>
            {/if}
            <div class="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-gray-600 dark:text-gray-400">
                {#if cortes.length}
                    {#each paleta as c, i}
                        <span class="inline-flex items-center gap-1">
                            <span class="inline-block h-3 w-3 rounded-sm" style="background:{c}"></span>
                            {i === 0 ? `< ${num(cortes[0])}` : i === paleta.length - 1 ? `> ${num(cortes[i - 1])}` : `${num(cortes[i - 1])} – ${num(cortes[i])}`}
                        </span>
                    {/each}
                {/if}
                <span class="inline-flex items-center gap-1"><span class="inline-block h-3 w-3 rounded-sm bg-gray-200 dark:bg-gray-700"></span>{tx.sin}</span>
                {#if unidad}<span class="text-gray-500">· {unidad}</span>{/if}
            </div>
        {/if}
    </div>
</figure>
