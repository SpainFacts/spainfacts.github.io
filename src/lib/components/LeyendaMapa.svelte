<script>
    // Leyenda de los mapas de coropletas (MapaEspana y MapaBarrios), como en wikibarrio.es:
    // extremos cortados («<» y «>» cuando hay valores fuera), mediana en el centro de la barra,
    // marca del valor bajo el ratón, rayado de «sin datos» y, si hay escala de referencia,
    // botones para colorear con la escala del propio mapa o con la de toda España.
    import { colorEn, RAYADO } from '../escalaMapa.js';

    export let escala; // de calcularEscala
    export let paleta = [];
    export let formatear = (v) => String(v);
    export let lang = 'es';
    export let sinDatos = true;
    export let marca = null; // valor del territorio bajo el ratón
    export let modos = []; // [{id, nombre}] — nombre: 'municipio' | 'mapa' | 'espana' | 'comunidad' o texto
    export let modo = undefined;

    const TXT = {
        es: { escala: 'Escala', mediana: 'mediana', bajo: '‹ bajo la mediana', encima: 'por encima ›', sin: 'Sin datos', municipio: 'Municipio', mapa: 'Este mapa', espana: 'España', comunidad: 'Comunidad', vista: 'Lo que se ve' },
        en: { escala: 'Scale', mediana: 'median', bajo: '‹ below the median', encima: 'above ›', sin: 'No data', municipio: 'Municipality', mapa: 'This map', espana: 'Spain', comunidad: 'Region', vista: 'Current view' },
        ca: { escala: 'Escala', mediana: 'mediana', bajo: '‹ sota la mediana', encima: 'per sobre ›', sin: 'Sense dades', municipio: 'Municipi', mapa: 'Aquest mapa', espana: 'Espanya', comunidad: 'Comunitat', vista: 'El que es veu' },
        gl: { escala: 'Escala', mediana: 'mediana', bajo: '‹ por baixo da mediana', encima: 'por riba ›', sin: 'Sen datos', municipio: 'Concello', mapa: 'Este mapa', espana: 'España', comunidad: 'Comunidade', vista: 'O que se ve' },
        eu: { escala: 'Eskala', mediana: 'mediana', bajo: '‹ medianaren azpitik', encima: 'gainetik ›', sin: 'Daturik ez', municipio: 'Udalerria', mapa: 'Mapa hau', espana: 'Espainia', comunidad: 'Erkidegoa', vista: 'Ikusten dena' }
    };
    $: tx = TXT[lang] ?? TXT.es;
    $: degradado = Array.from({ length: 11 }, (_, i) => colorEn(paleta, i / 10)).join(', ');
    $: posMarca = marca === null || marca === undefined ? null : escala?.t(marca);
</script>

<div class="mt-2 flex flex-wrap items-center gap-x-5 gap-y-2 text-xs text-gray-600 dark:text-gray-400">
    {#if modos.length > 1}
        <span class="inline-flex items-center gap-1.5">
            <span>{tx.escala}:</span>
            <span class="inline-flex rounded-md border border-gray-300 dark:border-gray-600 overflow-hidden">
                {#each modos as m}
                    <button
                        type="button"
                        class="px-2 py-0.5 {modo === m.id ? 'bg-gray-800 text-white dark:bg-gray-200 dark:text-gray-900' : 'hover:bg-gray-100 dark:hover:bg-gray-800'}"
                        aria-pressed={modo === m.id}
                        on:click={() => (modo = m.id)}>{tx[m.nombre] ?? m.nombre}</button>
                {/each}
            </span>
        </span>
    {/if}
    {#if escala}
        <span class="inline-flex items-center gap-2">
            <span class="tabular-nums">{escala.cortaAbajo ? '<' : ''}{formatear(escala.lo)}</span>
            <span class="inline-flex flex-col w-64 max-w-[55vw]">
                <span class="mb-0.5 text-center text-[11px] leading-tight font-semibold text-gray-700 dark:text-gray-300 tabular-nums whitespace-nowrap">{escala.esMediana ? `${tx.mediana} ` : ''}{formatear(escala.mid)}</span>
                <span class="relative block h-2.5 rounded-sm" style="background:linear-gradient(to right, {degradado})">
                    <span class="absolute left-1/2 -top-0.5 -bottom-0.5 w-px bg-gray-900/60 dark:bg-white/70"></span>
                    {#if posMarca !== null && posMarca !== undefined}
                        <span class="absolute -top-1 -bottom-1 w-[3px] -ml-[1.5px] rounded-sm bg-gray-900 dark:bg-white ring-1 ring-white dark:ring-gray-900 transition-[left] duration-150" style="left:{posMarca * 100}%"></span>
                    {/if}
                </span>
                {#if escala.esMediana}
                    <span class="mt-0.5 flex justify-between gap-2 text-[10px] leading-tight text-gray-500 dark:text-gray-400 whitespace-nowrap">
                        <span>{tx.bajo}</span>
                        <span>{tx.encima}</span>
                    </span>
                {/if}
            </span>
            <span class="tabular-nums">{escala.cortaArriba ? '>' : ''}{formatear(escala.hi)}</span>
        </span>
    {/if}
    <slot />
    {#if sinDatos}
        <span class="inline-flex items-center gap-1">
            <svg width="12" height="12" aria-hidden="true" class="rounded-sm"><rect width="12" height="12" fill="url(#{RAYADO})" /></svg>{tx.sin}
        </span>
    {/if}
</div>
