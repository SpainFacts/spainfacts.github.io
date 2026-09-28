-- Deflactor para expresar importes en euros constantes (principio de la web:
-- los importes se muestran descontada la inflación). IPC general del INE (base
-- 2025) en media anual; factor = IPC del último año completo / IPC del año, de
-- modo que importe_real = importe_nominal * factor está en euros de anio_base.
-- El año en curso usa la media de los meses publicados.
with anual as (
    select
        cast(year(periodo) as integer) as anio,
        avg(valor) as ipc_medio,
        count(*) as meses
    from {{ ref('metricas') }}
    where metrica_id = 'ipc_indice'
    group by 1
),

base as (
    select max(anio) as anio_base from anual where meses = 12
)

select
    a.anio,
    a.ipc_medio,
    a.meses,
    b.anio_base,
    (select ipc_medio from anual where anio = b.anio_base) / a.ipc_medio as factor
from anual a
cross join base b
