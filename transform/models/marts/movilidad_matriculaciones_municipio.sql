-- Turismos NUEVOS matriculados por año y municipio del domicilio del vehículo,
-- en columnas por energía (DGT, MATRABA). Ojo: el municipio es el del titular;
-- las flotas de renting y alquiler se concentran donde tienen la sede.
select
    cast(year(mes) as integer) as anio,
    cod_mun,
    sum(matriculaciones) as turismos,
    sum(matriculaciones) filter (where energia = 'bev') as bev,
    sum(matriculaciones) filter (where energia = 'phev') as phev,
    sum(matriculaciones) filter (where energia = 'hev') as hev,
    sum(matriculaciones) filter (where energia = 'gasolina') as gasolina,
    sum(matriculaciones) filter (where energia = 'diesel') as diesel,
    sum(matriculaciones) filter (where energia not in ('bev', 'phev', 'hev', 'gasolina', 'diesel')) as otras,
    sum(matriculaciones) filter (where not renting and titular = 'fisica') as particulares
from {{ source('raw_movilidad', 'dgt_matriculaciones') }}
where grupo = 'turismo'
  and nuevo_usado = 'N'
  and cod_mun is not null
group by all
