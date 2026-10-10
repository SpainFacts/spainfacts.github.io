// Locale de los formatos numéricos: lo fija el layout según el idioma de la ruta
// (es-ES, en-GB, ca-ES, gl-ES, eu-ES). Se lee en cada llamada.
let LOCALE = 'es-ES';
export function fijarLocale(locale) {
    LOCALE = locale || 'es-ES';
}
export function localeActual() {
    return LOCALE;
}

export const formatNumber = (num, decimales = 2) => {
    if (num === null || num === undefined || num === '') return '-';
    const numValue = typeof num === 'string' ? parseFloat(num) : num;
    if (isNaN(numValue)) return '-';
    return new Intl.NumberFormat(LOCALE, {
        minimumFractionDigits: decimales,
        maximumFractionDigits: decimales,
        useGrouping: true
    }).format(numValue);
};

export const formatCurrency = (num) => {
    if (num === null || num === undefined || num === '') return '-';
    const numValue = typeof num === 'string' ? parseFloat(num) : num;
    if (isNaN(numValue)) return '-';
    return new Intl.NumberFormat(LOCALE, {
        style: 'currency',
        currency: 'EUR',
        useGrouping: true
    }).format(numValue);
};

// Número en texto corrido con el separador del idioma y hasta `max` decimales (40 -> "40", 55.47 -> "55,5")
export const formatDecimal = (num, max = 1) => {
    if (num === null || num === undefined || num === '') return '-';
    const numValue = typeof num === 'string' ? parseFloat(num) : num;
    if (isNaN(numValue)) return '-';
    return new Intl.NumberFormat(LOCALE, { maximumFractionDigits: max, useGrouping: 'min2' }).format(numValue);
};

// Abbreviate large numbers without using "m", which can be mistaken for metres.
export const formatCompact = (num, decimales = 1) => {
    if (num === null || num === undefined || num === '') return '-';
    const numValue = typeof num === 'string' ? parseFloat(num) : num;
    if (isNaN(numValue)) return '-';

    const formatter = new Intl.NumberFormat(LOCALE, {
        minimumFractionDigits: decimales,
        maximumFractionDigits: decimales,
        useGrouping: true
    });

    if (Math.abs(numValue) >= 1e6) {
        return formatter.format(numValue / 1e6) + ' M';
    } else if (Math.abs(numValue) >= 1e3) {
        return formatter.format(numValue / 1e3) + (LOCALE.startsWith('en') ? 'k' : ' mil');
    }
    return formatter.format(numValue);
};

// Formatear específicamente en millones
export const formatMillions = (num, decimales = 2) => {
    if (num === null || num === undefined || num === '') return '-';
    const numValue = typeof num === 'string' ? parseFloat(num) : num;
    if (isNaN(numValue)) return '-';
    return new Intl.NumberFormat(LOCALE, {
        minimumFractionDigits: decimales,
        maximumFractionDigits: decimales,
        useGrouping: true
    }).format(numValue / 1e6) + ' M';
};

// Formatear específicamente en miles
export const formatThousands = (num, decimales = 1) => {
    if (num === null || num === undefined || num === '') return '-';
    const numValue = typeof num === 'string' ? parseFloat(num) : num;
    if (isNaN(numValue)) return '-';
    return new Intl.NumberFormat(LOCALE, {
        minimumFractionDigits: decimales,
        maximumFractionDigits: decimales,
        useGrouping: true
    }).format(numValue / 1e3) + (LOCALE.startsWith('en') ? 'k' : ' mil');
};

// UI Utilities
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { cubicOut } from 'svelte/easing';

/**
 * Merges and concatenates CSS class names.
 * @param {...ClassValue[]} inputs - The class values to merge.
 * @returns {string} The merged class names.
 */
export function cn(...inputs) {
    return twMerge(clsx(inputs));
}

/**
 * Creates a transition configuration for a fly and scale animation.
 */
export const flyAndScale = (node, params = { y: -8, x: 0, start: 0.95, duration: 150 }) => {
    const style = getComputedStyle(node);
    const transform = style.transform === 'none' ? '' : style.transform;

    const scaleConversion = (valueA, scaleA, scaleB) => {
        const [minA, maxA] = scaleA;
        const [minB, maxB] = scaleB;
        const percentage = (valueA - minA) / (maxA - minA);
        const valueB = percentage * (maxB - minB) + minB;
        return valueB;
    };

    const styleToString = (style) => {
        return Object.keys(style).reduce((str, key) => {
            if (style[key] === undefined) return str;
            return str + `${key}:${style[key]};`;
        }, '');
    };

    return {
        duration: params.duration ?? 200,
        delay: 0,
        css: (t) => {
            const y = scaleConversion(t, [0, 1], [params.y ?? 5, 0]);
            const x = scaleConversion(t, [0, 1], [params.x ?? 0, 0]);
            const scale = scaleConversion(t, [0, 1], [params.start ?? 0.95, 1]);
            return styleToString({
                transform: `${transform} translate3d(${x}px, ${y}px, 0) scale(${scale})`,
                opacity: t
            });
        },
        easing: cubicOut
    };
};
