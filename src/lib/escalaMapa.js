// Escala de color de los mapas de coropletas (MapaEspana y MapaBarrios), como en wikibarrio.es:
// - los extremos se cortan en los percentiles 5 y 95 (un valor raro ya no apaga el resto del mapa);
//   con menos de 30 valores se usan el mínimo y el máximo;
// - el color del medio de la paleta cae en la mediana, así la mitad del mapa queda a cada lado;
// - con una paleta divergente (centro casi blanco) y datos a los dos lados del 0, el centro es el 0;
// - si la página fija min y max, se respeta una escala lineal entre ellos;
// - `referencia` ({p05, p50, p95}) sustituye a los datos del mapa: p. ej. la escala de toda España
//   en un mapa de un solo municipio.

export function cuantil(ordenados, p) {
    if (!ordenados.length) return NaN;
    const x = (ordenados.length - 1) * p;
    const i = Math.floor(x);
    const f = x - i;
    return i + 1 < ordenados.length ? ordenados[i] + (ordenados[i + 1] - ordenados[i]) * f : ordenados[i];
}

function luminancia(c) {
    const m = String(c ?? '').trim().match(/^#?([0-9a-f]{3}|[0-9a-f]{6})$/i);
    if (!m) return 0;
    let h = m[1];
    if (h.length === 3) h = h.split('').map((x) => x + x).join('');
    const [r, g, b] = [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16));
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255;
}

/** Paleta divergente: número impar de colores con el del medio casi blanco */
export function esDivergente(paleta) {
    if (!paleta || paleta.length < 3 || paleta.length % 2 === 0) return false;
    return luminancia(paleta[(paleta.length - 1) / 2]) > 0.95;
}

const num = (v) => v !== null && v !== undefined && v !== '' && Number.isFinite(Number(v));

export function calcularEscala({ numeros = [], min, max, centro, referencia, paleta = [] }) {
    const orden = numeros.filter(Number.isFinite).sort((a, b) => a - b);
    const n = orden.length;
    let lo, mid, hi;
    let esMediana = true;
    if (referencia && num(referencia.p05) && num(referencia.p95) && Number(referencia.p95) > Number(referencia.p05)) {
        lo = Number(referencia.p05);
        hi = Number(referencia.p95);
        mid = num(referencia.p50) ? Number(referencia.p50) : (lo + hi) / 2;
    } else {
        const pocos = n < 30;
        lo = num(min) ? Number(min) : n ? (pocos ? orden[0] : cuantil(orden, 0.05)) : 0;
        hi = num(max) ? Number(max) : n ? (pocos ? orden[n - 1] : cuantil(orden, 0.95)) : 1;
        if (num(centro)) {
            mid = Number(centro);
            esMediana = false;
        } else if (esDivergente(paleta) && lo < 0 && hi > 0) {
            mid = 0;
            esMediana = false;
        } else if (num(min) && num(max)) {
            mid = (lo + hi) / 2;
            esMediana = false;
        } else {
            mid = n ? cuantil(orden, 0.5) : (lo + hi) / 2;
        }
    }
    if (hi < lo) [lo, hi] = [hi, lo];
    mid = Math.min(hi, Math.max(lo, mid));
    // Mediana pegada a un extremo (p. ej. la mitad de las secciones con 0 % de un partido):
    // escala lineal, si no casi todo el mapa saldría del color central
    if (hi > lo && (mid <= lo || mid >= hi)) {
        mid = (lo + hi) / 2;
        esMediana = false;
    }
    const t = (v) => {
        const x = Number(v);
        if (!Number.isFinite(x)) return null;
        if (hi === lo) return 0.5;
        if (x <= mid) return Math.max(0, 0.5 * ((x - lo) / (mid - lo)));
        return Math.min(1, 0.5 + 0.5 * ((x - mid) / (hi - mid)));
    };
    return {
        lo,
        mid,
        hi,
        esMediana,
        cortaAbajo: n > 0 && orden[0] < lo,
        cortaArriba: n > 0 && orden[n - 1] > hi,
        t
    };
}

/** Color de una paleta en la posición t (0-1), interpolando en RGB */
export function colorEn(paleta, t) {
    if (!paleta?.length) return '#3b82f6';
    if (paleta.length === 1) return paleta[0];
    const hex = (c) => {
        const m = String(c).trim().match(/^#?([0-9a-f]{3}|[0-9a-f]{6})$/i);
        if (!m) return [148, 163, 184];
        let h = m[1];
        if (h.length === 3) h = h.split('').map((x) => x + x).join('');
        return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16));
    };
    const x = Math.min(1, Math.max(0, t)) * (paleta.length - 1);
    const i = Math.min(paleta.length - 2, Math.floor(x));
    const a = hex(paleta[i]), b = hex(paleta[i + 1]), f = x - i;
    return '#' + a.map((v, j) => Math.round(v + (b[j] - v) * f).toString(16).padStart(2, '0')).join('');
}

/** Id del patrón de rayado para «sin datos» (cada mapa incluye el suyo, idéntico) */
export const RAYADO = 'mapa-rayado-sin-datos';
