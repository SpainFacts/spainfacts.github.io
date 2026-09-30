<script>
    // Aviso de sección en construcción: la página existe para no olvidar el tema y
    // explicar qué mostrará, de dónde saldrán los datos y qué falta para hacerla.
    import { page } from "$app/stores";
    import { idiomaDeRuta, t } from "../i18n.js";
    $: lang = idiomaDeRuta($page.url.pathname);

    /** qué impide hacerla todavía (texto libre, ya traducido por la página) */
    export let motivo = "";
</script>

<aside class="en-construccion" role="note">
    <span class="icono" aria-hidden="true">🚧</span>
    <div>
        <p class="titulo">{t("construccion.titulo", lang)}</p>
        <p class="texto">{t("construccion.texto", lang)}</p>
        {#if motivo}<p class="texto"><strong>{t("construccion.motivo", lang)}</strong> {motivo}</p>{/if}
    </div>
</aside>

<style>
    .en-construccion {
        display: flex;
        gap: 12px;
        align-items: flex-start;
        margin: 1rem 0 1.5rem;
        padding: 14px 16px;
        border: 1px dashed #d97706;
        border-radius: 10px;
        background: color-mix(in srgb, #f59e0b 10%, transparent);
    }
    .icono {
        font-size: 1.6rem;
        line-height: 1;
    }
    .titulo {
        margin: 0 0 4px;
        font-weight: 700;
        color: var(--base-content);
    }
    .texto {
        margin: 0.25rem 0 0;
        font-size: 0.95rem;
        color: var(--base-content);
    }
</style>
