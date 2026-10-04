-- Gasto anual en centros educativos por alumno equivalente a tiempo completo (Eurostat
-- educ_uoe_fini04, recogida conjunta UNESCO-OCDE-Eurostat). Incluye el gasto de todas las
-- fuentes (público y privado) en centros públicos y privados (sector TOT_SEC).
--   eur          euros corrientes;
--   eur_real     euros constantes del último año completo (eur x factor de
--                deflactor_paises: IPCA de Eurostat de España o de la UE-27, que es
--                el que permite comparar los dos);
--   pps          en estándar de poder de compra (PPS), para comparar España con la UE;
--   pct_pib_hab  gasto por alumno en % del PIB por habitante.
-- nivel_educativo: CINE 2011 agrupado con nombres del sistema español. Territorio: España
-- (ES) o media de la UE-27 (EU27_2020), con el seed paises_iso.
select
    cast(g.anio as integer) as anio,
    case g.geo when 'ES' then 'ES' else 'EU27_2020' end as cod_pais,
    case g.geo when 'ES' then 'España' else 'Unión Europea' end as pais,
    g.isced11,
    case g.isced11
        when 'ED02-8' then 'Todos los niveles (de infantil a universidad)'
        when 'ED02' then 'Infantil (3-5 años)'
        when 'ED1' then 'Primaria'
        when 'ED2' then 'ESO'
        when 'ED3_4' then 'Bachillerato y FP de grado medio'
        when 'ED34_44' then 'Bachillerato'
        when 'ED35_45' then 'FP de grado medio'
        when 'ED5-8' then 'Educación superior'
    end as nivel_educativo,
    max(case when g.unit = 'EUR' then g.valor end) as eur,
    max(case when g.unit = 'EUR' then g.valor * d.factor end) as eur_real,
    max(case when g.unit = 'PPS' then g.valor end) as pps,
    max(case when g.unit = 'GDP_HAB' then g.valor end) as pct_pib_hab,
    max(d.anio_base) as anio_base
from {{ source('raw_educacion', 'eurostat_edu_gasto_alumno') }} g
left join {{ ref('deflactor_paises') }} d
    on d.anio = cast(g.anio as integer)
   and d.cod_pais = case g.geo when 'ES' then 'ES' else 'EU27_2020' end
where g.sector = 'TOT_SEC'
  and g.isced11 in ('ED02-8', 'ED02', 'ED1', 'ED2', 'ED3_4', 'ED34_44', 'ED35_45', 'ED5-8')
group by all
