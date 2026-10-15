-- Cuentas de los grandes grupos de medios (seed medios_sector_grupos_cuentas, transcrito a mano de las
-- cuentas anuales consolidadas / informes anuales oficiales, con fuente_url por fila): ingresos,
-- ingresos de publicidad, resultado neto atribuido y plantilla media. Prisa, Vocento, Mediaset España y
-- Atresmedia son el grupo consolidado; Unidad Editorial es el segmento de RCS MediaGroup (perimetro).
-- En millones de euros constantes (main.deflactor, real = nominal * factor) y en euros por habitante
-- (padrón a 1 de enero de España, main.poblacion_territorios). margen_neto_pct = resultado / ingresos;
-- publicidad_pct_ingresos = publicidad / ingresos.
with pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
)
select
    cast(g.anio as integer) as anio,
    g.grupo,
    g.perimetro,
    g.ingresos_meur as ingresos_meur_nominal,
    g.ingresos_publicidad_meur as publicidad_meur_nominal,
    g.resultado_neto_meur as resultado_neto_meur_nominal,
    g.ingresos_meur * d.factor as ingresos_meur_real,
    g.ingresos_publicidad_meur * d.factor as publicidad_meur_real,
    g.resultado_neto_meur * d.factor as resultado_neto_meur_real,
    1e6 * g.ingresos_meur * d.factor / p.poblacion as ingresos_eur_hab_real,
    1e6 * g.ingresos_publicidad_meur * d.factor / p.poblacion as publicidad_eur_hab_real,
    1e6 * g.resultado_neto_meur * d.factor / p.poblacion as resultado_neto_eur_hab_real,
    g.plantilla_media,
    100.0 * g.resultado_neto_meur / nullif(g.ingresos_meur, 0) as margen_neto_pct,
    100.0 * g.ingresos_publicidad_meur / nullif(g.ingresos_meur, 0) as publicidad_pct_ingresos,
    d.anio_base,
    g.fuente,
    g.fuente_url
from {{ ref('medios_sector_grupos_cuentas') }} g
left join pob p on p.anio = g.anio
left join {{ ref('deflactor') }} d on d.anio = g.anio
