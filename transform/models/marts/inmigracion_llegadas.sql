-- Llegadas de migrantes en situación irregular a España por mes y vía
-- (Ministerio del Interior, vía ACNUR). Son personas interceptadas o que
-- llegan por costas y fronteras terrestres fuera de los puestos habilitados.
select
    make_date(cast(anio as integer), cast(mes as integer), 1) as mes,
    via,
    personas
from {{ source('raw_migracion', 'acnur_llegadas') }}
where personas is not null
