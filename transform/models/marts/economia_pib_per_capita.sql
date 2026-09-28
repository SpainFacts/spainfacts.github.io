-- PIB por habitante (Eurostat nama_10_pc):
--   real_eur: España en volumen, reexpresado en euros del último año completo
--             (volumen x PIB nominal por habitante / volumen de ese año).
--   indice_ue: PIB por habitante en paridad de poder de compra, UE27 = 100,
--             para comparar niveles de vida entre países.
with pc as (
    select
        cast(anio as integer) as anio,
        pais,
        max(case when unidad = 'CLV10_EUR_HAB' then valor end) as volumen,
        max(case when unidad = 'CP_PPS_EU27_2020_HAB' then valor end) as pps
    from {{ source('raw_economia', 'eurostat_pib_per_capita') }}
    group by all
),

ue as (
    select anio, pps as pps_ue from pc where pais = 'EU27_2020'
),

-- PIB nominal por habitante de España en los años con los cuatro trimestres
nominal_hab as (
    select t.anio, 1e6 * sum(t.nominal_meur) / max(1000 * po.valor) as pib_hab
    from {{ ref('economia_pib_trimestral') }} t
    join {{ source('raw_eurostat_extra', 'eurostat_poblacion') }} po on cast(po.periodo as integer) = t.anio
    where t.componente = 'B1GQ'
    group by t.anio
    having count(*) = 4
),

escala as (
    select p.volumen as volumen_base, n.pib_hab as nominal_base
    from pc p
    join nominal_hab n on n.anio = p.anio
    where p.pais = 'ES' and p.volumen is not null
    order by p.anio desc
    limit 1
)

select
    p.anio,
    p.pais,
    case p.pais
        when 'ES' then 'España' when 'EU27_2020' then 'UE-27' when 'DE' then 'Alemania'
        when 'FR' then 'Francia' when 'IT' then 'Italia' when 'PT' then 'Portugal'
    end as nombre,
    case when p.pais = 'ES' then p.volumen * e.nominal_base / e.volumen_base end as real_eur,
    100 * p.pps / u.pps_ue as indice_ue
from pc p
left join ue u using (anio)
cross join escala e
where p.anio >= 1995
