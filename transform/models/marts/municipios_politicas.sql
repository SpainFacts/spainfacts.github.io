-- Gasto de cada ayuntamiento por política de gasto (2 dígitos de la
-- clasificación por programas, Orden EHA/3565/2008): obligaciones reconocidas
-- netas consolidadas, en euros (Hacienda, CONPREL, base de datos Access).
-- Solo los últimos ejercicios con liquidación definitiva que se cargan
-- (CONPREL_ANIOS_POLITICAS; por defecto 3). importe_hab usa la población de
-- municipios_cuentas (padrón INE del año). importe_real e importe_hab_real están
-- en euros constantes de `anio_base` (deflactor del año del importe).
with nombres as (
    select codigo, nivel, nombre
    from {{ source('raw_conprel', 'conprel_politicas_nombres') }}
)

select
    p.cod_mun,
    c.municipio,
    p.anio::integer as anio,
    left(p.cod_politica, 1) as cod_area,
    a.nombre as area_nombre,
    p.cod_politica,
    coalesce(n.nombre, 'Política ' || p.cod_politica) as politica_nombre,
    c.poblacion,
    p.importe,
    round(p.importe / nullif(c.poblacion, 0), 2) as importe_hab,
    round(p.importe * d.factor) as importe_real,
    round(p.importe * d.factor / nullif(c.poblacion, 0), 2) as importe_hab_real,
    d.anio_base,
    p.cod_mun || '-' || p.anio || '-' || p.cod_politica as clave
from {{ source('raw_conprel', 'conprel_politicas') }} as p
join {{ ref('municipios_cuentas') }} as c
  on c.cod_mun = p.cod_mun and c.anio = p.anio
left join {{ ref('deflactor') }} as d on d.anio = p.anio::integer
left join nombres as n on n.nivel = 'politica' and n.codigo = p.cod_politica
left join nombres as a on a.nivel = 'area' and a.codigo = left(p.cod_politica, 1)
order by p.cod_mun, p.anio, p.cod_politica
