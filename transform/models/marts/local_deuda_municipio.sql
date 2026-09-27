-- Deuda PDE de los ayuntamientos de más de 300.000 habitantes, fin de trimestre
-- (Banco de España, Boletín Estadístico be1409; 1994-): 13 ciudades. Es la deuda
-- del ayuntamiento como unidad de las AAPP según el PDE; no incluye la diputación
-- ni otras entidades locales de su territorio.
select
    fecha,
    anio,
    trimestre,
    cod_territorio as cod_mun,
    territorio as municipio,
    valor * 1000 as deuda_eur,
    cod_territorio || '-' || strftime(fecha, '%Y-%m-%d') as clave
from {{ ref('stg_bde_series') }}
where ambito = 'municipio' and medida = 'deuda_miles_eur'
