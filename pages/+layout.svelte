<script context="module">
    import { setFormatLocale } from "@evidence-dev/component-utilities/localeFormatting";
    setFormatLocale("es-ES");
    import {
        formatNumber,
        formatCurrency,
        formatCompact,
        formatMillions,
        formatThousands,
        fijarLocale,
    } from "../../../../src/lib/utils.js";
    // Mapas: no dejar alejar más allá de donde se ve todo ni arrastrarlos lejos
    import { instalarLimitesMapas } from "../../../../src/lib/mapaLimites.js";
    instalarLimitesMapas();
    export {
        formatNumber,
        formatCurrency,
        formatCompact,
        formatMillions,
        formatThousands,
    };
</script>

<script>
    import "@evidence-dev/tailwind/fonts.css";
    import "../app.css";
    import { EvidenceDefaultLayout } from "@evidence-dev/core-components";
    import Header from "../../../../src/lib/components/Header.svelte";
    import { page } from "$app/stores";
    import { IDIOMAS, idiomaDeRuta, rutaEnIdioma, t } from "../../../../src/lib/i18n.js";
    export let data;

    // Idioma según la ruta (/en/..., /ca/..., /gl/..., /eu/...; sin prefijo, castellano)
    $: lang = idiomaDeRuta($page.url.pathname);
    // Números y fechas de Evidence con el formato del idioma (1.234,5 / 1,234.5)
    $: setFormatLocale(IDIOMAS[lang].locale);
    $: fijarLocale(IDIOMAS[lang].locale);
    // La plantilla de Evidence genera <html lang="en">: tools/html-lang-es.mjs lo corrige
    // en el HTML prerenderizado según la carpeta; esto cubre la navegación en el cliente.
    $: if (typeof document !== "undefined") document.documentElement.lang = lang;

    // "Saltar al contenido": lleva el foco al artículo (SvelteKit no mueve el foco con los #anclas)
    function saltarAlContenido(e) {
        const destino = document.getElementById("evidence-main-article");
        if (!destino) return;
        e.preventDefault();
        destino.setAttribute("tabindex", "-1");
        destino.focus();
        destino.scrollIntoView();
    }
</script>

<svelte:head>
    {#each Object.keys(IDIOMAS) as codigo}
        <link rel="alternate" hreflang={codigo} href={"https://spainfacts.org" + rutaEnIdioma($page.url.pathname, codigo)} />
    {/each}
    <link rel="alternate" hreflang="x-default" href={"https://spainfacts.org" + rutaEnIdioma($page.url.pathname, "es")} />
</svelte:head>

<a href="#evidence-main-article" class="saltar-contenido" on:click={saltarAlContenido}>{t("saltar", lang)}</a>

<Header {data} />

<EvidenceDefaultLayout
    {data}
    logo="/logo16.svg"
    builtWithEvidence={false}
    hideSidebar={true}
    hideHeader={true}
>
    <slot slot="content" />
</EvidenceDefaultLayout>
