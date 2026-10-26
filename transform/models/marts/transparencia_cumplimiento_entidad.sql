-- Resumen por entidad del índice propio de publicidad activa (elaboración propia):
-- índice 0-100 = media de la puntuación del último periodo medido de cada obligación
-- (ver transparencia_cumplimiento), con su comparación con las entidades del mismo
-- tipo y tramo de población, y la lista de incumplimientos a destacar.
-- Solo se da índice con al menos 3 obligaciones medidas.

-- Una obligación solo entra en el índice cuando mide al menos al 80 % de las
-- entidades de su tipo (p. ej., el rastreo del Tribunal de Cuentas mientras no está
-- completo): si no, el índice premiaría o castigaría según la provincia rastreada.
-- Por lo mismo, sus incumplimientos tampoco se destacan hasta que llega a esa cobertura.

with todos as (
    select * from {{ ref('transparencia_cumplimiento') }}
    where es_ultimo
),

-- cobertura = entidades de las que la fuente dice algo (cualquier estado, también
-- «sin registros» o «no aplica») sobre todas las de su tipo. El rastreo parcial del
-- Tribunal de Cuentas no tiene filas de las provincias aún no rastreadas.
cobertura as (
    select
        c.tipo_entidad, c.obligacion,
        count(distinct c.cod_entidad)::double / any_value(t.n) as cobertura
    from {{ ref('transparencia_cumplimiento') }} c
    join (select tipo_entidad, count(distinct cod_entidad) as n from {{ ref('transparencia_cumplimiento') }} group by 1) t
      using (tipo_entidad)
    group by all
),

ultimos as (
    select t.*, c.cobertura >= 0.8 and t.bloque = 'remision' as en_indice
    from todos t
    join cobertura c using (tipo_entidad, obligacion)
),

entidad as (
    select
        tipo_entidad, cod_entidad,
        any_value(nombre_entidad) as nombre_entidad,
        any_value(cod_mun) as cod_mun,
        any_value(cod_prov) as cod_prov,
        any_value(cod_ccaa) as cod_ccaa,
        any_value(provincia) as provincia,
        any_value(ccaa) as ccaa,
        max(poblacion) as poblacion,
        count(*) filter (where en_indice) as obligaciones_medidas,
        100 * avg(puntuacion) filter (where en_indice) as indice_bruto,
        count(*) filter (where estado = 'no_consta' and en_indice) as n_no_consta,
        count(*) filter (where estado = 'fuera_plazo' or (estado = 'con_registros' and n_fuera_plazo > 0)) as n_con_retrasos,
        count(*) filter (where incumplimiento_destacado and en_indice) as n_incumplimientos_destacados,
        string_agg(case when incumplimiento_destacado and en_indice then obligacion_nombre || ' (' || periodo || ')' end, ' · '
                   order by fecha_plazo) as incumplimientos,
        max(fecha_plazo) as ultimo_plazo
    from ultimos
    group by tipo_entidad, cod_entidad
),

con_indice as (
    select
        *,
        case when obligaciones_medidas >= 3 then indice_bruto end as indice,
        case
            when poblacion is null then null
            when poblacion < 1000 then '<1.000'
            when poblacion < 5000 then '1.000-5.000'
            when poblacion < 20000 then '5.000-20.000'
            when poblacion < 100000 then '20.000-100.000'
            else '>100.000'
        end as tramo_poblacion
    from entidad
),

comparado as (
    select
        *,
        avg(indice) over (partition by tipo_entidad, tramo_poblacion) as media_tramo_espana,
        avg(indice) over (partition by tipo_entidad, tramo_poblacion, cod_prov) as media_tramo_provincia,
        case when indice is not null then
            percent_rank() over (partition by tipo_entidad, tramo_poblacion, (indice is not null) order by indice)
        end as percentil_tramo,
        rank() over (partition by tipo_entidad, (indice is not null) order by indice desc) as puesto_tipo,
        count(indice) over (partition by tipo_entidad) as total_tipo
    from con_indice
),

alcalde_actual as (
    select cod_mun, alcalde, familia, partido_original
    from {{ ref('alcaldes_historia') }}
    where es_actual
    qualify row_number() over (partition by cod_mun order by fecha_posesion desc) = 1
)

select
    c.*,
    case when c.indice is not null then c.puesto_tipo end as puesto,
    a.alcalde as gobernante_actual,
    a.familia as familia_actual,
    a.partido_original as lista_actual,
    c.tipo_entidad || '|' || c.cod_entidad as clave
from comparado c
left join alcalde_actual a on c.tipo_entidad = 'Ayuntamiento' and a.cod_mun = c.cod_mun
