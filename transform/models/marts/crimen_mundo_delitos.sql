-- Delitos registrados por la policía en todos los países que informan a Naciones Unidas
-- (UNODC, UN-CTS; en Europa, la misma recogida que Eurostat), por tipo de delito, en tasa
-- por 100.000 habitantes. Más los homicidios intencionados (Banco Mundial con datos de
-- UNODC, los mismos de internacional_mundo) y los presos por 100.000 habitantes.
--
-- Comparar con cuidado: salvo los homicidios, lo que se compara son delitos REGISTRADOS,
-- que dependen de cuánto se denuncia (más donde hay más confianza en la policía o seguros
-- que lo exigen), de la definición legal de cada país (la violación, por ejemplo) y de
-- cómo se cuenta. Los homicidios son la cifra más comparable.
with delitos as (
    select * from (values
        ('homicidios', 'Homicidios intencionados', 1),
        ('Serious assault', 'Agresiones graves', 2),
        ('Kidnapping', 'Secuestros', 3),
        ('Sexual violence', 'Violencia sexual', 4),
        ('Sexual violence: Rape', 'Violaciones', 5),
        ('Robbery', 'Robos con violencia o intimidación', 6),
        ('Burglary', 'Robos con fuerza en viviendas y locales', 7),
        ('Theft', 'Hurtos', 8),
        ('Theft: of a motorized vehicle', 'Robos de vehículos', 9),
        ('Fraud', 'Estafas', 10),
        ('Fraud: Cyber-related (Cy)', 'Estafas informáticas', 11),
        ('Corruption', 'Corrupción', 12),
        ('Corruption: Bribery', 'Sobornos', 13),
        ('Money laundering', 'Blanqueo de capitales', 14),
        ('Smuggling of migrants', 'Tráfico de migrantes', 15),
        ('presos', 'Presos', 16)
    ) as t(categoria, delito, orden)
),

unodc as (
    select
        iso3, anio, categoria,
        max(valor) filter (where unidad like 'Rate%') as por_100k_hab,
        max(valor) filter (where unidad = 'Counts') as casos
    from {{ source('raw_criminalidad', 'unodc_delitos') }}
    group by iso3, anio, categoria
),

presos as (
    select
        iso3, anio, 'presos' as categoria,
        max(valor) filter (where unidad like 'Rate%' and situacion = 'Total') as por_100k_hab,
        max(valor) filter (where unidad = 'Counts' and situacion = 'Total') as casos
    from {{ source('raw_criminalidad', 'unodc_presos') }}
    group by iso3, anio
),

homicidios as (
    select p.iso3, m.anio, 'homicidios' as categoria, m.valor as por_100k_hab, null::double as casos
    from {{ ref('internacional_mundo') }} m
    join {{ ref('paises_iso') }} p on p.cod_pais = m.cod_pais
    where m.indicador_id = 'homicidios' and not m.es_agregado
),

todo as (
    select * from unodc
    union all select * from presos
    union all select * from homicidios
)

select
    d.categoria as delito_id,
    d.delito,
    d.orden,
    p.cod_pais,
    p.pais,
    p.region,
    p.es_europa,
    p.es_ue,
    p.es_ocde,
    t.anio,
    t.por_100k_hab,
    t.casos
from todo t
join delitos d using (categoria)
join {{ ref('paises_iso') }} p on p.iso3 = t.iso3 and not p.es_agregado
where t.por_100k_hab is not null
