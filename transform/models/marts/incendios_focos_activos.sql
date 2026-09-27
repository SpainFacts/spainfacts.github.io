-- Focos de calor detectados por satélite (NASA FIRMS) en España en los
-- últimos 7 días del último dato disponible. La tabla raw acumula histórico.
with focos as (
    select * from {{ ref('stg_firms_focos') }}
)

select
    f.latitud,
    f.longitud,
    f.fecha,
    f.fecha_hora_utc,
    f.satelite,
    f.instrumento,
    f.confianza,
    f.frp_mw,
    f.dia_noche,
    f.cod_prov,
    p.provincia
from focos f
left join (
    select distinct cod_prov, provincia
    from {{ ref('provincias_codigos') }}
) p on p.cod_prov = f.cod_prov
where f.fecha > (select max(fecha) from focos) - interval 7 day
