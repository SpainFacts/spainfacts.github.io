<script>
    // Selector de idioma de la cabecera: lleva a la misma página en el idioma elegido
    // (cambia solo el prefijo de la ruta: /economia/paro/ <-> /en/economia/paro/).
    import { goto } from "$app/navigation";
    import { IDIOMAS, rutaEnIdioma, t } from "../i18n.js";

    export let lang = "es";
    export let ruta = "/";

    function cambiar(e) {
        const nuevo = e.currentTarget.value;
        if (nuevo === lang) return;
        try {
            localStorage.setItem("idioma", nuevo);
        } catch {
            /* sin almacenamiento: no pasa nada */
        }
        goto(rutaEnIdioma(ruta, nuevo) + (typeof location !== "undefined" ? location.search : ""));
    }
</script>

<label class="selector-idioma">
    <span class="sr-only">{t("menu.idioma", lang)}</span>
    <svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
        ><circle cx="12" cy="12" r="10" /><path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" /></svg
    >
    <select value={lang} on:change={cambiar}>
        {#each Object.entries(IDIOMAS) as [codigo, info]}
            <option value={codigo} lang={codigo}>{info.corto} · {info.nombre}</option>
        {/each}
    </select>
</label>

<style>
    .selector-idioma {
        display: inline-flex;
        align-items: center;
        gap: 4px;
        padding: 2px 6px;
        border: 1px solid var(--base-300, #e5e7eb);
        border-radius: 8px;
        color: var(--base-content, #374151);
        font-size: 13px;
    }
    .selector-idioma:focus-within {
        outline: 2px solid #2563eb;
        outline-offset: 1px;
    }
    select {
        background: transparent;
        border: none;
        color: inherit;
        font: inherit;
        padding: 2px 0;
        min-height: 24px;
        cursor: pointer;
        max-width: 9.5rem;
    }
    select:focus {
        outline: none;
    }
    option {
        color: #111827;
        background: #fff;
    }
</style>
