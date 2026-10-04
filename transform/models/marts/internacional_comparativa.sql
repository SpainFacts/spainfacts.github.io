-- España frente a otros países y agregados, formato largo: una fila por
-- indicador, país y año. cod_pais = ISO alfa-2 (EU27_2020 la UE, OECD la OCDE) con el
-- seed paises_iso; la ingesta trae el ISO3 y aquí se traduce. Países: España, Francia, Portugal, Marruecos,
-- Estados Unidos, China, Alemania e Italia; agregados: Unión Europea (EUU) y
-- OCDE (OED); y países de referencia que la web solo muestra en los indicadores
-- donde son un caso emblemático (src/lib/paisesReferencia.js): Noruega,
-- Dinamarca, Suecia, Países Bajos, Grecia, Japón, Corea del Sur e Israel
-- (es_referencia = true). Los agregados del Banco Mundial están ponderados (por población,
-- PIB...), no son medias simples de países. Los indicadores de Eurostat solo
-- tienen países europeos y la UE-27; la deuda del FMI no tiene agregado OCDE;
-- los coches eléctricos de la AIE no tienen OCDE ni Marruecos. La vivienda social
-- (OCDE PH4.2) añade Austria y Reino Unido (Inglaterra) como referencia y tiene
-- pocos años por país (hacia 2010 y hacia 2022).
-- sentido: 'positivo' si un valor mayor es mejor, 'negativo' si es peor,
-- 'neutro' si no tiene lectura clara.
with catalogo (indicador_id, nombre, unidad, apartado, sentido, fuente, url_fuente) as (
    values
    ('pib_pc_ppa', 'PIB por habitante en paridad de poder adquisitivo', 'dólares internacionales de 2021 (PPA) por habitante', 'Economía', 'positivo', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.KD'),
    ('crecimiento_pib', 'Crecimiento del PIB real', '% anual', 'Economía', 'positivo', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/NY.GDP.MKTP.KD.ZG'),
    ('inflacion', 'Inflación (IPC)', '% anual', 'Economía', 'neutro', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/FP.CPI.TOTL.ZG'),
    ('deuda_publica', 'Deuda pública bruta de las administraciones públicas', '% del PIB', 'Economía', 'negativo', 'FMI (World Economic Outlook)', 'https://www.imf.org/external/datamapper/GGXWDG_NGDP@WEO'),
    ('exportaciones_pib', 'Exportaciones de bienes y servicios', '% del PIB', 'Economía', 'positivo', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/NE.EXP.GNFS.ZS'),
    ('id_pib', 'Gasto en I+D', '% del PIB', 'Economía', 'positivo', 'Banco Mundial (WDI, UNESCO)', 'https://data.worldbank.org/indicator/GB.XPD.RSDV.GD.ZS'),
    ('turistas_por_habitante', 'Llegadas de turistas internacionales por habitante', 'turistas por habitante', 'Economía', 'neutro', 'ONU Turismo vía Our World in Data; población del Banco Mundial', 'https://ourworldindata.org/grapher/international-tourist-trips'),
    ('paro', 'Tasa de paro', '% de la población activa', 'Empleo', 'negativo', 'Banco Mundial (WDI, estimación modelizada OIT)', 'https://data.worldbank.org/indicator/SL.UEM.TOTL.ZS'),
    ('paro_juvenil', 'Tasa de paro juvenil (15-24 años)', '% de la población activa de 15 a 24 años', 'Empleo', 'negativo', 'Banco Mundial (WDI, estimación modelizada OIT)', 'https://data.worldbank.org/indicator/SL.UEM.1524.ZS'),
    ('tasa_empleo', 'Tasa de empleo (15 años o más)', '% de la población de 15 años o más', 'Empleo', 'positivo', 'Banco Mundial (WDI, estimación modelizada OIT)', 'https://data.worldbank.org/indicator/SL.EMP.TOTL.SP.ZS'),
    ('actividad_femenina', 'Tasa de actividad femenina (15 años o más)', '% de las mujeres de 15 años o más', 'Empleo', 'positivo', 'Banco Mundial (WDI, estimación modelizada OIT)', 'https://data.worldbank.org/indicator/SL.TLF.CACT.FE.ZS'),
    ('poblacion', 'Población', 'personas', 'Población', 'neutro', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/SP.POP.TOTL'),
    ('crecimiento_poblacion', 'Crecimiento de la población', '% anual', 'Población', 'neutro', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/SP.POP.GROW'),
    ('fecundidad', 'Fecundidad', 'hijos por mujer', 'Población', 'neutro', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/SP.DYN.TFRT.IN'),
    ('poblacion_65', 'Población de 65 años o más', '% de la población', 'Población', 'neutro', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/SP.POP.65UP.TO.ZS'),
    ('migrantes', 'Población nacida en el extranjero (stock de migrantes)', '% de la población', 'Población', 'neutro', 'Banco Mundial (WDI, ONU DAES)', 'https://data.worldbank.org/indicator/SM.POP.TOTL.ZS'),
    ('esperanza_vida', 'Esperanza de vida al nacer', 'años', 'Salud', 'positivo', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/SP.DYN.LE00.IN'),
    ('mortalidad_infantil', 'Mortalidad infantil', 'muertes de menores de 1 año por 1.000 nacidos vivos', 'Salud', 'negativo', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/SP.DYN.IMRT.IN'),
    ('gasto_sanitario_pc_ppa', 'Gasto sanitario corriente por habitante', 'dólares internacionales corrientes (PPA) por habitante', 'Salud', 'positivo', 'Banco Mundial (WDI, OMS)', 'https://data.worldbank.org/indicator/SH.XPD.CHEX.PP.CD'),
    ('gasto_sanitario_pib', 'Gasto sanitario corriente', '% del PIB', 'Salud', 'neutro', 'Banco Mundial (WDI, OMS)', 'https://data.worldbank.org/indicator/SH.XPD.CHEX.GD.ZS'),
    ('medicos', 'Médicos', 'por 1.000 habitantes', 'Salud', 'positivo', 'Banco Mundial (WDI, OMS)', 'https://data.worldbank.org/indicator/SH.MED.PHYS.ZS'),
    ('camas', 'Camas de hospital', 'por 1.000 habitantes', 'Salud', 'positivo', 'Banco Mundial (WDI, OMS)', 'https://data.worldbank.org/indicator/SH.MED.BEDS.ZS'),
    ('suicidios', 'Tasa de suicidio', 'por 100.000 habitantes', 'Salud', 'negativo', 'Banco Mundial (WDI, OMS)', 'https://data.worldbank.org/indicator/SH.STA.SUIC.P5'),
    ('gasto_educacion_pib', 'Gasto público en educación', '% del PIB', 'Educación', 'positivo', 'Banco Mundial (WDI, UNESCO)', 'https://data.worldbank.org/indicator/SE.XPD.TOTL.GD.ZS'),
    ('estudios_terciarios', 'Población de 25 a 64 años con estudios superiores (CINE 5-8)', '% de la población de 25 a 64 años', 'Educación', 'positivo', 'Eurostat (EPA/LFS, edat_lfse_03)', 'https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_03/default/table'),
    ('estudios_terciarios_25mas', 'Población de 25 años o más con al menos estudios superiores de ciclo corto', '% de la población de 25 años o más', 'Educación', 'positivo', 'Banco Mundial (WDI, UNESCO)', 'https://data.worldbank.org/indicator/SE.TER.CUAT.ST.ZS'),
    ('internet', 'Personas que usan internet', '% de la población', 'Educación', 'positivo', 'Banco Mundial (WDI, UIT)', 'https://data.worldbank.org/indicator/IT.NET.USER.ZS'),
    ('gini', 'Índice de Gini de la renta', 'índice 0-100', 'Desigualdad', 'negativo', 'Banco Mundial (WDI, Plataforma de Pobreza y Desigualdad)', 'https://data.worldbank.org/indicator/SI.POV.GINI'),
    ('riesgo_pobreza', 'Tasa de riesgo de pobreza (60 % de la mediana)', '% de la población', 'Desigualdad', 'negativo', 'Eurostat (EU-SILC, ilc_li02)', 'https://ec.europa.eu/eurostat/databrowser/view/ilc_li02/default/table'),
    ('homicidios', 'Homicidios intencionados', 'por 100.000 habitantes', 'Seguridad', 'negativo', 'Banco Mundial (WDI, UNODC)', 'https://data.worldbank.org/indicator/VC.IHR.PSRC.P5'),
    ('gei_pc', 'Emisiones de gases de efecto invernadero por habitante (sin LULUCF)', 't CO2 equivalente por habitante', 'Energía y clima', 'negativo', 'Banco Mundial (WDI, EDGAR)', 'https://data.worldbank.org/indicator/EN.GHG.ALL.PC.CE.AR5'),
    ('co2_pc', 'Emisiones de CO2 por habitante (sin LULUCF)', 't CO2 por habitante', 'Energía y clima', 'negativo', 'Banco Mundial (WDI, EDGAR)', 'https://data.worldbank.org/indicator/EN.GHG.CO2.PC.CE.AR5'),
    ('electricidad_renovable', 'Electricidad de origen renovable', '% de la generación eléctrica', 'Energía y clima', 'positivo', 'Ember vía Our World in Data', 'https://ourworldindata.org/grapher/share-electricity-renewables'),
    ('consumo_electrico_pc', 'Consumo eléctrico por habitante', 'kWh por habitante', 'Energía y clima', 'neutro', 'Banco Mundial (WDI)', 'https://data.worldbank.org/indicator/EG.USE.ELEC.KH.PC'),
    ('electrificacion', 'Electricidad en el consumo final de energía', '% del consumo final de energía', 'Energía y clima', 'positivo', 'Eurostat (balances energéticos, nrg_bal_c)', 'https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c/default/table'),
    ('vivienda_social_pct', 'Viviendas sociales en alquiler', '% del parque total de viviendas', 'Vivienda', 'neutro', 'OCDE (Affordable Housing Database, PH4.2)', 'https://www.oecd.org/en/data/datasets/oecd-affordable-housing-database.html'),
    ('coche_electrico_cuota', 'Coches eléctricos en las ventas de turismos nuevos', '% de los turismos nuevos (eléctricos puros e híbridos enchufables)', 'Movilidad', 'positivo', 'AIE (Global EV Data Explorer)', 'https://www.iea.org/data-and-statistics/data-tools/global-ev-data-explorer')
),

paises (cod_pais, pais, es_agregado, es_referencia, orden_pais) as (
    values
    ('ESP', 'España', false, false, 1),
    ('EUU', 'Unión Europea', true, false, 2),
    ('OED', 'OCDE', true, false, 3),
    ('FRA', 'Francia', false, false, 4),
    ('DEU', 'Alemania', false, false, 5),
    ('ITA', 'Italia', false, false, 6),
    ('PRT', 'Portugal', false, false, 7),
    ('MAR', 'Marruecos', false, false, 8),
    ('USA', 'Estados Unidos', false, false, 9),
    ('CHN', 'China', false, false, 10),
    ('NOR', 'Noruega', false, true, 11),
    ('DNK', 'Dinamarca', false, true, 12),
    ('SWE', 'Suecia', false, true, 13),
    ('NLD', 'Países Bajos', false, true, 14),
    ('GRC', 'Grecia', false, true, 15),
    ('JPN', 'Japón', false, true, 16),
    ('KOR', 'Corea del Sur', false, true, 17),
    ('ISR', 'Israel', false, true, 18),
    -- solo en vivienda social (OCDE PH4.2)
    ('AUT', 'Austria', false, true, 19),
    ('GBR', 'Reino Unido', false, true, 20)
)

select
    s.indicador_id,
    c.nombre,
    c.unidad,
    c.apartado,
    i.cod_pais,
    p.pais,
    p.es_agregado,
    p.es_referencia,
    p.orden_pais,
    s.anio,
    cast(s.valor as double) as valor,
    c.fuente,
    c.url_fuente,
    c.sentido,
    s.cod_indicador
from {{ ref('stg_internacional_series') }} s
join catalogo c using (indicador_id)
join paises p using (cod_pais)
join {{ ref('paises_iso') }} i on i.iso3 = s.cod_pais
where s.valor is not null
