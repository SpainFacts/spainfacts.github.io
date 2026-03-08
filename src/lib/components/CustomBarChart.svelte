<script>
    import { ECharts } from "@evidence-dev/core-components";
    import { getNumberFormatter, getCompactFormatter } from "../chart-utils.js";

    export let data;
    export let x;
    export let y;
    export let y2 = undefined;
    export let title = undefined;
    export let yAxisTitle = undefined;
    export let locale = "es-ES"; // Por defecto español, pero configurable

    // Preparar datos
    $: xData = data.map((d) => d[x]);
    $: yData = data.map((d) => d[y]);
    $: y2Data = y2 ? data.map((d) => d[y2]) : [];

    // Crear formateadores basados en el locale seleccionado
    $: numFmt = getNumberFormatter(locale, {
        minimumFractionDigits: 0,
        maximumFractionDigits: 2,
    });
    $: compactFmt = getCompactFormatter(locale, 1);
    $: percentFmt = (val) =>
        getNumberFormatter(locale, {
            minimumFractionDigits: 1,
            maximumFractionDigits: 1,
        })(val) + "%";

    // Calcular min/max para alinear el cero manualmente
    $: yMax = Math.max(...yData);
    $: yMin = Math.min(...yData);
    $: y2Max = y2 ? Math.max(...y2Data) : 0;
    $: y2Min = y2 ? Math.min(...y2Data) : 0;

    // Determinar el ratio máximo necesario para acomodar los datos positivos y negativos
    $: maxRatio = Math.max(
        yMax > 0 ? yMax / (yMax - Math.min(0, yMin)) : 0,
        y2Max > 0 ? y2Max / (y2Max - Math.min(0, y2Min)) : 0,
    );

    // O simplemente forzar que el ratio positivo/negativo sea el mismo en ambos ejes
    // Una forma robusta es hacer que ambos ejes sean simétricos o tengan el mismo ratio max/min si cruzan el cero.
    // Pero ECharts alignTicks debería funcionar. Si no, probemos a quitarlo y dejar que ECharts decida, o forzar min/max.

    // Estrategia de alineación proporcional:
    // Calculamos la proporción de espacio que debe ocupar la parte positiva y negativa
    // para que el cero coincida en ambos ejes, sin forzar simetría total.

    // 1. Determinar los rangos actuales
    // yMax, yMin, y2Max, y2Min ya están calculados arriba.

    // 2. Calcular las fracciones de rango positivo y negativo necesarias
    // Queremos que: yMax / (yMax - yMin) = y2Max / (y2Max - y2Min) si ambos cruzan el cero.
    // O más simple: asegurarnos de que el ratio Max/Min sea el mismo en ambos.

    // Si solo uno cruza el cero, es más complejo, pero asumamos que queremos alinear el cero.

    $: alignZeros = (yMin < 0 && yMax > 0) || (y2Min < 0 && y2Max > 0);

    // Si vamos a alinear, necesitamos ajustar los límites.
    // Calculamos el ratio "positivo / rango total" más restrictivo (el que pide más espacio para un lado)
    // Ratio = Max / (Max - Min)  <-- Porcentaje del eje que está por encima de cero

    // Para el eje 1:
    $: r1 = yMax > 0 && yMin < 0 ? yMax / (yMax - yMin) : yMin >= 0 ? 1 : 0;
    // Para el eje 2:
    $: r2 =
        y2Max > 0 && y2Min < 0 ? y2Max / (y2Max - y2Min) : y2Min >= 0 ? 1 : 0;

    // Si ambos son "mixtos" (cruzan cero), usamos el ratio que requiera "más espacio arriba" o "más espacio abajo" para no cortar datos.
    // Pero es más fácil ajustar los topes.

    // Algoritmo simple: Escalar el eje "menor" para que coincida con la proporción del "mayor".

    // Vamos a usar una función auxiliar reactiva para calcular los límites finales
    $: limits = (() => {
        if (!y2 || !alignZeros)
            return {
                min1: undefined,
                max1: undefined,
                min2: undefined,
                max2: undefined,
            };

        let min1 = yMin,
            max1 = yMax;
        let min2 = y2Min,
            max2 = y2Max;

        // Añadir un pequeño margen (ej. 5%) para que las barras no toquen el borde
        const margin1 = (max1 - min1) * 0.05;
        max1 += margin1;
        if (min1 < 0) min1 -= margin1;
        else min1 = 0; // Si es positivo, el min suele ser 0 en barras

        const margin2 = (max2 - min2) * 0.05;
        max2 += margin2;
        if (min2 < 0) min2 -= margin2;
        else min2 = 0;

        // Ratios de la parte positiva sobre la parte negativa (valor absoluto)
        // Ratio = Max / |Min|
        const ratio1 = min1 !== 0 ? max1 / Math.abs(min1) : Infinity;
        const ratio2 = min2 !== 0 ? max2 / Math.abs(min2) : Infinity;

        // Queremos igualar los ratios. El que tenga el ratio menor (más parte negativa proporcionalmente) manda,
        // o el que tenga el ratio mayor (más parte positiva).
        // Para no cortar datos, debemos aumentar el rango del "otro" lado.

        if (ratio1 > ratio2) {
            // El eje 1 tiene más parte positiva relativa. Debemos aumentar la parte positiva del eje 2.
            // Nuevo Max2 = Ratio1 * |Min2|
            if (min2 !== 0) max2 = ratio1 * Math.abs(min2);
        } else if (ratio2 > ratio1) {
            // El eje 2 tiene más parte positiva relativa. Aumentamos la parte positiva del eje 1.
            if (min1 !== 0) max1 = ratio2 * Math.abs(min1);
        }

        // Nota: Esto asume que ambos tienen parte negativa. Si uno es todo positivo y el otro no,
        // ECharts suele manejarlo bien, pero para alinear el 0, el todo positivo debe empezar en 0.

        return { min1, max1, min2, max2 };
    })();

    // Estrategia de alineación manual: Forzar simetría si hay valores negativos
    // Esto asegura que el 0 esté siempre en el centro si hay negativos y positivos

    $: yAbsMax = Math.max(Math.abs(yMax), Math.abs(yMin));
    $: y2AbsMax = Math.max(Math.abs(y2Max), Math.abs(y2Min));

    // Solo aplicamos simetría si hay valores negativos en alguno de los ejes para forzar el 0 al centro
    $: useSymmetry = yMin < 0 || y2Min < 0;

    // Si alignTicks falló, probemos a quitarlo y usar una configuración más simple primero,
    // o tal vez el problema es que los datos son muy dispares.

    // Vamos a intentar quitar alignTicks primero si el usuario dice que se ve PEOR.

    $: config = {
        title: {
            text: title,
            left: "center",
            textStyle: { fontSize: 16 },
        },
        tooltip: {
            trigger: "axis",
            formatter: function (params) {
                return params
                    .map((p) => {
                        let valStr;
                        if (y2 && p.seriesIndex === 0) {
                            valStr = percentFmt(p.value);
                        } else if (y2 && p.seriesIndex === 1) {
                            valStr = compactFmt(p.value);
                        } else {
                            valStr = numFmt(p.value);
                        }
                        return `${p.marker} ${p.seriesName}: <b>${valStr}</b>`;
                    })
                    .join("<br/>");
            },
        },
        legend: {
            data: [y, y2].filter(Boolean),
            bottom: 0,
        },
        grid: {
            left: "3%",
            right: "4%",
            bottom: "10%",
            containLabel: true,
        },
        xAxis: {
            type: "category",
            data: xData,
        },
        yAxis: [
            {
                type: "value",
                name: yAxisTitle,
                min: limits.min1,
                max: limits.max1,
                axisLabel: {
                    formatter: (value) =>
                        y2 ? percentFmt(value) : compactFmt(value),
                },
            },
            y2
                ? {
                      type: "value",
                      position: "right",
                      min: limits.min2,
                      max: limits.max2,
                      // alignTicks: true, // REMOVED as it made it worse
                      axisLabel: {
                          formatter: (value) => compactFmt(value),
                      },
                      splitLine: { show: false },
                  }
                : undefined,
        ].filter(Boolean),
        series: [
            {
                name: y,
                type: "bar",
                data: yData,
                itemStyle: { color: "#2563eb" },
            },
            y2
                ? {
                      name: y2,
                      type: "bar",
                      yAxisIndex: 1,
                      data: y2Data,
                      itemStyle: {
                          color: "rgba(255, 165, 0, 0.3)",
                          borderColor: "rgba(255, 165, 0, 1)",
                          borderWidth: 2,
                      },
                  }
                : undefined,
        ].filter(Boolean),
    };
</script>

<div class="w-full h-80">
    <ECharts {config} />
</div>
