-- Series del Banco de España (PDE) con su territorio INE: una fila por serie y
-- periodo. Solo las series del seed bde_series_territorio (comunidades y
-- ayuntamientos de más de 300.000 habitantes); los totales se quedan en raw.
with series as (
    select cuadro, serie, fecha, valor from {{ source('raw_bde', 'bde_deuda_ccaa') }}
    union all
    select cuadro, serie, fecha, valor from {{ source('raw_bde', 'bde_saldo_ccaa') }}
    union all
    select cuadro, serie, fecha, valor from {{ source('raw_bde', 'bde_deuda_local') }}
    where cuadro = 'be1409'
)

select
    s.fecha,
    extract(year from s.fecha)::integer as anio,
    extract(quarter from s.fecha)::integer as trimestre,
    extract(month from s.fecha)::integer as mes,
    t.cuadro,
    t.medida,
    t.ambito,
    t.cod_territorio,
    t.territorio,
    s.valor
from series as s
inner join {{ ref('bde_series_territorio') }} as t
    on t.serie = s.serie
   and t.cuadro = s.cuadro
