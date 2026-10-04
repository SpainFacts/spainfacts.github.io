-- Lectores diarios de cada periódico en papel (y visor digital), EGM 2009-2025, transcrito del
-- «Marco General de los Medios en España 2026» de AIMC, pág. 50 (seed medios_sector_egm_diarios).
-- penetracion_pct = % de la población de 14 o más años; lectores_miles = penetración x universo
-- del EGM de ese año; por_1000_hab = lectores por cada 1.000 habitantes de toda la población
-- (padrón, main.poblacion_territorios). caida_pct = variación de lectores entre el primer y el
-- último año de la serie. No incluye la lectura en la web del periódico.
-- Solo cabeceras con los 17 años completos; «Total Lectores Prensa» se excluye (está en
-- medios_sector_audiencia como diarios_papel).
with d as (
    select cast(anio as integer) as anio, cabecera, penetracion_pct
    from {{ ref('medios_sector_egm_diarios') }}
    where cabecera <> 'Total Lectores Prensa'
),
u as (
    select cast(anio as integer) as anio, max(universo_miles) as universo_miles
    from {{ ref('medios_sector_egm_penetracion') }}
    group by 1
),
pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and cod = '00' and sexo = 'Total'
),
base as (
    select d.anio, d.cabecera, d.penetracion_pct,
        d.penetracion_pct / 100 * u.universo_miles as lectores_miles,
        1000.0 * d.penetracion_pct / 100 * u.universo_miles * 1000 / pob.poblacion as por_1000_hab
    from d
    join u on u.anio = d.anio
    left join pob on pob.anio = d.anio
)
select b.*,
    100.0 * (b.lectores_miles / first_value(b.lectores_miles) over w - 1) as variacion_desde_inicio_pct,
    rank() over (partition by b.anio order by b.penetracion_pct desc, b.cabecera) as puesto
from base b
window w as (partition by b.cabecera order by b.anio rows between unbounded preceding and unbounded following)
