-- Indicadores trimestrales del mercado laboral de España (INE, Encuesta de
-- Población Activa), una fila por trimestre desde 2002:
--   tasas de paro, empleo y actividad (tabla 65349), paro de menores de 25
--   años (65334), de españoles y extranjeros (65336);
--   pct_parados_larga: % de los parados que llevan un año o más buscando
--   empleo (65236); tasa_paro_larga = tasa_paro x pct_parados_larga / 100, es
--   decir, parados de larga duración en % de la población activa;
--   pct_hogares_todos_parados: % de hogares con al menos un activo en los que
--   todos los activos están en paro (65276);
--   tasa_temporalidad: % de asalariados con contrato temporal (65194);
--   pct_parcial_involuntario: % de ocupados a tiempo parcial que lo están por
--   no haber encontrado un trabajo a jornada completa (65152, desde 2005).
-- Los datos no están desestacionalizados: compárese cada trimestre con el
-- mismo del año anterior. Cifras absolutas en personas (el INE da miles).
with p as (
    select 'provincia' as t, date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)) as trimestre,
           string_split(rtrim(serie, '. '), '. ') as partes, valor
    from {{ source('raw_mercado', 'ine_epa_tasas_provincia') }} where valor is not null
    union all
    select 'edad', date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)),
           string_split(rtrim(serie, '. '), '. '), valor
    from {{ source('raw_mercado', 'ine_epa_paro_edad_ccaa') }} where valor is not null
    union all
    select 'nacionalidad', date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)),
           string_split(rtrim(serie, '. '), '. '), valor
    from {{ source('raw_mercado', 'ine_epa_paro_nacionalidad') }} where valor is not null
    union all
    select 'busqueda', date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)),
           string_split(rtrim(serie, '. '), '. '), valor
    from {{ source('raw_mercado', 'ine_epa_parados_busqueda') }} where valor is not null
    union all
    select 'hogares', date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)),
           string_split(rtrim(serie, '. '), '. '), valor
    from {{ source('raw_mercado', 'ine_epa_hogares_paro') }} where valor is not null
    union all
    select 'contrato', date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)),
           string_split(rtrim(serie, '. '), '. '), valor
    from {{ source('raw_mercado', 'ine_epa_asalariados_contrato') }} where valor is not null
    union all
    select 'parcial', date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)),
           string_split(rtrim(serie, '. '), '. '), valor
    from {{ source('raw_mercado', 'ine_epa_parcial_motivo') }} where valor is not null
),

nac as (
    select * from p
    where list_contains(partes, 'Total Nacional')
      and (list_contains(partes, 'Ambos sexos') or t = 'hogares')
),

ancho as (
    select
        trimestre,
        max(valor) filter (where t = 'provincia' and partes[1] = 'Tasa de paro de la población') as tasa_paro,
        max(valor) filter (where t = 'provincia' and partes[1] = 'Tasa de empleo de la población') as tasa_empleo,
        max(valor) filter (where t = 'provincia' and partes[1] = 'Tasa de actividad') as tasa_actividad,
        max(valor) filter (where t = 'edad' and list_contains(partes, 'Menores de 25 años')) as tasa_paro_menor25,
        max(valor) filter (where t = 'nacionalidad' and list_contains(partes, 'Española')) as tasa_paro_espanoles,
        max(valor) filter (where t = 'nacionalidad' and list_contains(partes, 'Extranjera: Total')) as tasa_paro_extranjeros,
        max(valor) filter (where t = 'busqueda' and partes[4] = 'Total' and partes[5] = 'Valor absoluto') * 1000 as parados,
        sum(valor) filter (where t = 'busqueda' and partes[5] = 'Porcentaje'
                           and partes[4] in ('De 1 año a menos de 2 años', '2 años o más')) as pct_parados_larga,
        max(valor) filter (where t = 'hogares' and partes[4] like 'Todos los activos son parados%') as pct_hogares_todos_parados,
        max(valor) filter (where t = 'contrato' and partes[4] = 'Temporal: Total' and partes[5] = 'Porcentaje') as tasa_temporalidad,
        max(valor) filter (where t = 'contrato' and partes[4] = 'Total' and partes[5] = 'Valor absoluto') * 1000 as asalariados,
        max(valor) filter (where t = 'parcial' and partes[5] = 'Total' and partes[6] = 'Total') * 1000 as ocupados_parcial,
        max(valor) filter (where t = 'parcial' and partes[5] = 'Total'
                           and partes[6] = 'No haber podido encontrar trabajo de jornada completa') * 1000 as parcial_involuntario
    from nac
    group by trimestre
)

select
    trimestre,
    cast(year(trimestre) as integer) as anio,
    cast(quarter(trimestre) as integer) as trim,
    cast(year(trimestre) as varchar) || '-T' || cast(quarter(trimestre) as varchar) as periodo,
    tasa_paro,
    tasa_empleo,
    tasa_actividad,
    tasa_paro_menor25,
    tasa_paro_espanoles,
    tasa_paro_extranjeros,
    parados,
    pct_parados_larga,
    tasa_paro * pct_parados_larga / 100 as tasa_paro_larga,
    pct_hogares_todos_parados,
    tasa_temporalidad,
    asalariados,
    ocupados_parcial,
    parcial_involuntario,
    100 * parcial_involuntario / ocupados_parcial as pct_parcial_involuntario,
    tasa_paro - lag(tasa_paro, 4) over (order by trimestre) as tasa_paro_dif_anual
from ancho
where tasa_paro is not null
