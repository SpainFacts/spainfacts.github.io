-- Pensiones contributivas y afiliación en España, mes a mes (desde enero de 2008).
-- Fuentes: Seguridad Social (INSS), pensiones en vigor el día 1 de cada mes por
-- clase (libros CA<aaaamm>.xlsx, fila Total sistema); Seguridad Social, afiliados
-- medios del mes (serie por regímenes, total del sistema).
-- Importes en euros constantes: nominal * IPC medio del año base / IPC del mes
-- (IPC general del INE, base 2025, metrica 'ipc_indice'; año base = el del deflactor).
-- afiliados_por_pension = afiliados medios del mes / pensiones en vigor el día 1.
with pen as (
    select
        cast(anio as integer) as anio,
        cast(mes as integer) as mes,
        sum(case when clase = 'Total' then pensiones end) as pensiones,
        sum(case when clase = 'Jubilación' then pensiones end) as pensiones_jubilacion,
        max(case when clase = 'Total' then pension_media end) as pension_media,
        max(case when clase = 'Jubilación' then pension_media end) as pension_media_jubilacion,
        max(case when clase = 'Viudedad' then pension_media end) as pension_media_viudedad
    from {{ source('raw_pensiones', 'ss_pensiones_territorio') }}
    where nivel = 'pais'
    group by 1, 2
),

afi as (
    select cast(anio as integer) as anio, cast(mes as integer) as mes, afiliados
    from {{ source('raw_pensiones', 'ss_afiliados_regimen') }}
    where regimen = 'Total'
),

ipc as (
    select cast(year(periodo) as integer) as anio, cast(month(periodo) as integer) as mes, valor as ipc
    from {{ ref('metricas_base') }}
    where metrica_id = 'ipc_indice'
),

base as (
    select any_value(anio_base) as anio_base,
           max(ipc_medio) filter (where anio = anio_base) as ipc_base
    from {{ ref('deflactor') }}
)

select
    p.anio,
    p.mes,
    make_date(p.anio, p.mes, 1) as fecha,
    p.pensiones,
    p.pensiones_jubilacion,
    p.pension_media,
    p.pension_media_jubilacion,
    p.pension_media * b.ipc_base / i.ipc as pension_media_real,
    p.pension_media_jubilacion * b.ipc_base / i.ipc as pension_media_jubilacion_real,
    p.pension_media_viudedad * b.ipc_base / i.ipc as pension_media_viudedad_real,
    p.pension_media * p.pensiones as importe_mensual,
    a.afiliados,
    a.afiliados / p.pensiones as afiliados_por_pension,
    100 * (p.pension_media_jubilacion / p0.pension_media_jubilacion - 1) as interanual_jubilacion_nominal,
    100 * ((p.pension_media_jubilacion / i.ipc) / (p0.pension_media_jubilacion / i0.ipc) - 1) as interanual_jubilacion_real,
    cast(b.anio_base as integer) as anio_euros
from pen p
left join afi a on a.anio = p.anio and a.mes = p.mes
left join ipc i on i.anio = p.anio and i.mes = p.mes
left join pen p0 on p0.anio = p.anio - 1 and p0.mes = p.mes
left join ipc i0 on i0.anio = p.anio - 1 and i0.mes = p.mes
cross join base b
order by p.anio, p.mes
