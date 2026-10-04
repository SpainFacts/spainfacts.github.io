-- Gasto de personal (capítulo 1 de la liquidación: sueldos, cotizaciones
-- sociales a cargo de la administración y retribuciones de los cargos
-- electos) por territorio y año:
--   gasto_personal_ccaa: el de la propia comunidad (liquidación consolidada,
--     Hacienda), solo en el nivel 'ccaa';
--   gasto_personal_ayuntamientos: la suma de los ayuntamientos con datos
--     (CONPREL, con sus organismos autónomos), por habitante de esos mismos
--     municipios. Sin Álava ni Navarra (régimen foral: no llegan a CONPREL).
with ayuntamientos as (
    select anio, cod_mun, cod_prov, cod_ccaa, poblacion, gastos_c1
    from {{ ref('municipios_cuentas') }}
    where tiene_datos and not provisional and gastos_c1 is not null
),

agregado_aytos as (
    select anio, 'pais' as nivel, '00' as cod, sum(gastos_c1) as gasto, sum(poblacion) as pob, count(*) as n
    from ayuntamientos group by all
    union all
    select anio, 'ccaa', cod_ccaa, sum(gastos_c1), sum(poblacion), count(*) from ayuntamientos group by all
    union all
    select anio, 'provincia', cod_prov, sum(gastos_c1), sum(poblacion), count(*) from ayuntamientos group by all
),

ccaa as (
    select c.anio, c.cod_ccaa, c.ejecutado as gasto_personal_ccaa
    from {{ ref('ccaa_cuentas_capitulos') }} c
    where c.tipo = 'gasto' and c.capitulo = 1
),

poblacion as (
    select anio, nivel, cod, poblacion from {{ ref('poblacion_territorios') }} where sexo = 'Total'
),

unido as (
    select
        coalesce(a.anio, c.anio) as anio,
        coalesce(a.nivel, 'ccaa') as nivel,
        coalesce(a.cod, c.cod_ccaa) as cod,
        c.gasto_personal_ccaa,
        c.gasto_personal_ccaa / p.poblacion as gasto_personal_ccaa_hab,
        a.gasto as gasto_personal_ayuntamientos,
        a.gasto / nullif(a.pob, 0) as gasto_personal_ayuntamientos_hab,
        a.n as ayuntamientos_con_datos
    from agregado_aytos a
    full join ccaa c on a.nivel = 'ccaa' and c.cod_ccaa = a.cod and c.anio = a.anio
    left join poblacion p on p.nivel = 'ccaa' and p.cod = coalesce(a.cod, c.cod_ccaa) and p.anio = coalesce(a.anio, c.anio)
)

-- Los importes por habitante están en euros constantes de anio_base (deflactor del INE); un año
-- sin deflactor da NULL. Los totales (gasto_personal_*) son euros corrientes.
select
    u.anio,
    u.nivel,
    u.cod,
    t.nombre,
    u.gasto_personal_ccaa,
    u.gasto_personal_ccaa_hab * d.factor as gasto_personal_ccaa_eur_hab_real,
    u.gasto_personal_ayuntamientos,
    u.gasto_personal_ayuntamientos_hab * d.factor as gasto_personal_ayuntamientos_eur_hab_real,
    u.ayuntamientos_con_datos,
    d.anio_base
from unido u
left join {{ ref('territorios') }} t on t.nivel = u.nivel and t.cod = u.cod
left join {{ ref('deflactor') }} d on d.anio = cast(u.anio as integer)
