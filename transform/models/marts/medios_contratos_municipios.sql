-- Contratos adjudicados a empresas de medios por los ayuntamientos (y sus organismos
-- y empresas cuando el órgano lleva el DIR3 o el NIF del municipio), por municipio y
-- año. Fuente: PLACSP (Ministerio de Hacienda) y, para los menores que PLACSP no trae,
-- plataformas autonómicas y municipales (Cataluña, Euskadi, Ayuntamiento de Madrid,
-- Barcelona 2018: fuente_plataforma), ver medios_contratos_base.
-- - Solo municipios con órgano identificado (cod_municipio); las diputaciones,
--   cabildos, consejos comarcales y mancomunidades no se reparten por municipio.
-- - Columnas principales: medios privados con es_medio = 'si' y sin importes
--   sospechosos; aparte, los NIF grises y los medios públicos.
-- - eur_hab_real = euros de 2025 por habitante del municipio (padrón INE,
--   poblacion_municipios; fuera del rango de años, el más cercano).
-- - familia / alcalde: el que estaba en el cargo a 1 de julio del año
--   (alcaldes_historia), si casa.
-- - OJO: muchos ayuntamientos grandes no publican sus menores en PLACSP (Zaragoza,
--   Gijón, Oviedo, A Coruña, Vigo, València, Valladolid...); los catalanes (desde 2021) y
--   vascos (KontratazioA) y el de Madrid se añaden desde sus plataformas, pero faltan los
--   menores de los navarros y de los demás madrileños, y los catalanes de 2018-2020 (salvo
--   Barcelona 2018): un cero no es gasto cero.
with b as (
    select * from {{ ref('medios_contratos_base') }}
    where cod_municipio is not null and ambito = 'local' and anio >= 2018
),

agregado as (
    select cod_municipio, anio,
        sum(importe_adjudicado_sin_iva) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as importe_eur_nominal,
        sum(importe_eur_real) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as importe_eur_real,
        count(*) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as n_contratos,
        count(*) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso and es_menor) as n_menores,
        sum(importe_eur_real) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso and categoria = 'patrocinio_eventos') as importe_patrocinio_eventos_eur_real,
        sum(importe_eur_real) filter (where es_medio = 'gris' and not sospechoso) as importe_gris_eur_real,
        sum(importe_eur_real) filter (where es_medio = 'si' and titularidad = 'publica' and not sospechoso) as importe_publicos_eur_real,
        string_agg(distinct grupo, ', ') filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as grupos,
        sum(importe_eur_real) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso and fuente_plataforma <> 'placsp') as importe_autonomicas_eur_real,
        string_agg(distinct fuente_plataforma, ', ' order by fuente_plataforma) filter (where es_medio = 'si' and titularidad = 'privada' and not sospechoso) as fuente_plataforma
    from b
    group by all
),

pob as (
    select cod_mun, cast(anio as integer) as anio, municipio, cod_ccaa, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

rango_pob as (
    select min(anio) as amin, max(anio) as amax from pob
),

nombres as (
    select cod_mun, any_value(municipio order by anio desc) as municipio, any_value(cod_ccaa order by anio desc) as cod_ccaa
    from pob group by cod_mun
),

alc as (
    select cod_mun, fecha_posesion, coalesce(fecha_fin, date '2100-01-01') as fecha_fin, alcalde, familia, color
    from {{ ref('alcaldes_historia') }}
)

select
    a.cod_municipio,
    n.municipio,
    n.cod_ccaa,
    a.anio,
    coalesce(a.importe_eur_nominal, 0) as importe_eur_nominal,
    coalesce(a.importe_eur_real, 0) as importe_eur_real,
    coalesce(a.importe_eur_real, 0) / p.poblacion as eur_hab_real,
    cast(coalesce(a.n_contratos, 0) as integer) as n_contratos,
    cast(coalesce(a.n_menores, 0) as integer) as n_menores,
    coalesce(a.importe_patrocinio_eventos_eur_real, 0) as importe_patrocinio_eventos_eur_real,
    coalesce(a.importe_gris_eur_real, 0) as importe_gris_eur_real,
    coalesce(a.importe_publicos_eur_real, 0) as importe_publicos_eur_real,
    a.grupos,
    coalesce(a.importe_autonomicas_eur_real, 0) as importe_autonomicas_eur_real,
    a.fuente_plataforma,
    cast(p.poblacion as bigint) as poblacion,
    l.familia,
    l.alcalde,
    l.color
from agregado a
cross join rango_pob r
left join nombres n on n.cod_mun = a.cod_municipio
left join pob p on p.cod_mun = a.cod_municipio and p.anio = greatest(least(a.anio, r.amax), r.amin)
left join alc l on l.cod_mun = a.cod_municipio
    and l.fecha_posesion <= make_date(a.anio, 7, 1) and l.fecha_fin > make_date(a.anio, 7, 1)
qualify row_number() over (partition by a.cod_municipio, a.anio order by l.fecha_posesion desc nulls last) = 1
order by a.anio, eur_hab_real desc
