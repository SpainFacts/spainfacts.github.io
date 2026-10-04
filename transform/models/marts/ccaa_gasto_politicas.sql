-- Gasto de cada comunidad autónoma por área (1 dígito) y política de gasto
-- (2 dígitos): obligaciones reconocidas de la liquidación consolidada, en euros corrientes.
-- `obligaciones` va depurada de IFL (participación de las entidades locales en
-- tributos) y PAC (fondos agrícolas europeos), que la comunidad solo canaliza;
-- `obligaciones_brutas` es la cifra sin depurar.
-- obligaciones_eur_hab_real: `obligaciones` por habitante (poblacion = padrón del año, o el último
-- anterior) en euros constantes de anio_base (main.deflactor).
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
),

pob as (
    select cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
),

base as (
    select
        p.anio,
        p.cod_ccaa,
        t.nombre as ccaa,
        p.cod_area,
        a.area_nombre,
        p.codigo as cod_politica,
        p.nombre as politica_nombre,
        -- depurada en blanco con bruta informada = se depuró entera (IFL/PAC)
        coalesce(p.obligaciones_depuradas, 0) as obligaciones,
        coalesce(p.obligaciones_brutas, p.obligaciones_depuradas) as obligaciones_brutas
    from politicas as p
    left join areas as a
      on a.anio = p.anio and a.cod_ccaa = p.cod_ccaa and a.cod_area = p.cod_area
    left join {{ ref('territorios_ccaa') }} as t
      on t.cod_ccaa = p.cod_ccaa
    where p.obligaciones_depuradas is not null or p.obligaciones_brutas is not null
)

select
    b.anio,
    b.cod_ccaa,
    b.ccaa,
    b.cod_area,
    b.area_nombre,
    b.cod_politica,
    b.politica_nombre,
    b.obligaciones,
    b.obligaciones_brutas,
    cast(pb.poblacion as bigint) as poblacion,
    b.obligaciones * d.factor / pb.poblacion as obligaciones_eur_hab_real,
    d.anio_base,
    b.anio || '-' || b.cod_ccaa || '-' || b.cod_politica as clave
from base as b
asof left join pob as pb
  on pb.cod = b.cod_ccaa and pb.anio <= b.anio
left join {{ ref('deflactor') }} as d
  on d.anio = cast(b.anio as integer)
order by b.anio, b.cod_ccaa, b.cod_politica
