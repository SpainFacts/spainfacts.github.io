-- Dinero público a las radios y televisiones autonómicas por comunidad y año
-- (2017-2025), por habitante y en euros reales, con su cuota de pantalla y el
-- partido que gobernaba la comunidad a 1 de julio.
-- Fuentes (seed medios_tv_aportacion): CNMC, Informe Económico Sectorial de
-- Telecomunicaciones y Audiovisual (subvenciones de explotación, de capital y
-- contratos-programa percibidas por TV, radio y ente de 13 comunidades); para la
-- Comunitat Valenciana, cuentas de la CVMC en la Cuenta General de la GVA
-- (2017-2023) y ejecución del programa 462D (2024-2025). Audiencias: Barlovento
-- Comunicación con datos de Kantar (seed medios_tv_audiencia).
-- Cálculos: meur_nominal = millones de la CNMC si los da (2017-2021); si solo da
-- €/hab (2022-2025) se reconstruye con nuestra población del INE
-- (poblacion_territorios, sexo Total): meur = €/hab CNMC x población / 1e6. Para
-- Valencia, suma de lo liquidado (incluidos los pagos extraordinarios, que se dan
-- aparte en meur_extraordinario). eur_hab_real = meur_nominal x 1e6 / población x
-- factor del deflactor (euros de anio_base). cuota_audiencia = suma de las cuotas
-- en su comunidad de todos los canales de TV del ente; eur_hab_real_por_punto_cuota
-- = eur_hab_real / cuota_audiencia (el dinero paga también la radio y el ente).
with seed as (
    select * from {{ ref('medios_tv_aportacion') }}
),

agregado as (
    select
        anio, cod_ccaa,
        any_value(ente) as ente,
        max(valor) filter (where tipo = 'percibido_cnmc' and unidad = 'meur') as meur_cnmc,
        max(valor) filter (where tipo = 'percibido_cnmc' and unidad = 'eur_hab') as eur_hab_cnmc,
        sum(valor) filter (where tipo = 'liquidado' and unidad = 'meur') as meur_liquidado,
        sum(valor) filter (where tipo = 'liquidado' and unidad = 'meur' and extraordinario) as meur_extra,
        max(valor) filter (where tipo = 'presupuestado' and unidad = 'meur') as meur_presupuestado,
        string_agg(distinct nota, ' ') filter (where tipo <> 'presupuestado') as nota
    from seed
    group by 1, 2
),

pob as (
    select cod, anio, poblacion from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total'
),

aud as (
    select anio, cod_ccaa,
        round(sum(cuota), 1) as cuota_grupo,
        max(cuota) filter (where principal) as cuota_principal,
        max(cadena) filter (where principal) as canal_principal
    from {{ ref('medios_tv_audiencia') }}
    where ambito = 'ccaa'
    group by 1, 2
),

gobiernos as (
    select cod, desde, coalesce(hasta, date '2100-01-01') as hasta, presidente, familia
    from {{ ref('gobiernos_presidentes') }}
    where nivel = 'autonomico'
),

colores as (
    select familia, any_value(color) as color
    from {{ ref('alcaldes_historia') }}
    where familia is not null and color is not null
    group by familia
),

calc as (
    select
        a.*,
        cast(p.poblacion as bigint) as poblacion,
        case
            when a.meur_cnmc is not null then a.meur_cnmc
            when a.eur_hab_cnmc is not null then a.eur_hab_cnmc * p.poblacion / 1e6
            when a.meur_liquidado is not null then a.meur_liquidado
            else a.meur_presupuestado
        end as meur_nominal,
        case
            when a.meur_cnmc is not null then 'percibido_cnmc'
            when a.eur_hab_cnmc is not null then 'percibido_cnmc_eur_hab'
            when a.meur_liquidado is not null then 'liquidado'
            else 'presupuestado'
        end as tipo
    from agregado a
    left join pob p on p.cod = a.cod_ccaa and p.anio = a.anio
)

select
    cast(c.anio as integer) as anio,
    cast(c.cod_ccaa as varchar) as cod_ccaa,
    t.nombre,
    c.ente,
    c.meur_nominal,
    coalesce(c.meur_extra, 0) as meur_extraordinario,
    c.meur_nominal * d.factor as meur_real,
    1e6 * c.meur_nominal / c.poblacion as eur_hab_nominal,
    1e6 * c.meur_nominal / c.poblacion * d.factor as eur_hab_real,
    c.eur_hab_cnmc,
    c.poblacion,
    au.cuota_grupo as cuota_audiencia,
    au.cuota_principal as cuota_canal_principal,
    au.canal_principal,
    1e6 * c.meur_nominal / c.poblacion * d.factor / nullif(au.cuota_grupo, 0) as eur_hab_real_por_punto_cuota,
    g.familia,
    coalesce(co.color, '#94a3b8') as color,
    g.presidente,
    c.tipo,
    d.anio_base,
    c.nota
from calc c
join {{ ref('territorios_ccaa') }} t on t.cod_ccaa = c.cod_ccaa
left join {{ ref('deflactor') }} d on d.anio = c.anio
left join aud au on au.anio = c.anio and au.cod_ccaa = c.cod_ccaa
left join gobiernos g on g.cod = c.cod_ccaa
    and g.desde <= make_date(c.anio, 7, 1) and g.hasta > make_date(c.anio, 7, 1)
left join colores co on co.familia = g.familia
order by c.cod_ccaa, c.anio
