-- Primeras solicitudes de protección internacional (asilo) en España por mes
-- (Eurostat migr_asyappctzm). Los últimos meses pueden estar incompletos.
select
    cast(strptime(mes || '-01', '%Y-%m-%d') as date) as mes,
    solicitudes
from {{ source('raw_migracion', 'eurostat_asilo_mensual') }}
where solicitudes is not null
