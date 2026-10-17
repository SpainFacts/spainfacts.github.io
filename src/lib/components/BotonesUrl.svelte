<script>
    // Grupo de botones (como el ButtonGroup de Evidence) que publica su valor como input de
    // Evidence y lo guarda en la URL (?<parametro>=<valor>), para compartir la vista exacta.
    // Las consultas lo usan como '${inputs.<name>}'.
    import { onMount } from 'svelte';
    import { afterNavigate } from '$app/navigation';
    import { getInputContext } from '@evidence-dev/sdk/utils/svelte';

    /** [{ value, label }] */
    export let opciones = [];
    export let name;
    export let parametro = name;
    export let defecto = opciones[0]?.value;
    export let titulo = '';

    const inputs = getInputContext();
    let actual = defecto;

    // Texto simple, como BuscadorMunicipio: la web compilada rehidrata los inputs como objetos planos
    function publicar(v) {
        actual = v;
        $inputs[name] = String(v);
    }

    function elegir(v) {
        publicar(v);
        if (typeof window === 'undefined') return;
        const url = new URL(window.location.href);
        if (v === defecto) url.searchParams.delete(parametro);
        else url.searchParams.set(parametro, v);
        window.history.replaceState(window.history.state, '', url);
    }

    // Durante el prerender y antes de montar, el valor por defecto
    publicar(defecto);

    function leerUrl() {
        const v = new URL(window.location.href).searchParams.get(parametro);
        if (!v && actual !== defecto) publicar(defecto);
        if (v && opciones.some((o) => o.value === v)) {
            publicar(v);
            // Si la rehidratación de la página pisa el input justo después, se vuelve a publicar
            setTimeout(() => { if (actual === v && $inputs[name] !== v) publicar(v); }, 300);
        }
    }
    onMount(leerUrl);
    // Enlaces de la propia página que cambian los parámetros sin volver a montar el componente
    afterNavigate(({ from, to }) => {
        if (from?.url && to?.url && from.url.pathname === to.url.pathname && from.url.search !== to.url.search) leerUrl();
    });
</script>

<div class="not-prose my-3">
    {#if titulo}<div class="mb-1 text-sm text-gray-700 dark:text-gray-300">{titulo}</div>{/if}
    <div class="flex flex-wrap gap-1" role="group" aria-label={titulo || name}>
        {#each opciones as o (o.value)}
            <button
                type="button"
                class="rounded-md border px-3 py-1 text-xs font-medium {actual === o.value
                    ? 'border-blue-500 bg-blue-50 text-blue-700 dark:bg-blue-950 dark:text-blue-300'
                    : 'border-gray-300 text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-gray-900'}"
                aria-pressed={actual === o.value}
                on:click={() => elegir(o.value)}>{o.label}</button>
        {/each}
    </div>
</div>
