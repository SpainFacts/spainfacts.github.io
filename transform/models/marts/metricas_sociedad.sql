-- Series de seguimiento (nivel España) de las secciones Sociedad y Demografía para
-- el catálogo de indicadores (/varios/indicadores/). Formato largo: una fila por
-- (metrica_id, periodo). Cada serie reproduce la consulta de la tarjeta KPI de su
-- página (mismo filtro y mismo ajuste): tasas por habitante y euros reales tal y
-- como ya los calculan los marts (renta_ecv_ccaa, educacion_gasto, sanidad_gasto).

with

-- ---------------------------------------------------------------- Demografía
env as (
    select * from {{ ref('demografia_envejecimiento') }} where nivel = 'pais'
),

anual as (
    select * from {{ ref('demografia_anual') }} where nivel = 'pais'
),

hogares as (
    select * from {{ ref('demografia_hogares') }} where nivel = 'pais'
),

-- Hombres por cada 100 mujeres de 85 y más años (pirámide por grupos)
ratio_85 as (
    select anio,
        100.0 * max(poblacion) filter (where sexo = 'Hombres')
            / max(poblacion) filter (where sexo = 'Mujeres') as valor
    from {{ ref('demografia_piramide') }}
    where nivel = 'pais' and edad_desde = 85
    group by anio
),

-- Concentración provincial (página distribucion-territorial)
prov_serie as (
    select e.anio, e.cod, e.poblacion, a.poblacion as poblacion_antes,
        e.poblacion / sum(e.poblacion) over (partition by e.anio) as cuota,
        row_number() over (partition by e.anio order by e.poblacion desc) as puesto
    from {{ ref('demografia_envejecimiento') }} e
    left join {{ ref('demografia_envejecimiento') }} a
        on a.nivel = 'provincia' and a.cod = e.cod and a.anio = e.anio - 1
    where e.nivel = 'provincia'
),

concentracion as (
    select anio,
        count(*) filter (where poblacion < poblacion_antes) as pierden,
        100 * sum(cuota) filter (where puesto <= 5) as pct_top5,
        count(*) filter (where acumulada - cuota < 0.5) as provincias_mitad
    from (
        select *, sum(cuota) over (partition by anio order by puesto) as acumulada
        from prov_serie
    )
    where anio >= 1975
    group by anio
),

-- ---------------------------------------------------------------- Criminalidad
-- Balance de Criminalidad (2019-) empalmado con la serie larga (antes de 2019),
-- igual que el sparkline de la página.
crimen_b as (
    select anio, categoria, infracciones, tasa_1000
    from {{ ref('crimen_balance') }}
    where nivel = 'pais'
),

crimen_l as (
    select anio,
        case when tipologia = 'TOTAL INFRACCIONES PENALES' then 'Total infracciones penales'
             else 'Homicidios y asesinatos consumados' end as categoria,
        max(tasa_1000) as tasa_1000
    from {{ ref('crimen_serie_larga') }}
    where nivel = 'pais' and (tipologia = 'TOTAL INFRACCIONES PENALES' or codigo_tipologia = '1.1.1')
    group by 1, 2
),

crimen_tasas as (
    select anio, categoria, tasa_1000
    from crimen_b
    where categoria in ('Total infracciones penales', 'Homicidios y asesinatos consumados')
    union all
    select anio, categoria, tasa_1000
    from crimen_l
    where anio < (select min(anio) from crimen_b)
),

crimen_ciber as (
    select c.anio, 100.0 * c.infracciones / t.infracciones as valor
    from crimen_b c
    join crimen_b t on t.anio = c.anio and t.categoria = 'Total infracciones penales'
    where c.categoria = 'Cibercriminalidad'
),

-- ---------------------------------------------------------------- Renta y desigualdad
ecv as (
    select * from {{ ref('renta_ecv_ccaa') }} where cod = '00'
),

-- ---------------------------------------------------------------- Educación
edu as (
    select * from {{ ref('educacion_indicadores') }} where nivel = 'pais'
),

edu_gasto as (
    select * from {{ ref('educacion_gasto') }} where nivel = 'pais' and funcion = 'Total'
),

-- ---------------------------------------------------------------- Elecciones
generales as (
    select *, ganador_pct + segundo_pct as dos_primeros
    from {{ ref('elecciones_participacion') }}
    where nivel = 'pais' and tipo = '02'
),

-- ---------------------------------------------------------------- Inmigración
llegadas as (
    select year(mes) as anio, sum(personas) as personas, count(distinct mes) as meses
    from {{ ref('inmigracion_llegadas') }}
    group by 1
),

-- ---------------------------------------------------------------- Salud y sanidad
causas as (
    select anio, codigo_causa, tasa_100k
    from {{ ref('salud_causas_muerte') }}
    where nivel = 'pais' and sexo = 'Total' and codigo_causa in ('001-102', '098', '090')
),

listas as (
    select * from {{ ref('sanidad_listas_espera') }} where nivel = 'pais'
),

san_rec as (
    select * from {{ ref('sanidad_recursos') }} where cod_pais = 'ES'
),

san_gasto as (
    select * from {{ ref('sanidad_gasto') }} where cod_pais = 'ES'
),

series as (

    -- ===================== Demografía =====================
    select 'demografia_poblacion' as metrica_id, 'Población residente' as nombre,
        make_date(cast(anio as integer), 1, 1) as periodo, poblacion as valor, 'personas' as unidad,
        'INE' as fuente, 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945' as url_fuente,
        'Demografía' as tema, '/demografia/evolucion-poblacion/' as pagina, 'Anual' as frecuencia
    from env

    union all
    select 'demografia_crecimiento_1000', 'Crecimiento anual de la población',
        make_date(cast(anio as integer), 1, 1), crecimiento_1000, 'por 1.000 hab',
        'INE', 'https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002',
        'Demografía', '/demografia/evolucion-poblacion/', 'Anual'
    from anual

    union all
    select 'demografia_vegetativo_1000', 'Nacimientos menos defunciones (crecimiento vegetativo)',
        make_date(cast(anio as integer), 1, 1), vegetativo_1000, 'por 1.000 hab',
        'INE', 'https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002',
        'Demografía', '/demografia/evolucion-poblacion/', 'Anual'
    from anual

    union all
    select 'demografia_migracion_1000', 'Migración y ajustes (crecimiento no vegetativo)',
        make_date(cast(anio as integer), 1, 1), resto_1000, 'por 1.000 hab',
        'INE', 'https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002',
        'Demografía', '/demografia/evolucion-poblacion/', 'Anual'
    from anual

    union all
    select 'demografia_tasa_natalidad', 'Tasa de natalidad',
        make_date(cast(anio as integer), 1, 1), tasa_natalidad, 'por 1.000 hab',
        'INE', 'https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002',
        'Demografía', '/demografia/natalidad/', 'Anual'
    from anual

    union all
    select 'demografia_fecundidad', 'Hijos por mujer (indicador coyuntural de fecundidad)',
        make_date(cast(anio as integer), 1, 1), fecundidad, 'hijos por mujer',
        'INE', 'https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002',
        'Demografía', '/demografia/natalidad/', 'Anual'
    from anual

    union all
    select 'demografia_edad_maternidad', 'Edad media de las madres',
        make_date(cast(anio as integer), 1, 1), edad_maternidad, 'años',
        'INE', 'https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002',
        'Demografía', '/demografia/natalidad/', 'Anual'
    from anual

    union all
    select 'demografia_madre_extranjera', 'Nacimientos de madre extranjera',
        make_date(cast(anio as integer), 1, 1), pct_madre_extranjera, '%',
        'INE', 'https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002',
        'Demografía', '/demografia/natalidad/', 'Anual'
    from anual

    union all
    select 'demografia_pct_65', 'Mayores de 65 años',
        make_date(cast(anio as integer), 1, 1), pct_65, '% de la población',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945',
        'Demografía', '/demografia/estructura-edades/', 'Anual'
    from env

    union all
    select 'demografia_pct_80', 'Mayores de 80 años',
        make_date(cast(anio as integer), 1, 1), pct_80, '% de la población',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945',
        'Demografía', '/demografia/estructura-edades/', 'Anual'
    from env

    union all
    select 'demografia_dependencia', 'Tasa de dependencia',
        make_date(cast(anio as integer), 1, 1), dependencia, '%',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945',
        'Demografía', '/demografia/estructura-edades/', 'Anual'
    from env

    union all
    select 'demografia_edad_media', 'Edad media de la población',
        make_date(cast(anio as integer), 1, 1), edad_media, 'años',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945',
        'Demografía', '/demografia/estructura-edades/', 'Anual'
    from env

    union all
    select 'demografia_hombres_por_100_mujeres', 'Hombres por cada 100 mujeres',
        make_date(cast(anio as integer), 1, 1), hombres_por_100_mujeres, 'hombres por 100 mujeres',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945',
        'Demografía', '/demografia/poblacion-sexo/', 'Anual'
    from env

    union all
    select 'demografia_hombres_por_100_mujeres_65', 'Hombres por cada 100 mujeres (65 y más años)',
        make_date(cast(anio as integer), 1, 1), hombres_por_100_mujeres_65, 'hombres por 100 mujeres',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945',
        'Demografía', '/demografia/poblacion-sexo/', 'Anual'
    from env

    union all
    select 'demografia_hombres_por_100_mujeres_85', 'Hombres por cada 100 mujeres (85 y más años)',
        make_date(cast(anio as integer), 1, 1), valor, 'hombres por 100 mujeres',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945',
        'Demografía', '/demografia/poblacion-sexo/', 'Anual'
    from ratio_85

    union all
    select 'demografia_tamano_hogar', 'Personas por hogar (tamaño medio)',
        make_date(cast(anio as integer), 1, 1), tamano_medio, 'personas por hogar',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=60133',
        'Demografía', '/demografia/hogares/', 'Anual'
    from hogares

    union all
    select 'demografia_hogares_unipersonales', 'Hogares de una persona',
        make_date(cast(anio as integer), 1, 1), pct_unipersonales, '% de los hogares',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=60133',
        'Demografía', '/demografia/hogares/', 'Anual'
    from hogares

    union all
    select 'demografia_hogares_4_o_mas', 'Hogares de 4 o más personas',
        make_date(cast(anio as integer), 1, 1), pct_4_o_mas, '% de los hogares',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=60133',
        'Demografía', '/demografia/hogares/', 'Anual'
    from hogares

    union all
    select 'demografia_provincias_mitad', 'Provincias donde vive la mitad de la población',
        make_date(cast(anio as integer), 1, 1), provincias_mitad, 'provincias (de 52)',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945',
        'Demografía', '/demografia/distribucion-territorial/', 'Anual'
    from concentracion

    union all
    select 'demografia_pct_top5_provincias', 'Población en las 5 provincias más pobladas',
        make_date(cast(anio as integer), 1, 1), pct_top5, '% de la población',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945',
        'Demografía', '/demografia/distribucion-territorial/', 'Anual'
    from concentracion

    union all
    select 'demografia_provincias_pierden', 'Provincias que pierden población',
        make_date(cast(anio as integer), 1, 1), pierden, 'provincias (de 52)',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945',
        'Demografía', '/demografia/distribucion-territorial/', 'Anual'
    from concentracion
    where anio > (select min(anio) from prov_serie)

    union all
    select 'demografia_nacidos_extranjero', 'Población nacida en el extranjero',
        make_date(cast(anio as integer), 1, 1), pct_nacidos_extranjero, '% de la población',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56948',
        'Demografía', '/demografia/distribucion-territorial/', 'Anual'
    from env

    -- ===================== Criminalidad =====================
    union all
    select 'sociedad_criminalidad_tasa', 'Infracciones penales conocidas',
        make_date(cast(anio as integer), 1, 1), tasa_1000, 'por 1.000 hab',
        'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/',
        'Sociedad', '/sociedad/criminalidad/', 'Anual'
    from crimen_tasas
    where categoria = 'Total infracciones penales'

    union all
    select 'sociedad_homicidios_tasa', 'Homicidios y asesinatos consumados',
        make_date(cast(anio as integer), 1, 1), tasa_1000 * 100, 'por 100.000 hab',
        'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/',
        'Sociedad', '/sociedad/criminalidad/', 'Anual'
    from crimen_tasas
    where categoria = 'Homicidios y asesinatos consumados'

    union all
    select 'sociedad_cibercriminalidad_pct', 'Cibercriminalidad (peso sobre el total de infracciones)',
        make_date(cast(anio as integer), 1, 1), valor, '% de las infracciones',
        'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/',
        'Sociedad', '/sociedad/criminalidad/', 'Anual'
    from crimen_ciber

    -- ===================== Renta y desigualdad (ECV) =====================
    union all
    select 'sociedad_renta_persona_real', 'Renta neta media por persona (real)',
        make_date(cast(anio_renta as integer), 1, 1), renta_persona_real,
        '€/hab (€ de ' || cast(anio_base as varchar) || ')',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=9947',
        'Sociedad', '/sociedad/desigualdad/', 'Anual'
    from ecv

    union all
    select 'sociedad_riesgo_pobreza', 'Tasa de riesgo de pobreza',
        make_date(cast(anio as integer), 1, 1), tasa_pobreza, '% de la población',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=9947',
        'Sociedad', '/sociedad/desigualdad/', 'Anual'
    from ecv

    union all
    select 'sociedad_arope', 'Riesgo de pobreza o exclusión social (AROPE)',
        make_date(cast(anio as integer), 1, 1), arope, '% de la población',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=9947',
        'Sociedad', '/sociedad/desigualdad/', 'Anual'
    from ecv

    union all
    select 'sociedad_gini', 'Índice de Gini',
        make_date(cast(anio as integer), 1, 1), gini, 'índice (0-100)',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=9947',
        'Sociedad', '/sociedad/desigualdad/', 'Anual'
    from ecv

    -- ===================== Educación =====================
    union all
    select 'sociedad_abandono_escolar', 'Abandono escolar temprano (18-24 años)',
        make_date(cast(anio as integer), 1, 1), valor, '%',
        'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_14',
        'Sociedad', '/sociedad/educacion/', 'Anual'
    from edu
    where indicador = 'abandono'

    union all
    select 'sociedad_estudios_superiores', 'Adultos de 25 a 64 años con estudios superiores',
        make_date(cast(anio as integer), 1, 1), valor, '%',
        'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_03',
        'Sociedad', '/sociedad/educacion/', 'Anual'
    from edu
    where indicador = 'superior_25_64'

    union all
    select 'sociedad_ninis', 'Jóvenes de 15 a 29 años que ni estudian ni trabajan',
        make_date(cast(anio as integer), 1, 1), valor, '%',
        'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_20',
        'Sociedad', '/sociedad/educacion/', 'Anual'
    from edu
    where indicador = 'neet_15_29'

    union all
    select 'sociedad_gasto_educacion_hab', 'Gasto público en educación por habitante (real)',
        make_date(cast(anio as integer), 1, 1), eur_hab_real,
        '€/hab (€ de ' || cast(anio_base as varchar) || ')',
        'Eurostat / IGAE', 'https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp',
        'Sociedad', '/sociedad/educacion/', 'Anual'
    from edu_gasto

    -- ===================== Elecciones generales =====================
    -- Una fila por elección; el periodo es el mes de la votación (en 2019 hubo dos).
    union all
    select 'sociedad_participacion_generales', 'Participación en las elecciones generales',
        cast(date_trunc('month', fecha) as date), participacion, '% del censo',
        'Ministerio del Interior', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/',
        'Sociedad', '/sociedad/elecciones/', 'Anual'
    from generales

    union all
    select 'sociedad_nep_votos', 'Número efectivo de partidos (en votos, generales)',
        cast(date_trunc('month', fecha) as date), nep_votos, 'partidos',
        'Cálculo propio (Ministerio del Interior)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/',
        'Sociedad', '/sociedad/elecciones/', 'Anual'
    from generales

    union all
    select 'sociedad_voto_dos_primeros', 'Voto a las dos candidaturas más votadas (generales)',
        cast(date_trunc('month', fecha) as date), dos_primeros, '% de los votos válidos',
        'Ministerio del Interior', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/',
        'Sociedad', '/sociedad/elecciones/', 'Anual'
    from generales

    -- ===================== Inmigración =====================
    union all
    select 'sociedad_extranjeros_pct', 'Residentes extranjeros',
        make_date(cast(anio as integer), 1, 1), extranjeros_pct, '% de la población',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56942',
        'Sociedad', '/sociedad/inmigracion/', 'Anual'
    from {{ ref('inmigracion_poblacion') }}
    where nivel = 'pais'

    union all
    select 'sociedad_saldo_migratorio_1000', 'Saldo migratorio con el extranjero',
        make_date(cast(anio as integer), 1, 1), saldo_1000, 'por 1.000 hab',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=69758',
        'Sociedad', '/sociedad/inmigracion/', 'Anual'
    from {{ ref('inmigracion_flujos_anuales') }}

    union all
    select 'sociedad_llegadas_irregulares', 'Llegadas irregulares por mar y tierra',
        make_date(cast(anio as integer), 1, 1), personas, 'personas',
        'Interior / ACNUR', 'https://data.unhcr.org/en/situations/europe-sea-arrivals/location/24522',
        'Sociedad', '/sociedad/inmigracion/', 'Anual'
    from llegadas
    where meses = 12

    union all
    select 'sociedad_nacionalizaciones_1000', 'Nacionalizaciones (nuevos españoles)',
        make_date(cast(anio as integer), 1, 1), por_1000_extranjeros, 'por 1.000 extranjeros',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=70012',
        'Sociedad', '/sociedad/inmigracion/', 'Anual'
    from {{ ref('inmigracion_nacionalizaciones') }}
    where cod = '00' and nacionalidad_previa = 'Total'

    -- ===================== Salud =====================
    union all
    select 'sociedad_esperanza_vida', 'Esperanza de vida al nacer',
        make_date(cast(anio as integer), 1, 1), anios, 'años',
        'INE / Eurostat', 'https://www.ine.es/jaxiT3/Tabla.htm?t=1448',
        'Sociedad', '/sociedad/salud/', 'Anual'
    from {{ ref('salud_esperanza_vida') }}
    where nivel = 'pais' and sexo = 'Ambos sexos'

    union all
    select 'sociedad_mortalidad_1000', 'Tasa de mortalidad (todas las causas)',
        make_date(cast(anio as integer), 1, 1), tasa_100k / 100, 'por 1.000 hab',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=9936',
        'Sociedad', '/sociedad/salud/', 'Anual'
    from causas
    where codigo_causa = '001-102'

    union all
    select 'sociedad_suicidios_100k', 'Suicidios',
        make_date(cast(anio as integer), 1, 1), tasa_100k, 'por 100.000 hab',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=9936',
        'Sociedad', '/sociedad/salud/', 'Anual'
    from causas
    where codigo_causa = '098'

    union all
    select 'sociedad_muertes_trafico_100k', 'Muertos en accidentes de tráfico',
        make_date(cast(anio as integer), 1, 1), tasa_100k, 'por 100.000 hab',
        'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=9936',
        'Sociedad', '/sociedad/salud/', 'Anual'
    from causas
    where codigo_causa = '090'

    -- ===================== Sanidad =====================
    -- Listas de espera: cortes a 30 de junio y 31 de diciembre (periodo = mes del corte).
    union all
    select 'sociedad_lista_espera_quirurgica', 'Lista de espera quirúrgica',
        cast(date_trunc('month', fecha) as date), tasa_1000, 'por 1.000 hab',
        'Ministerio de Sanidad', 'https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm',
        'Sociedad', '/sociedad/salud/', 'Semestral'
    from listas
    where tipo = 'quirurgica'

    union all
    select 'sociedad_espera_quirurgica_dias', 'Espera media para operarse',
        cast(date_trunc('month', fecha) as date), dias_medio, 'días',
        'Ministerio de Sanidad', 'https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm',
        'Sociedad', '/sociedad/salud/', 'Semestral'
    from listas
    where tipo = 'quirurgica'

    union all
    select 'sociedad_espera_especialista_dias', 'Espera media para el especialista (primera consulta)',
        cast(date_trunc('month', fecha) as date), dias_medio, 'días',
        'Ministerio de Sanidad', 'https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm',
        'Sociedad', '/sociedad/salud/', 'Semestral'
    from listas
    where tipo = 'consultas'

    union all
    select 'sociedad_gasto_sanitario_publico_hab', 'Gasto sanitario público por habitante (real)',
        make_date(cast(anio as integer), 1, 1), eur_hab_real,
        '€/hab (€ de ' || cast(anio_base as varchar) || ')',
        'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/hlth_sha11_hf',
        'Sociedad', '/sociedad/salud/', 'Anual'
    from san_gasto
    where financiacion = 'Público'

    union all
    select 'sociedad_gasto_sanitario_hogares_hab', 'Pago directo de los hogares en sanidad por habitante (real)',
        make_date(cast(anio as integer), 1, 1), eur_hab_real,
        '€/hab (€ de ' || cast(anio_base as varchar) || ')',
        'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/hlth_sha11_hf',
        'Sociedad', '/sociedad/salud/', 'Anual'
    from san_gasto
    where financiacion = 'Pago directo de los hogares'

    union all
    select 'sociedad_medicos_1000', 'Médicos',
        make_date(cast(anio as integer), 1, 1), por_1000, 'por 1.000 hab',
        'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_prs2',
        'Sociedad', '/sociedad/salud/', 'Anual'
    from san_rec
    where recurso = 'medicos'

    union all
    select 'sociedad_enfermeras_1000', 'Enfermeras',
        make_date(cast(anio as integer), 1, 1), por_1000, 'por 1.000 hab',
        'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_prs2',
        'Sociedad', '/sociedad/salud/', 'Anual'
    from san_rec
    where recurso = 'enfermeras'

    union all
    select 'sociedad_camas_hospital_1000', 'Camas de hospital',
        make_date(cast(anio as integer), 1, 1), por_1000, 'por 1.000 hab',
        'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_bds1',
        'Sociedad', '/sociedad/salud/', 'Anual'
    from san_rec
    where recurso = 'camas'
)

select
    cast(metrica_id as varchar) as metrica_id,
    cast(nombre as varchar) as nombre,
    cast(periodo as date) as periodo,
    cast(valor as double) as valor,
    cast(unidad as varchar) as unidad,
    cast(fuente as varchar) as fuente,
    cast(url_fuente as varchar) as url_fuente,
    cast(tema as varchar) as tema,
    cast(pagina as varchar) as pagina,
    cast(frecuencia as varchar) as frecuencia
from series
where valor is not null
