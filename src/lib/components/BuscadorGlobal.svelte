<script>
    import { tick } from "svelte";
    import { page } from "$app/stores";
    import { idiomaDeRuta, enlace, t } from "../i18n.js";
    import { buscarGlobal, cargarTodosMunicipios } from "../indice-busqueda.js";
    import { localeActual } from "../utils.js";

    export let abierto = false;

    $: lang = idiomaDeRuta($page.url.pathname);

    let texto = "";
    let activo = 0;
    let inputEl;
    let municipiosCargados = [];

    // Al abrir el modal, asegurar la carga de todos los municipios (+8.100) en segundo plano
    $: if (abierto) {
        tick().then(() => inputEl?.focus());
        if (!municipiosCargados.length) {
            cargarTodosMunicipios().then((res) => {
                if (res && res.length) municipiosCargados = res;
            });
        }
    } else {
        texto = "";
        activo = 0;
    }

    $: busqueda = buscarGlobal(texto, { lang, municipios: municipiosCargados });
    $: chatItem =
        texto.trim().length >= 3
            ? [
                  {
                      categoria: "chat",
                      href: `${enlace("/chat", lang)}?p=${encodeURIComponent(texto.trim())}`,
                      icono: "💬",
                      titulo: `${t("buscador.global.chat", lang)}: «${texto.trim()}»`,
                      subtitulo: "SpainFacts IA · SQL"
                  }
              ]
            : [];

    $: esBusquedaTerritorial =
        (busqueda.territorios[0]?.puntos ?? 0) >= 60 ||
        (busqueda.municipios[0]?.puntos ?? 0) >= 60;

    $: grupos = [
        ...(esBusquedaTerritorial
            ? [
                  { id: "territorios", titulo: t("buscador.global.cat.territorios", lang), items: busqueda.territorios },
                  { id: "municipios", titulo: t("buscador.global.cat.municipios", lang), items: busqueda.municipios },
                  { id: "temas", titulo: t("buscador.global.cat.temas", lang), items: busqueda.temas },
                  { id: "analisis", titulo: t("buscador.global.cat.analisis", lang), items: busqueda.analisis },
                  { id: "indicadores", titulo: t("buscador.global.cat.indicadores", lang), items: busqueda.indicadores }
              ]
            : [
                  { id: "temas", titulo: t("buscador.global.cat.temas", lang), items: busqueda.temas },
                  { id: "analisis", titulo: t("buscador.global.cat.analisis", lang), items: busqueda.analisis },
                  { id: "indicadores", titulo: t("buscador.global.cat.indicadores", lang), items: busqueda.indicadores },
                  { id: "territorios", titulo: t("buscador.global.cat.territorios", lang), items: busqueda.territorios },
                  { id: "municipios", titulo: t("buscador.global.cat.municipios", lang), items: busqueda.municipios }
              ]),
        { id: "chat", titulo: t("buscador.global.chat", lang), items: chatItem }
    ].filter((g) => g.items.length > 0);

    $: listaPlana = grupos.flatMap((g) => g.items);

    function cerrar() {
        abierto = false;
    }

    function ir(op) {
        if (!op?.href) return;
        abierto = false;
        window.location.href = op.href;
    }

    function teclaVentana(e) {
        if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
            e.preventDefault();
            abierto = !abierto;
            return;
        }
        if (!abierto) return;
        if (e.key === "Escape") {
            e.preventDefault();
            cerrar();
        }
    }

    function teclaInput(e) {
        if (!listaPlana.length) return;
        if (e.key === "ArrowDown") {
            activo = (activo + 1) % listaPlana.length;
            e.preventDefault();
        } else if (e.key === "ArrowUp") {
            activo = (activo - 1 + listaPlana.length) % listaPlana.length;
            e.preventDefault();
        } else if (e.key === "Enter") {
            ir(listaPlana[activo]);
            e.preventDefault();
        }
    }
</script>

<svelte:window on:keydown={teclaVentana} />

{#if abierto}
    <div
        class="fixed inset-0 z-[100] flex items-start justify-center bg-slate-900/60 backdrop-blur-xs px-4 pt-14 pb-6 sm:pt-20"
        role="dialog"
        aria-modal="true"
        aria-label={t("buscador.label", lang)}
        on:click|self={cerrar}
    >
        <div class="w-full max-w-2xl overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-2xl dark:border-gray-700 dark:bg-gray-900">
            <!-- Barra de entrada -->
            <div class="relative flex items-center border-b border-gray-200 px-4 py-3 dark:border-gray-800">
                <svg class="h-5 w-5 shrink-0 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
                </svg>
                <input
                    bind:this={inputEl}
                    type="search"
                    autocomplete="off"
                    placeholder={t("buscador.inicio.ph", lang)}
                    class="w-full border-0 bg-transparent px-3 py-1 text-base text-gray-900 placeholder:text-gray-400 focus:outline-none dark:text-white"
                    bind:value={texto}
                    on:input={() => (activo = 0)}
                    on:keydown={teclaInput}
                />
                <button
                    type="button"
                    on:click={cerrar}
                    class="rounded-md border border-gray-200 px-2 py-0.5 text-xs font-medium text-gray-500 hover:bg-gray-100 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-800"
                >
                    Esc
                </button>
            </div>

            <!-- Lista de resultados -->
            <div class="max-h-[65vh] overflow-y-auto p-2.5">
                {#each grupos as grupo}
                    <div class="mb-2 last:mb-0">
                        <div class="px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-gray-400 dark:text-gray-500">
                            {grupo.titulo}
                        </div>
                        {#each grupo.items as op}
                            {@const idx = listaPlana.indexOf(op)}
                            <button
                                type="button"
                                class="flex w-full items-center justify-between gap-3 rounded-xl px-3 py-2 text-left text-sm transition-colors {idx === activo
                                    ? 'bg-blue-50 text-blue-900 dark:bg-blue-950/60 dark:text-blue-200'
                                    : 'text-gray-800 hover:bg-gray-50 dark:text-gray-200 dark:hover:bg-gray-800/60'}"
                                on:mouseenter={() => (activo = idx)}
                                on:click={() => ir(op)}
                            >
                                <span class="flex items-center gap-2.5 min-w-0">
                                    <span class="text-base shrink-0" aria-hidden="true">{op.icono}</span>
                                    <span class="font-semibold truncate">{op.titulo}</span>
                                </span>
                                {#if op.categoria === "municipios"}
                                    <span class="shrink-0 text-xs text-gray-500 dark:text-gray-400">
                                        {op.subtitulo} · {Number(op.poblacion ?? 0).toLocaleString(localeActual())} {t("hab", lang)}
                                    </span>
                                {:else if op.categoria === "territorios"}
                                    <span class="shrink-0 text-xs rounded-md px-2 py-0.5 bg-blue-50 text-blue-700 dark:bg-blue-950/80 dark:text-blue-300 font-medium">
                                        {op.subtitulo}
                                    </span>
                                {:else}
                                    <span class="shrink-0 text-xs text-gray-500 dark:text-gray-400 max-w-[42%] truncate">
                                        {op.subtitulo}
                                    </span>
                                {/if}
                            </button>
                        {/each}
                    </div>
                {/each}
            </div>

            <!-- Pie del buscador -->
            <div class="flex flex-wrap items-center justify-between gap-2 border-t border-gray-100 bg-gray-50/80 px-4 py-2.5 text-xs text-gray-500 dark:border-gray-800 dark:bg-gray-900/80 dark:text-gray-400">
                <span>{t("buscador.global.atajo", lang)}</span>
                <div class="flex items-center gap-3">
                    <a href={enlace("/territorios/municipios", lang)} on:click={cerrar} class="font-semibold text-blue-600 hover:underline dark:text-blue-400">
                        {t("buscador.global.verMunicipios", lang)}
                    </a>
                    <a href={enlace("/varios/indicadores", lang)} on:click={cerrar} class="font-semibold text-blue-600 hover:underline dark:text-blue-400">
                        {t("buscador.global.verIndicadores", lang)}
                    </a>
                </div>
            </div>
        </div>
    </div>
{/if}
