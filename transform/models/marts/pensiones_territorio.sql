-- Pensiones contributivas por España, comunidad y provincia, por año (desde 2008).
-- Fuentes: Seguridad Social (INSS), pensiones en vigor el día 1 de cada mes por
-- territorio y clase (libros CA<aaaamm>.xlsx); Seguridad Social, afiliados medios
-- mensuales por provincia (desde 2021); INE, padrón (población total, mart
-- poblacion_territorios, y de 65 años o más por provincia, stg_ine_poblacion).
-- Cálculos:
--   pensiones = media de los meses publicados del año (meses indica cuántos);
--   pensión media real = media mensual de (pensión media * IPC del año base / IPC
--     del mes), en euros del año base del deflactor (IPC general INE, base 2025);
--   pensiones_por_1000_hab y pensiones_por_100_mayores = pensiones / población
--     (del año; para años sin padrón se usa el más cercano);
--   afiliados_por_pension = afiliados medios / pensiones (solo desde 2021 fuera
--     del total nacional).
-- Las comunidades uniprovinciales (Asturias, Baleares, Cantabria, Madrid, Murcia,
-- Navarra, La Rioja) y Ceuta y Melilla aparecen también como provincia.
with ipc as (
    select cast(year(periodo) as integer) as anio, cast(month(periodo) as integer) as mes, valor as ipc
    from {{ ref('metricas_base') }}
    where metrica_id = 'ipc_indice'
),

base as (
    select any_value(anio_base) as anio_base,
           max(ipc_medio) filter (where anio = anio_base) as ipc_base
    from {{ ref('deflactor') }}
),

mensual as (
    select
        cast(p.anio as integer) as anio,
        cast(p.mes as integer) as mes,
        p.nivel,
        cast(p.cod as varchar) as cod,
        sum(case when p.clase = 'Total' then p.pensiones end) as pensiones,
        sum(case when p.clase = 'Jubilación' then p.pensiones end) as pensiones_jubilacion,
        max(case when p.clase = 'Total' then p.pension_media end) as pension_media,
        max(case when p.clase = 'Jubilación' then p.pension_media end) as pension_media_jubilacion,
        max(case when p.clase = 'Total' then p.pension_media end) * any_value(b.ipc_base) / any_value(i.ipc) as pension_media_real,
        max(case when p.clase = 'Jubilación' then p.pension_media end) * any_value(b.ipc_base) / any_value(i.ipc) as pension_media_jubilacion_real
    from {{ source('raw_pensiones', 'ss_pensiones_territorio') }} p
    left join ipc i on i.anio = p.anio and i.mes = p.mes
    cross join base b
    group by 1, 2, 3, 4
),

anual as (
    select
        anio,
        nivel,
        cod,
        count(*) as meses,
        avg(pensiones) as pensiones,
        avg(pensiones_jubilacion) as pensiones_jubilacion,
        avg(pension_media) as pension_media,
        avg(pension_media_jubilacion) as pension_media_jubilacion,
        avg(pension_media_real) as pension_media_real,
        avg(pension_media_jubilacion_real) as pension_media_jubilacion_real
    from mensual
    group by 1, 2, 3
),

afi_prov as (
    select cast(anio as integer) as anio, cast(mes as integer) as mes, cast(cod_prov as varchar) as cod_prov, sum(afiliados) as afiliados
    from {{ source('raw_pensiones', 'ss_afiliados_provincia') }}
    group by 1, 2, 3
),

afi_mensual as (
    select anio, mes, 'provincia' as nivel, cod_prov as cod, afiliados from afi_prov
    union all
    select a.anio, a.mes, 'ccaa', t.cod_ccaa, sum(a.afiliados)
    from afi_prov a
    join {{ ref('territorios_provincias') }} t on t.cod_prov = a.cod_prov
    group by 1, 2, 3, 4
    union all
    select cast(anio as integer), cast(mes as integer), 'pais', '00', afiliados
    from {{ source('raw_pensiones', 'ss_afiliados_regimen') }}
    where regimen = 'Total'
),

afi as (
    -- solo los meses que también tienen dato de pensiones, para que el cociente sea homogéneo
    select a.anio, a.nivel, a.cod, avg(a.afiliados) as afiliados, count(*) as meses_afiliados
    from afi_mensual a
    join mensual m on m.anio = a.anio and m.mes = a.mes and m.nivel = a.nivel and m.cod = a.cod
    group by 1, 2, 3
),

pob as (
    select cast(anio as integer) as anio, nivel, cast(cod as varchar) as cod, poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
),

mayores_prov as (
    select cast(anio as integer) as anio, cast(cod_prov as varchar) as cod_prov, sum(poblacion) as mayores
    from {{ ref('stg_ine_poblacion') }}
    where not es_total_nacional and sexo = 'Total' and edad >= 65
    group by 1, 2
),

mayores as (
    select anio, 'provincia' as nivel, cod_prov as cod, mayores from mayores_prov
    union all
    select m.anio, 'ccaa', t.cod_ccaa, sum(m.mayores)
    from mayores_prov m
    join {{ ref('territorios_provincias') }} t on t.cod_prov = m.cod_prov
    group by 1, 2, 3
    union all
    select cast(anio as integer), 'pais', '00', sum(poblacion)
    from {{ ref('stg_ine_poblacion') }}
    where es_total_nacional and sexo = 'Total' and edad >= 65
    group by 1
),

rangos as (
    select
        (select min(anio) from pob) as pob_min, (select max(anio) from pob) as pob_max,
        (select min(anio) from mayores) as may_min, (select max(anio) from mayores) as may_max
)

select
    a.anio,
    a.nivel,
    a.cod,
    t.nombre,
    t.slug,
    a.meses,
    a.pensiones,
    a.pensiones_jubilacion,
    a.pension_media,
    a.pension_media_jubilacion,
    a.pension_media_real,
    a.pension_media_jubilacion_real,
    p.poblacion,
    m.mayores as poblacion_65,
    1000.0 * a.pensiones / p.poblacion as pensiones_por_1000_hab,
    100.0 * a.pensiones / m.mayores as pensiones_por_100_mayores,
    100.0 * a.pensiones_jubilacion / m.mayores as jubilaciones_por_100_mayores,
    f.afiliados,
    f.meses_afiliados,
    f.afiliados / a.pensiones as afiliados_por_pension,
    1000.0 * f.afiliados / p.poblacion as afiliados_por_1000_hab,
    cast((select anio_base from base) as integer) as anio_euros
from anual a
cross join rangos r
left join {{ ref('territorios') }} t on t.nivel = a.nivel and t.cod = a.cod
left join pob p on p.nivel = a.nivel and p.cod = a.cod and p.anio = greatest(least(a.anio, r.pob_max), r.pob_min)
left join mayores m on m.nivel = a.nivel and m.cod = a.cod and m.anio = greatest(least(a.anio, r.may_max), r.may_min)
left join afi f on f.anio = a.anio and f.nivel = a.nivel and f.cod = a.cod
order by a.nivel, a.cod, a.anio
