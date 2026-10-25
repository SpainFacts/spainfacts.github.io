-- Condenados adultos por 1.000 habitantes, españoles frente a extranjeros (todos,
-- procedencia = 'Total', o de cada procedencia: Unión Europea, Resto de Europa,
-- África, América, Asia y Oceanía), con tres grados de ajuste (columna `orden`):
--   1 'Sin ajustar': condenados / residentes de 18 o más años a mitad de año.
--   2 'Edad y sexo': ajuste directo por sexo y tramo de edad (18 estratos). Cada tasa
--     es la que tendría el grupo si tuviera la misma pirámide (sexo y edad) que toda
--     la población adulta de España del último año (población estándar fija, para
--     que la serie no cambie por el envejecimiento).
--   3 'Edad, sexo y visitantes': además suma al denominador de los extranjeros a los
--     visitantes no residentes presentes en un día medio (Frontur), que pueden ser
--     condenados pero no están en el padrón. Solo desde 2016.
-- Las columnas de españoles se repiten en cada procedencia para poder comparar.
--
-- Visitantes presentes: crimen_visitantes_presentes (Frontur). Se reparten entre sexos y edades
-- como la población estándar, y entre procedencias según el país de residencia de los
-- turistas (Frontur 23984 y el seed crimen_frontur_procedencia), suponiendo la misma
-- estancia media para todas. Frontur cuenta por país de residencia: incluye a
-- españoles que viven fuera, así que este ajuste tiende a quedarse largo.
--
-- Los extranjeros en situación irregular ya están en el denominador en su mayoría:
-- el padrón no pide permiso de residencia (Funcas estima la irregularidad restando
-- permisos a esa misma población). No se ajusta por los no empadronados: no hay cifra.

with estratos as (
    select * from {{ ref('crimen_condenados_edad') }}
),

ultimo as (
    select max(anio) as anio from estratos
),

-- población estándar: adultos residentes (españoles + extranjeros) del último año
estandar as (
    select e.sexo, e.tramo_edad, sum(e.poblacion) / sum(sum(e.poblacion)) over () as peso
    from estratos e, ultimo u
    where e.anio = u.anio and e.procedencia in ('España', 'Total')
    group by e.sexo, e.tramo_edad
),

presentes_total as (
    select anio, presentes from {{ ref('crimen_visitantes_presentes') }}
),

turistas_procedencia as (
    select f.anyo as anio, m.procedencia, sum(f.valor * m.cuota) as turistas
    from {{ source('raw_criminalidad', 'ine_frontur_pais_anual') }} f
    join {{ ref('crimen_frontur_procedencia') }} m on m.pais_residencia = split_part(f.serie, '. ', 1)
    where f.serie like '%. Dato base.%' and f.valor is not null
    group by f.anyo, m.procedencia
),

visitantes as (
    select p.anio, 'Total' as procedencia, p.presentes as no_residentes_presentes
    from presentes_total p
    union all
    select p.anio, t.procedencia, p.presentes * t.turistas / sum(t.turistas) over (partition by t.anio)
    from presentes_total p
    join turistas_procedencia t on t.anio = p.anio
),

por_grupo as (
    select
        e.anio,
        e.procedencia,
        sum(e.condenados) as condenados,
        sum(e.poblacion) as poblacion_18,
        1000.0 * sum(e.condenados) / sum(e.poblacion) as sin_ajustar,
        1000.0 * sum(s.peso * e.condenados / e.poblacion) as edad_sexo,
        1000.0 * sum(s.peso * e.condenados / (e.poblacion + coalesce(v.no_residentes_presentes, 0) * s.peso)) as con_visitantes,
        max(v.no_residentes_presentes) as no_residentes_presentes
    from estratos e
    join estandar s using (sexo, tramo_edad)
    left join visitantes v on v.anio = e.anio and v.procedencia = e.procedencia
    group by e.anio, e.procedencia
),

espanoles as (
    select * from por_grupo where procedencia = 'España'
),

extranjeros as (
    select * from por_grupo where procedencia <> 'España'
),

medidas as (
    select x.anio, x.procedencia, 1 as orden, 'Sin ajustar' as ajuste, e.sin_ajustar as esp, x.sin_ajustar as ext, x, e
    from extranjeros x join espanoles e using (anio)
    union all
    select x.anio, x.procedencia, 2, 'Edad y sexo', e.edad_sexo, x.edad_sexo, x, e
    from extranjeros x join espanoles e using (anio)
    union all
    -- a los españoles no se les suma nadie: su tasa es la de «Edad y sexo»
    select x.anio, x.procedencia, 3, 'Edad, sexo y visitantes', e.edad_sexo, x.con_visitantes, x, e
    from extranjeros x join espanoles e using (anio)
    where x.no_residentes_presentes is not null
)

select
    anio,
    procedencia,
    orden,
    ajuste,
    esp as espanoles_por_1000_hab,
    ext as extranjeros_por_1000_hab,
    ext / esp as veces,
    e.condenados as condenados_espanoles,
    x.condenados as condenados_extranjeros,
    round(e.poblacion_18) as poblacion_espanola_18,
    round(x.poblacion_18) as poblacion_extranjera_18,
    round(x.no_residentes_presentes) as no_residentes_presentes
from medidas
order by anio, procedencia, orden
