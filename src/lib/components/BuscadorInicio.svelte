<script>
    // Buscador de la portada: al elegir un municipio lleva a su ficha
    // (/territorios/municipios?m=<código INE>). Misma búsqueda sin tildes que
    // BuscadorMunicipio, pero sin publicar ningún input de Evidence.
    /** Filas con cod_mun, municipio, provincia, poblacion */
    export let opciones = [];

    let texto = '';
    let abierto = false;
    let activo = 0;

    const quitarAcentos = (s) => String(s ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

    $: consulta = quitarAcentos(texto.trim());
    $: resultados = consulta.length < 2
        ? []
        : opciones
              .filter((o) => quitarAcentos(o.municipio).includes(consulta))
              .sort((a, b) => {
                  const ea = quitarAcentos(a.municipio).startsWith(consulta) ? 0 : 1;
                  const eb = quitarAcentos(b.municipio).startsWith(consulta) ? 0 : 1;
                  return ea - eb || (b.poblacion ?? 0) - (a.poblacion ?? 0);
              })
              .slice(0, 8);

    function ir(op) {
        if (op) window.location.href = `/territorios/municipios?m=${op.cod_mun}`;
    }

    function tecla(e) {
        if (!resultados.length) return;
        if (e.key === 'ArrowDown') { activo = (activo + 1) % resultados.length; e.preventDefault(); }
        else if (e.key === 'ArrowUp') { activo = (activo - 1 + resultados.length) % resultados.length; e.preventDefault(); }
        else if (e.key === 'Enter') { ir(resultados[activo]); e.preventDefault(); }
        else if (e.key === 'Escape') { abierto = false; }
    }
</script>

<div class="relative w-full max-w-xl">
    <label for="buscador-inicio" class="sr-only">Busca tu municipio</label>
    <input
        id="buscador-inicio"
        type="search"
        autocomplete="off"
        placeholder="Escribe tu municipio: población, cuentas, quién gobierna…"
        class="w-full rounded-xl border-0 bg-white/95 px-5 py-3.5 text-base text-gray-900 shadow-lg placeholder:text-gray-500 focus:outline-none focus:ring-4 focus:ring-blue-400/50"
        bind:value={texto}
        on:input={() => { abierto = true; activo = 0; }}
        on:focus={() => (abierto = true)}
        on:blur={() => setTimeout(() => (abierto = false), 150)}
        on:keydown={tecla}
    />
    {#if abierto && resultados.length}
        <ul class="absolute z-20 mt-2 w-full overflow-hidden rounded-xl bg-white text-left shadow-2xl ring-1 ring-black/5 dark:bg-gray-900 dark:ring-white/10">
            {#each resultados as op, i}
                <li>
                    <button
                        type="button"
                        class="flex w-full items-baseline justify-between gap-3 px-4 py-2.5 text-left text-sm {i === activo ? 'bg-blue-50 dark:bg-blue-950/50' : ''} hover:bg-blue-50 dark:hover:bg-blue-950/50"
                        on:mousedown|preventDefault={() => ir(op)}
                    >
                        <span class="font-semibold text-gray-900 dark:text-white">{op.municipio}</span>
                        <span class="text-xs text-gray-500">{op.provincia} · {Number(op.poblacion ?? 0).toLocaleString('es-ES')} hab.</span>
                    </button>
                </li>
            {/each}
        </ul>
    {/if}
</div>
