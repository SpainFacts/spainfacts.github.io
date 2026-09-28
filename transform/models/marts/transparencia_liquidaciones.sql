-- Indicador de transparencia: ¿remitió el ayuntamiento la liquidación de su
-- presupuesto al Ministerio de Hacienda?
--
-- Obligación: art. 15.3 de la Orden HAP/2105/2012 (desarrollo de la LO 2/2012):
-- la liquidación del ejercicio N se remite antes del 31 de marzo de N+1.
-- Fuente: CONPREL (estado de información 'N' = no remitida).
--
-- Responsabilidad: se atribuye al gobierno municipal en funciones el día del
-- plazo (31/03/N+1), no al actual. Desde 2013: en 2010-2012 Hacienda imputó los
-- datos de muchos municipios pequeños y la no remisión no es medible.
-- Se excluyen los avances provisionales (quien remite tarde aún no aparece).
--
-- Territorios forales: en Álava y Navarra la liquidación municipal no llega a
-- CONPREL por el cauce común (tutela financiera de la Diputación Foral / Gobierno
-- de Navarra): ~100 % y ~80 % "sin datos" todos los años, un efecto del régimen
-- foral y no del ayuntamiento. En Bizkaia y Gipuzkoa ocurre lo mismo en 2013-2014.
-- Esas filas se marcan aplica_indicador = false (con el motivo) y no cuentan.
with cuentas as (
    select cod_mun, anio, poblacion, tiene_datos
    from {{ ref('municipios_cuentas') }}
    where not provisional
      and anio >= 2013
),

con_plazo as (
    select *, make_date(cast(anio as integer) + 1, 3, 31) as fecha_plazo
    from cuentas
),

gobierno as (
    select
        c.cod_mun,
        c.anio,
        h.alcalde,
        h.partido_original,
        h.familia,
        h.color,
        -- si hubiera solapes de fechas en la fuente, el que tomó posesión más tarde
        row_number() over (partition by c.cod_mun, c.anio order by h.fecha_posesion desc) as n
    from con_plazo c
    join {{ ref('alcaldes_historia') }} h
      on h.cod_mun = c.cod_mun
     and h.fecha_posesion <= c.fecha_plazo
     and (h.fecha_fin is null or h.fecha_fin > c.fecha_plazo)
)

select
    c.cod_mun,
    m.municipio,
    m.cod_prov,
    m.cod_ccaa,
    c.anio,
    c.fecha_plazo,
    c.poblacion,
    case
        when c.poblacion < 1000 then '<1.000'
        when c.poblacion < 5000 then '1.000-5.000'
        when c.poblacion < 20000 then '5.000-20.000'
        when c.poblacion < 50000 then '20.000-50.000'
        when c.poblacion < 100000 then '50.000-100.000'
        else '>100.000'
    end as tramo_poblacion,
    case
        when c.poblacion < 1000 then 1
        when c.poblacion < 5000 then 2
        when c.poblacion < 20000 then 3
        when c.poblacion < 50000 then 4
        when c.poblacion < 100000 then 5
        else 6
    end as tramo_orden,
    c.tiene_datos as remitida,
    not c.tiene_datos and not (m.cod_prov in ('01', '31') or (m.cod_prov in ('20', '48') and c.anio <= 2014)) as incumple,
    not (m.cod_prov in ('01', '31') or (m.cod_prov in ('20', '48') and c.anio <= 2014)) as aplica_indicador,
    case
        when m.cod_prov in ('01', '31') then 'Régimen foral: la liquidación no se canaliza por CONPREL'
        when m.cod_prov in ('20', '48') and c.anio <= 2014 then 'Régimen foral: sin datos en CONPREL en 2013-2014'
    end as motivo_exclusion,
    g.alcalde as alcalde_en_plazo,
    g.partido_original as lista_en_plazo,
    coalesce(g.familia, 'Sin dato de alcalde') as familia_en_plazo,
    coalesce(g.color, '#9ca3af') as color_familia,
    c.cod_mun || '-' || c.anio as clave
from con_plazo c
left join gobierno g
  on g.cod_mun = c.cod_mun and g.anio = c.anio and g.n = 1
left join (
    select cod_mun, municipio, cod_prov, cod_ccaa
    from {{ ref('poblacion_municipios') }}
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
) m on m.cod_mun = c.cod_mun
