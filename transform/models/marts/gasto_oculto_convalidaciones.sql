-- Convalidaciones de gasto aprobadas por el Consejo de Gobierno de la Comunidad de Madrid por
-- año y área de la consejería, 2004 en adelante: gasto que se hizo sin seguir el procedimiento
-- (sin contrato en vigor, sin fiscalización previa de la Intervención, sin crédito o de
-- ejercicios anteriores) y que el Gobierno «convalida» después para poder pagarlo.
-- Fuente: referencias oficiales de los acuerdos de cada sesión (mart gasto_oculto_acuerdos,
-- tipo = 'convalidacion').
-- - n_convalidaciones: acuerdos; importe_eur: suma de los importes citados (n_sin_importe =
--   acuerdos cuya referencia no da importe, que no suman).
-- - Contraste: la Cámara de Cuentas de Madrid (informe de fiscalización de la Cuenta General
--   2024) cuenta 209 expedientes de convalidación aprobados por el Consejo de Gobierno en 2024,
--   151 de la Administración de la Comunidad por 54,7 millones de euros (0,2 % de sus
--   obligaciones); las referencias de prensa pueden agrupar o no recoger todos.
-- - _hab_real: por habitante de la Comunidad de Madrid en euros constantes de anio_base.
with a as (
    select * from {{ ref('gasto_oculto_acuerdos') }}
    where tipo = 'convalidacion'
),

agregado as (
    select anio, area, count(*) as n_convalidaciones,
        count(*) filter (where importe_eur is null) as n_sin_importe,
        sum(importe_eur) as importe_eur,
        sum(importe_eur_real) as importe_eur_real,
        max(anio_base) as anio_base
    from a
    group by all
    union all
    select anio, 'Total', count(*), count(*) filter (where importe_eur is null),
        sum(importe_eur), sum(importe_eur_real), max(anio_base)
    from a
    group by all
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and cod = '13' and sexo = 'Total'
),

sesiones as (
    select cast(year(cast(fecha as date)) as integer) as anio, count(*) as n_sesiones
    from {{ source('raw_gasto_oculto', 'gasto_oculto_cm_sesiones') }}
    where fecha is not null and descargado
    group by all
)

select
    '13' as cod_ccaa,
    'Comunidad de Madrid' as ccaa,
    g.anio,
    g.area,
    g.n_convalidaciones,
    g.n_sin_importe,
    coalesce(g.importe_eur, 0) as importe_eur,
    coalesce(g.importe_eur_real, 0) as importe_eur_real,
    coalesce(g.importe_eur_real, 0) / p.poblacion as importe_eur_hab_real,
    s.n_sesiones,
    g.anio_base,
    g.anio = year(current_date) as es_parcial
from agregado as g
asof left join pob as p
  on p.anio <= g.anio
left join sesiones as s
  on s.anio = g.anio
order by g.anio, g.area
