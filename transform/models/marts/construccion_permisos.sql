-- Permisos de construcción y visados de obra por habitante, por año. Tres ámbitos en una tabla:
--   ambito = 'UE': países de la UE y EU27_2020 (Eurostat sts_cobp_a, raw.eurostat_construccion_permisos):
--     viviendas con permiso (residencial sin residencias colectivas, CPA_F41001_X_410014) y superficie
--     útil con permiso en edificios residenciales (CPA_F41001) y no residenciales (CPA_F41002),
--     desde 2005. Población: nama_10_pe. España en Eurostat da más viviendas que los visados de
--     obra nueva (p. ej. 2025: 200.000 frente a 139.000) porque el INE reporta otra fuente
--     (licencias); no mezclar las dos series.
--   ambito = 'CCAA': España ('00') y comunidades (código INE), visados de dirección de obra de los
--     colegios de aparejadores (Ministerio de Transportes, vía ISTAC E20006A_000002, filas anuales):
--     viviendas de obra nueva, de ampliación y de reforma, desde 2000. Sin Ceuta ni Melilla.
--     Población a 1 de enero (main.poblacion_territorios, desde 1996).
--   ambito = 'ES_LARGA': España, viviendas visadas de obra nueva y superficie a construir desde 1992
--     (Banco de España, Boletín Estadístico 23.8, suma de 12 meses; mismo dato que la fila '00'
--     de CCAA desde 2000). Población: nama_10_pe desde 1995.
-- *_1000hab: por 1.000 habitantes; m2_*_hab: metros cuadrados por habitante.
with ue_base as (
    select
        cast(anio as integer) as anio,
        pais,
        max(valor) filter (where edificio = 'CPA_F41001_X_410014' and indicador = 'BPRM_DW' and unidad = 'THS')
            as viviendas_miles,
        max(valor) filter (where edificio = 'CPA_F41001' and indicador = 'BPRM_SQM' and unidad = 'MIO_M2')
            as m2_residencial_mill,
        max(valor) filter (where edificio = 'CPA_F41002' and indicador = 'BPRM_SQM' and unidad = 'MIO_M2')
            as m2_no_residencial_mill
    from {{ source('raw_construccion', 'eurostat_construccion_permisos') }}
    group by all
),

pob_ue as (
    select cast(anio as integer) as anio, pais, miles as poblacion_miles
    from {{ source('raw_construccion', 'eurostat_construccion_poblacion') }}
),

ue as (
    select
        'UE' as ambito,
        b.pais as cod,
        n.pais_nombre as nombre,
        b.anio,
        b.viviendas_miles * 1000.0 as viviendas_nueva,
        cast(null as double) as viviendas_ampliacion,
        cast(null as double) as viviendas_reforma,
        b.viviendas_miles / nullif(p.poblacion_miles, 0) * 1000.0 as viviendas_nueva_1000hab,
        cast(null as double) as viviendas_reforma_1000hab,
        b.m2_residencial_mill / nullif(p.poblacion_miles, 0) * 1000.0 as m2_residencial_hab,
        b.m2_no_residencial_mill / nullif(p.poblacion_miles, 0) * 1000.0 as m2_no_residencial_hab,
        cast(null as double) as m2_obra_nueva_hab,
        p.poblacion_miles * 1000.0 as poblacion,
        'Eurostat sts_cobp_a (permisos)' as fuente
    from ue_base b
    left join pob_ue p using (anio, pais)
    left join {{ ref('industria_paises') }} n on n.pais = b.pais
    where coalesce(b.viviendas_miles, b.m2_residencial_mill, b.m2_no_residencial_mill) is not null
),

vis as (
    select
        m.cod_ccaa as cod,
        m.nombre,
        cast(v.anio as integer) as anio,
        max(v.viviendas) filter (where v.tipo_obra = 'OBRA_NUEVA') as nueva,
        max(v.viviendas) filter (where v.tipo_obra = 'AMPLIACION') as ampliacion,
        max(v.viviendas) filter (where v.tipo_obra = 'REFORMA_RESTAURACION') as reforma
    from {{ source('raw_construccion', 'construccion_visados_ccaa') }} v
    join {{ ref('construccion_nuts') }} m on m.nuts = v.territorio_code
    where v.mes is null
    group by all
),

pob as (
    select nivel, cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('pais', 'ccaa')
),

ccaa as (
    select
        'CCAA' as ambito,
        v.cod,
        v.nombre,
        v.anio,
        v.nueva as viviendas_nueva,
        v.ampliacion as viviendas_ampliacion,
        v.reforma as viviendas_reforma,
        1000.0 * v.nueva / p.poblacion as viviendas_nueva_1000hab,
        1000.0 * v.reforma / p.poblacion as viviendas_reforma_1000hab,
        cast(null as double) as m2_residencial_hab,
        cast(null as double) as m2_no_residencial_hab,
        cast(null as double) as m2_obra_nueva_hab,
        cast(p.poblacion as double) as poblacion,
        'Ministerio de Transportes, visados (ISTAC E20006A_000002)' as fuente
    from vis v
    asof left join pob p
      on p.nivel = case when v.cod = '00' then 'pais' else 'ccaa' end and p.cod = v.cod and p.anio <= v.anio
),

bde as (
    select
        cast(anio as integer) as anio,
        sum(valor) filter (where serie = 'D_1KB52212') as viviendas,
        sum(valor) filter (where serie = 'D_1KB52220') as m2_obra_nueva,
        count(distinct mes) as meses
    from {{ source('raw_construccion', 'construccion_bde_series') }}
    where cuadro = 'be2308' and serie in ('D_1KB52212', 'D_1KB52220')
    group by 1
),

larga as (
    select
        'ES_LARGA' as ambito,
        '00' as cod,
        'España' as nombre,
        b.anio,
        b.viviendas as viviendas_nueva,
        cast(null as double) as viviendas_ampliacion,
        cast(null as double) as viviendas_reforma,
        b.viviendas / nullif(p.poblacion_miles, 0) as viviendas_nueva_1000hab,
        cast(null as double) as viviendas_reforma_1000hab,
        cast(null as double) as m2_residencial_hab,
        cast(null as double) as m2_no_residencial_hab,
        b.m2_obra_nueva / nullif(p.poblacion_miles * 1000.0, 0) as m2_obra_nueva_hab,
        p.poblacion_miles * 1000.0 as poblacion,
        'Banco de España, Boletín Estadístico 23.8 (visados)' as fuente
    from bde b
    left join pob_ue p on p.pais = 'ES' and p.anio = b.anio
    where b.meses = 12
)

select * from ue
union all
select * from ccaa
union all
select * from larga
