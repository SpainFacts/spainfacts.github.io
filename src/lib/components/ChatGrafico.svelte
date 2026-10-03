<script>
    // Gráfico o tabla que pide el modelo en el chat (herramienta crear_grafico). El modelo
    // solo elige tipo y columnas; el dibujo, los formatos y el tema son los de la web.
    import { ECharts } from "@evidence-dev/core-components";
    import { localeActual } from "../utils.js";
    import { getCompactFormatter, getNumberFormatter } from "../chart-utils.js";

    /** @type {{ tipo: 'linea'|'barras'|'tabla', x: string, y: string, serie: string, titulo: string, filas: Record<string, any>[] }} */
    export let grafico;

    const MAX_SERIES = 12;
    const MAX_FILAS_TABLA = 200;

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

    $: ({ tipo, x, y, serie, titulo, filas } = grafico);
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
                  connectNulls: false
              }))
    };
    $: columnas = filas.length ? Object.keys(filas[0]) : [];
</script>

<figure class="my-3">
    {#if titulo}<figcaption class="text-sm font-semibold mb-1">{titulo}</figcaption>{/if}
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
        <ECharts {config} height="{horizontal ? Math.min(900, 60 + categorias.length * 22) : 340}px" />
        {#if recortadas > 0}<p class="text-xs text-gray-500 mt-1">+{recortadas}</p>{/if}
    {/if}
</figure>
