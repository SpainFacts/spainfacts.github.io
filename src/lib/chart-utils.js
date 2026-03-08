
/**
 * Genera una función de formateo de números basada en el locale y opciones.
 * @param {string} locale - El código de idioma (ej: 'es-ES', 'en-US').
 * @param {object} options - Opciones de Intl.NumberFormat.
 * @returns {function} Función que acepta un valor y devuelve el string formateado.
 */
export const getNumberFormatter = (locale = 'es-ES', options = {}) => {
    return (value) => {
        if (value === null || value === undefined || isNaN(value)) return '-';
        return new Intl.NumberFormat(locale, options).format(value);
    };
};

/**
 * Genera una función de formateo compacto (K, M, etc.)
 */
export const getCompactFormatter = (locale = 'es-ES', decimals = 1) => {
    return (value) => {
        if (value === null || value === undefined || isNaN(value)) return '-';
        const abs = Math.abs(value);
        const formatter = new Intl.NumberFormat(locale, {
            minimumFractionDigits: decimals,
            maximumFractionDigits: decimals
        });

        if (abs >= 1e6) return formatter.format(value / 1e6) + ' M';
        if (abs >= 1e3) return formatter.format(value / 1e3) + ' k'; // 'k' es más estándar internacionalmente, pero puedes cambiarlo

        return new Intl.NumberFormat(locale, { maximumFractionDigits: decimals }).format(value);
    };
};

/**
 * Genera una configuración base de ECharts con los formateadores aplicados.
 */
export const getBaseChartConfig = (locale = 'es-ES') => {
    const numberFmt = getNumberFormatter(locale, { maximumFractionDigits: 2 });

    return {
        tooltip: {
            trigger: 'axis',
            valueFormatter: (value) => numberFmt(value)
        },
        yAxis: {
            axisLabel: {
                formatter: (value) => numberFmt(value)
            }
        },
        grid: {
            left: '3%',
            right: '4%',
            bottom: '3%',
            containLabel: true
        }
    };
};
