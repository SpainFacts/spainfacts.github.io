-- Universidades españolas (públicas y privadas) con su comunidad, si tienen ánimo de lucro y
-- la norma de creación o reconocimiento con su fecha. Fuente: Ministerio de Ciencia, Innovación
-- y Universidades, Registro de Universidades, Centros y Títulos (RUCT), ficha de cada
-- universidad (https://www.educacion.gob.es/ruct/universidad.action?codigoUniversidad=NNN).
-- tipo: 'Pública' o 'Privada' (las privadas de la Iglesia y concordatarias -Deusto, Navarra,
-- Comillas, Pontificia de Salamanca, Católica de Valencia, UCAM, Católica de Ávila- se marcan
-- con es_iglesia). anio_reconocimiento = año de la fecha de la disposición (ley estatal o
-- autonómica, decreto); para las concordatarias es la fecha histórica de erección.
-- animo_lucro: NULL si el RUCT no lo indica (suele faltar en las más recientes).
-- Se excluyen las entradas del RUCT que no son universidades (centros extranjeros autorizados,
-- centros de enseñanzas artísticas superiores, centros del Ministerio de Defensa).
with base as (
    select
        codigo,
        nombre,
        tipo as tipo_ruct,
        animo_lucro,
        comunidad,
        tipo_disposicion,
        boletin,
        strptime(fecha_disposicion, '%d/%m/%Y')::date as fecha_disposicion,
        url,
        case
            when comunidad ilike '%Andaluc%' then '01'
            when comunidad ilike '%Arag%' then '02'
            when comunidad ilike '%Asturias%' then '03'
            when comunidad ilike '%Balears%' then '04'
            when comunidad ilike '%Canarias%' then '05'
            when comunidad ilike '%Cantabria%' then '06'
            when comunidad ilike '%Castilla y Le%' then '07'
            when comunidad ilike '%Castilla-La Mancha%' then '08'
            when comunidad ilike '%Catalu%' then '09'
            when comunidad ilike '%Valenciana%' then '10'
            when comunidad ilike '%Extremadura%' then '11'
            when comunidad ilike '%Galicia%' then '12'
            when comunidad ilike '%Madrid%' then '13'
            when comunidad ilike '%Murcia%' then '14'
            when comunidad ilike '%Navarra%' then '15'
            when comunidad ilike '%Pa_s Vasco%' then '16'
            when comunidad ilike '%Rioja%' then '17'
        end as cod_ccaa
    from {{ source('raw_educacion_privada', 'educacion_privada_ruct_universidades') }}
    where nombre not ilike 'Centros %'
)

select
    b.cod_ccaa,
    t.nombre as ccaa,
    b.codigo as codigo_ruct,
    b.nombre as universidad,
    case when b.tipo_ruct ilike 'Privada%' then 'Privada' else 'Pública' end as tipo_universidad,
    b.tipo_ruct ilike '%Iglesia%' or b.tipo_ruct ilike '%concordataria%' as es_iglesia,
    case b.animo_lucro when 'Sí' then true when 'No' then false end as animo_lucro,
    b.tipo_disposicion,
    b.boletin,
    b.fecha_disposicion,
    cast(year(b.fecha_disposicion) as integer) as anio_reconocimiento,
    b.url as fuente_url
from base b
left join {{ ref('territorios') }} t on t.nivel = 'ccaa' and t.cod = b.cod_ccaa
