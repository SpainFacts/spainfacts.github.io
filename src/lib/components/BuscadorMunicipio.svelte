<script>
    import { localeActual } from "../utils.js";
    import { page } from "$app/stores";
    import { idiomaDeRuta, t, tf } from "../i18n.js";
    $: lang = idiomaDeRuta($page.url.pathname);
    // Buscador de municipios con URL compartible (?m=<código INE>).
    // Publica la selección como un input de Evidence (igual que TextInput), así
    // las consultas de la página pueden usar '${inputs.<name>}'.
    import { onMount } from 'svelte';
    import { getInputContext } from '@evidence-dev/sdk/utils/svelte';

    /** Filas con cod_mun, municipio, provincia, poblacion */
    export let opciones = [];
    export let name = 'municipio';
    export let defecto = '28079';
    export let parametro = 'm';

    const inputs = getInputContext();
    let texto = '';
    let abierto = false;
    let activo = 0;
    let seleccion = null;

    const quitarAcentos = (s) => String(s ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

    // Se publica un TEXTO simple (como ButtonGroup), no un objeto con toString():
    // en la web compilada Evidence rehidrata los inputs desde el prerender como objetos
    // planos, sin toString, y la consulta acababa recibiendo '[object Object]'.
    function publicar(cod) {
        const limpio = String(cod).replace(/[^0-9]/g, '').slice(0, 5);
        $inputs[name] = limpio;
    }

    function elegir(op, actualizarUrl = true) {
        if (!op) return;
        seleccion = op;
        texto = op.municipio;
        abierto = false;
        publicar(op.cod_mun);
        if (actualizarUrl && typeof window !== 'undefined') {
            const url = new URL(window.location.href);
            url.searchParams.set(parametro, op.cod_mun);
            window.history.replaceState(window.history.state, '', url);
        }
    }

    /** Código del municipio que ya muestran los datos de la página (p. ej. mun[0]?.cod_mun):
     *  mientras no coincida con el pedido en la URL, se ocultan los datos del municipio por defecto */
    export let listo = undefined;

    const enNavegador = typeof window !== 'undefined';
    const valido = (c) => /^[0-9]{5}$/.test(c ?? '');
    // El código de la URL se aplica YA, sin esperar a la lista de 8.100 municipios
    // (antes se pintaba y consultaba el municipio por defecto hasta que llegaba la lista)
    let codUrl = enNavegador ? new URL(window.location.href).searchParams.get(parametro) : null;
    if (!valido(codUrl)) codUrl = null;
    const pedido = codUrl ?? defecto;
    // Al iniciar, siempre el municipio por defecto: es el que trae el HTML prerenderizado.
    // Si se publicara aquí el de la URL, Evidence asociaría los datos prerenderizados del
    // municipio por defecto a la consulta del otro (se quedaba Madrid). Se cambia al montar.
    publicar(defecto);

    // El HTML prerenderizado trae el municipio por defecto: si la URL pide otro, se tapa
    // hasta que lleguen sus datos (el script de <svelte:head> lo hace antes de pintar)
    const ATRIBUTO = 'data-municipio-pendiente';
    const tapar = (si) => {
        if (!enNavegador) return;
        if (si) document.documentElement.setAttribute(ATRIBUTO, defecto);
        else document.documentElement.removeAttribute(ATRIBUTO);
    };
    if (pedido !== defecto) tapar(true);
    $: if (enNavegador && listo && listo === (seleccion?.cod_mun ?? pedido)) tapar(false);
    const scriptPrevio = `<script>try{var c=new URLSearchParams(location.search).get(${JSON.stringify(parametro)});if(/^[0-9]{5}$/.test(c||'')&&c!==${JSON.stringify(defecto)})document.documentElement.setAttribute('${ATRIBUTO}',${JSON.stringify(defecto)})}catch(e){}<\/script>`;

    let montado = false;
    onMount(() => {
        montado = true;
        if (!seleccion) publicar(pedido);
        // Si la rehidratación de la página pisa el input, se vuelve a publicar
        setTimeout(() => { if (!seleccion && $inputs[name] !== pedido) publicar(pedido); }, 300);
        // Por si algo falla, no dejar la página tapada para siempre
        const t = setTimeout(() => tapar(false), 20000);
        return () => { clearTimeout(t); tapar(false); };
    });

    // Cuando llega la lista se rellena el texto del buscador (y se corrige un código que no exista)
    $: if (montado && !seleccion && opciones.length) {
        elegir(opciones.find((o) => o.cod_mun === pedido) ?? opciones.find((o) => o.cod_mun === defecto), false);
        const cod = seleccion?.cod_mun;
        if (cod) setTimeout(() => { if (seleccion?.cod_mun === cod && $inputs[name] !== cod) publicar(cod); }, 300);
    }

    $: q = quitarAcentos(texto.trim());
    $: sugerencias =
        abierto && q.length >= 2
            ? opciones
                  .filter((o) => quitarAcentos(o.municipio).includes(q))
                  // primero los que empiezan por el texto, luego los más poblados
                  .sort((a, b) => (quitarAcentos(b.municipio).startsWith(q) - quitarAcentos(a.municipio).startsWith(q)) || b.poblacion - a.poblacion)
                  .slice(0, 12)
            : [];
    $: if (activo >= sugerencias.length) activo = 0;

    function teclado(e) {
        if (e.key === 'ArrowDown') { activo = Math.min(activo + 1, sugerencias.length - 1); e.preventDefault(); }
        else if (e.key === 'ArrowUp') { activo = Math.max(activo - 1, 0); e.preventDefault(); }
        else if (e.key === 'Enter' && sugerencias[activo]) { elegir(sugerencias[activo]); e.preventDefault(); }
        else if (e.key === 'Escape') { abierto = false; }
    }

    const miles = (n) => new Intl.NumberFormat(localeActual()).format(n ?? 0);
</script>

<svelte:head>{@html scriptPrevio}</svelte:head>

<div class="buscador-municipio not-prose relative max-w-xl my-4">
    <label for="buscador-municipio" class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">{t('buscador.label', lang)}</label>
    <input
        id="buscador-municipio"
        type="search"
        autocomplete="off"
        placeholder={t('buscador.ph', lang)}
        class="w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-900 px-4 py-2 text-base text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
        bind:value={texto}
        on:focus={() => { abierto = true; texto = ''; }}
        on:input={() => (abierto = true)}
        on:keydown={teclado}
        on:blur={() => setTimeout(() => { abierto = false; if (seleccion && !texto) texto = seleccion.municipio; }, 150)}
        role="combobox"
        aria-autocomplete="list"
        aria-expanded={sugerencias.length > 0}
        aria-controls="sugerencias-municipio"
        aria-activedescendant={sugerencias.length ? `sugerencia-municipio-${activo}` : undefined}
    />
    <span class="sr-only" role="status">{abierto && q.length >= 2 ? tf('buscador.encontrados', lang, { n: sugerencias.length }) : ''}</span>
    {#if sugerencias.length > 0}
        <ul id="sugerencias-municipio" role="listbox" aria-label={t('buscador.municipios', lang)} class="absolute z-20 mt-1 w-full max-h-80 overflow-auto rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 shadow-lg">
            {#each sugerencias as op, i (op.cod_mun)}
                <li id="sugerencia-municipio-{i}" role="option" aria-selected={i === activo}>
                    <button
                        type="button"
                        tabindex="-1"
                        class="w-full text-left px-4 py-2 text-sm {i === activo ? 'bg-blue-50 dark:bg-blue-950' : ''} hover:bg-blue-50 dark:hover:bg-blue-950"
                        on:mousedown|preventDefault={() => elegir(op)}
                    >
                        <span class="font-medium text-gray-900 dark:text-white">{op.municipio}</span>
                        <span class="text-gray-600 dark:text-gray-400"> · {op.provincia} · {miles(op.poblacion)} {t('hab', lang)}</span>
                    </button>
                </li>
            {/each}
        </ul>
    {/if}
</div>

<style>
    /* Mientras llegan los datos del municipio de la URL, no enseñar los del municipio por defecto */
    :global(html[data-municipio-pendiente] .buscador-municipio ~ *) {
        visibility: hidden;
    }
    :global(html[data-municipio-pendiente] .buscador-municipio)::after {
        content: '…';
        display: block;
        margin-top: 1.5rem;
        font-size: 2rem;
        letter-spacing: 0.2em;
        color: var(--base-content-muted, #888);
        animation: latido 1.2s ease-in-out infinite;
    }
    @keyframes latido {
        50% { opacity: 0.3; }
    }
</style>
