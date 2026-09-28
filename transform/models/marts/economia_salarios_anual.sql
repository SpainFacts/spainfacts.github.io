-- Salario medio mensual por año (media de los cuatro trimestres de la ETCL,
-- con pagas extra prorrateadas), nominal y en euros constantes del último año
-- completo, con su crecimiento anual. Solo años con los cuatro trimestres.
with anual as (
    select
        anio,
        jornada,
        sector,
        avg(salario_total) as salario_nominal,
        avg(salario_total_real) as salario_real,
        count(*) as trimestres
    from {{ ref('economia_salarios') }}
    group by all
    having count(*) = 4 and count(salario_total_real) = 4
)

select
    anio,
    jornada,
    sector,
    salario_nominal,
    salario_real,
    12 * salario_nominal as salario_anual_nominal,
    12 * salario_real as salario_anual_real,
    100 * (salario_nominal / lag(salario_nominal) over w - 1) as crecimiento_nominal,
    100 * (salario_real / lag(salario_real) over w - 1) as crecimiento_real
from anual
window w as (partition by jornada, sector order by anio)
