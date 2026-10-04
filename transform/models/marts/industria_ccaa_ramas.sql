-- Ramas industriales por comunidad (INE, Estadística Estructural de Empresas del sector
-- industrial, tabla 76823, raw.ine_industria_eee_ccaa; actividad por establecimiento, desde 2018).
-- Una fila por comunidad, rama CNAE (secciones y divisiones a 2 dígitos) y año.
--   cifra_negocios_miles_eur: miles de euros corrientes; cifra_negocios_hab_real: euros constantes
--     de anio_base por habitante (main.deflactor, main.poblacion_territorios).
--   cuota_espana_pct: parte de la cifra de negocios española de esa rama que está en la comunidad
--     (España = suma de las comunidades, la tabla no trae total nacional; los datos con secreto
--     estadístico quedan fuera y la suma puede quedarse corta en ramas pequeñas).
--   veces_peso_poblacion: cuota_espana_pct / peso de la comunidad en la población de España.
--   peso_en_industria_ccaa_pct: la rama sobre la cifra de negocios industrial total de la comunidad.
--   n_ccaa_con_dato / nota: cuántas comunidades publican el dato (con pocas, la cuota no es fiable;
--     p. ej. el refino solo lo publica Madrid).
--   cod_ccaa: código INE (País Vasco 16, Navarra 15).
with eee as (
    select
        c.cod_ccaa,
        split_part(e.serie, '. ', 1) as ccaa,
        split_part(e.serie, '. ', 2) as magnitud,
        split_part(e.serie, '. ', 3) as rama,
        cast(e.anyo as integer) as anio,
        e.valor
    from {{ source('raw_industria', 'ine_industria_eee_ccaa') }} e
    join {{ ref('ine_ccaa_nombres') }} c on c.nombre_ine = split_part(e.serie, '. ', 1)
    where e.valor is not null and not coalesce(e.secreto, false)
),

ancho as (
    select
        cod_ccaa, ccaa, rama, anio,
        max(case when magnitud = 'Cifra de negocios' then valor end) as cifra_negocios_miles_eur,
        max(case when magnitud = 'Personal ocupado' then valor end) as ocupados,
        max(case when magnitud = 'Número de locales' then valor end) as locales
    from eee
    group by all
),

pob as (
    select cod as cod_ccaa, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel in ('ccaa', 'pais') and sexo = 'Total'
),

pob_rango as (select min(anio) as amin, max(anio) as amax from pob),

con_pob as (
    select a.*, p.poblacion, pe.poblacion as poblacion_espana
    from ancho a
    cross join pob_rango r
    left join pob p on p.cod_ccaa = a.cod_ccaa and p.anio = greatest(least(a.anio, r.amax), r.amin)
    left join pob pe on pe.cod_ccaa = '00' and pe.anio = greatest(least(a.anio, r.amax), r.amin)
)

select
    c.cod_ccaa,
    tt.nombre as ccaa,
    c.rama,
    c.rama in ('Industria', 'Industria manufacturera', 'Industrias extractivas') as es_agregado,
    c.anio,
    c.cifra_negocios_miles_eur,
    c.cifra_negocios_miles_eur * 1000.0 / nullif(c.poblacion, 0) * d.factor as cifra_negocios_hab_real,
    d.anio_base,
    c.ocupados,
    1000.0 * c.ocupados / nullif(c.poblacion, 0) as ocupados_1000_hab,
    c.locales,
    100.0 * c.cifra_negocios_miles_eur
        / nullif(sum(c.cifra_negocios_miles_eur) over (partition by c.rama, c.anio), 0) as cuota_espana_pct,
    (100.0 * c.cifra_negocios_miles_eur
        / nullif(sum(c.cifra_negocios_miles_eur) over (partition by c.rama, c.anio), 0))
        / nullif(100.0 * c.poblacion / c.poblacion_espana, 0) as veces_peso_poblacion,
    100.0 * c.cifra_negocios_miles_eur / nullif(t.cifra_negocios_miles_eur, 0) as peso_en_industria_ccaa_pct,
    rank() over (partition by c.rama, c.anio order by c.cifra_negocios_miles_eur desc nulls last) as puesto_en_espana,
    count(c.cifra_negocios_miles_eur) over (partition by c.rama, c.anio) as n_ccaa_con_dato,
    case when count(c.cifra_negocios_miles_eur) over (partition by c.rama, c.anio) < 10
         then 'Solo ' || count(c.cifra_negocios_miles_eur) over (partition by c.rama, c.anio)
              || ' comunidades publican la cifra de negocios de esta rama (el resto tiene secreto estadístico): la cuota sobre España está sobrestimada' end as nota
from con_pob c
left join ancho t on t.cod_ccaa = c.cod_ccaa and t.anio = c.anio and t.rama = 'Industria'
left join {{ ref('deflactor') }} d on d.anio = c.anio
left join {{ ref('territorios') }} tt on tt.nivel = 'ccaa' and tt.cod = c.cod_ccaa
