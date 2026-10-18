-- Suelo medido en laboratorio (LUCAS 2018 TOPSOIL, JRC/ESDAC, capa de 0-20 cm) por país europeo y
-- por comunidad autónoma, en tierras de cultivo, prados y las dos juntas: medianas de materia
-- orgánica, pH, carbonatos y nutrientes, % de muestras pobres en materia orgánica, básicas o
-- calizas, y puesto de cada país (1 = menos materia orgánica). Sirve para contrastar el modelo
-- SoilGrids, que en los secanos mediterráneos da más carbono del que miden los análisis.
with l as (
    select * from {{ ref('suelos_lucas_2018') }}
)

select
    l.nivel,
    case when l.nivel = 'pais' then p.cod_pais else l.cod end as cod,
    case when l.nivel = 'pais' then p.pais when l.nivel = 'ccaa' then t.nombre else coalesce(r.nombre, l.cod) end as nombre,
    case when l.nivel = 'pais' then p.es_ue end as es_ue,
    t.ruta,
    l.uso,
    l.muestras,
    l.materia_organica_pct,
    l.carbono_g_kg,
    l.carbono_medio_g_kg,
    l.pct_mo_menos_1,
    l.pct_mo_menos_2,
    l.ph,
    l.pct_basico,
    l.pct_acido,
    l.carbonatos_g_kg,
    l.pct_calizo,
    l.nitrogeno_g_kg,
    l.fosforo_mg_kg,
    l.potasio_mg_kg,
    l.pct_erosion_visible,
    l.pct_carcavas,
    case when l.nivel = 'pais' then rank() over (partition by l.nivel, l.uso order by l.materia_organica_pct) end as puesto_mo_menor,
    count(*) over (partition by l.nivel, l.uso) as territorios
from l
left join {{ ref('paises_iso') }} p on l.nivel = 'pais' and p.eurostat = l.cod
left join {{ ref('territorios') }} t on l.nivel = 'ccaa' and t.nivel = 'ccaa' and t.cod = l.cod
left join {{ source('raw_suelos', 'suelos_regiones') }} r on l.nivel = 'nuts2' and r.cod = l.cod
