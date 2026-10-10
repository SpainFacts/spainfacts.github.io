-- Prueba de coherencia entre comunidades de las listas de espera del SNS (Ministerio de
-- Sanidad, SISLE-SNS, mart sanidad_listas_espera, cortes de junio y diciembre): si una lista
-- es más larga (más pacientes por 1.000 habitantes), la espera media declarada debería ser más
-- larga. Para cada corte, tipo de lista y comunidad se ajusta una recta dias_medio = a + b x tasa
-- con las DEMÁS comunidades (sin la propia), y se compara la espera declarada con la esperada:
--   residuo_dias = declarada - esperada;  z = residuo / desviación típica de los residuos de
--   las demás comunidades en esa recta (n - 2 grados de libertad).
-- Un z muy negativo = la comunidad declara mucha menos espera de la que corresponde a su
-- tamaño de lista. Es una comparación estadística, no una prueba: hay comunidades con
-- criterios de cómputo distintos (el ministerio advierte cambios, p. ej. Andalucía en 2018).
-- tipo 'consultas' (primera consulta) y 'quirurgica'. Ceuta y Melilla (INGESA) incluidas.
with d as (
    select fecha, anio, corte, tipo, cod as cod_ccaa, nombre as ccaa,
           tasa_1000, dias_medio
    from {{ ref('sanidad_listas_espera') }}
    where nivel = 'ccaa' and tasa_1000 is not null and dias_medio is not null
),

ajuste as (
    select
        t.fecha, t.tipo, t.cod_ccaa,
        regr_slope(o.dias_medio, o.tasa_1000) as pendiente,
        regr_intercept(o.dias_medio, o.tasa_1000) as ordenada,
        regr_r2(o.dias_medio, o.tasa_1000) as r2,
        count(*) as n_comunidades
    from d t
    join d o on o.fecha = t.fecha and o.tipo = t.tipo and o.cod_ccaa <> t.cod_ccaa
    group by t.fecha, t.tipo, t.cod_ccaa
),

dispersion as (
    select
        t.fecha, t.tipo, t.cod_ccaa,
        sqrt(sum(power(o.dias_medio - (a.ordenada + a.pendiente * o.tasa_1000), 2)) / nullif(count(*) - 2, 0)) as sd_residuos
    from d t
    join ajuste a on a.fecha = t.fecha and a.tipo = t.tipo and a.cod_ccaa = t.cod_ccaa
    join d o on o.fecha = t.fecha and o.tipo = t.tipo and o.cod_ccaa <> t.cod_ccaa
    group by t.fecha, t.tipo, t.cod_ccaa
)

select
    d.fecha,
    d.anio,
    d.corte,
    d.tipo,
    d.cod_ccaa,
    d.ccaa,
    d.tasa_1000,
    d.dias_medio as dias_declarados,
    round(a.ordenada + a.pendiente * d.tasa_1000, 1) as dias_esperados,
    round(d.dias_medio - (a.ordenada + a.pendiente * d.tasa_1000), 1) as residuo_dias,
    round((d.dias_medio - (a.ordenada + a.pendiente * d.tasa_1000)) / nullif(s.sd_residuos, 0), 2) as z,
    round(a.pendiente, 4) as pendiente_dias_por_punto_tasa,
    round(a.r2, 3) as r2,
    cast(a.n_comunidades as integer) as n_comunidades
from d
join ajuste a on a.fecha = d.fecha and a.tipo = d.tipo and a.cod_ccaa = d.cod_ccaa
join dispersion s on s.fecha = d.fecha and s.tipo = d.tipo and s.cod_ccaa = d.cod_ccaa
where a.n_comunidades >= 5
order by d.tipo, d.fecha, d.cod_ccaa
