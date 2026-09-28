-- Saldo migratorio con el extranjero (inmigraciones - emigraciones) por año,
-- con su tasa por 1.000 habitantes (INE, Estadística de Migraciones y Cambios
-- de Residencia, desde 2021):
--   nivel 'pais': por nacionalidad (grupos continentales y países) — tabla 69758;
--   nivel 'ccaa': por comunidad y nacionalidad española/extranjera — tabla 69762.
-- es_grupo: fila de agregado (Total, Española, UE, continentes) frente a país.
with pais as (
    select
        cast(anyo as integer) as anio,
        'pais' as nivel,
        '00' as cod,
        split_part(serie, '. ', 1) as nacionalidad,
        valor as saldo_exterior
    from {{ source('raw_migracion', 'ine_saldos_migratorios') }}
    where serie like '%. Total. Saldo exterior. Dato base.%' and valor is not null
),

ccaa as (
    select
        cast(s.anyo as integer) as anio,
        case when n.cod_ccaa = '00' then 'pais_nac' else 'ccaa' end as nivel,
        n.cod_ccaa as cod,
        split_part(s.serie, '. ', 3) as nacionalidad,
        s.valor as saldo_exterior
    from {{ source('raw_migracion', 'ine_saldos_migratorios_ccaa') }} s
    join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = split_part(s.serie, '. ', 1)
    where split_part(s.serie, '. ', 2) = 'Todas las edades'
      and split_part(s.serie, '. ', 4) = 'Total'
      and split_part(s.serie, '. ', 5) = 'Saldo exterior'
      and s.valor is not null
),

todo as (
    select * from pais
    union all
    select * from ccaa where nivel = 'ccaa'
),

poblacion as (
    select cast(anio as integer) as anio, nivel, cod, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
)

select
    t.anio,
    t.nivel,
    t.cod,
    t.nacionalidad,
    t.nacionalidad in ('Total', 'Española', 'Extranjera', 'UE27_2020 sin España', 'Europa menos UE27_2020', 'África',
                       'América del Norte', 'Centro América y Caribe', 'Sudamérica', 'Asia', 'Oceanía', 'Apátridas')
        or t.nacionalidad like 'Otro país%' as es_grupo,
    t.saldo_exterior,
    1000.0 * t.saldo_exterior / p.poblacion as saldo_1000
from todo t
left join poblacion p
  on p.nivel = t.nivel and p.cod = t.cod
 and p.anio = least(t.anio, (select max(anio) from poblacion))
