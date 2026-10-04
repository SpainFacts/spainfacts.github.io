-- Deflactor para expresar importes en euros constantes (principio de la web:
-- los importes se muestran descontada la inflación). IPC general del INE (base
-- 2025) en media anual; factor = IPC del último año completo / IPC del año, de
-- modo que importe_real = importe_nominal * factor está en euros de anio_base.
-- El año en curso usa la media de los meses publicados.
-- 1996-2001 (antes del IPC base actual del INE): el factor de 2002 enlazado con el IPCA
-- anual de España de Eurostat, factor(a) = factor(2002) * IPCA(2002) / IPCA(a).
-- Antes de 1996 no hay deflactor: no hay fila, y el importe real queda vacío.
with anual as (
    select
        cast(year(periodo) as integer) as anio,
        avg(valor) as ipc_medio,
        count(*) as meses
    from {{ ref('metricas_base') }}
    where metrica_id = 'ipc_indice'
    group by 1
),

base as (
    select max(anio) as anio_base from anual where meses = 12
),

ine as (
    select
        a.anio,
        a.ipc_medio,
        a.meses,
        b.anio_base,
        (select ipc_medio from anual where anio = b.anio_base) / a.ipc_medio as factor
    from anual a
    cross join base b
),

ipca as (
    select cast(anio as integer) as anio, indice
    from {{ source('raw', 'eurostat_hicp_paises') }}
    where geo = 'ES' and indice is not null
),

enlace as (
    select i.factor * h.indice as k, i.anio_base
    from ine i join ipca h using (anio)
    where i.anio = (select min(anio) from ine)
)

select anio, ipc_medio, meses, anio_base, factor, 'INE IPC' as origen from ine
union all
select h.anio, null, 12, e.anio_base, e.k / h.indice, 'Eurostat IPCA enlazado'
from ipca h cross join enlace e
where h.anio < (select min(anio) from ine)
