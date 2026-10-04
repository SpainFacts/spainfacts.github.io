-- Vivienda social en alquiler: España frente a otros países, formato largo.
-- pct_parque_total: OCDE Affordable Housing Database PH4.2, viviendas
--   sociales en alquiler en % del parque total de viviendas (todas las
--   viviendas, también vacías y secundarias), hacia 2010 y hacia 2022 (el año
--   real de cada país); UE y OCDE son medias de la OCDE con el último dato.
--   España: 290.000 viviendas en 2019 (puede incluir otras viviendas de renta
--   reducida, como las de empresa).
-- pct_viviendas_principales: Tabla 2.1 del Boletín especial Vivienda Social 2024
--   del MIVAU (Eurostat, Housing Europe): % de las viviendas principales
--   (hogares) en alquiler social; dato de 2023 o, si no lo hay, de 2017. Para
--   España el boletín usa la ECV (alquiler inferior al precio de mercado, 3,3 %);
--   se añade como fila aparte el parque público estimado por el propio MIVAU
--   (1,72 % de los hogares) para no mezclar conceptos.
-- Cada fila lleva una sola de las dos definiciones (la otra columna es NULL): pct_parque_total
-- (OCDE, % del parque total) o pct_viviendas_principales (MIVAU/Eurostat, % de viviendas principales).
-- cod_pais: ISO alfa-2 (EU27_2020 la UE, OECD la OCDE; seed paises_iso).
with nombres (iso3, pais) as (
    values
    ('ESP', 'España'), ('EUU', 'Unión Europea'), ('OED', 'OCDE'), ('NLD', 'Países Bajos'),
    ('AUT', 'Austria'), ('DNK', 'Dinamarca'), ('GBR', 'Reino Unido (Inglaterra)'), ('FRA', 'Francia'),
    ('IRL', 'Irlanda'), ('ISL', 'Islandia'), ('FIN', 'Finlandia'), ('KOR', 'Corea del Sur'),
    ('POL', 'Polonia'), ('SVN', 'Eslovenia'), ('BEL', 'Bélgica'), ('NOR', 'Noruega'),
    ('NZL', 'Nueva Zelanda'), ('CZE', 'Chequia'), ('USA', 'Estados Unidos'), ('CAN', 'Canadá'),
    ('AUS', 'Australia'), ('JPN', 'Japón'), ('HUN', 'Hungría'), ('DEU', 'Alemania'),
    ('SVK', 'Eslovaquia'), ('ITA', 'Italia'), ('LVA', 'Letonia'), ('ISR', 'Israel'),
    ('EST', 'Estonia'), ('PRT', 'Portugal'), ('LTU', 'Lituania'), ('COL', 'Colombia'),
    ('CHE', 'Suiza'), ('MLT', 'Malta'), ('LUX', 'Luxemburgo'), ('SWE', 'Suecia'), ('GRC', 'Grecia'),
    ('BGR', 'Bulgaria'), ('CYP', 'Chipre'), ('HRV', 'Croacia'), ('ROU', 'Rumanía'), ('CHL', 'Chile'),
    ('TUR', 'Turquía')
),

-- países que la página destaca (los de referencia de vivienda social y los habituales)
destacados (iso3) as (
    values ('ESP'), ('EUU'), ('OED'), ('NLD'), ('AUT'), ('DNK'), ('FRA'), ('GBR'), ('DEU'), ('ITA'), ('PRT')
),

ocde as (
    select o.cod_pais as iso3, n.pais, cast(o.anio as integer) as anio,
        o.pct_parque as pct_parque_total, cast(null as double) as pct_viviendas_principales,
        o.viviendas_sociales, o.es_media as es_agregado,
        'OCDE, Affordable Housing Database (PH4.2)' as fuente
    from {{ source('raw_vivienda_publica', 'vp_ocde') }} o
    join nombres n on n.iso3 = o.cod_pais
),

ue as (
    select e.cod_pais as iso3,
        case when e.cod_pais = 'ESP' then 'España (alquiler bajo mercado, ECV)' else n.pais end as pais,
        cast(e.anio_dato as integer) as anio, cast(null as double) as pct_parque_total,
        e.pct_social as pct_viviendas_principales,
        cast(e.viviendas_sociales as double) as viviendas_sociales, e.cod_pais = 'EUU' as es_agregado,
        'MIVAU, Boletín especial Vivienda Social 2024 (Eurostat, Housing Europe)' as fuente
    from {{ source('raw_vivienda_publica', 'vp_europa') }} e
    join nombres n on n.iso3 = e.cod_pais
),

espana_publico as (
    select 'ESP' as iso3, 'España (parque público, MIVAU)' as pais,
        cast(anio as integer) as anio, cast(null as double) as pct_parque_total,
        max(valor) filter (where concepto = 'pct_hogares') as pct_viviendas_principales,
        max(valor) filter (where concepto = 'parque_alquiler_publico') as viviendas_sociales,
        false as es_agregado,
        'MIVAU, Encuesta sobre vivienda social 2023' as fuente
    from {{ source('raw_vivienda_publica', 'vp_nacional') }}
    group by anio
),

todo as (
    select * from ocde
    union all select * from ue
    union all select * from espana_publico
)

select
    i.cod_pais,
    t.pais,
    t.anio,
    t.pct_parque_total,
    t.pct_viviendas_principales,
    cast(t.viviendas_sociales as bigint) as viviendas_sociales,
    t.es_agregado,
    t.iso3 = 'ESP' as es_espana,
    d.iso3 is not null as destacado,
    -- último dato de cada país en cada definición (OCDE o MIVAU/Eurostat)
    row_number() over (
        partition by t.pct_parque_total is not null, t.pais order by t.anio desc
    ) = 1 as es_ultimo,
    t.fuente
from todo t
join {{ ref('paises_iso') }} i on i.iso3 = t.iso3
left join destacados d on d.iso3 = t.iso3
order by t.pct_parque_total is null, coalesce(t.pct_parque_total, t.pct_viviendas_principales) desc
