<script>
    import { page } from "$app/stores";
    import { idiomaDeRuta, t } from "../i18n.js";
    $: lang = idiomaDeRuta($page.url.pathname);

    // Tabla con buscador en la que cada fila se puede seleccionar. La fila elegida
    // se guarda como un input de Evidence (igual que un ButtonGroup o un Dropdown),
    // así que las consultas de la página pueden usar ${inputs.<name>}.
    import { getInputContext } from "@evidence-dev/sdk/utils/svelte";
    import { get } from "svelte/store";

    export let data = [];
    export let name;
    export let value; // columna con el identificador que se guarda en el input
    export let columnas = []; // [{ id, titulo, fmt?: (v) => string, alinear?: 'right' }]
    export let placeholder = undefined;
    export let alto = 420; // px de la zona con scroll
    export let etiqueta = "Tabla seleccionable"; // nombre accesible de la tabla y del buscador

    const inputs = getInputContext();
    let busqueda = "";

    $: filas = Array.from(data ?? []);

    const normalizar = (t) =>
        String(t ?? "")
            .toLowerCase()
            .normalize("NFD")
            .replace(/[̀-ͯ]/g, "");

    $: terminos = normalizar(busqueda).split(/\s+/).filter(Boolean);
    $: visibles = terminos.length
        ? filas.filter((f) => {
              const texto = normalizar(columnas.map((c) => f[c.id]).join(" "));
              return terminos.every((t) => texto.includes(t));
          })
        : filas;

    // Si no hay nada elegido (o lo elegido ya no está en los datos), se elige la primera fila
    // (se lee el store con get() para que esta comprobación dependa solo de los datos)
    $: seleccionado = $inputs[name];
    $: asegurarSeleccion(filas);
    function asegurarSeleccion(lista) {
        const actual = get(inputs)[name];
        if (lista.length && !lista.some((f) => f[value] === actual)) {
            inputs.update((i) => ({ ...i, [name]: lista[0][value] }));
        }
    }

    function elegir(fila) {
        $inputs[name] = fila[value];
    }

    function teclado(e, fila) {
        if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            elegir(fila);
        }
    }
</script>

<div class="tabla-seleccion">
    <div class="buscador">
        <svg aria-hidden="true" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
            ><circle cx="11" cy="11" r="7" /><path d="M20 20l-3.5-3.5" /></svg
        >
        <label class="sr-only" for="buscar-{name}">{etiqueta}</label>
        <input id="buscar-{name}" type="search" bind:value={busqueda} placeholder={placeholder ?? t("buscar", lang)} />
        <span class="contador" role="status">{visibles.length} {t("de", lang)} {filas.length}</span>
    </div>
    <div class="zona" style="max-height: {alto}px">
        <table role="grid" aria-label={etiqueta}>
            <thead>
                <tr>
                    {#each columnas as c}
                        <th scope="col" class:derecha={c.alinear === "right"}>{c.titulo}</th>
                    {/each}
                </tr>
            </thead>
            <tbody>
                {#each visibles as fila (fila[value])}
                    <tr
                        role="row"
                        class:activa={fila[value] === seleccionado}
                        tabindex="0"
                        aria-selected={fila[value] === seleccionado}
                        on:click={() => elegir(fila)}
                        on:keydown={(e) => teclado(e, fila)}
                    >
                        {#each columnas as c}
                            <td role="gridcell" class:derecha={c.alinear === "right"}>{c.fmt ? c.fmt(fila[c.id], fila) : (fila[c.id] ?? "")}</td>
                        {/each}
                    </tr>
                {:else}
                    <tr><td colspan={columnas.length} class="vacio">{t("sin.resultados", lang)} «{busqueda}»</td></tr>
                {/each}
            </tbody>
        </table>
    </div>
</div>

<style>
    .tabla-seleccion {
        border: 1px solid var(--base-300);
        border-radius: 10px;
        overflow: hidden;
        margin: 0.75rem 0;
        font-size: 13px;
    }
    .buscador {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 8px 12px;
        border-bottom: 1px solid var(--base-300);
        background: var(--base-100);
        color: var(--base-content-muted, #6b7280);
    }
    .buscador:focus-within {
        box-shadow: inset 0 0 0 2px var(--primary);
    }
    .buscador input {
        flex: 1;
        border: none;
        outline: none;
        background: transparent;
        color: var(--base-content);
        font-size: 14px;
    }
    .contador {
        font-size: 12px;
        white-space: nowrap;
    }
    .zona {
        overflow-y: auto;
    }
    table {
        width: 100%;
        border-collapse: collapse;
    }
    th {
        position: sticky;
        top: 0;
        z-index: 1;
        text-align: left;
        font-weight: 600;
        padding: 6px 10px;
        background: var(--base-200);
        color: var(--base-content);
    }
    td {
        padding: 6px 10px;
        border-top: 1px solid var(--base-200);
        color: var(--base-content);
    }
    .derecha {
        text-align: right;
        white-space: nowrap;
    }
    tbody tr {
        cursor: pointer;
    }
    tbody tr:hover {
        background: var(--base-200);
    }
    tbody tr:focus-visible {
        background: var(--base-200);
        outline: 2px solid var(--primary);
        outline-offset: -2px;
    }
    tr.activa {
        background: color-mix(in srgb, var(--primary) 14%, transparent);
        box-shadow: inset 3px 0 0 var(--primary);
    }
    tr.activa td {
        font-weight: 600;
    }
    .vacio {
        text-align: center;
        padding: 16px;
        color: var(--base-content-muted, #6b7280);
    }
</style>
