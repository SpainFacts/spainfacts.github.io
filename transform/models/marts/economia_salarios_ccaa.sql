-- Salario y coste laboral por trabajador y mes por comunidad autónoma y año
-- (INE, Encuesta Trimestral de Coste Laboral, tabla 6061; industria,
-- construcción y servicios). Media de los cuatro trimestres del año (solo años
-- completos), nominal y en euros constantes del último año completo del IPC
-- (main.deflactor). coste_laboral: lo que paga la empresa (salario +
-- cotizaciones + otros costes). indice_espana: salario real / España x 100.
-- No se corrige por diferencias de precios entre comunidades.
with base as (
    select
        n.cod_ccaa as cod,
        case when n.cod_ccaa = '00' then 'España' else split_part(s.serie, '. ', 1) end as territorio,
        cast(s.anyo as integer) as anio,
        split_part(s.serie, '. ', 3) as componente,
        s.valor
    from {{ source('raw_economia', 'ine_coste_laboral_ccaa') }} s
    join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = split_part(s.serie, '. ', 1)
    where split_part(s.serie, '. ', 2) like 'Industria, construcción y servicios%'
      and split_part(s.serie, '. ', 3) in ('Coste salarial total', 'Coste laboral total')
      and s.valor is not null
),

anual as (
    select
        cod,
        territorio,
        anio,
        avg(valor) filter (where componente = 'Coste salarial total') as salario_nominal,
        avg(valor) filter (where componente = 'Coste laboral total') as coste_laboral_nominal
    from base
    group by all
    having count(*) filter (where componente = 'Coste salarial total') = 4
),

real as (
    select
        a.*,
        a.salario_nominal * d.factor as salario_real,
        a.coste_laboral_nominal * d.factor as coste_laboral_real,
        d.anio_base as anio_euros
    from anual a
    join {{ ref('deflactor') }} d on d.anio = a.anio
)

select
    r.cod,
    r.territorio,
    r.anio,
    r.anio_euros,
    r.salario_nominal,
    r.salario_real,
    r.coste_laboral_nominal,
    r.coste_laboral_real,
    100 * (r.salario_real / lag(r.salario_real) over (partition by r.cod order by r.anio) - 1) as crecimiento_real,
    100 * r.salario_real / e.salario_real as indice_espana
from real r
left join real e on e.cod = '00' and e.anio = r.anio
