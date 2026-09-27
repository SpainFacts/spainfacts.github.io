-- Deuda según el Protocolo de Déficit Excesivo (PDE) de cada comunidad autónoma,
-- fin de trimestre (Banco de España, Boletín Estadístico be1309 y be1310).
-- Incluye administración general, organismos, universidades y empresas públicas
-- clasificadas como AAPP. Ceuta y Melilla no se publican aquí (son CCLL).
-- deuda_pct_pib: % del PIB regional según lo publica el BdE (nulo en dic-1994).
with base as (
    select * from {{ ref('stg_bde_series') }}
    where ambito = 'ccaa' and medida in ('deuda_miles_eur', 'deuda_pct_pib')
)

select
    fecha,
    anio,
    trimestre,
    cod_territorio as cod_ccaa,
    any_value(territorio) as ccaa,
    sum(valor) filter (where medida = 'deuda_miles_eur') * 1000 as deuda_eur,
    sum(valor) filter (where medida = 'deuda_pct_pib') as deuda_pct_pib,
    cod_territorio || '-' || strftime(fecha, '%Y-%m-%d') as clave
from base
group by fecha, anio, trimestre, cod_territorio
having sum(valor) filter (where medida = 'deuda_miles_eur') is not null
