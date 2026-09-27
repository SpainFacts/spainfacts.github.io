-- Los 20 días más calurosos (temperatura máxima) de cada provincia desde 1991.
select
    cod_prov,
    provincia,
    estacion,
    fecha,
    anio,
    tmax,
    tmax_media_historica,
    anomalia_tmax,
    row_number() over (partition by cod_prov order by tmax desc, fecha desc) as posicion
from {{ ref('calor_provincia_diario') }}
where tmax is not null
qualify posicion <= 20
