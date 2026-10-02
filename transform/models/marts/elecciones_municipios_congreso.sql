-- Resultado de las últimas elecciones al Congreso en cada municipio, con nombre,
-- provincia y comunidad, para la tabla con buscador de /sociedad/elecciones
-- (Ministerio del Interior, infoelectoral, ficheros 05/06; cálculos en
-- elecciones_municipios). `participacion_anterior` es la de las generales
-- anteriores y `poblacion` la última del padrón (INE).
with ult as (
    select max(proceso) as proceso from {{ ref('elecciones_municipios') }} where tipo = '02'
),

ant as (
    select max(proceso) as proceso
    from {{ ref('elecciones_municipios') }}
    where tipo = '02' and proceso < (select proceso from ult)
),

pob as (
    select cod_mun, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    qualify anio = max(anio) over ()
)

select
    e.proceso,
    e.anio,
    e.cod_mun,
    coalesce(d.nombre, raw.municipio) as municipio,
    left(e.cod_mun, 2) as cod_prov,
    pr.nombre as provincia,
    pr.cod_ccaa,
    c.nombre as ccaa,
    p.poblacion,
    e.censo,
    e.participacion,
    a.participacion as participacion_anterior,
    e.ganador_siglas,
    e.ganador_familia,
    b.color as ganador_color,
    e.ganador_pct,
    e.pct_izquierda,
    e.pct_derecha,
    e.pct_centro,
    e.pct_nacionalistas,
    e.pct_psoe,
    e.pct_pp,
    e.pct_vox,
    e.pct_iu_podemos_sumar,
    e.nep,
    '/territorios/municipios?m=' || e.cod_mun as enlace
from {{ ref('elecciones_municipios') }} e
left join {{ ref('elecciones_municipios') }} a
    on a.cod_mun = e.cod_mun and a.proceso = (select proceso from ant)
left join {{ ref('stg_ine_municipios') }} d on d.cod_mun = e.cod_mun
left join {{ source('raw_elecciones', 'elecciones_municipios') }} raw
    on raw.proceso = e.proceso and raw.cod_mun = e.cod_mun and raw.vuelta = 1
left join {{ ref('territorios_provincias') }} pr on pr.cod_prov = left(e.cod_mun, 2)
left join {{ ref('territorios_ccaa') }} c on c.cod_ccaa = pr.cod_ccaa
left join {{ ref('elecciones_bloques') }} b on b.familia = e.ganador_familia
left join pob p on p.cod_mun = e.cod_mun
where e.proceso = (select proceso from ult)
