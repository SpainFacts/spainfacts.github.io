-- Primeras solicitudes de asilo en España por año y nacionalidad (Eurostat
-- migr_asyappctza), sin los agregados (total, UE, extra-UE, desconocida...).
select
    cast(anio as integer) as anio,
    cod_nacionalidad,
    nacionalidad,
    solicitudes
from {{ source('raw_migracion', 'eurostat_asilo_nacionalidad') }}
where solicitudes is not null
  and length(cod_nacionalidad) = 2
  and cod_nacionalidad not in ('EU', 'UE', 'EA')
