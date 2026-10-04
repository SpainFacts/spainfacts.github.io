-- Asalariados públicos y privados por comunidad (y España, nivel 'pais'), trimestral desde 2002 (INE,
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
),

agregado as (
    select
        b.trimestre,
        n.cod_ccaa,
        sum(asalariados) filter (where tipo = 'Asalariado sector público') as publicos,
        sum(asalariados) filter (where tipo = 'Asalariado sector privado') as privados,
        sum(asalariados) filter (where tipo = 'Asalariados : Total') as total
    from base b
    join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = b.territorio
    group by all
),

-- población del año del trimestre (el último disponible para los más recientes), como empleo_territorio
poblacion as (
    select anio, nivel, cod, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
)

select
    case when a.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
    a.cod_ccaa as cod,
    t.nombre,
    cast(a.trimestre as date) as fecha,
    year(a.trimestre) as anio,
    a.publicos,
    a.privados,
    a.total,
    100.0 * a.publicos / a.total as cuota_publico_pct,
    1000.0 * a.publicos / p.poblacion as publicos_por_1000_hab
from agregado a
left join {{ ref('territorios') }} t
    on t.nivel = case when a.cod_ccaa = '00' then 'pais' else 'ccaa' end and t.cod = a.cod_ccaa
left join poblacion p
    on p.nivel = case when a.cod_ccaa = '00' then 'pais' else 'ccaa' end and p.cod = a.cod_ccaa
   and p.anio = least(year(a.trimestre), (select max(anio) from poblacion))
