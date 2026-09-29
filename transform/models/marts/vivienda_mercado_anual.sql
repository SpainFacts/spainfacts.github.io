-- Compraventas de viviendas (INE ETDP, tabla 6150) e hipotecas sobre viviendas
-- (INE Estadística de Hipotecas, tablas 13896 y 3200) por año, España,
-- comunidades y provincias, a partir de vivienda_mercado_mensual.
-- *_1000: por 1.000 habitantes (población a 1 de enero, poblacion_territorios;
-- fuera de su rango se usa el año más cercano). importe_medio_real: importe
-- medio por hipoteca en euros del año base (cada mes deflactado con su IPC).
-- pct_hipoteca: hipotecas sobre viviendas / compraventas de viviendas, una
-- aproximación a qué parte de las compras se financia con hipoteca (no son
-- las mismas operaciones: también se hipotecan viviendas ya compradas).
-- meses: meses con dato; el año en curso está incompleto.
with anual as (
    select
        nivel,
        cod,
        nombre,
        anio,
        count(compraventas) as meses,
        count(hipotecas) as meses_hipotecas,
        sum(compraventas) as compraventas,
        sum(compraventas_nueva) as compraventas_nueva,
        sum(compraventas_segunda_mano) as compraventas_segunda_mano,
        sum(compraventas_protegida) as compraventas_protegida,
        sum(hipotecas) as hipotecas,
        sum(importe_hipotecas) as importe_hipotecas,
        sum(importe_hipotecas_real) as importe_hipotecas_real,
        max(anio_base) as anio_base
    from {{ ref('vivienda_mercado_mensual') }}
    group by all
),

pob as (
    select nivel, cod, anio, poblacion from {{ ref('poblacion_territorios') }} where sexo = 'Total'
),

rango as (
    select min(anio) as min_anio, max(anio) as max_anio from pob
)

select
    a.nivel,
    a.cod,
    a.nombre,
    a.anio,
    a.meses,
    a.meses_hipotecas,
    a.compraventas,
    a.compraventas_nueva,
    a.compraventas_segunda_mano,
    a.compraventas_protegida,
    a.hipotecas,
    a.importe_hipotecas,
    a.importe_hipotecas / nullif(a.hipotecas, 0) as importe_medio,
    a.importe_hipotecas_real / nullif(a.hipotecas, 0) as importe_medio_real,
    a.anio_base,
    p.poblacion,
    1000.0 * a.compraventas / p.poblacion as compraventas_1000,
    1000.0 * a.compraventas_nueva / p.poblacion as compraventas_nueva_1000,
    1000.0 * a.compraventas_segunda_mano / p.poblacion as compraventas_segunda_mano_1000,
    1000.0 * a.hipotecas / p.poblacion as hipotecas_1000,
    100.0 * a.compraventas_nueva / nullif(a.compraventas, 0) as pct_nueva,
    100.0 * a.compraventas_protegida / nullif(a.compraventas, 0) as pct_protegida,
    100.0 * a.hipotecas / nullif(a.compraventas, 0) as pct_hipoteca
from anual a
cross join rango r
left join pob p
  on p.nivel = a.nivel and p.cod = a.cod
 and p.anio = greatest(least(a.anio, r.max_anio), r.min_anio)
