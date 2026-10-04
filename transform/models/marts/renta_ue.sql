-- Desigualdad y pobreza en los países europeos según Eurostat (EU-SILC):
-- coeficiente de Gini de la renta disponible equivalente (ilc_di12, escala
-- 0-100), ratio S80/S20 (ilc_di11: renta del 20 % más rico entre la del 20 %
-- más pobre) y tasa AROPE en % de la población (ilc_peps01n). Total de edades
-- y sexos. anio = año de la encuesta (la renta es la del año anterior, salvo
-- en Irlanda y Reino Unido). es_ue = los 27 Estados miembros actuales (verdadero para los
-- 27 países y falso para el agregado). cod_pais = ISO (Grecia GR, la UE-27 'EU27_2020');
-- es_agregado = la fila de la UE-27. unidad: % (arope), índice 0-100 (gini) o veces (s80_s20).
with ue27 as (
    select unnest(['BE','BG','CZ','DK','DE','EE','IE','EL','ES','FR','HR','IT','CY','LV','LT','LU',
                   'HU','MT','NL','AT','PL','PT','RO','SI','SK','FI','SE']) as geo
)

select
    r.indicador,
    cast(i.cod_pais as varchar) as cod_pais,
    case r.geo
        when 'EU27_2020' then 'UE-27'
        when 'ES' then 'España' when 'DE' then 'Alemania' when 'FR' then 'Francia' when 'IT' then 'Italia'
        when 'PT' then 'Portugal' when 'BE' then 'Bélgica' when 'BG' then 'Bulgaria' when 'CZ' then 'Chequia'
        when 'DK' then 'Dinamarca' when 'EE' then 'Estonia' when 'IE' then 'Irlanda' when 'EL' then 'Grecia'
        when 'HR' then 'Croacia' when 'CY' then 'Chipre' when 'LV' then 'Letonia' when 'LT' then 'Lituania'
        when 'LU' then 'Luxemburgo' when 'HU' then 'Hungría' when 'MT' then 'Malta' when 'NL' then 'Países Bajos'
        when 'AT' then 'Austria' when 'PL' then 'Polonia' when 'RO' then 'Rumanía' when 'SI' then 'Eslovenia'
        when 'SK' then 'Eslovaquia' when 'FI' then 'Finlandia' when 'SE' then 'Suecia'
        else r.pais end as pais,
    cast(r.anio as integer) as anio,
    r.valor,
    case r.indicador when 'arope' then '%' when 'gini' then 'índice 0-100' else 'veces' end as unidad,
    u.geo is not null as es_ue,
    r.geo = 'EU27_2020' as es_agregado
from {{ source('raw_renta', 'eurostat_renta_desigualdad') }} r
join {{ ref('paises_iso') }} i on i.eurostat = r.geo
left join ue27 u on u.geo = r.geo
where r.geo = 'EU27_2020' or u.geo is not null
