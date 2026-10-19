import { writable } from 'svelte/store';
import { browser } from '$app/environment';

/**
 * Paleta activa por defecto en toda la web.
 * Para fijar otra paleta como definitiva, basta con cambiar esta constante
 * a cualquiera de las claves de PALETAS ('azul', 'clasica', 'cobalto', 'esmeralda', 'terracota').
 */
export const PALETA_POR_DEFECTO = 'azul';

export const PALETAS = {
    azul: {
        id: 'azul',
        nombre: {
            es: 'Editorial Azul (Marfil + Azul)',
            en: 'Editorial Blue (Ivory + Blue)',
            ca: 'Editorial Blau (vori + blau)',
            gl: 'Editorial Azul (marfil + azul)',
            eu: 'Editorial Urdina (boli + urdina)'
        },
        muestra: '#2563eb'
    },
    clasica: {
        id: 'clasica',
        nombre: {
            es: 'Clásica (Blanco + Azul)',
            en: 'Classic (White + Blue)',
            ca: 'Clàssica (blanc + blau)',
            gl: 'Clásica (branco + azul)',
            eu: 'Klasikoa (zuria + urdina)'
        },
        muestra: '#1d4ed8'
    },
    cobalto: {
        id: 'cobalto',
        nombre: {
            es: 'Institucional (Marino + Cobalto)',
            en: 'Institutional (Navy + Cobalt)',
            ca: 'Institucional (marí + cobalt)',
            gl: 'Institucional (mariño + cobalto)',
            eu: 'Instituzionala (itsas urdina + kobaltoa)'
        },
        muestra: '#0f4c81'
    },
    esmeralda: {
        id: 'esmeralda',
        nombre: {
            es: 'Cívica (Pizarra + Esmeralda)',
            en: 'Civic (Slate + Emerald)',
            ca: 'Cívica (pissarra + maragda)',
            gl: 'Cívica (lousa + esmeralda)',
            eu: 'Zibikoa (arbela + esmeralda)'
        },
        muestra: '#0d9488'
    },
    terracota: {
        id: 'terracota',
        nombre: {
            es: 'Cálida (Marfil + Terracota)',
            en: 'Warm (Ivory + Terracotta)',
            ca: 'Càlida (vori + terracota)',
            gl: 'Cálida (marfil + terracota)',
            eu: 'Epela (boli + terrakota)'
        },
        muestra: '#c84b31'
    }
};

const CLAVE_STORAGE = 'sf_paleta';

function leerPaletaInicial() {
    if (!browser) return PALETA_POR_DEFECTO;
    try {
        const guardada = localStorage.getItem(CLAVE_STORAGE);
        if (guardada && PALETAS[guardada]) return guardada;
    } catch {
        /* sin acceso a localStorage */
    }
    return PALETA_POR_DEFECTO;
}

export const paletaActiva = writable(PALETA_POR_DEFECTO);

export function aplicarPaletaEnDom(id) {
    const valida = PALETAS[id] ? id : PALETA_POR_DEFECTO;
    if (browser && typeof document !== 'undefined') {
        document.documentElement.dataset.paleta = valida;
    }
}

export function inicializarPaleta() {
    const inicial = leerPaletaInicial();
    paletaActiva.set(inicial);
    aplicarPaletaEnDom(inicial);
}

export function cambiarPaleta(id) {
    if (!PALETAS[id]) return;
    paletaActiva.set(id);
    aplicarPaletaEnDom(id);
    if (browser) {
        try {
            localStorage.setItem(CLAVE_STORAGE, id);
        } catch {
            /* sin acceso a localStorage */
        }
    }
}

/**
 * Mapa de rutas principales a identificador semántico de tema
 * (usado en +layout.svelte para asignar data-tema y --sf-topic-color).
 */
export function temaDeRuta(pathname = '/') {
    const limpia = String(pathname).replace(/^\/(en|ca|gl|eu)(?=\/|$)/, '') || '/';
    const seg = limpia.split('/').filter(Boolean)[0] ?? 'inicio';
    const mapa = {
        territorios: 'territorios',
        demografia: 'demografia',
        economia: 'economia',
        vivienda: 'vivienda',
        'cuentas-publicas': 'cuentas',
        'energia-clima': 'energia',
        movilidad: 'movilidad',
        sociedad: 'sociedad',
        medios: 'medios',
        transparencia: 'transparencia',
        analisis: 'analisis',
        fuentes: 'fuentes',
        varios: 'varios'
    };
    return mapa[seg] ?? 'inicio';
}
