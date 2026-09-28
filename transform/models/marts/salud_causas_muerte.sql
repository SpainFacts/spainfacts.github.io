-- Defunciones por causa, sexo, año y territorio (España, comunidad y
-- provincia de residencia), con tasa bruta por 100.000 habitantes (INE,
-- Estadística de Defunciones según la Causa de Muerte, tabla 9936).
-- es_capitulo = grandes grupos de la CIE-10 ("II.Tumores"); el resto son
-- causas concretas de la lista reducida. Tasa BRUTA: una provincia envejecida
-- tiene más muertes por habitante sin que su salud sea peor.
with base as (
    select
        d.anio,
        d.sexo,
        d.cod_prov,
        d.codigo_causa,
        regexp_replace(d.causa, '^[IVX-]+\.', '') as causa,
        d.codigo_causa like '%-%' as es_capitulo,
        d.defunciones
    from {{ source('raw', 'ine_defunciones_causas') }} d
    where d.defunciones is not null and d.cod_prov <> '99'
),

territorios as (
    select anio, sexo, 'pais' as nivel, '00' as cod, codigo_causa, causa, es_capitulo, defunciones
    from base where cod_prov = '00'
    union all
    select b.anio, b.sexo, 'ccaa', p.cod_ccaa, b.codigo_causa, b.causa, b.es_capitulo, sum(b.defunciones)
    from base b join {{ ref('territorios_provincias') }} p on p.cod_prov = b.cod_prov
    group by all
    union all
    select anio, sexo, 'provincia', cod_prov, codigo_causa, causa, es_capitulo, defunciones
    from base where cod_prov <> '00'
),

poblacion as (
    select anio, nivel, cod, sexo, poblacion from {{ ref('poblacion_territorios') }}
)

select
    t.anio,
    t.nivel,
    t.cod,
    t.sexo,
    t.codigo_causa,
    t.causa,
    t.es_capitulo,
    t.defunciones,
    100000.0 * t.defunciones / nullif(p.poblacion, 0) as tasa_100k
from territorios t
left join poblacion p
  on p.nivel = t.nivel and p.cod = t.cod and p.anio = t.anio and p.sexo = t.sexo
