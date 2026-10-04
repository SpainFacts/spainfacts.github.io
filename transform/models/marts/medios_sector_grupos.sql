-- Ingresos y beneficio neto de los grandes grupos de medios cotizados (seed medios_sector_grupos_cuentas:
-- de momento Atresmedia 2007-2025, tabla «Principales magnitudes» de su web de accionistas).
-- En millones de euros constantes (main.deflactor, real = nominal * factor) y en euros por
-- habitante (padrón a 1 de enero de España, main.poblacion_territorios). margen_neto_pct =
-- beneficio neto / ingresos.
with pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
)
select
    cast(g.anio as integer) as anio,
    g.grupo,
    g.ingresos_meur as ingresos_meur_nominal,
    g.resultado_neto_meur as resultado_neto_meur_nominal,
    g.ingresos_meur * d.factor as ingresos_meur_real,
    g.resultado_neto_meur * d.factor as resultado_neto_meur_real,
    1e6 * g.ingresos_meur * d.factor / p.poblacion as ingresos_eur_hab_real,
    100.0 * g.resultado_neto_meur / g.ingresos_meur as margen_neto_pct,
    d.anio_base,
    g.fuente
from {{ ref('medios_sector_grupos_cuentas') }} g
left join pob p on p.anio = g.anio
left join {{ ref('deflactor') }} d on d.anio = g.anio
