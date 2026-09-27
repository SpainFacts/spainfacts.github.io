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
with entidades as (
    select * from {{ source('raw_bde', 'bde_deuda_viva_eell') }}
    where tipo_fila = 'entidad'
)

select
    make_date(anio, 12, 31) as fecha,
    anio,
    4 as trimestre,
    cod_prov,
    sum(deuda_miles_eur) * 1000 as deuda_eur,
    coalesce(sum(deuda_miles_eur) filter (where tipo_entidad = 'ayuntamiento'), 0) * 1000 as deuda_ayuntamientos_eur,
    coalesce(sum(deuda_miles_eur) filter (where tipo_entidad = 'diputacion_consejo_cabildo'), 0) * 1000 as deuda_diputaciones_eur,
    coalesce(sum(deuda_miles_eur) filter (where tipo_entidad = 'resto_eell'), 0) * 1000 as deuda_resto_eell_eur,
    cod_prov || '-' || anio as clave
from entidades
group by anio, cod_prov
