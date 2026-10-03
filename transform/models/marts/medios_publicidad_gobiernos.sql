-- Publicidad de la Administración General del Estado según el presidente del
-- Gobierno (a 1 de julio de cada año) a partir de medios_publicidad_age_anual
-- (Informes de la Comisión de Publicidad y Comunicación Institucional, 2006-).
-- Media anual de euros constantes por habitante (media simple de los años con
-- dato ejecutado), mínimo, máximo y años. El gasto de un año depende también
-- de campañas obligatorias o extraordinarias (procesos electorales, COVID en
-- 2020-2022, DGT, Hacienda): la comparación entre gobiernos es orientativa.
-- 2011 cuenta para Zapatero y 2018 para Sánchez (presidían a 1 de julio).
with base as (
    select * from {{ ref('medios_publicidad_age_anual') }}
    where institucional_eur_nominal is not null and presidente is not null
)

select
    presidente,
    familia,
    any_value(color) as color,
    cast(min(anio) as integer) as anio_desde,
    cast(max(anio) as integer) as anio_hasta,
    cast(count(*) as integer) as anios,
    avg(institucional_eur_hab_real) as institucional_eur_hab_real_media,
    min(institucional_eur_hab_real) as institucional_eur_hab_real_min,
    max(institucional_eur_hab_real) as institucional_eur_hab_real_max,
    avg(comercial_eur_hab_real) as comercial_eur_hab_real_media,
    avg(total_eur_hab_real) as total_eur_hab_real_media,
    avg(institucional_eur_real) as institucional_eur_real_media,
    avg(ejecucion_pct) as ejecucion_pct_media,
    avg(campanas_institucionales) as campanas_institucionales_media
from base
group by presidente, familia
order by anio_desde
