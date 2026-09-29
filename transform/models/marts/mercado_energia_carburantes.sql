-- Precio semanal de los carburantes y del gasóleo de calefacción con todos los
-- impuestos (Comisión Europea, Weekly Oil Bulletin), España y media de la UE,
-- desde 2005, en €/litro.
--   eur_litro: euros de cada momento (el boletín da €/1.000 l).
--   eur_litro_real: descontada la inflación, en euros de anio_euros (el último
--     año completo del IPC), con el IPC general español del mes de la semana
--     (último mes publicado para las semanas más recientes). La media de la UE
--     se deflacta con el mismo IPC español para que la comparación con España
--     no cambie.
with ipc as (
    select date_trunc('month', mes) as mes, indice from {{ ref('mercado_ipc_mensual') }}
),

base as (
    select avg(indice) as indice_base, max(year(mes)) as anio_euros
    from ipc
    where year(mes) = (select max(anio) from {{ ref('deflactor') }} where meses = 12)
),

ult as (select max(mes) as mes_ult from ipc)

select
    w.fecha as semana,
    w.geo,
    case w.geo when 'ES' then 'España' else 'Media UE' end as territorio,
    w.producto,
    w.eur_1000l / 1000 as eur_litro,
    w.eur_1000l / 1000 * b.indice_base / i.indice as eur_litro_real,
    b.anio_euros
from {{ source('raw_mercado', 'ce_boletin_petrolero') }} w
cross join base b
cross join ult u
join ipc i on i.mes = least(date_trunc('month', w.fecha), u.mes_ult)
where w.eur_1000l > 0
