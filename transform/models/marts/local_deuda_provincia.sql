-- Deuda viva de las entidades locales por provincia a 31 de diciembre (anual, 2008-).
-- El Banco de España no desglosa la deuda PDE local por provincia; esta foto es la
-- "Deuda viva de las Entidades Locales" de Hacienda, entidad a entidad, elaborada con
-- la Central de Información de Riesgos del BdE. deuda_eur suma, en cada provincia:
--   deuda_ayuntamientos_eur  todos los ayuntamientos (Ceuta y Melilla incluidas, 51/52)
--   deuda_diputaciones_eur   diputación provincial o foral, consejos y cabildos insulares
--   deuda_resto_eell_eur     mancomunidades, comarcas, áreas metropolitanas, entidades
--                            locales menores, consorcios y demás entes adscritos
-- No se reparten los importes sin provincia del fichero (diferencias de conciliación
-- con el BdE, "sin desagregar" en 2008, diputaciones forales en 2009 y 2011), así que
-- la suma de provincias puede diferir ligeramente del total nacional publicado.
-- Cada importe en euros corrientes lleva su versión por habitante en euros constantes
-- (_hab_real); población del padrón del año (el último para los años sin padrón).
with entidades as (
    select * from {{ source('raw_bde', 'bde_deuda_viva_eell') }}
    where tipo_fila = 'entidad'
),

deuda as (
    select
        make_date(anio, 12, 31) as fecha,
        anio,
        4 as trimestre,
        cod_prov,
        sum(deuda_miles_eur) * 1000 as deuda_eur,
        coalesce(sum(deuda_miles_eur) filter (where tipo_entidad = 'ayuntamiento'), 0) * 1000 as deuda_ayuntamientos_eur,
        coalesce(sum(deuda_miles_eur) filter (where tipo_entidad = 'diputacion_consejo_cabildo'), 0) * 1000 as deuda_diputaciones_eur,
        coalesce(sum(deuda_miles_eur) filter (where tipo_entidad = 'resto_eell'), 0) * 1000 as deuda_resto_eell_eur
    from entidades
    group by anio, cod_prov
),

pob as (
    select cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'provincia' and sexo = 'Total'
),

ultimo as (select max(anio) as anio from pob)

select
    d.fecha,
    d.anio,
    d.trimestre,
    d.cod_prov,
    t.nombre as provincia,
    t.cod_ccaa,
    d.deuda_eur,
    d.deuda_ayuntamientos_eur,
    d.deuda_diputaciones_eur,
    d.deuda_resto_eell_eur,
    d.deuda_eur * f.factor as deuda_eur_real,
    100.0 * d.deuda_ayuntamientos_eur / nullif(d.deuda_eur, 0) as pct_ayuntamientos,
    d.deuda_eur * f.factor / p.poblacion as deuda_eur_hab_real,
    d.deuda_ayuntamientos_eur * f.factor / p.poblacion as deuda_ayuntamientos_eur_hab_real,
    d.deuda_diputaciones_eur * f.factor / p.poblacion as deuda_diputaciones_eur_hab_real,
    d.deuda_resto_eell_eur * f.factor / p.poblacion as deuda_resto_eell_eur_hab_real,
    f.anio_base,
    d.cod_prov || '-' || d.anio as clave
from deuda d
join {{ ref('territorios_provincias') }} t on t.cod_prov = d.cod_prov
join ultimo u on true
left join pob p on p.cod = d.cod_prov and p.anio = least(d.anio, u.anio)
left join {{ ref('deflactor') }} f on f.anio = d.anio
