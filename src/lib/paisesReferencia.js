// Países de referencia por indicador internacional (mart internacional_ultimo).
// Comparativa.svelte los añade, destacados discretamente, a los países fijos
// (UE, OCDE, Francia, Portugal, Alemania, Italia, Marruecos, EE. UU. y China)
// solo en el indicador donde son un caso emblemático: el líder, el extremo o el
// ejemplo que se suele citar. Máximo tres por indicador para no recargar la línea.
// Si el país no tiene dato de ese indicador (p. ej. Japón en los de Eurostat),
// simplemente no aparece.
// Países con datos en la ingesta: NO, DK, SE, NL, GR, JP, KR, IL
// (y AT y GB solo en vivienda_social_pct)
// (ingestion/internacional.py, PAISES_REFERENCIA). Para añadir otro, amplía
// también esa lista, la tabla `paises` de internacional_comparativa y las claves
// `pais.XX` de src/lib/i18n.js (ISO alfa-2).

export const PAISES_REFERENCIA = {
    // Movilidad y energía
    coche_electrico_cuota: ['NO', 'DK'], // Noruega: casi todo lo que se vende es eléctrico; Dinamarca, segundo de Europa (China ya está)
    electrificacion: ['NO', 'SE'], // Noruega y Suecia: las economías más electrificadas de Europa (hidráulica, bombas de calor, coche eléctrico)
    electricidad_renovable: ['DK', 'NO'], // Dinamarca: referente eólico; Noruega: casi toda su electricidad es hidráulica
    consumo_electrico_pc: ['NO'], // Noruega: el mayor consumo eléctrico por habitante de Europa (calefacción y coche eléctricos)
    gei_pc: ['SE'], // Suecia: país rico con emisiones por habitante muy bajas
    co2_pc: ['SE'],

    // Población y salud
    esperanza_vida: ['JP', 'KR'], // Japón: la esperanza de vida más alta; Corea del Sur, la que más ha subido
    poblacion_65: ['JP'], // Japón: la población más envejecida del mundo
    crecimiento_poblacion: ['JP'], // Japón: población en declive desde 2010
    fecundidad: ['KR'], // Corea del Sur: la fecundidad más baja del mundo (Francia, la más alta de la UE, ya está)
    mortalidad_infantil: ['JP', 'SE'], // Japón y Suecia: de las más bajas del mundo
    suicidios: ['KR'], // Corea del Sur: la tasa más alta de la OCDE
    camas: ['JP', 'KR'], // Japón y Corea: los sistemas con más camas por habitante

    // Economía y empleo
    paro: ['NL'], // Países Bajos: de los paros más bajos de la UE (Alemania ya está)
    paro_juvenil: ['NL', 'GR'], // Países Bajos: de los paros juveniles más bajos de la UE; Grecia: el caso comparable del sur
    tasa_empleo: ['NL', 'SE'], // Países Bajos y Suecia: las tasas de empleo más altas de la UE
    actividad_femenina: ['SE', 'NL'], // Suecia y Países Bajos: las tasas de actividad femenina más altas de la UE
    id_pib: ['KR', 'IL'], // Corea del Sur e Israel: los que más invierten en I+D del mundo
    deuda_publica: ['JP', 'GR'], // Japón: la mayor deuda de los países ricos; Grecia: la mayor de la UE
    exportaciones_pib: ['NL'], // Países Bajos: gran economía exportadora (puerto de Róterdam)
    turistas_por_habitante: ['GR'], // Grecia: destino mediterráneo comparable, con aún más turistas por habitante

    // Sociedad
    gini: ['NO', 'NL'], // Noruega y Países Bajos: de las rentas más igualitarias del mundo rico
    riesgo_pobreza: ['NO', 'DK'], // Noruega y Dinamarca: el menor riesgo de pobreza con este umbral
    estudios_terciarios: ['SE'], // Suecia: la mitad de los adultos con estudios superiores
    estudios_terciarios_25mas: ['KR'], // Corea del Sur: la expansión universitaria más rápida (casi la mitad de los adultos)
    gasto_educacion_pib: ['SE'], // Suecia: de los que más gastan en educación pública

    // Vivienda
    vivienda_social_pct: ['NL', 'AT', 'DK'] // Países Bajos, Austria y Dinamarca: los mayores parques de vivienda social de Europa (Reino Unido, en la página)
};

/** ISO alfa-2 de los países de referencia de un indicador ([] si no tiene) */
export const paisesReferencia = (indicadorId) => PAISES_REFERENCIA[indicadorId] ?? [];
