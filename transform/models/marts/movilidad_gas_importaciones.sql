-- Importaciones de gas natural de España por país de origen (Eurostat nrg_ti_gas), en millones
-- de m3 al año, su peso en el total y el total por habitante. Por gasoducto llega el gas de
-- Argelia (Medgaz) y de Francia y Portugal; el resto entra en barco como GNL por las
-- regasificadoras. Los agregados de Eurostat (UE, fuera de la UE...) no se publican; lo que
-- Eurostat no asigna a ningún país va como «Sin especificar».
with crudo as (
    select * from {{ source('raw_oleoductos', 'oleoductos_gas_importaciones') }}
),

total as (
    select anio, millones_m3 as total_millones_m3 from crudo where socio = 'TOTAL'
),

paises as (
    select * from {{ ref('paises_iso') }} where not es_agregado
),

filas as (
    select c.anio, p.cod_pais, p.pais, c.millones_m3
    from crudo c
    join paises p on p.eurostat = c.socio
    union all
    select anio, null, 'Sin especificar', millones_m3
    from crudo
    where socio = 'NSP'
),

poblacion as (
    select anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and sexo = 'Total'
)

select
    f.anio,
    f.cod_pais,
    f.pais,
    f.millones_m3,
    100.0 * f.millones_m3 / nullif(t.total_millones_m3, 0) as cuota_pct,
    t.total_millones_m3,
    1e6 * t.total_millones_m3 / nullif(h.poblacion, 0) as total_m3_por_hab
from filas f
join total t on t.anio = f.anio
left join poblacion h on h.anio = f.anio
where f.millones_m3 > 0
