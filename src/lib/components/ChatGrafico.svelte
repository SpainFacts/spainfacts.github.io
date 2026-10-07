<script>
    // Gráfico o tabla de una respuesta del chat. El modelo (o el traductor del modo decisión)
    // solo elige tipo y columnas; el dibujo, los formatos y el tema son los de la web. Quien
    // lee puede cambiar el tipo (barras, líneas, área, tabla) y descargar los datos (CSV) o
    // el gráfico (PNG).
    import { ECharts } from "@evidence-dev/core-components";
    import { getInstanceByDom } from "echarts";
    import { localeActual } from "../utils.js";
    import { t } from "../i18n.js";
    import { getCompactFormatter, getNumberFormatter } from "../chart-utils.js";

    /** @type {{ tipo: 'linea'|'barras'|'area'|'tabla', x: string, y: string, serie: string, titulo: string, filas: Record<string, any>[], sql?: string }} */
    export let grafico;
    export let lang = "es";

    const MAX_SERIES = 12;
    const MAX_FILAS_TABLA = 200;
    const TIPOS = ["barras", "linea", "area", "tabla"];

    $: locale = localeActual();
    $: compacto = getCompactFormatter(locale, 1);
    $: numero = getNumberFormatter(locale, { maximumFractionDigits: 2 });
    const fmt = (v) => (typeof v === "number" ? numero(v) : v ?? "—");

    // Orden natural del eje X: números y fechas ascendentes, texto tal cual llega
    function ordenarX(valores) {
        const unicos = [...new Set(valores)];
        if (unicos.every((v) => typeof v === "number")) return unicos.sort((a, b) => a - b);
        if (unicos.every((v) => typeof v === "string" && /^\d{4}(-\d\d)?(-\d\d)?$/.test(v))) return unicos.sort();
        return unicos;
    }

    // Fechas de DuckDB como AAAA-MM-DD (en la tabla, el eje y el CSV) y enteros grandes como números
    const valorPlano = (v) => (v instanceof Date ? v.toISOString().slice(0, 10) : typeof v === "bigint" ? Number(v) : v);
    $: ({ x, y, serie, titulo } = grafico);
    $: filas = grafico.filas.map((f) => Object.fromEntries(Object.entries(f).map(([k, v]) => [k, valorPlano(v)])));
    // El tipo lo elige quien lee; parte del que traía la respuesta y solo vuelve a él si
    // llega otro gráfico (el chat repinta los mensajes y pasa el mismo objeto de nuevo)
    let tipo = grafico.tipo;
    let graficoAnterior = grafico;
    $: if (grafico !== graficoAnterior) {
        graficoAnterior = grafico;
        tipo = grafico.tipo;
    }
    // Solo se puede dibujar si hay eje X y cifra, y más de una fila
    $: dibujable = Boolean(x && y) && filas.length > 1;
    $: tiposPosibles = dibujable ? TIPOS : ["tabla"];
    $: categorias = ordenarX(filas.map((f) => f[x]));
    $: nombresSerie = serie ? [...new Set(filas.map((f) => f[serie]))] : [y];
    $: seriesVisibles = nombresSerie.slice(0, MAX_SERIES);
    $: recortadas = nombresSerie.length - seriesVisibles.length;

    // Formato ancho: una serie por valor de `serie`, alineada con las categorías
    $: datosSeries = seriesVisibles.map((nombre) => {
        const porX = new Map();
        for (const f of filas) if (!serie || f[serie] === nombre) porX.set(f[x], f[y]);
        return { nombre: String(nombre), valores: categorias.map((c) => (porX.has(c) ? porX.get(c) : null)) };
    });

    // Muchas barras sin series: horizontales y ordenadas de mayor a menor
    $: horizontal = tipo === "barras" && !serie && categorias.length > 10;
    $: ordenHorizontal = horizontal
        ? categorias.map((c, i) => [c, datosSeries[0].valores[i]]).sort((a, b) => (a[1] ?? -Infinity) - (b[1] ?? -Infinity))
        : null;

    $: ejeCategorias = {
        type: "category",
        data: horizontal ? ordenHorizontal.map((p) => p[0]) : categorias,
        axisLabel: { hideOverlap: true }
    };
    $: ejeValores = { type: "value", axisLabel: { formatter: (v) => compacto(v) } };

    $: config = {
        tooltip: {
            trigger: "axis",
            valueFormatter: (v) => (v === null || v === undefined ? "—" : numero(v))
        },
        legend: serie ? { type: "scroll", bottom: 0 } : undefined,
        grid: { left: 8, right: 16, top: 16, bottom: serie ? 40 : 8, containLabel: true },
        xAxis: horizontal ? ejeValores : ejeCategorias,
        yAxis: horizontal ? ejeCategorias : ejeValores,
        series: horizontal
            ? [{ type: "bar", name: y, data: ordenHorizontal.map((p) => p[1]) }]
            : datosSeries.map((s) => ({
                  type: tipo === "barras" ? "bar" : "line",
                  name: s.nombre,
                  data: s.valores,
                  showSymbol: categorias.length < 30,
                  connectNulls: false,
                  ...(tipo === "area" ? { areaStyle: { opacity: 0.25 }, ...(serie ? { stack: "total" } : {}) } : {})
              }))
    };
    $: columnas = filas.length ? Object.keys(filas[0]) : [];

    // ---------- Descargas ----------
    const nombreFichero = (ext) =>
        `${(titulo || "datos")
            .normalize("NFD")
            .replace(/[̀-ͯ]/g, "")
            .replace(/[^\w]+/g, "-")
            .replace(/^-|-$/g, "")
            .slice(0, 60)
            .toLowerCase() || "datos"}.${ext}`;

    function bajar(blob, nombre) {
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = nombre;
        document.body.appendChild(a);
        a.click();
        a.remove();
        setTimeout(() => URL.revokeObjectURL(url), 1000);
    }

    /** CSV con todas las filas y columnas (UTF-8 con BOM para que Excel lea las tildes) */
    function descargarCSV() {
        const celda = (v) => {
            if (v === null || v === undefined) return "";
            if (v instanceof Date) return v.toISOString().slice(0, 10);
            const s = typeof v === "bigint" ? v.toString() : String(v);
            return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
        };
        const lineas = [columnas.map(celda).join(","), ...filas.map((f) => columnas.map((c) => celda(f[c])).join(","))];
        bajar(new Blob(["﻿" + lineas.join("\r\n")], { type: "text/csv;charset=utf-8" }), nombreFichero("csv"));
    }

    let figura;
    /** PNG del gráfico tal como se ve, a doble resolución y con el fondo de la página */
    function descargarPNG() {
        const el = figura?.querySelector("[_echarts_instance_]");
        const instancia = el ? getInstanceByDom(el) : null;
        if (!instancia) return;
        const fondo = getComputedStyle(document.body).backgroundColor || "#ffffff";
        const url = instancia.getDataURL({ type: "png", pixelRatio: 2, backgroundColor: fondo });
        const a = document.createElement("a");
        a.href = url;
        a.download = nombreFichero("png");
        a.click();
    }
</script>

<figure class="my-3" bind:this={figura}>
    <div class="flex flex-wrap items-center justify-between gap-2 mb-1">
        {#if titulo}<figcaption class="text-sm font-semibold">{titulo}</figcaption>{:else}<span></span>{/if}
        <div class="flex flex-wrap items-center gap-1 text-xs">
            {#if tiposPosibles.length > 1}
                <div class="inline-flex rounded-md border border-gray-300 dark:border-gray-600 overflow-hidden" role="group" aria-label={t("chat.grafico.tipo", lang)}>
                    {#each tiposPosibles as tp}
                        <button type="button" on:click={() => (tipo = tp)} aria-pressed={tipo === tp}
                            class="px-2 py-0.5 {tipo === tp ? 'bg-gray-800 text-white dark:bg-gray-200 dark:text-gray-900' : 'hover:bg-gray-100 dark:hover:bg-gray-800'}">{t(`chat.grafico.${tp}`, lang)}</button>
                    {/each}
                </div>
            {/if}
            <button type="button" on:click={descargarCSV} title={t("chat.grafico.csvTitulo", lang)}
                class="rounded-md border border-gray-300 dark:border-gray-600 px-2 py-0.5 hover:bg-gray-100 dark:hover:bg-gray-800">CSV</button>
            {#if tipo !== "tabla"}
                <button type="button" on:click={descargarPNG} title={t("chat.grafico.pngTitulo", lang)}
                    class="rounded-md border border-gray-300 dark:border-gray-600 px-2 py-0.5 hover:bg-gray-100 dark:hover:bg-gray-800">PNG</button>
            {/if}
        </div>
    </div>
    {#if tipo === "tabla"}
        <div class="overflow-x-auto max-h-96 border border-gray-200 dark:border-gray-700 rounded-md">
            <table class="text-xs w-full">
                <thead class="sticky top-0 bg-gray-50 dark:bg-gray-800">
                    <tr>{#each columnas as c}<th class="text-left font-semibold px-2 py-1">{c}</th>{/each}</tr>
                </thead>
                <tbody>
                    {#each filas.slice(0, MAX_FILAS_TABLA) as f}
                        <tr class="border-t border-gray-100 dark:border-gray-800">
                            {#each columnas as c}<td class="px-2 py-1 {typeof f[c] === 'number' ? 'text-right tabular-nums' : ''}">{fmt(f[c])}</td>{/each}
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
        {#if filas.length > MAX_FILAS_TABLA}<p class="text-xs text-gray-500 mt-1">{MAX_FILAS_TABLA} / {filas.length}</p>{/if}
    {:else}
        {#key tipo}
            <ECharts {config} height="{horizontal ? Math.min(900, 60 + categorias.length * 22) : 340}px" />
        {/key}
        {#if recortadas > 0}<p class="text-xs text-gray-500 mt-1">+{recortadas}</p>{/if}
    {/if}
</figure>
