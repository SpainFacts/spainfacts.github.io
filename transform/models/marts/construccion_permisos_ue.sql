-- Permisos de construcción por habitante en los países de la UE y la UE-27 (Eurostat sts_cobp_a,
-- raw.eurostat_construccion_permisos), desde 2005: viviendas con permiso (residencial sin
-- residencias colectivas, CPA_F41001_X_410014) y superficie útil con permiso en edificios
-- residenciales (CPA_F41001) y no residenciales (CPA_F41002). Población: nama_10_pe.
-- España en Eurostat da más viviendas que los visados de obra nueva (p. ej. 2025: 200.000 frente
-- a 139.000) porque el INE reporta otra fuente (licencias): no mezclar con construccion_permisos.
-- cod_pais / pais: seed paises_iso (ISO 3166-1 alfa-2; EU27_2020 la UE-27).
-- viviendas_nueva_1000hab: por 1.000 habitantes; m2_*_hab: metros cuadrados por habitante.
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
)

select
    n.cod_pais,
    n.pais,
    b.anio,
    b.viviendas_miles * 1000.0 as viviendas_nueva,
    b.viviendas_miles / nullif(p.poblacion_miles, 0) * 1000.0 as viviendas_nueva_1000hab,
    b.m2_residencial_mill / nullif(p.poblacion_miles, 0) * 1000.0 as m2_residencial_hab,
    b.m2_no_residencial_mill / nullif(p.poblacion_miles, 0) * 1000.0 as m2_no_residencial_hab,
    p.poblacion_miles * 1000.0 as poblacion
from ue_base b
left join pob_ue p using (anio, pais)
join {{ ref('paises_iso') }} n on n.eurostat = b.pais
where coalesce(b.viviendas_miles, b.m2_residencial_mill, b.m2_no_residencial_mill) is not null
order by n.cod_pais, b.anio
