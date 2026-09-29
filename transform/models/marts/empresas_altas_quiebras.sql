-- Altas de empresas y declaraciones de quiebra por trimestre: índices 2021 = 100,
-- desestacionalizados y corregidos de calendario, economía de mercado (NACE B a S
-- sin O ni S94), España, UE-27 y otros países (Eurostat sts_rb_q). Sirve para ver la
-- tendencia reciente de los concursos, que el INE dejó de publicar en 2020; al ser
-- índices, comparan cada país consigo mismo, no niveles entre países.
select
    cast(geo as varchar) as geo,
    case geo
        when 'EU27_2020' then 'UE-27' when 'ES' then 'España' when 'DE' then 'Alemania'
        when 'FR' then 'Francia' when 'IT' then 'Italia' when 'PT' then 'Portugal'
        when 'NL' then 'Países Bajos'
    end as pais,
    case indic_bt when 'BKRT' then 'Quiebras' when 'REG' then 'Altas' end as indicador,
    periodo,
    cast(left(periodo, 4) as integer) as anio,
    cast(right(periodo, 1) as integer) as trimestre,
    make_date(cast(left(periodo, 4) as integer), 3 * cast(right(periodo, 1) as integer) - 2, 1) as fecha,
    valor as indice
from {{ source('raw_empresas', 'eurostat_empresas_altas_quiebras') }}
order by geo, indicador, fecha
