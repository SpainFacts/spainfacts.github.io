<script>
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

    function publicar(cod) {
        const limpio = String(cod).replace(/[^0-9]/g, '').slice(0, 5);
        $inputs[name] = {
            value: limpio,
            toString() {
                return limpio;
            },
            sql: `'${limpio}'`
        };
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

    // Antes de montar (y durante el prerender) la página usa el municipio por defecto
    publicar(defecto);

    // El código de la URL se lee al montar, pero la lista de municipios puede
    // llegar después (la consulta es asíncrona): se aplica cuando haya ambas cosas.
    let montado = false;
    let codUrl = null;
    onMount(() => {
        codUrl = new URL(window.location.href).searchParams.get(parametro);
        montado = true;
    });

    $: if (montado && !seleccion && opciones.length) {
        elegir(opciones.find((o) => o.cod_mun === codUrl) ?? opciones.find((o) => o.cod_mun === defecto), false);
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

    const miles = (n) => new Intl.NumberFormat('es-ES').format(n ?? 0);
</script>

<div class="not-prose relative max-w-xl my-4">
    <label for="buscador-municipio" class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">Busca tu municipio</label>
    <input
        id="buscador-municipio"
        type="search"
        autocomplete="off"
        placeholder="Escribe al menos dos letras: Sevilla, Vigo, Almendralejo…"
        class="w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-900 px-4 py-2 text-base text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
        bind:value={texto}
        on:focus={() => { abierto = true; texto = ''; }}
        on:input={() => (abierto = true)}
        on:keydown={teclado}
        on:blur={() => setTimeout(() => { abierto = false; if (seleccion && !texto) texto = seleccion.municipio; }, 150)}
        role="combobox"
        aria-expanded={sugerencias.length > 0}
        aria-controls="sugerencias-municipio"
    />
    {#if sugerencias.length > 0}
        <ul id="sugerencias-municipio" role="listbox" class="absolute z-20 mt-1 w-full max-h-80 overflow-auto rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 shadow-lg">
            {#each sugerencias as op, i (op.cod_mun)}
                <li role="option" aria-selected={i === activo}>
                    <button
                        type="button"
                        class="w-full text-left px-4 py-2 text-sm {i === activo ? 'bg-blue-50 dark:bg-blue-950' : ''} hover:bg-blue-50 dark:hover:bg-blue-950"
                        on:mousedown|preventDefault={() => elegir(op)}
                    >
                        <span class="font-medium text-gray-900 dark:text-white">{op.municipio}</span>
                        <span class="text-gray-500"> · {op.provincia} · {miles(op.poblacion)} hab.</span>
                    </button>
                </li>
            {/each}
        </ul>
    {/if}
</div>
