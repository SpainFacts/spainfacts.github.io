-- Viajeros de transporte público en España por mes y modo (INE TV, tabla
-- 20239), en viajeros (el INE publica miles). Los modos se solapan: cada uno
-- está dentro de su `clave_padre` (comprobado: la suma de los hijos es el padre,
-- salvo redondeos de ±1.000) y `total` = urbano + interurbano + especial y
-- discrecional. Para sumar sin duplicar, usa solo `es_hoja` o un único nivel.
-- Población: España, padrón del año (el último disponible para años posteriores).
with base as (
    select
        cast(epoch_ms(fecha) + interval 12 hour as date) as mes,
        split_part(serie, '. ', 1) as modo,
        valor * 1000 as viajeros
    from {{ source('raw_movilidad', 'ine_transporte_viajeros') }}
    where serie like '%Viajeros transportados%'
      and valor is not null
),

claves as (
    select * from (values
        ('Total de viajeros', 'total', null),
        ('Transporte urbano', 'urbano', 'total'),
        ('Urbano por metro', 'metro', 'urbano'),
        ('Transporte urbano regular por autobús', 'autobus_urbano', 'urbano'),
        ('Transporte interurbano regular', 'interurbano', 'total'),
        ('Interurbano por autobús regular', 'autobus_interurbano', 'interurbano'),
        ('Transporte interurbano regular por autobús: Cercanías', 'autobus_cercanias', 'autobus_interurbano'),
        ('Transporte interurbano regular por autobús: Media distancia', 'autobus_media_distancia', 'autobus_interurbano'),
        ('Transporte interurbano regular por autobús: Larga distancia', 'autobus_larga_distancia', 'autobus_interurbano'),
        ('Interurbano por ferrocarril', 'ferrocarril', 'interurbano'),
        ('Ferrocarril: Cercanías', 'cercanias', 'ferrocarril'),
        ('Ferrocarril: Media distancia', 'media_distancia', 'ferrocarril'),
        ('Ferrocarril: Larga distancia', 'larga_distancia', 'ferrocarril'),
        ('Alta Velocidad', 'alta_velocidad', 'larga_distancia'),
        ('Resto ferrocarril larga distancia', 'larga_distancia_convencional', 'larga_distancia'),
        ('Interurbano Aéreo (interior)', 'avion_interior', 'interurbano'),
        ('Aéreo: Peninsula-Resto Territorio', 'aereo_peninsula_resto', 'avion_interior'),
        ('Aéreo: Peninsular', 'aereo_peninsular', 'avion_interior'),
        ('Aéreo: Interinsular', 'aereo_interinsular', 'avion_interior'),
        ('Interurbano Marítimo (cabotaje)', 'maritimo', 'interurbano'),
        ('Transporte especial y discrecional', 'especial_discrecional', 'total'),
        ('Transporte especial', 'especial', 'especial_discrecional'),
        ('Transporte especial escolar', 'especial_escolar', 'especial'),
        ('Transporte especial laboral', 'especial_laboral', 'especial'),
        ('Transporte Discrecional', 'discrecional', 'especial_discrecional')
    ) as t(modo, clave, clave_padre)
),

pob as (
    select anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and sexo = 'Total'
)

select
    date_trunc('month', b.mes) as mes,
    cast(year(b.mes) as integer) as anio,
    b.modo,
    c.clave,
    c.clave_padre,
    c.clave not in (select clave_padre from claves where clave_padre is not null) as es_hoja,
    b.viajeros,
    p.poblacion,
    1000.0 * b.viajeros / p.poblacion as viajeros_por_1000_hab
from base b
join claves c on c.modo = b.modo
left join pob p on p.anio = least(year(b.mes), (select max(anio) from pob))
