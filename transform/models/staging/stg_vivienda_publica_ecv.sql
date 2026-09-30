-- ECV (INE 9997): % de hogares por régimen de tenencia, España ('00') y CCAA,
-- una fila por comunidad y año con las cuatro categorías principales.
with base as (
    select
        trim(split_part(serie, '.', 1)) as territorio,
        trim(split_part(serie, '.', 2)) as regimen,
        cast(anyo as integer) as anio,
        cast(valor as double) as valor
    from {{ source('raw_vivienda_publica', 'ine_ecv_tenencia_ccaa') }}
    where valor is not null
)

select
    n.cod_ccaa,
    b.anio,
    max(b.valor) filter (where b.regimen = 'Propiedad') as pct_propiedad,
    max(b.valor) filter (where b.regimen = 'Alquiler a precio de mercado') as pct_alquiler_mercado,
    max(b.valor) filter (where b.regimen = 'Alquiler inferior al precio de mercado') as pct_alquiler_inferior,
    max(b.valor) filter (where b.regimen = 'Cesión') as pct_cesion
from base b
join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = b.territorio
group by all
