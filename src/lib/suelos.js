// Etiquetas visibles de los suelos agrarios (ingestion/suelos.py) en cada idioma: los datos
// guardan las clases en castellano; las páginas las muestran con etiquetaSuelo(tipo, valor, idioma).
// Las usan /territorios/suelos y la sección «Suelo agrario» de las fichas de territorio.

export const ETIQUETAS_SUELO = {
    "CULTIVO": {
        "es": {
            "Toda la superficie agraria": "Toda la superficie agraria",
            "Secano": "Cultivos de secano",
            "Regadío": "Regadío",
            "Arrozal": "Arrozales",
            "Viñedo": "Viñedo",
            "Frutales": "Frutales",
            "Olivar": "Olivar",
            "Prados": "Prados",
            "Mosaico de cultivos": "Mosaico de cultivos y huertas",
            "Dehesa": "Dehesas"
        },
        "en": {
            "Toda la superficie agraria": "All farmland",
            "Secano": "Rain-fed crops",
            "Regadío": "Irrigated land",
            "Arrozal": "Rice fields",
            "Viñedo": "Vineyards",
            "Frutales": "Fruit trees",
            "Olivar": "Olive groves",
            "Prados": "Meadows",
            "Mosaico de cultivos": "Mixed crops and market gardens",
            "Dehesa": "Dehesas (wood-pastures)"
        },
        "ca": {
            "Toda la superficie agraria": "Tota la superfície agrària",
            "Secano": "Conreus de secà",
            "Regadío": "Regadiu",
            "Arrozal": "Arrossars",
            "Viñedo": "Vinya",
            "Frutales": "Fruiters",
            "Olivar": "Oliverar",
            "Prados": "Prats",
            "Mosaico de cultivos": "Mosaic de conreus i hortes",
            "Dehesa": "Deveses"
        },
        "gl": {
            "Toda la superficie agraria": "Toda a superficie agraria",
            "Secano": "Cultivos de secaño",
            "Regadío": "Regadío",
            "Arrozal": "Arrozais",
            "Viñedo": "Viñedo",
            "Frutales": "Froiteiras",
            "Olivar": "Olivar",
            "Prados": "Prados",
            "Mosaico de cultivos": "Mosaico de cultivos e hortas",
            "Dehesa": "Devesas"
        },
        "eu": {
            "Toda la superficie agraria": "Nekazaritza-azalera osoa",
            "Secano": "Lehorreko laboreak",
            "Regadío": "Ureztatua",
            "Arrozal": "Arrozak",
            "Viñedo": "Mahastia",
            "Frutales": "Fruta-arbolak",
            "Olivar": "Olibadia",
            "Prados": "Belardiak",
            "Mosaico de cultivos": "Labore-mosaikoa eta baratzeak",
            "Dehesa": "Larre-basoak (dehesak)"
        }
    },
    "GRUPO": {
        "es": {
            "Arenosa (ligera)": "Arenosa (tierra ligera)",
            "Franca (media)": "Franca (tierra media)",
            "Franco-arcillosa": "Franco-arcillosa (tierra fuerte)",
            "Arcillosa (pesada)": "Arcillosa (tierra pesada)"
        },
        "en": {
            "Arenosa (ligera)": "Sandy (light soil)",
            "Franca (media)": "Loamy (medium soil)",
            "Franco-arcillosa": "Clay loam (heavy-ish soil)",
            "Arcillosa (pesada)": "Clayey (heavy soil)"
        },
        "ca": {
            "Arenosa (ligera)": "Sorrenca (terra lleugera)",
            "Franca (media)": "Franca (terra mitjana)",
            "Franco-arcillosa": "Franca argilosa (terra forta)",
            "Arcillosa (pesada)": "Argilosa (terra pesada)"
        },
        "gl": {
            "Arenosa (ligera)": "Areosa (terra lixeira)",
            "Franca (media)": "Franca (terra media)",
            "Franco-arcillosa": "Franco-arxilosa (terra forte)",
            "Arcillosa (pesada)": "Arxilosa (terra pesada)"
        },
        "eu": {
            "Arenosa (ligera)": "Hareatsua (lur arina)",
            "Franca (media)": "Frankoa (lur ertaina)",
            "Franco-arcillosa": "Franko-buztintsua (lur gogorra)",
            "Arcillosa (pesada)": "Buztintsua (lur astuna)"
        }
    },
    "TEXTURA": {
        "es": {
            "Arenosa": "Arenosa",
            "Arenoso-franca": "Arenoso-franca",
            "Franco-arenosa": "Franco-arenosa",
            "Franca": "Franca",
            "Franco-limosa": "Franco-limosa",
            "Limosa": "Limosa",
            "Franco-arcillo-arenosa": "Franco-arcillo-arenosa",
            "Franco-arcillosa": "Franco-arcillosa",
            "Franco-arcillo-limosa": "Franco-arcillo-limosa",
            "Arcillo-arenosa": "Arcillo-arenosa",
            "Arcillo-limosa": "Arcillo-limosa",
            "Arcillosa": "Arcillosa"
        },
        "en": {
            "Arenosa": "Sand",
            "Arenoso-franca": "Loamy sand",
            "Franco-arenosa": "Sandy loam",
            "Franca": "Loam",
            "Franco-limosa": "Silt loam",
            "Limosa": "Silt",
            "Franco-arcillo-arenosa": "Sandy clay loam",
            "Franco-arcillosa": "Clay loam",
            "Franco-arcillo-limosa": "Silty clay loam",
            "Arcillo-arenosa": "Sandy clay",
            "Arcillo-limosa": "Silty clay",
            "Arcillosa": "Clay"
        },
        "ca": {
            "Arenosa": "Sorrenca",
            "Arenoso-franca": "Sorrenca franca",
            "Franco-arenosa": "Franca sorrenca",
            "Franca": "Franca",
            "Franco-limosa": "Franca llimosa",
            "Limosa": "Llimosa",
            "Franco-arcillo-arenosa": "Franca argilosa sorrenca",
            "Franco-arcillosa": "Franca argilosa",
            "Franco-arcillo-limosa": "Franca argilosa llimosa",
            "Arcillo-arenosa": "Argilosa sorrenca",
            "Arcillo-limosa": "Argilosa llimosa",
            "Arcillosa": "Argilosa"
        },
        "gl": {
            "Arenosa": "Areosa",
            "Arenoso-franca": "Areoso-franca",
            "Franco-arenosa": "Franco-areosa",
            "Franca": "Franca",
            "Franco-limosa": "Franco-limosa",
            "Limosa": "Limosa",
            "Franco-arcillo-arenosa": "Franco-arxilo-areosa",
            "Franco-arcillosa": "Franco-arxilosa",
            "Franco-arcillo-limosa": "Franco-arxilo-limosa",
            "Arcillo-arenosa": "Arxilo-areosa",
            "Arcillo-limosa": "Arxilo-limosa",
            "Arcillosa": "Arxilosa"
        },
        "eu": {
            "Arenosa": "Hareatsua",
            "Arenoso-franca": "Hareatsu-frankoa",
            "Franco-arenosa": "Franko-hareatsua",
            "Franca": "Frankoa",
            "Franco-limosa": "Franko-limotsua",
            "Limosa": "Limotsua",
            "Franco-arcillo-arenosa": "Franko-buztintsu-hareatsua",
            "Franco-arcillosa": "Franko-buztintsua",
            "Franco-arcillo-limosa": "Franko-buztintsu-limotsua",
            "Arcillo-arenosa": "Buztintsu-hareatsua",
            "Arcillo-limosa": "Buztintsu-limotsua",
            "Arcillosa": "Buztintsua"
        }
    },
    "PH": {
        "es": {
            "Muy ácido (< 5,5)": "Muy ácido (menos de 5,5)",
            "Ácido (5,5-6,5)": "Ácido (5,5 a 6,5)",
            "Neutro (6,5-7,5)": "Neutro (6,5 a 7,5)",
            "Básico (7,5-8,5)": "Básico o calizo (7,5 a 8,5)",
            "Muy básico (> 8,5)": "Muy básico (más de 8,5)"
        },
        "en": {
            "Muy ácido (< 5,5)": "Very acidic (below 5.5)",
            "Ácido (5,5-6,5)": "Acidic (5.5 to 6.5)",
            "Neutro (6,5-7,5)": "Neutral (6.5 to 7.5)",
            "Básico (7,5-8,5)": "Alkaline or calcareous (7.5 to 8.5)",
            "Muy básico (> 8,5)": "Very alkaline (above 8.5)"
        },
        "ca": {
            "Muy ácido (< 5,5)": "Molt àcid (menys de 5,5)",
            "Ácido (5,5-6,5)": "Àcid (5,5 a 6,5)",
            "Neutro (6,5-7,5)": "Neutre (6,5 a 7,5)",
            "Básico (7,5-8,5)": "Bàsic o calcari (7,5 a 8,5)",
            "Muy básico (> 8,5)": "Molt bàsic (més de 8,5)"
        },
        "gl": {
            "Muy ácido (< 5,5)": "Moi ácido (menos de 5,5)",
            "Ácido (5,5-6,5)": "Ácido (5,5 a 6,5)",
            "Neutro (6,5-7,5)": "Neutro (6,5 a 7,5)",
            "Básico (7,5-8,5)": "Básico ou calcario (7,5 a 8,5)",
            "Muy básico (> 8,5)": "Moi básico (máis de 8,5)"
        },
        "eu": {
            "Muy ácido (< 5,5)": "Oso azidoa (5,5 baino gutxiago)",
            "Ácido (5,5-6,5)": "Azidoa (5,5etik 6,5era)",
            "Neutro (6,5-7,5)": "Neutroa (6,5etik 7,5era)",
            "Básico (7,5-8,5)": "Basikoa edo kareharritsua (7,5etik 8,5era)",
            "Muy básico (> 8,5)": "Oso basikoa (8,5 baino gehiago)"
        }
    },
    "WRB": {
        "es": {
            "Calcisoles": "Calcisoles",
            "Cambisoles": "Cambisoles",
            "Luvisoles": "Luvisoles",
            "Leptosoles": "Leptosoles",
            "Vertisoles": "Vertisoles",
            "Regosoles": "Regosoles",
            "Fluvisoles": "Fluvisoles",
            "Kastanozems": "Kastanozems",
            "Phaeozems": "Phaeozems",
            "Gipsisoles": "Gipsisoles",
            "Arenosoles": "Arenosoles",
            "Umbrisoles": "Umbrisoles",
            "Podzoles": "Podzoles",
            "Chernozems": "Chernozems",
            "Gleysoles": "Gleysoles",
            "Solonchaks": "Solonchaks",
            "Albeluvisoles": "Albeluvisoles",
            "Andosoles": "Andosoles",
            "Acrisoles": "Acrisoles",
            "Alisoles": "Alisoles",
            "Histosoles": "Histosoles",
            "Planosoles": "Planosoles",
            "Stagnosoles": "Stagnosoles",
            "Solonetz": "Solonetz"
        },
        "en": {
            "Calcisoles": "Calcisols",
            "Cambisoles": "Cambisols",
            "Luvisoles": "Luvisols",
            "Leptosoles": "Leptosols",
            "Vertisoles": "Vertisols",
            "Regosoles": "Regosols",
            "Fluvisoles": "Fluvisols",
            "Kastanozems": "Kastanozems",
            "Phaeozems": "Phaeozems",
            "Gipsisoles": "Gypsisols",
            "Arenosoles": "Arenosols",
            "Umbrisoles": "Umbrisols",
            "Podzoles": "Podzols",
            "Chernozems": "Chernozems",
            "Gleysoles": "Gleysols",
            "Solonchaks": "Solonchaks",
            "Albeluvisoles": "Albeluvisols",
            "Andosoles": "Andosols",
            "Acrisoles": "Acrisols",
            "Alisoles": "Alisols",
            "Histosoles": "Histosols",
            "Planosoles": "Planosols",
            "Stagnosoles": "Stagnosols",
            "Solonetz": "Solonetz"
        },
        "ca": {
            "Calcisoles": "Calcisòls",
            "Cambisoles": "Cambisòls",
            "Luvisoles": "Luvisòls",
            "Leptosoles": "Leptosòls",
            "Vertisoles": "Vertisòls",
            "Regosoles": "Regosòls",
            "Fluvisoles": "Fluvisòls",
            "Kastanozems": "Kastanozems",
            "Phaeozems": "Phaeozems",
            "Gipsisoles": "Gipsisòls",
            "Arenosoles": "Arenosòls",
            "Umbrisoles": "Umbrisòls",
            "Podzoles": "Podzòls",
            "Chernozems": "Chernozems",
            "Gleysoles": "Gleisòls",
            "Solonchaks": "Solontxacs",
            "Albeluvisoles": "Albeluvisòls",
            "Andosoles": "Andosòls",
            "Acrisoles": "Acrisòls",
            "Alisoles": "Alisòls",
            "Histosoles": "Histosòls",
            "Planosoles": "Planosòls",
            "Stagnosoles": "Stagnosòls",
            "Solonetz": "Solonetz"
        },
        "gl": {
            "Calcisoles": "Calcisolos",
            "Cambisoles": "Cambisolos",
            "Luvisoles": "Luvisolos",
            "Leptosoles": "Leptosolos",
            "Vertisoles": "Vertisolos",
            "Regosoles": "Regosolos",
            "Fluvisoles": "Fluvisolos",
            "Kastanozems": "Kastanozems",
            "Phaeozems": "Phaeozems",
            "Gipsisoles": "Xipsisolos",
            "Arenosoles": "Arenosolos",
            "Umbrisoles": "Umbrisolos",
            "Podzoles": "Podzolos",
            "Chernozems": "Chernozems",
            "Gleysoles": "Gleisolos",
            "Solonchaks": "Solonchaks",
            "Albeluvisoles": "Albeluvisolos",
            "Andosoles": "Andosolos",
            "Acrisoles": "Acrisolos",
            "Alisoles": "Alisolos",
            "Histosoles": "Histosolos",
            "Planosoles": "Planosolos",
            "Stagnosoles": "Stagnosolos",
            "Solonetz": "Solonetz"
        },
        "eu": {
            "Calcisoles": "Kaltzisolak",
            "Cambisoles": "Kanbisolak",
            "Luvisoles": "Luvisolak",
            "Leptosoles": "Leptosolak",
            "Vertisoles": "Vertisolak",
            "Regosoles": "Regosolak",
            "Fluvisoles": "Fluvisolak",
            "Kastanozems": "Kastanozemak",
            "Phaeozems": "Phaeozemak",
            "Gipsisoles": "Gipsisolak",
            "Arenosoles": "Arenosolak",
            "Umbrisoles": "Unbrisolak",
            "Podzoles": "Podzolak",
            "Chernozems": "Txernozemak",
            "Gleysoles": "Gleisolak",
            "Solonchaks": "Solontxakak",
            "Albeluvisoles": "Albeluvisolak",
            "Andosoles": "Andosolak",
            "Acrisoles": "Akrisolak",
            "Alisoles": "Alisolak",
            "Histosoles": "Histosolak",
            "Planosoles": "Planosolak",
            "Stagnosoles": "Stagnosolak",
            "Solonetz": "Solonetzak"
        }
    }
};

// tipo: 'CULTIVO', 'GRUPO' (grupo de textura), 'TEXTURA', 'PH' o 'WRB'
export function etiquetaSuelo(tipo, valor, idioma = 'es') {
    if (valor === null || valor === undefined) return '—';
    return ETIQUETAS_SUELO[tipo]?.[idioma]?.[valor] ?? ETIQUETAS_SUELO[tipo]?.es?.[valor] ?? valor;
}

export const COLOR_GRUPO_TEXTURA = {
    'Arenosa (ligera)': '#f2d48f',
    'Franca (media)': '#c8955a',
    'Franco-arcillosa': '#9a5a34',
    'Arcillosa (pesada)': '#5b2a17'
};

// Añade a cada fila las etiquetas visibles de sus columnas de clase (cultivo_txt, textura_txt,
// grupo_txt, wrb_txt) en el idioma de la página
export function etiquetasSuelo(filas, idioma = 'es') {
    return Array.from(filas ?? []).map((d) => ({
        ...d,
        cultivo_txt: d.cultivo !== undefined ? etiquetaSuelo('CULTIVO', d.cultivo, idioma) : undefined,
        textura_txt: d.textura_dominante !== undefined ? etiquetaSuelo('TEXTURA', d.textura_dominante, idioma) : undefined,
        grupo_txt: d.grupo_textura_dominante !== undefined ? etiquetaSuelo('GRUPO', d.grupo_textura_dominante, idioma) : undefined,
        wrb_txt: d.wrb_dominante !== undefined ? etiquetaSuelo('WRB', d.wrb_dominante, idioma) : undefined
    }));
}

// Filas del mapa de puntos coloreadas por grupo de textura, con las etiquetas del idioma
export function puntosPorTextura(filas, idioma = 'es') {
    return etiquetasSuelo(filas, idioma).map((d) => ({
        ...d,
        categoria: etiquetaSuelo('GRUPO', d.textura_grupo, idioma),
        color: COLOR_GRUPO_TEXTURA[d.textura_grupo] ?? '#cbd5e1',
        textura_txt: etiquetaSuelo('TEXTURA', d.textura, idioma),
        wrb_txt: etiquetaSuelo('WRB', d.wrb, idioma),
        cultivo_txt: etiquetaSuelo('CULTIVO', d.cultivo, idioma)
    })).filter((d) => d.textura_grupo);
}

// ------------------------------------------------------------------ celdas de 250 m de un municipio
// Mismo orden que TEXTURAS, WRB y CULTIVOS de ingestion/suelos.py (los ficheros guardan índices)
const TEXTURAS = ['Arenosa', 'Arenoso-franca', 'Franco-arenosa', 'Franca', 'Franco-limosa', 'Limosa',
    'Franco-arcillo-arenosa', 'Franco-arcillosa', 'Franco-arcillo-limosa', 'Arcillo-arenosa', 'Arcillo-limosa', 'Arcillosa'];
const GRUPOS = ['Arenosa (ligera)', 'Franca (media)', 'Franco-arcillosa', 'Arcillosa (pesada)'];
const WRB = ['Acrisoles', 'Albeluvisoles', 'Alisoles', 'Andosoles', 'Arenosoles', 'Calcisoles', 'Cambisoles',
    'Chernozems', 'Criosoles', 'Durisoles', 'Ferralsoles', 'Fluvisoles', 'Gleysoles', 'Gipsisoles', 'Histosoles',
    'Kastanozems', 'Leptosoles', 'Lixisoles', 'Luvisoles', 'Nitisoles', 'Phaeozems', 'Planosoles', 'Plintosoles',
    'Podzoles', 'Regosoles', 'Solonchaks', 'Solonetz', 'Stagnosoles', 'Umbrisoles', 'Vertisoles'];
const CULTIVOS = ['Secano', 'Regadío', 'Arrozal', 'Viñedo', 'Frutales', 'Olivar', 'Prados', 'Mosaico de cultivos', 'Dehesa'];

const cacheCeldas = new Map();

// Celdas de 250 m con superficie agraria de un municipio (fichero /suelos250/<cod>.json que escribe
// tools/geo/suelos250.py): filas con lat, lon, celda_km = 0,25 y las mismas columnas que el mapa de
// puntos (textura, textura_grupo, wrb, cultivo, ph, materia_organica_pct, arcilla_pct). [] si no hay.
export async function celdasMunicipio(cod) {
    if (!cod || typeof fetch === 'undefined') return [];
    if (cacheCeldas.has(cod)) return cacheCeldas.get(cod);
    let filas = [];
    try {
        const r = await fetch(`/suelos250/${cod}.json`);
        if (r.ok) {
            const j = await r.json();
            const bin = Uint8Array.from(atob(j.d), (c) => c.charCodeAt(0));
            const dv = new DataView(bin.buffer);
            const [lon0, lonC, lonF, lat0, latC, latF] = j.a;
            for (let o = 0; o + 10 <= bin.length; o += 10) {
                const c = dv.getUint16(o, true), f = dv.getUint16(o + 2, true);
                const t = bin[o + 4], w = bin[o + 5], k = bin[o + 6], ph = bin[o + 7], mo = bin[o + 8], ar = bin[o + 9];
                filas.push({
                    lon: lon0 + lonC * c + lonF * f,
                    lat: lat0 + latC * c + latF * f,
                    celda_km: j.paso / 1000,
                    superficie_agraria_km2: (j.paso / 1000) ** 2,
                    textura: t === 255 ? null : TEXTURAS[t],
                    textura_grupo: t === 255 ? null : GRUPOS[Math.floor(t / 3)],
                    wrb: w === 255 ? null : WRB[w],
                    cultivo: CULTIVOS[k] ?? null,
                    ph: ph === 0 ? null : ph / 20,
                    materia_organica_pct: mo === 255 ? null : mo / 10,
                    arcilla_pct: ar === 255 ? null : ar
                });
            }
        }
    } catch (e) {
        filas = [];
    }
    cacheCeldas.set(cod, filas);
    return filas;
}
