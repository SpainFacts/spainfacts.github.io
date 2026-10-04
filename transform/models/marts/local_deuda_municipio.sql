-- Deuda PDE de los ayuntamientos de más de 300.000 habitantes, fin de trimestre
-- (Banco de España, Boletín Estadístico be1409; 1994-): 13 ciudades. Es la deuda
-- del ayuntamiento como unidad de las AAPP según el PDE; no incluye la diputación
-- ni otras entidades locales de su territorio.
-- Además del total corriente (deuda_eur) trae la deuda en euros constantes
-- (deuda_eur_real, con el deflactor anual: NULL en años sin deflactor), por habitante
-- (deuda_eur_hab) y por habitante en euros constantes (deuda_eur_hab_real). La
-- población es la del padrón del año de la fecha; fuera del rango del padrón cargado
-- se usa el año más cercano.
with deuda as (
    select
        fecha,
        anio,
        trimestre,
        cod_territorio as cod_mun,
        territorio as municipio,
        valor * 1000 as deuda_eur
    from {{ ref('stg_bde_series') }}
    where ambito = 'municipio' and medida = 'deuda_miles_eur'
),

pob as (
    select cod_mun, anio, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

rango as (
    select cod_mun, min(anio) as ini, max(anio) as fin from pob group by 1
)

select
    d.fecha,
    d.anio,
    d.trimestre,
    d.cod_mun,
    d.municipio,
    left(d.cod_mun, 2) as cod_prov,
    pr.nombre as provincia,
    p.poblacion,
    d.deuda_eur,
    d.deuda_eur * f.factor as deuda_eur_real,
    d.deuda_eur / nullif(p.poblacion, 0) as deuda_eur_hab,
    d.deuda_eur * f.factor / nullif(p.poblacion, 0) as deuda_eur_hab_real,
    f.anio_base,
    d.cod_mun || '-' || strftime(d.fecha, '%Y-%m-%d') as clave
from deuda d
left join rango r on r.cod_mun = d.cod_mun
left join pob p
    on p.cod_mun = d.cod_mun
    and p.anio = greatest(least(d.anio, r.fin), r.ini)
left join {{ ref('deflactor') }} f on f.anio = d.anio
left join {{ ref('territorios_provincias') }} pr on pr.cod_prov = left(d.cod_mun, 2)
