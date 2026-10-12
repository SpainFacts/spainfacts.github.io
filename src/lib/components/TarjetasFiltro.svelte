<script>
    import { page } from "$app/stores";
    import { idiomaDeRuta } from "../i18n.js";
    $: lang = idiomaDeRuta($page.url.pathname);

    // Tarjetas de resumen que filtran: cada una muestra una cifra y, al pulsarla, guarda su
    // `valor` en el input de Evidence `name` (como un ButtonGroup), así que las consultas de
    // la página pueden usar ${inputs.<name>}. Al volver a pulsar la tarjeta activa, el input
    // vuelve a 'todos'.
    //
    //   <TarjetasFiltro name=filtro tarjetas={[
    //       { valor: 'mejor', n: balance[0]?.mejor, texto: 'indicadores mejor que la UE', tono: 'verde' }, ...
    //   ]} />
    import { getInputContext } from "@evidence-dev/sdk/utils/svelte";
    import { get } from "svelte/store";
    import { onMount } from "svelte";

    export let name;
    /** [{ valor, n, texto, tono?: 'verde' | 'rojo' }] */
    export let tarjetas = [];

    const TEXTOS = {
        es: { filtrar: "Pulsa para ver cuáles", activo: "Filtro activo · pulsa para quitarlo" },
        en: { filtrar: "Click to see which ones", activo: "Filter on · click to remove it" },
        ca: { filtrar: "Prem per veure quins", activo: "Filtre actiu · prem per treure'l" },
        gl: { filtrar: "Preme para ver cales", activo: "Filtro activo · preme para quitalo" },
        eu: { filtrar: "Sakatu zeintzuk diren ikusteko", activo: "Iragazkia aktibo · sakatu kentzeko" }
    };
    $: tx = TEXTOS[lang] ?? TEXTOS.es;

    const inputs = getInputContext();
    // valor inicial al montar (antes, Evidence aún no sigue el input y la consulta falla)
    onMount(() => {
        if (typeof get(inputs)[name] !== "string") inputs.update((i) => ({ ...i, [name]: "todos" }));
    });
    $: activo = typeof $inputs[name] === "string" ? $inputs[name] : "todos";

    function pulsar(valor) {
        $inputs[name] = activo === valor ? "todos" : valor;
    }
</script>

<div class="grid grid-cols-2 md:grid-cols-4 gap-3 my-6 not-prose" role="group">
    {#each tarjetas as c (c.valor)}
        <button
            type="button"
            class="tarjeta text-left rounded-xl border p-4 transition-colors {c.tono === 'verde'
                ? 'border-green-200 dark:border-green-900 bg-green-50/60 dark:bg-green-950/30'
                : c.tono === 'rojo'
                  ? 'border-red-200 dark:border-red-900 bg-red-50/60 dark:bg-red-950/30'
                  : 'border-gray-200 dark:border-gray-700'}"
            class:activa={activo === c.valor}
            aria-pressed={activo === c.valor}
            on:click={() => pulsar(c.valor)}
        >
            <span class="block text-3xl font-bold {c.tono === 'verde' ? 'text-green-700 dark:text-green-400' : c.tono === 'rojo' ? 'text-red-700 dark:text-red-400' : 'text-gray-900 dark:text-white'}">{c.n ?? "–"}</span>
            <span class="block text-sm text-gray-600 dark:text-gray-400">{c.texto}</span>
            <span class="block mt-2 text-xs {activo === c.valor ? 'font-semibold text-gray-800 dark:text-gray-100' : 'text-gray-400 dark:text-gray-500'}">{activo === c.valor ? tx.activo : tx.filtrar}</span>
        </button>
    {/each}
</div>

<style>
    .tarjeta {
        cursor: pointer;
    }
    .tarjeta:hover {
        border-color: var(--base-content-muted, #9ca3af);
    }
    .tarjeta:focus-visible {
        outline: 2px solid var(--primary);
        outline-offset: 2px;
    }
    .tarjeta.activa {
        box-shadow: 0 0 0 2px var(--base-content, #111827);
    }
</style>
