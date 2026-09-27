-- Población oficial por municipio, año y sexo (padrón, INE 29005).
-- Los municipios que ya no existen en el diccionario vigente (fusiones o
-- segregaciones) conservan la provincia de los 2 primeros dígitos de su código
-- y la comunidad a través de la provincia.
select
    p.anio,
    p.cod_mun,
    coalesce(m.nombre, p.municipio) as municipio,
    coalesce(m.cod_prov, left(p.cod_mun, 2)) as cod_prov,
    coalesce(m.cod_ccaa, pr.cod_ccaa) as cod_ccaa,
    p.sexo,
    p.poblacion,
    m.cod_mun is not null as vigente,
    p.cod_mun || '-' || p.sexo || '-' || p.anio as clave
from {{ ref('stg_ine_poblacion_municipios') }} p
left join {{ ref('stg_ine_municipios') }} m on m.cod_mun = p.cod_mun
left join {{ ref('territorios_provincias') }} pr on pr.cod_prov = left(p.cod_mun, 2)
