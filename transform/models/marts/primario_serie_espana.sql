-- Series anuales de España en el sector primario (desde 2000): producción de cada producto
-- de primario_paises_largo (cultivos, ganadería, pesca, valor de la producción agraria y
-- exportaciones; Eurostat apro_*, fish_*, aact_eaa01 y Comext DS-045409), su cuota sobre la
-- suma de los países de la UE con dato ese año y su puesto.
-- n_paises: países con dato ese año (los últimos años y los años antiguos pueden estar
-- incompletos: la cuota de un año con pocos países sale inflada; ver primario_ranking_ue
-- para el año de referencia de cada producto).
-- valor_hab: por habitante (kg/hab, ha o cabezas por 1.000 hab., euros/hab...; ver
-- unidad_hab) con la población media de Eurostat (nama_10_pe).
-- valor_real / valor_hab_real: solo para productos en M EUR, en euros constantes del último
-- año completo del IPC (main.deflactor, real = nominal x factor).
with base as (
    select * from {{ ref('primario_paises_largo') }}
),

ranking as (
    select *,
           rank() over (partition by producto_id, anio order by valor desc) as puesto,
           sum(valor) over (partition by producto_id, anio) as total_ue,
           count(*) over (partition by producto_id, anio) as n_paises
    from base
)

select
    r.categoria,
    r.producto_id,
    r.producto,
    r.unidad,
    r.anio,
    r.valor as valor_espana,
    r.total_ue,
    round(100 * r.valor / r.total_ue, 2) as cuota_pct,
    cast(r.puesto as integer) as puesto,
    cast(r.n_paises as integer) as n_paises,
    case when r.unidad = 'buques' then r.valor / r.poblacion_miles * 100
         else r.valor * 1000 / r.poblacion_miles end as valor_hab,
    case r.unidad
        when 'miles de t' then 'kg por habitante'
        when 'miles de ha' then 'ha por 1.000 habitantes'
        when 'miles de cabezas' then 'cabezas por 1.000 habitantes'
        when 'M EUR' then 'euros por habitante'
        when 'miles de GT' then 'GT por 1.000 habitantes'
        when 'buques' then 'buques por 100.000 habitantes'
    end as unidad_hab,
    case when r.unidad = 'M EUR' then r.valor * d.factor end as valor_real,
    case when r.unidad = 'M EUR' then r.valor * d.factor * 1000 / r.poblacion_miles end as valor_hab_real,
    d.anio_base
from ranking r
left join {{ ref('deflactor') }} d on d.anio = r.anio
where r.geo = 'ES' and r.anio >= 2000 and r.total_ue > 0
order by r.categoria, r.producto_id, r.anio
