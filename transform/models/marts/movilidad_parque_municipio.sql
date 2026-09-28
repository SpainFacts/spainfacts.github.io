-- Turismos en circulación por municipio en el último mes (DGT). La DGT no da
-- el municipio en los de menos de 10.000 habitantes: esos no aparecen aquí.
select
    p.mes,
    p.cod_mun,
    sum(p.vehiculos) as turismos,
    sum(p.vehiculos) filter (where p.energia = 'bev') as bev,
    sum(p.vehiculos) filter (where p.energia = 'phev') as phev,
    sum(p.vehiculos) filter (where p.energia = 'hev') as hev,
    sum(p.vehiculos) filter (where p.distintivo = 'CERO') as distintivo_cero,
    sum(p.vehiculos) filter (where p.distintivo = 'ECO') as distintivo_eco,
    sum(p.vehiculos) filter (where p.distintivo = 'C') as distintivo_c,
    sum(p.vehiculos) filter (where p.distintivo = 'B') as distintivo_b,
    sum(p.vehiculos) filter (where p.distintivo = 'SIN') as sin_distintivo,
    sum(p.vehiculos) filter (where p.antiguedad in ('15-19', '20+')) as mas_de_15_anios
from {{ source('raw_movilidad', 'dgt_parque') }} p
where p.mes = (select max(mes) from {{ source('raw_movilidad', 'dgt_parque') }})
  and p.grupo = 'turismo'
  and p.cod_mun is not null
group by all
