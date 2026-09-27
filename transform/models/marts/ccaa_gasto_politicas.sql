-- Gasto de cada comunidad autónoma por área (1 dígito) y política de gasto
-- (2 dígitos): obligaciones reconocidas de la liquidación consolidada, en euros.
-- `obligaciones` va depurada de IFL (participación de las entidades locales en
-- tributos) y PAC (fondos agrícolas europeos), que la comunidad solo canaliza;
-- `obligaciones_brutas` es la cifra sin depurar.
-- Solo la clasificación por áreas y políticas (desde 2006-2010 según comunidad):
-- la antigua por grupos de función usa códigos incompatibles y se queda en raw.
with politicas as (
    select * from {{ ref('stg_hacienda_ccaa_funcional') }}
    where clasificacion = 'politicas' and nivel = 'politica'
),

areas as (
    select anio, cod_ccaa, codigo as cod_area, nombre as area_nombre
    from {{ ref('stg_hacienda_ccaa_funcional') }}
    where clasificacion = 'politicas' and nivel = 'area'
)

select
    p.anio,
    p.cod_ccaa,
    p.cod_area,
    a.area_nombre,
    p.codigo as cod_politica,
    p.nombre as politica_nombre,
    -- depurada en blanco con bruta informada = se depuró entera (IFL/PAC)
    coalesce(p.obligaciones_depuradas, 0) as obligaciones,
    coalesce(p.obligaciones_brutas, p.obligaciones_depuradas) as obligaciones_brutas,
    p.anio || '-' || p.cod_ccaa || '-' || p.codigo as clave
from politicas as p
left join areas as a
  on a.anio = p.anio and a.cod_ccaa = p.cod_ccaa and a.cod_area = p.cod_area
where p.obligaciones_depuradas is not null or p.obligaciones_brutas is not null
order by p.anio, p.cod_ccaa, p.codigo
