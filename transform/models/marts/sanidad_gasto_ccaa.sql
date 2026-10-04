-- Gasto sanitario público por comunidad autónoma (Ministerio de Sanidad, Estadística de Gasto
-- Sanitario Público, cuentas satélite, anexos I.1 y I.2): gasto consolidado del sector
-- Comunidades Autónomas (el de los servicios de salud autonómicos, entre el 92 % y el 94 % del gasto
-- sanitario público; no incluye mutualidades de funcionarios, Seguridad Social ni
-- ayuntamientos), en euros por habitante (población residente a 1 de julio, INE) y en % del PIB
-- regional. cod '00' = conjunto de las comunidades. Ceuta y Melilla no aparecen (su sanidad la
-- gestiona el INGESA). Los dos últimos años son provisionales.
--   eur_hab_real = eur_hab x factor del deflactor (IPC medio anual del INE), euros constantes.
with base as (
    select
        cast(anio as integer) as anio,
        cast(cod_ccaa as varchar) as cod,
        bool_or(provisional) as provisional,
        max(case when medida = 'eur_hab_ccaa' then valor end) as eur_hab,
        max(case when medida = 'pct_pib_ccaa' then valor end) as pct_pib
    from {{ source('raw_sanidad', 'sanidad_egsp') }}
    where medida in ('eur_hab_ccaa', 'pct_pib_ccaa') and cod_ccaa is not null
    group by all
)

select
    b.anio,
    case when b.cod = '00' then 'total_ccaa' else 'ccaa' end as nivel,
    b.cod,
    case when b.cod = '00' then 'Total comunidades autónomas' else t.nombre end as nombre,
    b.provisional,
    b.eur_hab,
    b.eur_hab * d.factor as eur_hab_real,
    b.pct_pib,
    d.anio_base
from base b
left join {{ ref('deflactor') }} d on d.anio = b.anio
left join {{ ref('territorios') }} t on t.nivel = 'ccaa' and t.cod = b.cod
