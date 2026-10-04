-- Deuda según el Protocolo de Déficit Excesivo (PDE) de cada comunidad autónoma,
-- fin de trimestre (Banco de España, Boletín Estadístico be1309 y be1310).
-- Incluye administración general, organismos, universidades y empresas públicas
-- clasificadas como AAPP. Ceuta y Melilla no se publican aquí (son CCLL).
-- deuda_pct_pib: % del PIB regional según lo publica el BdE (nulo en dic-1994).
-- deuda_eur_hab_real: deuda por habitante (padrón del año, o el último anterior) en euros
-- constantes de anio_base (main.deflactor, desde 1996; antes queda vacío).
with base as (
    select * from {{ ref('stg_bde_series') }}
    where ambito = 'ccaa' and medida in ('deuda_miles_eur', 'deuda_pct_pib')
),

agregado as (
    select
        fecha,
        anio,
        trimestre,
        cod_territorio as cod_ccaa,
        any_value(territorio) as ccaa_bde,
        sum(valor) filter (where medida = 'deuda_miles_eur') * 1000 as deuda_eur,
        sum(valor) filter (where medida = 'deuda_pct_pib') as deuda_pct_pib
    from base
    group by fecha, anio, trimestre, cod_territorio
    having sum(valor) filter (where medida = 'deuda_miles_eur') is not null
),

pob as (
    select cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
)

select
    a.fecha,
    a.anio,
    a.trimestre,
    a.cod_ccaa,
    coalesce(t.nombre, a.ccaa_bde) as ccaa,
    a.deuda_eur,
    a.deuda_pct_pib,
    a.deuda_eur * d.factor / p.poblacion as deuda_eur_hab_real,
    d.anio_base,
    a.cod_ccaa || '-' || strftime(a.fecha, '%Y-%m-%d') as clave
from agregado as a
left join {{ ref('territorios_ccaa') }} as t
  on t.cod_ccaa = a.cod_ccaa
asof left join pob as p
  on p.cod = a.cod_ccaa and p.anio <= a.anio
left join {{ ref('deflactor') }} as d
  on d.anio = cast(a.anio as integer)
