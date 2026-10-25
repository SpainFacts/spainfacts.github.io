-- Condenados y presos por nacionalidad en los países europeos que lo publican en
-- Eurostat (crim_just_ctz, crim_pris_ctz), con tasas por 1.000 habitantes de 15 o más
-- años de la misma nacionalidad (migr_pop1ctz, a 1 de enero) y cuántas veces es mayor
-- la tasa de los extranjeros que la de los nacionales.
--
-- Corrección por edad y sexo (aproximada): Eurostat no da la edad de los condenados,
-- así que se aplica a la pirámide de nacionales y extranjeros de cada país la curva de
-- condenados por sexo y edad de España (crimen_curva_edad_referencia). Así se calcula cuántos condenados
-- cabría esperar en cada grupo solo por su sexo y edad, y `veces_edad_sexo` compara
-- condenados observados entre esperados (como una razón estandarizada). Supone que la
-- forma de la curva por edad es parecida en todos los países, que es lo habitual.
-- En España da casi lo mismo que el ajuste directo con datos completos
-- (crimen_condenados_ajuste).
--
-- Cautelas: cada país cuenta condenas a su manera (en Alemania incluyen delitos de
-- extranjería que solo puede cometer un extranjero; la edad penal cambia), y los
-- turistas y los extranjeros no empadronados no están en el denominador en ninguno.
-- Por eso se compara sobre todo «veces», que es interna a cada país.
with condenados as (
    select
        geo,
        anio,
        max(condenados) filter (where citizen = 'FOR') as condenados_extranjeros,
        max(condenados) filter (where citizen = 'NAT') as condenados_nacionales,
        max(condenados) filter (where citizen = 'TOTAL') as condenados_total
    from {{ source('raw_migracion', 'eurostat_condenados_nacionalidad') }}
    group by geo, anio
),

presos as (
    select
        geo,
        anio,
        max(presos) filter (where citizen = 'FOR') as presos_extranjeros,
        max(presos) filter (where citizen = 'NAT') as presos_nacionales
    from {{ source('raw_migracion', 'eurostat_presos_nacionalidad') }}
    group by geo, anio
),

poblacion as (
    select
        geo, anio, citizen,
        case sexo when 'M' then 'Hombres' when 'F' then 'Mujeres' end as sexo,
        cast(regexp_extract(edad, '([0-9]+)', 1) as integer) as grupo_desde,
        edad = 'Y_GE85' as abierto,
        poblacion
    from {{ source('raw_migracion', 'eurostat_poblacion_nacionalidad') }}
    where sexo in ('M', 'F') and edad <> 'TOTAL' and poblacion is not null
),

curva_grupos as (
    select * from {{ ref('crimen_curva_edad_referencia') }}
),

poblacion_pais as (
    select
        p.geo, p.anio, p.citizen,
        sum(p.poblacion) as poblacion_15,
        sum(p.poblacion * c.tasa) as condenados_esperados
    from poblacion p
    join curva_grupos c on c.sexo = p.sexo and c.grupo_desde = p.grupo_desde
    group by p.geo, p.anio, p.citizen
    -- solo países con todos los grupos de edad de los dos sexos
    having count(*) = 30
),

ancho as (
    select
        geo, anio,
        max(poblacion_15) filter (where citizen = 'FOR') as poblacion_extranjera_15,
        max(poblacion_15) filter (where citizen = 'NAT') as poblacion_nacional_15,
        max(condenados_esperados) filter (where citizen = 'FOR') as esperados_extranjeros,
        max(condenados_esperados) filter (where citizen = 'NAT') as esperados_nacionales
    from poblacion_pais
    group by geo, anio
)

select
    p.cod_pais,
    p.pais,
    c.anio,
    c.condenados_extranjeros,
    c.condenados_nacionales,
    a.poblacion_extranjera_15,
    a.poblacion_nacional_15,
    100.0 * a.poblacion_extranjera_15 / (a.poblacion_extranjera_15 + a.poblacion_nacional_15) as extranjeros_poblacion_pct,
    100.0 * c.condenados_extranjeros / (c.condenados_extranjeros + c.condenados_nacionales) as extranjeros_condenados_pct,
    1000.0 * c.condenados_extranjeros / a.poblacion_extranjera_15 as extranjeros_por_1000_hab,
    1000.0 * c.condenados_nacionales / a.poblacion_nacional_15 as nacionales_por_1000_hab,
    (c.condenados_extranjeros / a.poblacion_extranjera_15) / (c.condenados_nacionales / a.poblacion_nacional_15) as veces,
    (a.esperados_extranjeros / a.poblacion_extranjera_15) / (a.esperados_nacionales / a.poblacion_nacional_15) as factor_edad_sexo,
    (c.condenados_extranjeros / a.esperados_extranjeros) / (c.condenados_nacionales / a.esperados_nacionales) as veces_edad_sexo,
    s.presos_extranjeros,
    s.presos_nacionales,
    (s.presos_extranjeros / a.poblacion_extranjera_15) / (s.presos_nacionales / a.poblacion_nacional_15) as veces_presos
from condenados c
join ancho a using (geo, anio)
join {{ ref('paises_iso') }} p on p.eurostat = c.geo
left join presos s using (geo, anio)
where c.condenados_extranjeros > 0 and c.condenados_nacionales > 0
  and a.poblacion_extranjera_15 > 0
