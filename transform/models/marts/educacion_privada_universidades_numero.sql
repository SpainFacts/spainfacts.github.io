-- Número de universidades con actividad por comunidad autónoma, curso, tipo (pública/privada)
-- y modalidad. Fuente: Ministerio de Ciencia, Innovación y Universidades, SIIU, Estadística de
-- Universidades, Centros y Titulaciones (EUCT/ESTR/px_euct_estr_univ_ca.px), desde 2015-16.
-- La comunidad es la de la sede de la universidad. España ('00') es el total de la fuente e
-- incluye las universidades de ámbito estatal (UNED, UIMP), que no tienen comunidad.
-- modalidad: 'Todas', 'Presencial', 'No presencial' y 'Especial' (UIMP y similares).
-- anio = año de fin del curso.
select
    case when u.cod_siiu = 'CAXX' then '00' else right(u.cod_siiu, 2) end as cod_ccaa,
    t.nombre as ccaa,
    u.curso,
    cast(right(u.curso, 4) as integer) as anio,
    case u.modalidad when 'Total' then 'Todas' when 'No Presencial' then 'No presencial'
        else u.modalidad end as modalidad,
    u.tipo_universidad,
    cast(u.universidades as integer) as universidades
from {{ source('raw_educacion_privada', 'educacion_privada_univ_numero') }} u
join {{ ref('territorios') }} t
    on t.cod = case when u.cod_siiu = 'CAXX' then '00' else right(u.cod_siiu, 2) end
   and t.nivel = case when u.cod_siiu = 'CAXX' then 'pais' else 'ccaa' end
where u.cod_siiu <> 'CA00'
