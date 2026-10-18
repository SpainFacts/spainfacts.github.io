<script>
    // Catálogo de /fuentes: buscador, filtro por organismo y, por dataset, su ficha completa con el
    // linaje en GitHub (script de ingesta -> tablas raw -> modelos dbt -> consultas -> páginas).
    // Las etiquetas de fuente de los KPI enlazan aquí con ?fuente=<texto>; ?id=<fuente_id> abre un dataset.
    // El linaje sale de static/fuentes/linaje.json (python tools/fuentes/linaje.py).
    import { onMount, tick } from "svelte";
    import { page } from "$app/stores";
    import { idiomaDeRuta, enlace, t, tf } from "../i18n.js";
    $: lang = idiomaDeRuta($page.url.pathname);

    export let data = [];

    const GITHUB = "https://github.com/SpainFacts/spainfacts.github.io";
    const gh = (ruta) => `${GITHUB}/blob/main/${ruta}`;
    const MAX_LISTA = 8;
    const DBT = "--project-dir transform --profiles-dir transform";

    // Siglas y abreviaturas de las etiquetas de los KPI que en el catálogo aparecen con el nombre largo
    const ALIAS = {
        ree: ["red electrica"],
        esios: ["red electrica"],
        "atlas de renta": ["adrh"],
        etdp: ["transmisiones de derechos de la propiedad", "compraventas"],
        "comision de publicidad institucional": ["publicidad y comunicacion institucional"],
        boe: ["boletin oficial del estado"],
        bde: ["banco de espana"],
        aeat: ["agencia tributaria"],
        cpci: ["publicidad y comunicacion institucional"],
        placsp: ["plataforma de contratacion del sector publico"],
        bdns: ["base de datos nacional de subvenciones"],
        sermas: ["consejeria de sanidad"],
        "capitulo 1": ["por capitulo"],
        "colegios de aparejadores": ["visados de obra"],
    };

    const normalizar = (s) => String(s ?? "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").trim();
    const escapar = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const textoFila = (d) => normalizar(`${d.organismo} | ${d.nombre_dataset} | ${d.cod_oficial} | ${d.fuente_id}`);

    // «INE / EPA», «REE (ESIOS)», «SoilGrids · CORINE 2018» -> grupos de términos alternativos
    function terminos(texto) {
        return normalizar(texto)
            .replace(/\bmº\s*/g, "ministerio ")
            .split(/\s*(?:\/|·|,|;|–|—|\(|\)|\by\b|\be\b|\bcon datos de\b)\s*/)
            .map((p) => p.replace(/\b(19|20)\d{2}\b/g, "").trim())
            .filter((p) => p.length >= 2)
            .map((p) => [p, ...(ALIAS[p] ?? [])].map((x) => new RegExp(`(^|[^a-z0-9])${escapar(x)}([^a-z0-9]|$)`)));
    }

    // Datasets de una etiqueta de KPI: si alguno casa con varios términos («INE / EPA»), solo esos;
    // si no, todos, empezando por el término más específico («DGT / INE»: primero la DGT)
    function deEtiqueta(filas, etiqueta) {
        const grupos = terminos(etiqueta);
        const casa = filas.map((d) => grupos.map((g) => g.some((re) => re.test(textoFila(d)))));
        const veces = grupos.map((_, j) => casa.filter((c) => c[j]).length);
        const puntuadas = filas
            .map((d, i) => ({
                d,
                n: casa[i].filter(Boolean).length,
                rareza: Math.min(...veces.filter((_, j) => casa[i][j])),
            }))
            .filter((x) => x.n > 0);
        const maximo = Math.max(0, ...puntuadas.map((x) => x.n));
        return puntuadas
            .filter((x) => (maximo > 1 ? x.n === maximo : true))
            .sort((a, b) => a.rareza - b.rareza)
            .map((x) => x.d);
    }

    let etiqueta = ""; // ?fuente= (desde un KPI)
    let soloId = ""; // ?id= (enlace a un dataset)
    let busqueda = "";
    let organismo = "";
    let abiertos = new Set();
    let linaje = {};
    let copiado = "";
    let raiz;

    $: filas = Array.isArray(data) ? data : [];
    $: organismos = [...new Set(filas.map((d) => d.organismo))].sort((a, b) => a.localeCompare(b, "es"));
    $: base = soloId ? filas.filter((d) => d.fuente_id === soloId) : etiqueta ? deEtiqueta(filas, etiqueta) : filas;
    $: palabras = normalizar(busqueda).split(/\s+/).filter(Boolean);
    $: visibles = base.filter(
        (d) =>
            (!organismo || d.organismo === organismo) &&
            palabras.every((p) => `${textoFila(d)} | ${normalizar(d.metodologia)}`.includes(p))
    );

    function alternar(id, abierto) {
        abiertos = new Set(abiertos);
        abierto ? abiertos.add(id) : abiertos.delete(id);
    }

    function quitarEtiqueta() {
        etiqueta = "";
        soloId = "";
        abiertos = new Set();
        const url = new URL(window.location.href);
        url.searchParams.delete("fuente");
        url.searchParams.delete("id");
        history.replaceState(history.state, "", url);
    }

    async function copiarEnlace(id) {
        const url = new URL(window.location.href);
        url.search = `?id=${encodeURIComponent(id)}`;
        url.hash = "";
        try {
            await navigator.clipboard.writeText(url.toString());
            copiado = id;
            setTimeout(() => (copiado = ""), 2000);
        } catch {
            /* sin portapapeles: el enlace sigue en el botón */
        }
    }

    // Lo que pide la URL se aplica cuando llegan los datos (en Evidence pueden llegar después de montar)
    let pedido = null;
    // (la consulta puede dar ya su longitud con las filas aún vacías)
    $: if (pedido && filas.some((d) => d?.fuente_id)) aplicarPedido(pedido);

    async function aplicarPedido({ id }) {
        pedido = null;
        if (id) abiertos = new Set([id]);
        else abiertos = new Set(deEtiqueta(filas, etiqueta).slice(0, 6).map((d) => d.fuente_id));
        await tick();
        // Salto directo (el scroll suave se queda a medias mientras la página carga) y se repite
        // mientras lo de arriba (tarjetas, gráficos) termina de ocupar su sitio, salvo que el
        // lector ya se haya movido
        let movido = false;
        const parar = () => (movido = true);
        const eventos = ["wheel", "touchstart", "keydown", "mousedown"];
        eventos.forEach((e) => window.addEventListener(e, parar, { once: true, passive: true }));
        for (const espera of [0, 500, 1200, 2500]) {
            setTimeout(() => !movido && raiz?.scrollIntoView({ block: "start", behavior: "instant" }), espera);
        }
        setTimeout(() => eventos.forEach((e) => window.removeEventListener(e, parar)), 2600);
    }

    onMount(() => {
        const params = new URL(window.location.href).searchParams;
        etiqueta = params.get("fuente") ?? "";
        const id = params.get("id");
        soloId = id ?? "";
        if (id || etiqueta) pedido = { id };

        fetch("/fuentes/linaje.json")
            .then((r) => (r.ok ? r.json() : {}))
            .then((j) => (linaje = j))
            .catch(() => {});
    });
</script>

<section bind:this={raiz} id="catalogo-fuentes" class="my-4 scroll-mt-20">
    {#if etiqueta || soloId}
        <div class="mb-3 flex flex-wrap items-center justify-between gap-2 rounded-lg border border-blue-200 bg-blue-50/60 px-3 py-2 text-sm dark:border-blue-900/60 dark:bg-blue-950/30">
            <span class="text-gray-700 dark:text-gray-200">
                {#if soloId}<b>{base[0]?.nombre_dataset ?? soloId}</b>{:else}{t('fuente.desde', lang)}: <b>{etiqueta}</b>{/if}
                {#if !base.length}· {t('fuente.sinficha', lang)}{/if}
            </span>
            <button type="button" on:click={quitarEtiqueta} class="font-semibold text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300">
                {t('fuente.todas', lang)}
            </button>
        </div>
    {/if}

    <div class="flex flex-col gap-2 sm:flex-row">
        <label class="min-w-0 flex-1">
            <span class="sr-only">{t('fuente.buscar', lang)}</span>
            <input
                type="search"
                bind:value={busqueda}
                placeholder={t('fuente.buscar', lang)}
                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/40 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-100"
            />
        </label>
        <label class="sm:w-72">
            <span class="sr-only">{t('fuente.organismo', lang)}</span>
            <select
                bind:value={organismo}
                class="w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/40 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-100"
            >
                <option value="">{t('fuente.todos', lang)}</option>
                {#each organismos as o}
                    <option value={o}>{o}</option>
                {/each}
            </select>
        </label>
    </div>
    <p class="!my-2 text-xs text-gray-500 dark:text-gray-400" aria-live="polite">
        {tf('fuente.resultados', lang, { n: visibles.length, total: filas.length })}
    </p>

    {#if !visibles.length}
        <p class="text-sm text-gray-600 dark:text-gray-300">{t('fuente.nada', lang)}</p>
    {/if}

    <ul class="!m-0 !list-none divide-y divide-gray-200 rounded-lg border border-gray-200 !p-0 dark:divide-gray-800 dark:border-gray-800">
        {#each visibles as d (d.fuente_id)}
            {@const l = linaje[d.fuente_id]}
            <li id={`fuente-${d.fuente_id}`} class="!m-0 scroll-mt-20 !p-0">
                <details open={abiertos.has(d.fuente_id)} on:toggle={(e) => alternar(d.fuente_id, e.currentTarget.open)} class="group">
                    <summary class="flex cursor-pointer list-none items-start gap-3 px-3 py-2.5 hover:bg-gray-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-blue-500 dark:hover:bg-gray-800/50 [&::-webkit-details-marker]:hidden">
                        <svg class="mt-1 h-3.5 w-3.5 shrink-0 text-gray-400 transition-transform group-open:rotate-90" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true"><path d="M7.2 4.2a.75.75 0 011.06 0l5.25 5.25a.75.75 0 010 1.06L8.26 15.8a.75.75 0 11-1.06-1.06L11.94 10 7.2 5.26a.75.75 0 010-1.06z" /></svg>
                        <span class="min-w-0 flex-1">
                            <span class="block text-sm font-semibold text-gray-900 dark:text-white">{d.nombre_dataset}</span>
                            <span class="block text-xs text-gray-500 dark:text-gray-400">{d.organismo}{d.frecuencia ? ` · ${d.frecuencia}` : ""}</span>
                        </span>
                    </summary>

                    {#if abiertos.has(d.fuente_id)}
                        <div class="grid gap-4 px-3 pb-4 pl-9 lg:grid-cols-2">
                            <div class="min-w-0">
                                <dl class="!m-0 grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-sm">
                                    {#if d.cod_oficial}
                                        <dt class="text-gray-500 dark:text-gray-400">{t('fuente.codigo', lang)}</dt>
                                        <dd class="!m-0 min-w-0 break-words font-mono text-xs leading-5 text-gray-800 dark:text-gray-200">{d.cod_oficial}</dd>
                                    {/if}
                                    {#if d.formato_ingesta}
                                        <dt class="text-gray-500 dark:text-gray-400">{t('fuente.formato', lang)}</dt>
                                        <dd class="!m-0 min-w-0 break-words text-gray-800 dark:text-gray-200">{d.formato_ingesta}</dd>
                                    {/if}
                                    {#if d.tipo_licencia}
                                        <dt class="text-gray-500 dark:text-gray-400">{t('fuente.licencia', lang)}</dt>
                                        <dd class="!m-0 min-w-0 break-words text-gray-800 dark:text-gray-200">{d.tipo_licencia}</dd>
                                    {/if}
                                </dl>
                                {#if d.metodologia}
                                    <p class="!mb-0 mt-3 text-sm text-gray-700 dark:text-gray-300">
                                        <span class="font-semibold">{t('fuente.metodologia', lang)}:</span> {d.metodologia}
                                    </p>
                                {/if}
                                <div class="mt-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-sm">
                                    {#if d.url_oficial}
                                        <a href={d.url_oficial} target="_blank" rel="noopener noreferrer" class="font-semibold text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300">
                                            {t('fuente.origen', lang)} ↗<span class="sr-only"> {t('nueva.pestana', lang)}</span>
                                        </a>
                                    {/if}
                                    <button type="button" on:click={() => copiarEnlace(d.fuente_id)} class="text-gray-500 hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400">
                                        {copiado === d.fuente_id ? t('fuente.copiado', lang) : t('fuente.enlace', lang)}
                                    </button>
                                </div>
                            </div>

                            <div class="min-w-0 rounded-md bg-gray-50 p-3 text-sm dark:bg-gray-800/50">
                                <p class="!m-0 font-semibold text-gray-900 dark:text-white">{t('fuente.linaje', lang)}</p>
                                {#if l && (l.scripts.length || l.tablas.length)}
                                    <ol class="!mb-0 mt-2 list-decimal space-y-1.5 pl-5">
                                        {#if l.scripts.length}
                                            <li>
                                                {t('fuente.paso.ingesta', lang)}:
                                                {#each l.scripts as x, i}
                                                    <a href={gh(x)} target="_blank" rel="noopener noreferrer" class="break-all font-mono text-xs text-blue-600 hover:underline dark:text-blue-400">{x}</a>{i < l.scripts.length - 1 ? ", " : ""}
                                                {/each}
                                            </li>
                                        {/if}
                                        {#if l.tablas.length}
                                            <li>
                                                {t('fuente.paso.raw', lang)}:
                                                <span class="break-all font-mono text-xs text-gray-700 dark:text-gray-300">{l.tablas.join(", ")}</span>
                                            </li>
                                        {/if}
                                        {#if l.modelos.length}
                                            <li>
                                                {t('fuente.paso.dbt', lang)}:
                                                {#each l.modelos.slice(0, MAX_LISTA) as m, i}
                                                    <a href={gh(m.ruta)} target="_blank" rel="noopener noreferrer" class="break-all font-mono text-xs text-blue-600 hover:underline dark:text-blue-400">{m.nombre}</a>{i < Math.min(l.modelos.length, MAX_LISTA) - 1 ? ", " : ""}
                                                {/each}
                                                {#if l.modelos.length > MAX_LISTA}<span class="text-xs text-gray-500"> {tf('fuente.mas', lang, { n: l.modelos.length - MAX_LISTA })}</span>{/if}
                                            </li>
                                        {/if}
                                        {#if l.consultas.length}
                                            <li>
                                                {t('fuente.paso.consultas', lang)}:
                                                {#each l.consultas.slice(0, MAX_LISTA) as c, i}
                                                    <a href={gh(c.ruta)} target="_blank" rel="noopener noreferrer" class="break-all font-mono text-xs text-blue-600 hover:underline dark:text-blue-400">{c.nombre}</a>{i < Math.min(l.consultas.length, MAX_LISTA) - 1 ? ", " : ""}
                                                {/each}
                                                {#if l.consultas.length > MAX_LISTA}<span class="text-xs text-gray-500"> {tf('fuente.mas', lang, { n: l.consultas.length - MAX_LISTA })}</span>{/if}
                                            </li>
                                        {/if}
                                    </ol>
                                    {#if l.paginas.length}
                                        <p class="!mb-0 mt-2">
                                            {t('fuente.paso.paginas', lang)}:
                                            {#each l.paginas.slice(0, MAX_LISTA) as p, i}
                                                <a href={enlace(p.url, lang)} class="text-blue-600 hover:underline dark:text-blue-400">{p.titulo}</a>{i < Math.min(l.paginas.length, MAX_LISTA) - 1 ? " · " : ""}
                                            {/each}
                                            {#if l.paginas.length > MAX_LISTA}<span class="text-xs text-gray-500"> {tf('fuente.mas', lang, { n: l.paginas.length - MAX_LISTA })}</span>{/if}
                                        </p>
                                    {/if}
                                    <p class="!mb-1 mt-3 text-xs font-semibold text-gray-600 dark:text-gray-300">{t('fuente.reproducir', lang)}</p>
                                    <pre class="!m-0 overflow-x-auto whitespace-pre rounded bg-gray-900 p-2 text-[11px] leading-4 text-gray-100">{[
                                        ...l.modulos.map((m) => `uv run python -m ${m}`),
                                        // Scripts sin __main__: se lanzan como asset de Dagster
                                        ...l.scripts
                                            .filter((x) => x.endsWith(".py") && !l.modulos.includes(x.slice(0, -3).replace(/\//g, ".")))
                                            .map((x) => `uv run dagster dev -m orchestration.definitions  # materializa ${x}`),
                                        l.scripts.some((x) => x.endsWith(".csv"))
                                            ? `uv run dbt seed ${DBT} --select ${l.scripts.filter((x) => x.endsWith(".csv")).map((x) => x.split("/").pop().replace(/\.csv$/, "")).join(" ")}`
                                            : null,
                                        l.directos?.length ? `uv run dbt build ${DBT} --select ${l.directos.map((m) => `${m}+`).join(" ")}` : null,
                                    ].filter(Boolean).join("\n") || 'dagster asset materialize -m orchestration.definitions --select "*"'}</pre>
                                {:else}
                                    <p class="!mb-0 mt-1 text-gray-600 dark:text-gray-300">{Object.keys(linaje).length ? t('fuente.sinlinaje', lang) : t('cargando', lang)}</p>
                                {/if}
                            </div>
                        </div>
                    {/if}
                </details>
            </li>
        {/each}
    </ul>
</section>
