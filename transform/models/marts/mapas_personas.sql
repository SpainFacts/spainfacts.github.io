-- Catálogo largo de indicadores territoriales (comunidad y provincia) de Economía,
-- Sociedad y Demografía para el explorador de mapas (/varios/mapas/).
-- Una fila por indicador, territorio y año. Se construye en dos pasos:
--   1) datos: cada bloque saca de un mart existente (nivel, cod, anio) y columnas
--      anchas; UNPIVOT las pasa a (src, col, valor) y descarta los nulos.
--   2) meta: una fila por (src, col) con el nombre, la unidad, el sentido, la fuente
--      y los niveles en que se publica. Si un indicador está en los dos niveles su
--      id lleva el sufijo _ccaa / _prov.
-- Códigos INE (cod_ccaa '01'..'19', cod_prov '01'..'52'); se descartan España y
-- cualquier fila sin territorio en main.territorios. Importes en euros constantes
-- (main.deflactor, vía los marts de origen) y por habitante; totales convertidos en
-- tasas salvo la propia población.
-- Series infraanuales: media de los periodos publicados del año (EPA, paro
-- registrado) o último dato del año (IPC, listas de espera, viviendas turísticas);
-- el año en curso puede ser parcial (lo indica la nota).
-- No hay PIB regional cargado (Contabilidad Regional del INE): no se incluye.

with terr as (
    select nivel, cod, nombre
    from {{ ref('territorios') }}
    where nivel in ('ccaa', 'provincia')
),

-- comunidades con una sola provincia (y Ceuta y Melilla): permiten rellenar el nivel
-- provincial cuando la fuente solo las publica como comunidad
uniprov as (
    select cod_ccaa, min(cod) as cod_prov
    from {{ ref('territorios') }}
    where nivel = 'provincia'
    group by cod_ccaa
    having count(*) = 1
),

-- ============================== ECONOMÍA ==============================

epa as (
    select 'epa' as src, nivel, cod, cast(year(trimestre) as integer) as anio,
        avg(tasa_paro) as tasa_paro,
        avg(tasa_paro_menor25) as tasa_paro_menor25,
        avg(tasa_paro_extranjeros) as tasa_paro_extranjeros,
        avg(tasa_paro_mujeres) as tasa_paro_mujeres,
        avg(pct_hogares_todos_parados) as pct_hogares_todos_parados,
        avg(tasa_empleo) as tasa_empleo,
        avg(tasa_actividad) as tasa_actividad
    from {{ ref('mercado_paro_territorios') }}
    group by all
),

paro_reg as (
    select 'paro_reg' as src, nivel, cod, cast(year(mes) as integer) as anio,
        avg(por_100_16_64) as por_100_16_64
    from {{ ref('mercado_paro_registrado') }}
    group by all
),

ipc as (
    select 'ipc' as src, 'ccaa' as nivel, cod_ccaa as cod, anio, var_anual, subida_desde_2019
    from {{ ref('mercado_ipc_ccaa') }}
    qualify row_number() over (partition by cod_ccaa, anio order by mes desc) = 1
),

salarios as (
    select 'salarios' as src, 'ccaa' as nivel, cod, anio, salario_real, coste_laboral_real
    from {{ ref('economia_salarios_ccaa') }}
),

dirce as (
    select 'dirce' as src, nivel, cod, anio, empresas_1000hab
    from {{ ref('empresas_dirce_territorio') }}
),

sociedades as (
    select 'sociedades' as src, 'ccaa' as nivel, cod, anio, constituidas_100k, saldo_100k, capital_real_hab
    from {{ ref('empresas_sociedades_anual') }}
),

concursos as (
    select 'concursos' as src, 'ccaa' as nivel, cod, anio, concursos_100k
    from {{ ref('empresas_concursos') }}
),

autonomos as (
    select 'autonomos' as src, 'ccaa' as nivel, cod, anio, pct_cuenta_propia
    from {{ ref('empresas_autonomos_anual') }}
),

idi as (
    select 'idi' as src, 'ccaa' as nivel, cod, anio, pct_pib, eur_hab_real, investigadores_1000ocup
    from {{ ref('empresas_id_ccaa') }}
    where sector = 'Total'
),

turismo as (
    -- solo años completos de la encuesta hotelera
    select 'turismo' as src, 'ccaa' as nivel, cod_ccaa as cod, anio,
        pernoct_1000hab, pct_extranjeros_hotel, ocupacion_hotel
    from {{ ref('turismo_ccaa') }}
    where meses_hotel = 12
),

vut as (
    select 'vut' as src, nivel, cod, anio, viviendas_1000hab, pct_viviendas
    from {{ ref('turismo_viviendas') }}
    qualify row_number() over (partition by nivel, cod, anio order by periodo desc) = 1
),

-- ============================== SOCIEDAD ==============================

ecv as (
    select 'ecv' as src, nivel, cod, anio,
        renta_persona_real, tasa_pobreza, arope, carencia_severa, fin_mes_dificultad, gini, s80_s20
    from {{ ref('renta_ecv_ccaa') }}
),

adrh as (
    select 'adrh' as src, nivel, cod, anio, renta_persona_real, renta_uc_mediana_real
    from {{ ref('renta_territorios') }}
),

educ as (
    pivot (
        select nivel, cod, anio, indicador, valor
        from {{ ref('educacion_indicadores') }}
        where nivel = 'ccaa'
    ) on indicador in ('abandono', 'superior_25_64', 'basica_25_64', 'neet_15_29')
    using max(valor)
),

educacion as (
    select 'educacion' as src, * from educ
),

san_gasto as (
    select 'san_gasto' as src, nivel, cod, anio, eur_hab_real
    from {{ ref('sanidad_gasto_ccaa') }}
    where nivel = 'ccaa'
),

san_recursos as (
    select 'san_recursos' as src, nivel, cod, anio,
        max(por_100k) filter (where recurso = 'medicos') as medicos_100k,
        max(por_100k) filter (where recurso = 'camas') as camas_100k
    from {{ ref('sanidad_recursos_ccaa') }}
    where nivel = 'ccaa'
    group by all
),

listas_ult as (
    select *
    from {{ ref('sanidad_listas_espera') }}
    where nivel = 'ccaa'
    qualify row_number() over (partition by tipo, cod, anio order by fecha desc) = 1
),

listas as (
    select 'listas' as src, nivel, cod, anio,
        max(tasa_1000) filter (where tipo = 'quirurgica') as quir_tasa_1000,
        max(pct_espera_larga) filter (where tipo = 'quirurgica') as quir_pct_6meses,
        max(dias_medio) filter (where tipo = 'quirurgica') as quir_dias,
        max(dias_medio) filter (where tipo = 'consultas') as cons_dias,
        max(pct_espera_larga) filter (where tipo = 'consultas') as cons_pct_60dias
    from listas_ult
    group by all
),

esperanza as (
    select 'esperanza' as src, nivel, cod, anio, anios as esperanza_vida
    from {{ ref('salud_esperanza_vida') }}
    where sexo = 'Ambos sexos'
),

crimen_total as (
    select 'crimen_total' as src, nivel, cod, anio, tasa_1000
    from {{ ref('crimen_serie_larga') }}
    where tipologia = 'TOTAL INFRACCIONES PENALES'
),

crimen_cat_base as (
    select nivel, cod, anio,
        max(tasa_1000) filter (where categoria = 'Criminalidad convencional') as convencional,
        max(tasa_1000) filter (where categoria = 'Cibercriminalidad') as ciber,
        100 * max(tasa_1000) filter (where categoria = 'Homicidios y asesinatos consumados') as homicidios_100k,
        max(tasa_1000) filter (where categoria = 'Robos con violencia o intimidación') as robos_violencia,
        max(tasa_1000) filter (where categoria = 'Robos con fuerza en domicilios') as robos_domicilios,
        max(tasa_1000) filter (where categoria = 'Hurtos') as hurtos,
        100 * max(tasa_1000) filter (where categoria = 'Delitos contra la libertad sexual') as sexuales_100k,
        100 * max(tasa_1000) filter (where categoria = 'Tráfico de drogas') as drogas_100k
    from {{ ref('crimen_balance') }}
    where nivel in ('ccaa', 'provincia')
    group by all
),

crimen_cat as (
    select 'crimen_cat' as src, * from crimen_cat_base
    union all by name
    -- el Balance solo publica como comunidad las uniprovinciales, Ceuta y Melilla
    select 'crimen_cat' as src, 'provincia' as nivel, u.cod_prov as cod, c.* exclude (nivel, cod)
    from crimen_cat_base c
    join uniprov u on u.cod_ccaa = c.cod
    where c.nivel = 'ccaa'
      and not exists (
          select 1 from crimen_cat_base p
          where p.nivel = 'provincia' and p.cod = u.cod_prov and p.anio = c.anio
      )
),

condenados as (
    select 'condenados' as src, nivel, cod, anio, tasa_1000
    from {{ ref('crimen_condenados') }}
    where sexo = 'Total' and nacionalidad = 'Total'
),

extranjeros as (
    select 'extranjeros' as src, nivel, cod, anio, pct_extranjeros, pct_nacidos_extranjero
    from {{ ref('demografia_envejecimiento') }}
),

nacionalizaciones as (
    select 'nacionalizaciones' as src, 'ccaa' as nivel, cod, anio, por_1000_extranjeros
    from {{ ref('inmigracion_nacionalizaciones') }}
    where nacionalidad_previa = 'Total'
),

saldo_ext as (
    select 'saldo_ext' as src, nivel, cod, anio, saldo_1000
    from {{ ref('inmigracion_saldos') }}
    where nacionalidad = 'Total'
),

-- elecciones: si hay dos del mismo tipo en un año (Congreso 2019), la última
procesos as (
    select distinct tipo, anio, proceso, fecha
    from {{ ref('elecciones_participacion') }}
    qualify row_number() over (partition by tipo, anio order by fecha desc) = 1
),

participacion as (
    select 'participacion' as src, e.nivel, e.cod, cast(e.anio as integer) as anio,
        max(e.participacion) filter (where e.tipo = '02') as congreso,
        max(e.participacion) filter (where e.tipo = '04') as municipales,
        max(e.participacion) filter (where e.tipo = '07') as europeas
    from {{ ref('elecciones_participacion') }} e
    join procesos p using (proceso)
    group by all
),

fam as (
    select f.nivel, f.cod, cast(f.anio as integer) as anio, f.proceso,
        case f.familia
            when 'PSOE' then 'psoe'
            when 'PP' then 'pp'
            when 'Vox' then 'vox'
            when 'IU, Podemos y Sumar' then 'iu_podemos_sumar'
            when 'Ciudadanos' then 'cs'
        end as col,
        f.bloque,
        f.pct
    from {{ ref('elecciones_familias') }} f
    join procesos p using (proceso)
    where f.tipo = '02' and f.nivel in ('ccaa', 'provincia')
),

-- familias: donde no se presentó en ese proceso, 0 %
fam_col as (
    select a.nivel, a.cod, a.anio, a.proceso, c.col, coalesce(sum(f.pct), 0) as valor
    from (select distinct nivel, cod, anio, proceso from fam) a
    join (select distinct proceso, col from fam where col is not null) c using (proceso)
    left join fam f on f.nivel = a.nivel and f.cod = a.cod and f.proceso = a.proceso and f.col = c.col
    group by all
),

bloques as (
    select a.nivel, a.cod, a.anio, a.proceso, b.col, coalesce(sum(f.pct), 0) as valor
    from (select distinct nivel, cod, anio, proceso from fam) a
    cross join (values ('Izquierda', 'bloque_izquierda'), ('Derecha', 'bloque_derecha'), ('Centro', 'bloque_centro'),
        ('Nacionalistas y regionalistas', 'bloque_nacionalistas')) b(bloque, col)
    left join fam f on f.nivel = a.nivel and f.cod = a.cod and f.proceso = a.proceso and f.bloque = b.bloque
    group by all
),

voto_largo as (
    select 'voto' as src, nivel, cod, anio, col, valor from fam_col
    union all
    select 'voto' as src, nivel, cod, anio, col, valor from bloques
),

pensiones as (
    select 'pensiones' as src, nivel, cod, anio,
        pension_media_real, pension_media_jubilacion_real, pensiones_por_1000_hab,
        jubilaciones_por_100_mayores, afiliados_por_pension
    from {{ ref('pensiones_territorio') }}
),

-- ============================== DEMOGRAFÍA ==============================

poblacion as (
    select 'poblacion' as src, nivel, cod, anio, cast(poblacion as double) as poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total'
),

demo as (
    select 'demo' as src, nivel, cod, anio,
        tasa_natalidad, tasa_mortalidad, vegetativo_1000, fecundidad, edad_maternidad,
        pct_madre_extranjera, crecimiento_1000, resto_1000
    from {{ ref('demografia_anual') }}
),

edades as (
    select 'edades' as src, nivel, cod, anio,
        pct_menores_16, pct_65, pct_80, indice_envejecimiento, dependencia, edad_media,
        hombres_por_100_mujeres
    from {{ ref('demografia_envejecimiento') }}
),

hogares as (
    select 'hogares' as src, nivel, cod, anio, tamano_medio, pct_unipersonales
    from {{ ref('demografia_hogares') }}
),

-- ============================== UNPIVOT ==============================

datos as (
    unpivot (
        select * from epa
        union all by name select * from paro_reg
        union all by name select * from ipc
        union all by name select * from salarios
        union all by name select * from dirce
        union all by name select * from sociedades
        union all by name select * from concursos
        union all by name select * from autonomos
        union all by name select * from idi
        union all by name select * from turismo
        union all by name select * from vut
        union all by name select * from ecv
        union all by name select * from adrh
        union all by name select * from educacion
        union all by name select * from san_gasto
        union all by name select * from san_recursos
        union all by name select * from listas
        union all by name select * from esperanza
        union all by name select * from crimen_total
        union all by name select * from crimen_cat
        union all by name select * from condenados
        union all by name select * from extranjeros
        union all by name select * from nacionalizaciones
        union all by name select * from saldo_ext
        union all by name select * from participacion
        union all by name select * from pensiones
        union all by name select * from poblacion
        union all by name select * from demo
        union all by name select * from edades
        union all by name select * from hogares
    ) on columns(* exclude (src, nivel, cod, anio))
    into name col value valor
),

todos as (
    select src, nivel, cod, cast(anio as integer) as anio, col, cast(valor as double) as valor from datos
    union all
    select src, nivel, cod, cast(anio as integer), col, cast(valor as double) from voto_largo
),

-- ============================== METADATOS ==============================

meta(src, col, niveles, base_id, nombre, tema, unidad, sentido, fuente, url_fuente, pagina, nota) as (
    values
    -- Economía: paro
    ('epa', 'tasa_paro', ['ccaa', 'provincia'], 'economia_tasa_paro', 'Tasa de paro (EPA)', 'Economía', '%', 'negativo', 'INE (EPA)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65334', '/economia/paro/', 'Media de los trimestres publicados del año; en provincias la muestra es pequeña (tabla 65349).'),
    ('epa', 'tasa_paro_mujeres', ['ccaa', 'provincia'], 'economia_tasa_paro_mujeres', 'Tasa de paro de las mujeres (EPA)', 'Economía', '%', 'negativo', 'INE (EPA)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65334', '/economia/paro/', 'Media de los trimestres publicados del año.'),
    ('epa', 'tasa_paro_menor25', ['ccaa'], 'economia_tasa_paro_menor25', 'Tasa de paro de los menores de 25 años (EPA)', 'Economía', '%', 'negativo', 'INE (EPA)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65334', '/economia/paro/', 'Media de los trimestres publicados del año.'),
    ('epa', 'tasa_paro_extranjeros', ['ccaa'], 'economia_tasa_paro_extranjeros', 'Tasa de paro de los extranjeros (EPA)', 'Economía', '%', 'negativo', 'INE (EPA)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65336', '/economia/paro/', 'Media de los trimestres publicados del año; muestra pequeña en las comunidades con pocos extranjeros.'),
    ('epa', 'pct_hogares_todos_parados', ['ccaa'], 'economia_hogares_todos_parados', 'Hogares con todos sus activos en paro', 'Economía', '% de hogares con algún activo', 'negativo', 'INE (EPA)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65276', '/economia/paro/', 'Media de los trimestres publicados del año.'),
    ('epa', 'tasa_empleo', ['provincia'], 'economia_tasa_empleo_prov', 'Tasa de empleo (EPA)', 'Economía', '% de la población de 16 y más años', 'positivo', 'INE (EPA)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65349', '/economia/paro/', 'Media de los trimestres publicados del año.'),
    ('epa', 'tasa_actividad', ['provincia'], 'economia_tasa_actividad_prov', 'Tasa de actividad (EPA)', 'Economía', '% de la población de 16 y más años', 'positivo', 'INE (EPA)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65349', '/economia/paro/', 'Media de los trimestres publicados del año.'),
    ('paro_reg', 'por_100_16_64', ['ccaa', 'provincia'], 'economia_paro_registrado', 'Paro registrado por cada 100 habitantes de 16 a 64 años', 'Economía', 'por 100 hab. de 16-64 años', 'negativo', 'SEPE', 'https://sede.sepe.gob.es/es/portaltrabaja/resources/sede/datos_abiertos/datos/Paro_por_municipios_2026_csv.csv', '/economia/paro/', 'Media de los meses publicados del año. No es la tasa de paro de la EPA.'),
    -- Economía: precios y salarios
    ('ipc', 'var_anual', ['ccaa'], 'economia_ipc_interanual', 'Inflación (IPC, tasa interanual)', 'Economía', '%', 'negativo', 'INE (IPC)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76140', '/economia/ipc/', 'Tasa interanual del último mes publicado del año (diciembre en los años completos).'),
    ('ipc', 'subida_desde_2019', ['ccaa'], 'economia_ipc_subida_2019', 'Subida acumulada de los precios desde diciembre de 2019', 'Economía', '%', 'negativo', 'INE (IPC)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76140', '/economia/ipc/', 'Hasta el último mes publicado del año, encadenando las tasas mensuales.'),
    ('salarios', 'salario_real', ['ccaa'], 'economia_salario_real', 'Salario medio por trabajador y mes (real)', 'Economía', '€/mes (€ constantes)', 'positivo', 'INE (ETCL)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=6061', '/economia/salarios/', 'Coste salarial total, media de los cuatro trimestres; industria, construcción y servicios. Sin corregir por diferencias de precios entre comunidades.'),
    ('salarios', 'coste_laboral_real', ['ccaa'], 'economia_coste_laboral_real', 'Coste laboral por trabajador y mes (real)', 'Economía', '€/mes (€ constantes)', 'neutro', 'INE (ETCL)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=6061', '/economia/salarios/', 'Salario + cotizaciones + otros costes; media de los cuatro trimestres.'),
    -- Economía: empresas
    ('dirce', 'empresas_1000hab', ['ccaa', 'provincia'], 'economia_empresas_1000hab', 'Empresas activas por 1.000 habitantes', 'Economía', 'por 1.000 hab', 'positivo', 'INE (DIRCE)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=302', '/economia/empresas/', 'A 1 de enero; incluye autónomos (personas físicas).'),
    ('sociedades', 'constituidas_100k', ['ccaa'], 'economia_sociedades_constituidas', 'Sociedades mercantiles constituidas por 100.000 habitantes', 'Economía', 'por 100.000 hab', 'positivo', 'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=13912', '/economia/empresas/', 'Solo años con los 12 meses publicados.'),
    ('sociedades', 'saldo_100k', ['ccaa'], 'economia_sociedades_saldo', 'Saldo de sociedades (constituidas - disueltas) por 100.000 habitantes', 'Economía', 'por 100.000 hab', 'positivo', 'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=13912', '/economia/empresas/', 'Solo años con los 12 meses publicados.'),
    ('sociedades', 'capital_real_hab', ['ccaa'], 'economia_sociedades_capital_hab', 'Capital suscrito por las nuevas sociedades por habitante (real)', 'Economía', '€/hab (€ constantes)', 'positivo', 'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=13912', '/economia/empresas/', 'La sede social concentra el capital en Madrid.'),
    ('concursos', 'concursos_100k', ['ccaa'], 'economia_concursos', 'Deudores concursados por 100.000 habitantes', 'Economía', 'por 100.000 hab', 'negativo', 'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=2992', '/economia/empresas/', 'El INE no publica datos posteriores a 2020.'),
    ('autonomos', 'pct_cuenta_propia', ['ccaa'], 'economia_pct_cuenta_propia', 'Trabajadores por cuenta propia (autónomos)', 'Economía', '% de los ocupados', 'neutro', 'INE (EPA)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65316', '/economia/empresas/', 'Media de los cuatro trimestres (años completos).'),
    ('idi', 'pct_pib', ['ccaa'], 'economia_idi_pct_pib', 'Gasto en I+D sobre el PIB regional', 'Economía', '% del PIB', 'positivo', 'Eurostat / INE', 'https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdreg/default/table', '/economia/empresas/', 'Todos los sectores ejecutores.'),
    ('idi', 'eur_hab_real', ['ccaa'], 'economia_idi_eur_hab', 'Gasto en I+D por habitante (real)', 'Economía', '€/hab (€ constantes)', 'positivo', 'Eurostat / INE', 'https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdreg/default/table', '/economia/empresas/', 'Todos los sectores ejecutores.'),
    ('idi', 'investigadores_1000ocup', ['ccaa'], 'economia_investigadores', 'Investigadores por 1.000 ocupados', 'Economía', 'por 1.000 ocupados (EJC)', 'positivo', 'Eurostat / INE', 'https://ec.europa.eu/eurostat/databrowser/view/rd_p_persreg/default/table', '/economia/empresas/', 'En equivalencia a jornada completa.'),
    -- Economía: turismo
    ('turismo', 'pernoct_1000hab', ['ccaa'], 'economia_turismo_pernoctaciones', 'Pernoctaciones en hoteles y apartamentos turísticos por 1.000 habitantes', 'Economía', 'por 1.000 hab', 'neutro', 'INE (Coyuntura Turística)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=2074', '/economia/turismo/', 'Solo años completos. Apartamentos sin Ceuta ni Melilla.'),
    ('turismo', 'pct_extranjeros_hotel', ['ccaa'], 'economia_turismo_pct_extranjeros', 'Pernoctaciones hoteleras de no residentes en España', 'Economía', '% de las pernoctaciones hoteleras', 'neutro', 'INE (Coyuntura Turística)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=2074', '/economia/turismo/', 'Solo años completos.'),
    ('turismo', 'ocupacion_hotel', ['ccaa'], 'economia_turismo_ocupacion_hotel', 'Grado de ocupación hotelera por plazas', 'Economía', '%', 'positivo', 'INE (Coyuntura Turística)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=2066', '/economia/turismo/', 'Media del año ponderada por plazas y días.'),
    ('vut', 'viviendas_1000hab', ['ccaa', 'provincia'], 'economia_viviendas_turisticas', 'Viviendas de uso turístico por 1.000 habitantes', 'Economía', 'por 1.000 hab', 'neutro', 'INE (medición experimental)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=39363', '/economia/turismo/', 'Último periodo publicado del año (agosto hasta 2024; mayo/noviembre después).'),
    ('vut', 'pct_viviendas', ['ccaa', 'provincia'], 'economia_viviendas_turisticas_pct', 'Viviendas de uso turístico sobre el total de viviendas', 'Economía', '% de las viviendas', 'neutro', 'INE (medición experimental)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=39363', '/economia/turismo/', 'Último periodo publicado del año.'),
    -- Sociedad: renta y desigualdad
    ('ecv', 'renta_persona_real', ['ccaa'], 'sociedad_renta_persona_ecv', 'Renta neta media por persona (real, ECV)', 'Sociedad', '€/hab (€ constantes)', 'positivo', 'INE (ECV)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=9947', '/sociedad/desigualdad/', 'Año de la encuesta; la renta es la del año anterior.'),
    ('ecv', 'tasa_pobreza', ['ccaa'], 'sociedad_riesgo_pobreza', 'Tasa de riesgo de pobreza', 'Sociedad', '% de la población', 'negativo', 'INE (ECV)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=9963', '/sociedad/desigualdad/', 'Umbral nacional; año de la encuesta (renta del año anterior).'),
    ('ecv', 'arope', ['ccaa'], 'sociedad_arope', 'Riesgo de pobreza o exclusión social (AROPE)', 'Sociedad', '% de la población', 'negativo', 'INE (ECV)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76847', '/sociedad/desigualdad/', 'Año de la encuesta.'),
    ('ecv', 'carencia_severa', ['ccaa'], 'sociedad_carencia_severa', 'Carencia material y social severa', 'Sociedad', '% de la población', 'negativo', 'INE (ECV)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76847', '/sociedad/desigualdad/', 'Año de la encuesta.'),
    ('ecv', 'fin_mes_dificultad', ['ccaa'], 'sociedad_fin_mes_dificultad', 'Personas que llegan a fin de mes con dificultad', 'Sociedad', '% de la población', 'negativo', 'INE (ECV)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=9990', '/sociedad/desigualdad/', 'Con dificultad o con mucha dificultad; año de la encuesta.'),
    ('ecv', 'gini', ['ccaa'], 'sociedad_gini', 'Coeficiente de Gini', 'Sociedad', 'índice 0-100', 'negativo', 'INE (ECV)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76846', '/sociedad/desigualdad/', 'Año de la encuesta (renta del año anterior).'),
    ('ecv', 's80_s20', ['ccaa'], 'sociedad_s80_s20', 'Desigualdad S80/S20', 'Sociedad', 'veces', 'negativo', 'INE (ECV)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76846', '/sociedad/desigualdad/', 'Renta del 20 % más rico entre la del 20 % más pobre; año de la encuesta.'),
    ('adrh', 'renta_persona_real', ['provincia'], 'sociedad_renta_persona_adrh_prov', 'Renta neta media por persona (real, Atlas de renta)', 'Sociedad', '€/hab (€ constantes)', 'positivo', 'INE (ADRH)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=53689', '/territorios/', 'Datos tributarios del propio año; País Vasco desde 2020 y Navarra desde 2021.'),
    ('adrh', 'renta_uc_mediana_real', ['provincia'], 'sociedad_renta_mediana_uc_adrh_prov', 'Mediana de la renta por unidad de consumo (real, Atlas de renta)', 'Sociedad', '€ por unidad de consumo (€ constantes)', 'positivo', 'INE (ADRH)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=53689', '/territorios/', 'Datos tributarios del propio año; País Vasco desde 2020 y Navarra desde 2021.'),
    -- Sociedad: educación
    ('educacion', 'abandono', ['ccaa'], 'sociedad_abandono_escolar', 'Abandono temprano de la educación y la formación', 'Sociedad', '% de 18-24 años', 'negativo', 'Eurostat / INE (EPA)', 'https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_16', '/sociedad/educacion/', 'Muestras pequeñas en Ceuta y Melilla.'),
    ('educacion', 'superior_25_64', ['ccaa'], 'sociedad_estudios_superiores', 'Población de 25-64 años con estudios superiores', 'Sociedad', '% de 25-64 años', 'positivo', 'Eurostat / INE (EPA)', 'https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_04', '/sociedad/educacion/', 'CINE 5-8: FP de grado superior y universidad.'),
    ('educacion', 'basica_25_64', ['ccaa'], 'sociedad_estudios_basicos', 'Población de 25-64 años con, como mucho, la ESO', 'Sociedad', '% de 25-64 años', 'negativo', 'Eurostat / INE (EPA)', 'https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_04', '/sociedad/educacion/', 'CINE 0-2.'),
    ('educacion', 'neet_15_29', ['ccaa'], 'sociedad_ninis', 'Jóvenes que ni estudian ni trabajan (15-29 años)', 'Sociedad', '% de 15-29 años', 'negativo', 'Eurostat / INE (EPA)', 'https://ec.europa.eu/eurostat/databrowser/view/edat_lfse_22', '/sociedad/educacion/', null),
    -- Sociedad: sanidad
    ('san_gasto', 'eur_hab_real', ['ccaa'], 'sociedad_gasto_sanitario_hab', 'Gasto sanitario público autonómico por habitante (real)', 'Sociedad', '€/hab (€ constantes)', 'positivo', 'Ministerio de Sanidad (EGSP)', 'https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/gastoSanitario2005/home.htm', '/sociedad/salud/', 'Sector Comunidades Autónomas; sin Ceuta ni Melilla (INGESA). Los dos últimos años son provisionales.'),
    ('san_recursos', 'medicos_100k', ['ccaa'], 'sociedad_medicos', 'Médicos por 100.000 habitantes', 'Sociedad', 'por 100.000 hab', 'positivo', 'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_physreg', '/sociedad/salud/', null),
    ('san_recursos', 'camas_100k', ['ccaa'], 'sociedad_camas_hospital', 'Camas hospitalarias por 100.000 habitantes', 'Sociedad', 'por 100.000 hab', 'positivo', 'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/hlth_rs_bdsrg2', '/sociedad/salud/', null),
    ('listas', 'quir_tasa_1000', ['ccaa'], 'sociedad_lista_quirurgica_tasa', 'Pacientes en lista de espera quirúrgica por 1.000 habitantes', 'Sociedad', 'por 1.000 hab', 'negativo', 'Ministerio de Sanidad (SISLE)', 'https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm', '/sociedad/salud/', 'Último corte del año (31 de diciembre o 30 de junio). Cada comunidad aplica sus criterios.'),
    ('listas', 'quir_dias', ['ccaa'], 'sociedad_lista_quirurgica_dias', 'Espera media para una operación', 'Sociedad', 'días', 'negativo', 'Ministerio de Sanidad (SISLE)', 'https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm', '/sociedad/salud/', 'Último corte del año.'),
    ('listas', 'quir_pct_6meses', ['ccaa'], 'sociedad_lista_quirurgica_6meses', 'Pacientes que llevan más de 6 meses esperando una operación', 'Sociedad', '% de la lista', 'negativo', 'Ministerio de Sanidad (SISLE)', 'https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm', '/sociedad/salud/', 'Último corte del año.'),
    ('listas', 'cons_dias', ['ccaa'], 'sociedad_lista_consultas_dias', 'Espera media para la primera consulta del especialista', 'Sociedad', 'días', 'negativo', 'Ministerio de Sanidad (SISLE)', 'https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm', '/sociedad/salud/', 'Último corte del año.'),
    ('listas', 'cons_pct_60dias', ['ccaa'], 'sociedad_lista_consultas_60dias', 'Pacientes con cita del especialista a más de 60 días', 'Sociedad', '% de la lista', 'negativo', 'Ministerio de Sanidad (SISLE)', 'https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/listaEspera.htm', '/sociedad/salud/', 'Último corte del año.'),
    ('esperanza', 'esperanza_vida', ['ccaa', 'provincia'], 'sociedad_esperanza_vida', 'Esperanza de vida al nacer', 'Sociedad', 'años', 'positivo', 'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=1448', '/sociedad/salud/', 'Ambos sexos (provincias: tabla 1485).'),
    -- Sociedad: criminalidad
    ('crimen_total', 'tasa_1000', ['ccaa', 'provincia'], 'sociedad_criminalidad', 'Infracciones penales conocidas por 1.000 habitantes', 'Sociedad', 'por 1.000 hab', 'negativo', 'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/', '/sociedad/criminalidad/', 'Hechos conocidos por las fuerzas de seguridad; las zonas turísticas suben porque la tasa se calcula sobre los residentes.'),
    ('crimen_cat', 'convencional', ['ccaa', 'provincia'], 'sociedad_criminalidad_convencional', 'Criminalidad convencional por 1.000 habitantes', 'Sociedad', 'por 1.000 hab', 'negativo', 'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/', '/sociedad/criminalidad/', 'Balance de Criminalidad (sin ciberdelitos). Uniprovinciales, Ceuta y Melilla con el dato de la comunidad.'),
    ('crimen_cat', 'ciber', ['ccaa', 'provincia'], 'sociedad_cibercriminalidad', 'Cibercriminalidad por 1.000 habitantes', 'Sociedad', 'por 1.000 hab', 'negativo', 'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/', '/sociedad/criminalidad/', 'Balance de Criminalidad. Uniprovinciales, Ceuta y Melilla con el dato de la comunidad.'),
    ('crimen_cat', 'homicidios_100k', ['ccaa', 'provincia'], 'sociedad_homicidios', 'Homicidios y asesinatos consumados por 100.000 habitantes', 'Sociedad', 'por 100.000 hab', 'negativo', 'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/', '/sociedad/criminalidad/', 'Pocos casos: el dato anual de las provincias pequeñas oscila mucho.'),
    ('crimen_cat', 'robos_violencia', ['ccaa', 'provincia'], 'sociedad_robos_violencia', 'Robos con violencia o intimidación por 1.000 habitantes', 'Sociedad', 'por 1.000 hab', 'negativo', 'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/', '/sociedad/criminalidad/', 'Balance de Criminalidad.'),
    ('crimen_cat', 'robos_domicilios', ['ccaa', 'provincia'], 'sociedad_robos_domicilios', 'Robos con fuerza en domicilios por 1.000 habitantes', 'Sociedad', 'por 1.000 hab', 'negativo', 'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/', '/sociedad/criminalidad/', 'Balance de Criminalidad.'),
    ('crimen_cat', 'hurtos', ['ccaa', 'provincia'], 'sociedad_hurtos', 'Hurtos por 1.000 habitantes', 'Sociedad', 'por 1.000 hab', 'negativo', 'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/', '/sociedad/criminalidad/', 'Balance de Criminalidad; muy afectado por el turismo.'),
    ('crimen_cat', 'sexuales_100k', ['ccaa', 'provincia'], 'sociedad_delitos_sexuales', 'Delitos contra la libertad sexual por 100.000 habitantes', 'Sociedad', 'por 100.000 hab', 'negativo', 'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/', '/sociedad/criminalidad/', 'Hechos conocidos: depende también de cuánto se denuncia.'),
    ('crimen_cat', 'drogas_100k', ['ccaa', 'provincia'], 'sociedad_trafico_drogas', 'Tráfico de drogas por 100.000 habitantes', 'Sociedad', 'por 100.000 hab', 'negativo', 'Ministerio del Interior', 'https://estadisticasdecriminalidad.ses.mir.es/', '/sociedad/criminalidad/', 'Refleja sobre todo la actividad policial (rutas de entrada).'),
    ('condenados', 'tasa_1000', ['ccaa'], 'sociedad_condenados', 'Condenados adultos por 1.000 residentes de 18 y más años', 'Sociedad', 'por 1.000 hab de 18+ años', 'negativo', 'INE (Estadística de Condenados)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=25704', '/sociedad/criminalidad/', 'Comunidad del juzgado que condena, no la de residencia.'),
    -- Sociedad: inmigración
    ('extranjeros', 'pct_extranjeros', ['ccaa', 'provincia'], 'sociedad_pct_extranjeros', 'Población de nacionalidad extranjera', 'Sociedad', '% de la población', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56947', '/sociedad/inmigracion/', 'A 1 de enero.'),
    ('extranjeros', 'pct_nacidos_extranjero', ['ccaa', 'provincia'], 'sociedad_pct_nacidos_extranjero', 'Población nacida en el extranjero', 'Sociedad', '% de la población', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56948', '/sociedad/inmigracion/', 'A 1 de enero; incluye a los que ya tienen la nacionalidad española.'),
    ('nacionalizaciones', 'por_1000_extranjeros', ['ccaa'], 'sociedad_nacionalizaciones', 'Nacionalizaciones por 1.000 extranjeros residentes', 'Sociedad', 'por 1.000 extranjeros', 'neutro', 'INE', 'https://www.ine.es/jaxiT3/Tabla.htm?t=70012', '/sociedad/inmigracion/', 'Comunidad de residencia.'),
    ('saldo_ext', 'saldo_1000', ['ccaa'], 'sociedad_saldo_migratorio_exterior', 'Saldo migratorio con el extranjero por 1.000 habitantes', 'Sociedad', 'por 1.000 hab', 'neutro', 'INE (EMCR)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=69758', '/sociedad/inmigracion/', 'Inmigraciones menos emigraciones con el extranjero, todas las nacionalidades.'),
    -- Sociedad: elecciones
    ('participacion', 'congreso', ['ccaa', 'provincia'], 'sociedad_participacion_congreso', 'Participación en las elecciones al Congreso', 'Sociedad', '% del censo', 'positivo', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Censo con residentes en el extranjero (CERA). En 2019, la de noviembre.'),
    ('participacion', 'municipales', ['ccaa', 'provincia'], 'sociedad_participacion_municipales', 'Participación en las elecciones municipales', 'Sociedad', '% del censo', 'positivo', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', null),
    ('participacion', 'europeas', ['ccaa', 'provincia'], 'sociedad_participacion_europeas', 'Participación en las elecciones europeas', 'Sociedad', '% del censo', 'positivo', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', null),
    ('voto', 'psoe', ['ccaa', 'provincia'], 'sociedad_voto_congreso_psoe', 'Voto al PSOE en el Congreso', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Familia política (incluye PSC). En 2019, la de noviembre.'),
    ('voto', 'pp', ['ccaa', 'provincia'], 'sociedad_voto_congreso_pp', 'Voto al PP (y AP) en el Congreso', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Familia política. En 2019, la de noviembre.'),
    ('voto', 'vox', ['ccaa', 'provincia'], 'sociedad_voto_congreso_vox', 'Voto a Vox en el Congreso', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', '0 donde no se presentó. En 2019, la de noviembre.'),
    ('voto', 'iu_podemos_sumar', ['ccaa', 'provincia'], 'sociedad_voto_congreso_iu_podemos_sumar', 'Voto a IU, Podemos y Sumar en el Congreso', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Familia política (PCE, IU, Podemos, Sumar y sus confluencias). En 2019, la de noviembre.'),
    ('voto', 'cs', ['ccaa', 'provincia'], 'sociedad_voto_congreso_cs', 'Voto a Ciudadanos en el Congreso', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', '0 donde no se presentó. En 2019, la de noviembre.'),
    ('voto', 'bloque_izquierda', ['ccaa', 'provincia'], 'sociedad_voto_congreso_izquierda', 'Voto al bloque de izquierda en el Congreso', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'Suma de las familias de izquierda de ámbito estatal (sin nacionalistas). En 2019, la de noviembre.'),
    ('voto', 'bloque_derecha', ['ccaa', 'provincia'], 'sociedad_voto_congreso_derecha', 'Voto al bloque de derecha en el Congreso', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'PP (y AP), Vox y UPN. En 2019, la de noviembre.'),
    ('voto', 'bloque_centro', ['ccaa', 'provincia'], 'sociedad_voto_congreso_centro', 'Voto a partidos de centro en el Congreso', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'UCD, CDS, Ciudadanos y UPyD. En 2019, la de noviembre.'),
    ('voto', 'bloque_nacionalistas', ['ccaa', 'provincia'], 'sociedad_voto_congreso_nacionalistas', 'Voto a partidos nacionalistas y regionalistas en el Congreso', 'Sociedad', '% de los votos válidos', 'neutro', 'Ministerio del Interior (infoelectoral)', 'https://infoelectoral.interior.gob.es/es/elecciones-celebradas/area-de-descargas/', '/sociedad/elecciones/', 'En 2019, la de noviembre.'),
    -- Sociedad: pensiones
    ('pensiones', 'pension_media_real', ['ccaa', 'provincia'], 'sociedad_pension_media', 'Pensión contributiva media (real)', 'Sociedad', '€/mes (€ constantes)', 'positivo', 'Seguridad Social (INSS)', 'https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24', '/cuentas-publicas/pensiones/', 'Media de los meses publicados del año (el año en curso es parcial).'),
    ('pensiones', 'pension_media_jubilacion_real', ['ccaa', 'provincia'], 'sociedad_pension_media_jubilacion', 'Pensión media de jubilación (real)', 'Sociedad', '€/mes (€ constantes)', 'positivo', 'Seguridad Social (INSS)', 'https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24', '/cuentas-publicas/pensiones/', 'Media de los meses publicados del año (el año en curso es parcial).'),
    ('pensiones', 'pensiones_por_1000_hab', ['ccaa', 'provincia'], 'sociedad_pensiones_1000hab', 'Pensiones contributivas por 1.000 habitantes', 'Sociedad', 'por 1.000 hab', 'neutro', 'Seguridad Social (INSS)', 'https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24', '/cuentas-publicas/pensiones/', 'Media de los meses publicados del año.'),
    ('pensiones', 'jubilaciones_por_100_mayores', ['ccaa', 'provincia'], 'sociedad_jubilaciones_100_mayores', 'Pensiones de jubilación por cada 100 personas de 65 y más años', 'Sociedad', 'por 100 hab de 65+ años', 'neutro', 'Seguridad Social (INSS)', 'https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24', '/cuentas-publicas/pensiones/', 'Media de los meses publicados del año.'),
    ('pensiones', 'afiliados_por_pension', ['ccaa', 'provincia'], 'sociedad_afiliados_por_pension', 'Afiliados a la Seguridad Social por pensión', 'Sociedad', 'afiliados por pensión', 'positivo', 'Seguridad Social', 'https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24', '/cuentas-publicas/pensiones/', 'Desde 2021; media de los meses publicados del año.'),
    -- Demografía
    ('poblacion', 'poblacion', ['ccaa', 'provincia'], 'demografia_poblacion', 'Población (padrón)', 'Demografía', 'habitantes', 'neutro', 'INE (padrón)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=29005', '/demografia/distribucion-territorial/', 'Cifras oficiales a 1 de enero.'),
    ('demo', 'crecimiento_1000', ['ccaa', 'provincia'], 'demografia_crecimiento', 'Crecimiento de la población por 1.000 habitantes', 'Demografía', 'por 1.000 hab', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945', '/demografia/evolucion-poblacion/', 'Del 1 de enero del año al 1 de enero del siguiente.'),
    ('demo', 'resto_1000', ['ccaa', 'provincia'], 'demografia_saldo_migratorio', 'Saldo migratorio (crecimiento no vegetativo) por 1.000 habitantes', 'Demografía', 'por 1.000 hab', 'neutro', 'INE (ECP y MNP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945', '/demografia/evolucion-poblacion/', 'Crecimiento menos saldo vegetativo: migraciones exteriores e interiores y ajustes.'),
    ('demo', 'vegetativo_1000', ['ccaa', 'provincia'], 'demografia_saldo_vegetativo', 'Saldo vegetativo por 1.000 habitantes', 'Demografía', 'por 1.000 hab', 'neutro', 'INE (Indicadores Demográficos Básicos)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=1470', '/demografia/natalidad/', 'Tasa de natalidad menos tasa de mortalidad.'),
    ('demo', 'tasa_natalidad', ['ccaa', 'provincia'], 'demografia_natalidad', 'Tasa bruta de natalidad', 'Demografía', 'nacimientos por 1.000 hab', 'neutro', 'INE (Indicadores Demográficos Básicos)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=1470', '/demografia/natalidad/', null),
    ('demo', 'tasa_mortalidad', ['ccaa', 'provincia'], 'demografia_mortalidad', 'Tasa bruta de mortalidad', 'Demografía', 'defunciones por 1.000 hab', 'neutro', 'INE (Indicadores Demográficos Básicos)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=1482', '/demografia/natalidad/', 'Tasa bruta: sube con el envejecimiento.'),
    ('demo', 'fecundidad', ['ccaa', 'provincia'], 'demografia_fecundidad', 'Hijos por mujer (indicador coyuntural de fecundidad)', 'Demografía', 'hijos por mujer', 'neutro', 'INE (Indicadores Demográficos Básicos)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=1478', '/demografia/natalidad/', null),
    ('demo', 'edad_maternidad', ['ccaa', 'provincia'], 'demografia_edad_maternidad', 'Edad media a la maternidad', 'Demografía', 'años', 'neutro', 'INE (Indicadores Demográficos Básicos)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=1581', '/demografia/natalidad/', null),
    ('demo', 'pct_madre_extranjera', ['ccaa'], 'demografia_nacidos_madre_extranjera', 'Nacidos de madre extranjera', 'Demografía', '% de los nacimientos', 'neutro', 'INE (Indicadores Demográficos Básicos)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=2777', '/demografia/natalidad/', null),
    ('edades', 'pct_65', ['ccaa', 'provincia'], 'demografia_pct_65', 'Población de 65 y más años', 'Demografía', '% de la población', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945', '/demografia/estructura-edades/', 'A 1 de enero.'),
    ('edades', 'pct_80', ['ccaa', 'provincia'], 'demografia_pct_80', 'Población de 80 y más años', 'Demografía', '% de la población', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945', '/demografia/estructura-edades/', 'A 1 de enero.'),
    ('edades', 'pct_menores_16', ['ccaa', 'provincia'], 'demografia_pct_menores_16', 'Población menor de 16 años', 'Demografía', '% de la población', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945', '/demografia/estructura-edades/', 'A 1 de enero.'),
    ('edades', 'indice_envejecimiento', ['ccaa', 'provincia'], 'demografia_indice_envejecimiento', 'Índice de envejecimiento', 'Demografía', 'mayores de 64 por 100 menores de 16', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945', '/demografia/estructura-edades/', 'A 1 de enero.'),
    ('edades', 'dependencia', ['ccaa', 'provincia'], 'demografia_dependencia', 'Tasa de dependencia', 'Demografía', '(<16 + 65+) por 100 de 16-64', 'negativo', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945', '/demografia/estructura-edades/', 'A 1 de enero.'),
    ('edades', 'edad_media', ['ccaa', 'provincia'], 'demografia_edad_media', 'Edad media de la población', 'Demografía', 'años', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945', '/demografia/estructura-edades/', 'A 1 de enero.'),
    ('edades', 'hombres_por_100_mujeres', ['ccaa', 'provincia'], 'demografia_masculinidad', 'Hombres por cada 100 mujeres', 'Demografía', 'hombres por 100 mujeres', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=56945', '/demografia/poblacion-sexo/', 'A 1 de enero.'),
    ('hogares', 'tamano_medio', ['ccaa', 'provincia'], 'demografia_tamano_hogar', 'Tamaño medio del hogar', 'Demografía', 'personas por hogar', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=60132', '/demografia/hogares/', 'A 1 de enero.'),
    ('hogares', 'pct_unipersonales', ['ccaa', 'provincia'], 'demografia_hogares_unipersonales', 'Hogares unipersonales', 'Demografía', '% de los hogares', 'neutro', 'INE (ECP)', 'https://www.ine.es/jaxiT3/Tabla.htm?t=60131', '/demografia/hogares/', 'A 1 de enero.')
)

select
    m.base_id || case when len(m.niveles) > 1
        then case d.nivel when 'ccaa' then '_ccaa' else '_prov' end
        else '' end as indicador_id,
    m.nombre,
    m.tema,
    case d.nivel when 'ccaa' then 'Comunidad' else 'Provincia' end as nivel,
    d.cod,
    t.nombre as territorio,
    d.anio,
    d.valor,
    m.unidad,
    m.sentido,
    m.fuente,
    m.url_fuente,
    m.pagina,
    m.nota
from todos d
join meta m on m.src = d.src and m.col = d.col and list_contains(m.niveles, d.nivel)
join terr t on t.nivel = d.nivel and t.cod = d.cod
where d.valor is not null and isfinite(d.valor) and d.anio is not null
