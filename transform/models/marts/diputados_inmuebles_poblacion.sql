-- Comparación con la población general: % de declaraciones del IRPF con rendimientos del
-- capital inmobiliario (inmuebles arrendados o cedidos, partida 102) y con rentas
-- imputadas por inmuebles a disposición de sus titulares (segundas viviendas vacías o de
-- uso propio, partida 155), por año y tramo de rendimientos e imputaciones.
-- Fuente: AEAT, Estadística de los declarantes del IRPF, "Estadística por partidas, por
-- tramos de rendimiento" (territorio de régimen fiscal común: sin País Vasco ni Navarra).
-- OJO: la unidad es la liquidación (una declaración conjunta cuenta una vez), no la persona.
-- Se añade la fila de los diputados (colectivo 'Diputados XV') con el % que declara rentas de
-- alquiler en su declaración inicial (diputados_inmuebles_grupos, fila Total), con el año
-- del ejercicio de esas rentas (el más frecuente: 2022, declaraciones de agosto de 2023).
with aeat as (
    select
        cast(anio as integer) as anio,
        partida,
        tramo,
        liquidaciones_total,
        liquidaciones_partida,
        importe_partida_eur
    from {{ source('raw_diputados_inmuebles', 'cong_aeat_irpf_inmobiliario') }}
    where partida in ('102', '155')
),

tramos as (
    select
        a.anio,
        case when a.tramo = 'Total' then 'Declarantes IRPF (todos)'
             else 'Declarantes IRPF, rendimientos ' || a.tramo || ' mil €' end as colectivo,
        a.tramo,
        case a.partida when '102' then 'alquila' else 'inmuebles_a_disposicion' end as indicador_id,
        case a.partida
            when '102' then 'Declara rendimientos por inmuebles arrendados o cedidos'
            else 'Declara inmuebles a su disposición (sin alquilar ni vivienda habitual)'
        end as indicador,
        a.liquidaciones_partida as n,
        a.liquidaciones_total as total,
        round(100.0 * a.liquidaciones_partida / nullif(a.liquidaciones_total, 0), 1) as pct,
        round(a.importe_partida_eur / nullif(a.liquidaciones_partida, 0) * f.factor, 0) as media_real_eur,
        'AEAT, Estadística de los declarantes del IRPF (partida ' || a.partida || ')' as fuente
    from aeat a
    left join {{ ref('deflactor') }} f on f.anio = a.anio
),

diputados as (
    select
        cast(ejercicio_rentas_moda as integer) as anio,
        'Diputados XV (declaración inicial)' as colectivo,
        'Total' as tramo,
        'alquila' as indicador_id,
        'Declara rentas por alquiler de inmuebles' as indicador,
        n_alquila as n,
        n_validos as total,
        pct_alquila as pct,
        media_alquiler_real_eur as media_real_eur,
        'Congreso de los Diputados, declaraciones de Bienes y Rentas' as fuente
    from {{ ref('diputados_inmuebles_grupos') }}
    where grupo = 'Total'
)

select * from tramos
union all
select * from diputados
order by indicador_id, anio, colectivo
