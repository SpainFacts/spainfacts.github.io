-- Nombre de territorio tal como lo escribe el INE en las series de vivienda
-- (ETDP, Hipotecas, IPV) -> nivel ('pais' / 'ccaa' / 'provincia') y código INE.
-- Parte de las semillas ine_ccaa_nombres e ine_provincias_nombres y añade las
-- variantes de provincia que usan estas tablas ('Coruña, A', 'Bizkaia'...).
-- Las comunidades uniprovinciales (Cantabria, La Rioja, Illes Balears...) y
-- Ceuta y Melilla aparecen dos veces en la ETDP, como comunidad y como
-- provincia, con el mismo valor: por eso un nombre puede tener dos filas.
with ccaa as (
    select
        nombre_ine,
        case when cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
        cast(cod_ccaa as varchar) as cod
    from {{ ref('ine_ccaa_nombres') }}
    union all
    select 'Nacional', 'pais', '00'
),

provincias as (
    select nombre_ine, 'provincia' as nivel, cast(cod_prov as varchar) as cod
    from {{ ref('ine_provincias_nombres') }}
    union all
    select * from (values
        ('Coruña, A', 'provincia', '15'),
        ('Gipuzkoa', 'provincia', '20'),
        ('Bizkaia', 'provincia', '48'),
        ('Araba/Álava', 'provincia', '01'),
        ('Palmas, Las', 'provincia', '35'),
        ('Rioja, La', 'provincia', '26'),
        ('Balears, Illes', 'provincia', '07'),
        ('Cantabria', 'provincia', '39'),
        ('Ceuta', 'provincia', '51'),
        ('Melilla', 'provincia', '52')
    ) as t(nombre_ine, nivel, cod)
)

select distinct nombre_ine, nivel, cod from ccaa
union
select distinct nombre_ine, nivel, cod from provincias
