-- Empresas, empleo y facturación de las ramas de los medios de comunicación, España y la UE.
-- Fuente: Eurostat, estadísticas estructurales de empresas (para España, INE: Estadística
-- Estructural de Empresas del sector servicios). Dos tablas unidas: sbs_na_1a_se_r2 (2005-2020)
-- y sbs_ovw_act (2021-último, nueva metodología FRIBS); en los años que estén en las dos manda
-- la nueva. serie = 'hasta_2020' / 'desde_2021' para marcar la ruptura.
-- Ramas NACE: J5813 edición de periódicos, J5814 revistas, J601 radio, J602 televisión,
-- J6391 agencias de noticias, más los agregados J58 (incluye libros y software), J581, J59 y J60.
-- Por habitante: España con main.poblacion_territorios (1 de enero) y los demás países con la
-- población media de Eurostat (nama_10_pe, cargada por ingestion/industria.py).
-- Euros reales solo para España (deflactor IPC del INE, real = nominal * factor, euros del año base).
with datos as (
    select anio, pais, rama, indicador, valor, 'desde_2021' as serie, 1 as prioridad
    from {{ source('raw_medios_sector', 'eurostat_medios_sbs') }}
    union all
    select anio, case when pais = 'EU28' then 'EU28' else pais end, rama, indicador, valor, 'hasta_2020', 2
    from {{ source('raw_medios_sector', 'eurostat_medios_sbs_2008') }}
),
uno as (
    select * from datos
    where valor is not null
    qualify row_number() over (partition by anio, pais, rama, indicador order by prioridad) = 1
),
ancho as (
    select cast(anio as integer) as anio, pais, rama, any_value(serie) as serie,
        max(valor) filter (where indicador = 'ENT_NR') as empresas,
        max(valor) filter (where indicador = 'EMP_NR') as ocupados,
        max(valor) filter (where indicador = 'NETTUR_MEUR') as cifra_negocios_meur,
        max(valor) filter (where indicador = 'AV_MEUR') as valor_anadido_meur
    from uno
    group by all
),
pob as (
    select cast(anio as integer) as anio, pais, miles * 1000 as poblacion
    from {{ source('raw_industria', 'eurostat_industria_poblacion') }}
),
pob_es as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
)
select
    a.anio, a.pais, a.rama,
    case a.rama
        when 'J58' then 'Edición (libros, prensa y software)'
        when 'J581' then 'Edición de libros, periódicos y revistas'
        when 'J5813' then 'Periódicos'
        when 'J5814' then 'Revistas'
        when 'J59' then 'Cine, vídeo, programas de TV y música'
        when 'J60' then 'Radio y televisión'
        when 'J601' then 'Radio'
        when 'J602' then 'Televisión'
        when 'J639' then 'Otros servicios de información'
        when 'J6391' then 'Agencias de noticias'
    end as rama_nombre,
    a.serie, a.empresas, a.ocupados, a.cifra_negocios_meur, a.valor_anadido_meur,
    coalesce(case when a.pais = 'ES' then pe.poblacion end, p.poblacion) as poblacion,
    1e5 * a.ocupados / coalesce(case when a.pais = 'ES' then pe.poblacion end, p.poblacion) as ocupados_100k_hab,
    1e6 * a.cifra_negocios_meur / coalesce(case when a.pais = 'ES' then pe.poblacion end, p.poblacion) as cifra_negocios_eur_hab,
    case when a.pais = 'ES' then 1e6 * a.cifra_negocios_meur * d.factor / pe.poblacion end as cifra_negocios_eur_hab_real,
    case when a.pais = 'ES' then a.cifra_negocios_meur * d.factor end as cifra_negocios_meur_real,
    case when a.pais = 'ES' then 1e6 * a.valor_anadido_meur * d.factor / pe.poblacion end as valor_anadido_eur_hab_real,
    1e6 * a.cifra_negocios_meur / nullif(a.ocupados, 0) as cifra_negocios_eur_ocupado,
    d.anio_base
from ancho a
left join pob p on p.anio = a.anio and p.pais = a.pais
left join pob_es pe on pe.anio = a.anio and a.pais = 'ES'
left join {{ ref('deflactor') }} d on d.anio = a.anio
