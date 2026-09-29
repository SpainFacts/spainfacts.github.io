-- Índice de Precios de Vivienda en Alquiler (INE, tabla 59057, base 2015 = 100),
-- anual 2011-2024, España y comunidades (sin País Vasco ni Navarra, que tienen
-- fiscalidad foral), total de superficies. Elaborado con datos del IRPF, mide
-- la evolución de la renta de los mismos contratos (alquiler a calidad
-- constante). indice_real: descontada la inflación (IPC anual) y reescalado
-- a 2015 = 100.
with base as (
    select
        n.nivel,
        n.cod,
        cast(s.anyo as integer) as anio,
        max(s.valor) filter (where split_part(s.serie, '. ', 3) = 'Índice') as indice,
        max(s.valor) filter (where split_part(s.serie, '. ', 3) = 'Variación anual') as variacion_nominal
    from {{ source('raw_vivienda', 'ine_ipva_ccaa') }} s
    join {{ ref('vivienda_nombres') }} n
      on n.nombre_ine = split_part(s.serie, '. ', 1) and n.nivel in ('pais', 'ccaa')
    where split_part(s.serie, '. ', 2) = 'Total' and s.valor is not null
    group by all
),

real as (
    select b.*, b.indice * d.factor as indice_deflactado
    from base b
    join {{ ref('deflactor') }} d on d.anio = b.anio
)

select
    r.nivel,
    r.cod,
    coalesce(t.nombre, 'España') as nombre,
    r.anio,
    r.indice,
    r.variacion_nominal,
    100 * r.indice_deflactado / b.indice_deflactado as indice_real,
    100 * (r.indice_deflactado / l.indice_deflactado - 1) as variacion_real
from real r
join real b on b.nivel = r.nivel and b.cod = r.cod and b.anio = 2015
left join real l on l.nivel = r.nivel and l.cod = r.cod and l.anio = r.anio - 1
left join {{ ref('territorios') }} t on t.nivel = r.nivel and t.cod = r.cod
