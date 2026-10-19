<script>
    import { localeActual } from "../utils.js";
    import { page } from "$app/stores";
    import { idiomaDeRuta, enlace, t, tf } from "../i18n.js";
    import { buscarGlobal } from "../indice-busqueda.js";

    $: lang = idiomaDeRuta($page.url.pathname);
    /** Filas con cod_mun, municipio, provincia, poblacion */
    export let opciones = [];

    let texto = "";
    let abierto = false;
    let activo = 0;

    $: busqueda = buscarGlobal(texto, { lang, municipios: opciones });
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

    $: grupos = busqueda.vacio
        ? []
        : (esBusquedaTerritorial
              ? [
                    { id: "territorios", titulo: t("buscador.global.cat.territorios", lang), items: busqueda.territorios },
                    { id: "municipios", titulo: t("buscador.global.cat.municipios", lang), items: busqueda.municipios },
                    { id: "temas", titulo: t("buscador.global.cat.temas", lang), items: busqueda.temas },
                    { id: "analisis", titulo: t("buscador.global.cat.analisis", lang), items: busqueda.analisis },
                    { id: "indicadores", titulo: t("buscador.global.cat.indicadores", lang), items: busqueda.indicadores },
                    { id: "chat", titulo: t("buscador.global.chat", lang), items: chatItem }
                ]
              : [
                    { id: "temas", titulo: t("buscador.global.cat.temas", lang), items: busqueda.temas },
                    { id: "analisis", titulo: t("buscador.global.cat.analisis", lang), items: busqueda.analisis },
                    { id: "indicadores", titulo: t("buscador.global.cat.indicadores", lang), items: busqueda.indicadores },
                    { id: "territorios", titulo: t("buscador.global.cat.territorios", lang), items: busqueda.territorios },
                    { id: "municipios", titulo: t("buscador.global.cat.municipios", lang), items: busqueda.municipios },
                    { id: "chat", titulo: t("buscador.global.chat", lang), items: chatItem }
                ]
          ).filter((g) => g.items.length > 0);

    $: listaPlana = grupos.flatMap((g) => g.items);

    function ir(op) {
        if (op?.href) window.location.href = op.href;
    }

    function tecla(e) {
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
        } else if (e.key === "Escape") {
            abierto = false;
        }
    }
</script>

<div class="relative w-full max-w-2xl">
    <label for="buscador-inicio" class="sr-only">{t("buscador.label", lang)}</label>
    <div class="relative">
        <span class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4 text-gray-400" aria-hidden="true">
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
            </svg>
        </span>
        <input
            id="buscador-inicio"
            type="search"
            autocomplete="off"
            placeholder={t("buscador.inicio.ph", lang)}
            role="combobox"
            aria-autocomplete="list"
            aria-expanded={abierto && listaPlana.length > 0}
            aria-controls="buscador-inicio-lista"
            aria-activedescendant={abierto && listaPlana.length ? `buscador-inicio-op-${activo}` : undefined}
            class="w-full rounded-xl border-0 bg-white/95 pl-11 pr-5 py-3.5 text-base text-gray-900 shadow-lg placeholder:text-gray-500 focus:outline-none focus:ring-4 focus:ring-blue-400/50"
            bind:value={texto}
            on:input={() => {
                abierto = true;
                activo = 0;
            }}
            on:focus={() => (abierto = true)}
            on:blur={() => setTimeout(() => (abierto = false), 160)}
            on:keydown={tecla}
        />
    </div>
    <span class="sr-only" role="status">
        {!busqueda.vacio ? tf("buscador.encontrados", lang, { n: listaPlana.length }) : ""}
    </span>
    {#if abierto && listaPlana.length}
        <div
            id="buscador-inicio-lista"
            role="listbox"
            aria-label={t("buscador.label", lang)}
            class="absolute z-30 mt-2 max-h-[26rem] w-full overflow-y-auto rounded-2xl bg-white p-2 text-left shadow-2xl ring-1 ring-black/10 dark:bg-gray-900 dark:ring-white/15"
        >
            {#each grupos as grupo}
                <div class="mb-1.5 last:mb-0">
                    <div class="px-3 py-1 text-[11px] font-bold uppercase tracking-wider text-gray-400 dark:text-gray-500">
                        {grupo.titulo}
                    </div>
                    {#each grupo.items as op}
                        {@const idx = listaPlana.indexOf(op)}
                        <button
                            id="buscador-inicio-op-{idx}"
                            type="button"
                            role="option"
                            aria-selected={idx === activo}
                            tabindex="-1"
                            class="flex w-full items-center justify-between gap-3 rounded-xl px-3 py-2 text-left text-sm transition-colors {idx === activo
                                ? 'bg-blue-50 dark:bg-blue-950/60'
                                : 'hover:bg-gray-50 dark:hover:bg-gray-800/60'}"
                            on:mousedown|preventDefault={() => ir(op)}
                        >
                            <span class="flex items-center gap-2.5 min-w-0">
                                <span class="text-base shrink-0" aria-hidden="true">{op.icono}</span>
                                <span class="font-semibold text-gray-900 dark:text-white truncate">{op.titulo}</span>
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
    {/if}
</div>
