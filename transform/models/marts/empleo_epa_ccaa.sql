-- Asalariados públicos y privados por comunidad, trimestral desde 2002 (INE,
-- EPA, tabla 65327). Por comunidad de residencia; muestra pequeña en las
-- comunidades menos pobladas (Ceuta, Melilla, La Rioja): más ruido trimestral.
with base as (
    select
        date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)) as trimestre,
        split_part(serie, '. ', 2) as territorio,
        split_part(serie, '. ', 3) as tipo,
        valor * 1000 as asalariados
    from {{ source('raw_empleo', 'ine_epa_asalariados_ccaa') }}
    where serie like 'Ambos sexos. %. Valor absoluto.%'
      and valor is not null
)
select
    b.trimestre,
    n.cod_ccaa,
    sum(asalariados) filter (where tipo = 'Asalariado sector público') as publicos,
    sum(asalariados) filter (where tipo = 'Asalariado sector privado') as privados,
    sum(asalariados) filter (where tipo = 'Asalariados : Total') as total,
    sum(asalariados) filter (where tipo = 'Asalariado sector público')
        / sum(asalariados) filter (where tipo = 'Asalariados : Total') as cuota_publico
from base b
join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = b.territorio
group by all
