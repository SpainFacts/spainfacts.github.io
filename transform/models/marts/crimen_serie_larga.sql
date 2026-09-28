-- Serie larga de infracciones penales conocidas (2010-) por España, comunidad
-- y provincia y tipología (Ministerio del Interior, Datos1), con tasa por 1.000 hab.
-- nivel_tipologia: 0 = grupo ("1. CONTRA LAS PERSONAS"), 1 = tipo ("1.1"), 2 = subtipo ("1.1.1").
with base as (
    select
        a.anio,
        case when s.cod = '00' then 'pais' else a.nivel end as nivel,
        s.cod,
        rtrim(regexp_extract(a.tipologia, '^([0-9.]+)', 1), '.') as codigo_tipologia,
        trim(regexp_replace(a.tipologia, '^[0-9.]+\s*-?\s*', '')) as tipologia,
        a.infracciones
    from {{ source('raw_criminalidad', 'ses_criminalidad_anual') }} a
    join {{ ref('ses_territorios') }} s on s.territorio_ses = a.territorio and s.nivel = a.nivel
    -- el total nacional viene en los dos ficheros (comunidades y provincias): solo uno
    where not (s.cod = '00' and a.nivel = 'provincia')
)

select
    b.anio,
    b.nivel,
    b.cod,
    b.codigo_tipologia,
    b.tipologia,
    length(b.codigo_tipologia) - length(replace(b.codigo_tipologia, '.', '')) as nivel_tipologia,
    b.infracciones,
    p.poblacion,
    1000.0 * b.infracciones / nullif(p.poblacion, 0) as tasa_1000
from base b
left join {{ ref('poblacion_territorios') }} p
  on p.sexo = 'Total' and p.anio = b.anio and p.cod = b.cod and p.nivel = b.nivel
