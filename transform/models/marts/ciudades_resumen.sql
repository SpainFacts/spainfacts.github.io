-- Un resumen por indicador de ciudades: catálogo (nombre, unidad, apartado, sentido,
-- decimales), año de referencia, ciudades europeas y españolas con dato, la mediana de las
-- europeas y de las españolas, y la mejor ciudad europea y española (con ciudades_ultimo).
with u as (
    select * from {{ ref('ciudades_ultimo') }}
)

select
    i.indicador_id,
    i.nombre,
    i.unidad,
    i.apartado,
    i.sentido,
    i.decimales,
    i.orden,
    'Eurostat, Urban Audit (' || i.tabla || ')' as fuente,
    'https://ec.europa.eu/eurostat/databrowser/view/' || i.tabla || '/default/table' as url_fuente,
    max(u.anio) as anio_ref,
    min(u.anio) as anio_min,
    count(*) as n_ciudades,
    count(*) filter (where u.es_espana) as n_espana,
    median(u.valor) as mediana_europa,
    median(u.valor) filter (where u.es_espana) as mediana_espana,
    arg_min(u.ciudad, u.puesto) as mejor_ciudad,
    arg_min(u.pais, u.puesto) as mejor_ciudad_pais,
    arg_min(u.valor, u.puesto) as mejor_valor,
    arg_min(u.ciudad, u.puesto_espana) as mejor_espana,
    arg_min(u.valor, u.puesto_espana) as mejor_espana_valor
from {{ ref('ciudades_indicadores') }} i
join u using (indicador_id)
group by i.indicador_id, i.nombre, i.unidad, i.apartado, i.sentido, i.decimales, i.orden, i.tabla
