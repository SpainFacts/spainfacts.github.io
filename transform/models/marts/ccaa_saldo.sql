-- Capacidad (+) / necesidad (-) de financiación anual de cada comunidad autónoma
-- (saldo PDE, SEC 2010). Convención de signo: NEGATIVO = DÉFICIT, positivo = superávit.
-- El BdE (be13a) publica flujos MENSUALES no acumulados; el anual es la suma de
-- los 12 meses y solo se dan años completos (por comunidad, desde 2013).
-- saldo_pct_pib no lo publica el BdE por comunidad: se calcula con el PIB regional
-- implícito en la deuda del 4.º trimestre (deuda_eur / deuda_pct_pib * 100).
with mensual as (
    select * from {{ ref('stg_bde_series') }}
    where ambito = 'ccaa' and medida = 'saldo_miles_eur'
),

anual as (
    select
        anio,
        cod_territorio as cod_ccaa,
        any_value(territorio) as ccaa,
        sum(valor) * 1000 as saldo_eur,
        count(*) as meses
    from mensual
    group by anio, cod_territorio
),

pib as (
    select anio, cod_ccaa, deuda_eur / (deuda_pct_pib / 100) as pib_eur
    from {{ ref('ccaa_deuda') }}
    where trimestre = 4 and deuda_pct_pib > 0
)

select
    a.anio,
    a.cod_ccaa,
    a.ccaa,
    a.saldo_eur,
    round(100 * a.saldo_eur / p.pib_eur, 3) as saldo_pct_pib,
    p.pib_eur as pib_implicito_eur,
    a.cod_ccaa || '-' || a.anio as clave
from anual as a
left join pib as p
    on p.anio = a.anio and p.cod_ccaa = a.cod_ccaa
where a.meses = 12
