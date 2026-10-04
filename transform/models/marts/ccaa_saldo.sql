-- Capacidad (+) / necesidad (-) de financiación anual de cada comunidad autónoma
-- (saldo PDE, SEC 2010). Convención de signo: NEGATIVO = DÉFICIT, positivo = superávit.
-- El BdE (be13a) publica flujos MENSUALES no acumulados; el anual es la suma de
-- los 12 meses y solo se dan años completos (por comunidad, desde 2013).
-- saldo_pct_pib no lo publica el BdE por comunidad: se calcula con el PIB regional
-- implícito en la deuda del 4.º trimestre (deuda_eur / deuda_pct_pib * 100).
-- saldo_eur_hab_real: saldo por habitante (padrón del año, o el último anterior) en euros
-- constantes de anio_base (main.deflactor).
with mensual as (
    select * from {{ ref('stg_bde_series') }}
    where ambito = 'ccaa' and medida = 'saldo_miles_eur'
),

anual as (
    select
        anio,
        cod_territorio as cod_ccaa,
        any_value(territorio) as ccaa_bde,
        sum(valor) * 1000 as saldo_eur,
        count(*) as meses
    from mensual
    group by anio, cod_territorio
),

pib as (
    select anio, cod_ccaa, deuda_eur / (deuda_pct_pib / 100) as pib_eur
    from {{ ref('ccaa_deuda') }}
    where trimestre = 4 and deuda_pct_pib > 0
),

pob as (
    select cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
),

base as (
    select
        a.anio,
        a.cod_ccaa,
        coalesce(t.nombre, a.ccaa_bde) as ccaa,
        a.saldo_eur,
        round(100 * a.saldo_eur / p.pib_eur, 3) as saldo_pct_pib,
        p.pib_eur as pib_implicito_eur
    from anual as a
    left join pib as p
        on p.anio = a.anio and p.cod_ccaa = a.cod_ccaa
    left join {{ ref('territorios_ccaa') }} as t
        on t.cod_ccaa = a.cod_ccaa
    where a.meses = 12
)

select
    b.anio,
    b.cod_ccaa,
    b.ccaa,
    b.saldo_eur,
    b.saldo_pct_pib,
    b.pib_implicito_eur,
    b.saldo_eur * d.factor / pb.poblacion as saldo_eur_hab_real,
    d.anio_base,
    b.cod_ccaa || '-' || b.anio as clave
from base as b
asof left join pob as pb
    on pb.cod = b.cod_ccaa and pb.anio <= b.anio
left join {{ ref('deflactor') }} as d
    on d.anio = cast(b.anio as integer)
