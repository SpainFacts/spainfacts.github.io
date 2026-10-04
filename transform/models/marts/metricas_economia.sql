-- Series de seguimiento de la sección Economía (formato largo), a nivel España.
-- Replica la lógica de las KpiCard y gráficas principales de pages/economia/*.md.
-- Importes por habitante y en euros reales (año base del mart deflactor); tasas tal cual.
-- No incluye ipc_variacion_anual, ipc_indice ni tasa_paro (ya están en metricas).

with base as (
    select max(anio_base) as anio_base from {{ ref('deflactor') }}
),

eur as (
    select 'euros de ' || anio_base as txt from base
),

-- ---------------------------------------------------------------- PIB
pib_hab as (
    select
        'economia_pib_hab_real' as metrica_id,
        'PIB por habitante (real)' as nombre,
        make_date(anio, 1, 1) as periodo,
        real_eur as valor,
        '€/hab (' || (select txt from eur) || ')' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table' as url_fuente,
        '/economia/pib/' as pagina,
        'Anual' as frecuencia
    from {{ ref('economia_pib_per_capita') }}
    where pais = 'ES'
),

pib_ue as (
    select
        'economia_pib_hab_indice_ue' as metrica_id,
        'Nivel de vida frente a la UE (PIB por habitante en PPA)' as nombre,
        make_date(anio, 1, 1) as periodo,
        indice_ue as valor,
        'índice UE-27 = 100' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/nama_10_pc/default/table' as url_fuente,
        '/economia/pib/' as pagina,
        'Anual' as frecuencia
    from {{ ref('economia_pib_per_capita') }}
    where pais = 'ES'
),

pib_trim as (
    select
        'economia_pib_crecimiento_interanual' as metrica_id,
        'Crecimiento del PIB (interanual real)' as nombre,
        trimestre as periodo,
        interanual as valor,
        '%' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table' as url_fuente,
        '/economia/pib/' as pagina,
        'Trimestral' as frecuencia
    from {{ ref('economia_pib_trimestral') }}
    where componente = 'B1GQ'
    union all
    select
        'economia_pib_hab_trimestral_real',
        'PIB por habitante, ritmo anual (trimestral, real)',
        trimestre,
        por_habitante_real,
        '€/hab al año (' || (select txt from eur) || ')',
        'Eurostat',
        'https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table',
        '/economia/pib/',
        'Trimestral'
    from {{ ref('economia_pib_trimestral') }}
    where componente = 'B1GQ'
),

-- ---------------------------------------------------------------- Comercio exterior
comercio as (
    select
        case componente when 'P6' then 'economia_exportaciones_pib' else 'economia_importaciones_pib' end as metrica_id,
        case componente when 'P6' then 'Exportaciones de bienes y servicios (% del PIB)'
                        else 'Importaciones de bienes y servicios (% del PIB)' end as nombre,
        trimestre as periodo,
        pct_pib as valor,
        '% del PIB' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table' as url_fuente,
        '/economia/comercio-exterior/' as pagina,
        'Trimestral' as frecuencia
    from {{ ref('economia_pib_trimestral') }}
    where componente in ('P6', 'P7')
    union all
    select
        'economia_exportaciones_interanual_real',
        'Exportaciones reales (variación interanual en volumen)',
        trimestre,
        interanual,
        '%',
        'Eurostat',
        'https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table',
        '/economia/comercio-exterior/',
        'Trimestral'
    from {{ ref('economia_pib_trimestral') }}
    where componente = 'P6'
),

saldo_exterior as (
    select
        'economia_saldo_exterior_pib' as metrica_id,
        'Saldo exterior (exportaciones menos importaciones, % del PIB)' as nombre,
        make_date(anio, 1, 1) as periodo,
        100 * (sum(case when componente = 'P6' then nominal_meur end) - sum(case when componente = 'P7' then nominal_meur end))
            / sum(case when componente = 'B1GQ' then nominal_meur end) as valor,
        '% del PIB' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/namq_10_gdp/default/table' as url_fuente,
        '/economia/comercio-exterior/' as pagina,
        'Anual' as frecuencia
    from {{ ref('economia_pib_trimestral') }}
    where componente in ('P6', 'P7', 'B1GQ')
    group by anio
    having count(*) = 12
),

-- ---------------------------------------------------------------- Sectores
sectores as (
    select
        'economia_vab_crecimiento_real' as metrica_id,
        'Crecimiento real de la economía (valor añadido total)' as nombre,
        make_date(anio, 1, 1) as periodo,
        crecimiento_real as valor,
        '%' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table' as url_fuente,
        '/economia/sectores/' as pagina,
        'Anual' as frecuencia
    from {{ ref('economia_sectores') }}
    where rama = 'TOTAL'
    union all
    select
        'economia_ocupados_1000hab',
        'Ocupados por 1.000 habitantes',
        make_date(anio, 1, 1),
        ocupados_1000_hab,
        'por 1.000 hab',
        'Eurostat',
        'https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table',
        '/economia/sectores/',
        'Anual'
    from {{ ref('economia_sectores') }}
    where rama = 'TOTAL'
    union all
    select
        'economia_productividad_ocupado_real',
        'Productividad por ocupado (valor añadido real)',
        make_date(anio, 1, 1),
        productividad_real,
        '€ por ocupado (' || (select txt from eur) || ')',
        'Eurostat',
        'https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table',
        '/economia/sectores/',
        'Anual'
    from {{ ref('economia_sectores') }}
    where rama = 'TOTAL'
),

-- ---------------------------------------------------------------- Salarios
salarios as (
    select
        'economia_salario_medio_real' as metrica_id,
        'Salario medio mensual bruto (real)' as nombre,
        make_date(anio, 1, 1) as periodo,
        salario_real as valor,
        '€/mes (' || (select txt from eur) || ')' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=6038' as url_fuente,
        '/economia/salarios/' as pagina,
        'Anual' as frecuencia
    from {{ ref('economia_salarios_anual') }}
    where jornada = 'Todas' and sector = 'Total'
    union all
    select
        'economia_salario_interanual_real',
        'Subida real del salario (interanual)',
        trimestre,
        interanual_real,
        '%',
        'INE',
        'https://www.ine.es/jaxiT3/Tabla.htm?t=6038',
        '/economia/salarios/',
        'Trimestral'
    from {{ ref('economia_salarios') }}
    where jornada = 'Todas' and sector = 'Total'
    union all
    select
        'economia_salario_decil5_real',
        'Salario del decil central (D5, real)',
        make_date(cast(d.anio as integer), 1, 1),
        d.salario_mensual * f.factor,
        '€/mes (' || (select txt from eur) || ')',
        'INE',
        'https://www.ine.es/jaxiT3/Tabla.htm?t=66250',
        '/economia/salarios/',
        'Anual'
    from {{ ref('empleo_salarios_deciles') }} d
    join {{ ref('deflactor') }} f on f.anio = d.anio
    where d.jornada = 'Total' and d.sector = 'Total' and d.decil = 5
),

-- ---------------------------------------------------------------- Paro y empleo (EPA)
epa as (
    select
        'economia_' || k.id as metrica_id,
        k.nombre,
        p.trimestre as periodo,
        case k.id
            when 'paro_menor25' then p.tasa_paro_menor25
            when 'tasa_empleo' then p.tasa_empleo
            when 'paro_larga_duracion' then p.tasa_paro_larga
            when 'hogares_todos_parados' then p.pct_hogares_todos_parados
            when 'temporalidad' then p.tasa_temporalidad
            when 'parcialidad_involuntaria' then p.pct_parcial_involuntario
        end as valor,
        k.unidad,
        'INE' as fuente,
        k.url as url_fuente,
        '/economia/paro/' as pagina,
        'Trimestral' as frecuencia
    from {{ ref('mercado_paro_trimestral') }} p
    cross join (values
        ('paro_menor25', 'Paro juvenil (menores de 25 años)', '% de los activos de 16 a 24 años', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65219'),
        ('tasa_empleo', 'Tasa de empleo', '% de la población de 16 y más años', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65219'),
        ('paro_larga_duracion', 'Paro de larga duración (un año o más)', '% de los activos', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65236'),
        ('hogares_todos_parados', 'Hogares con todos sus activos en paro', '% de los hogares con algún activo', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65276'),
        ('temporalidad', 'Temporalidad (asalariados con contrato temporal)', '% de los asalariados', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65194'),
        ('parcialidad_involuntaria', 'Parcialidad involuntaria', '% de los ocupados a tiempo parcial', 'https://www.ine.es/jaxiT3/Tabla.htm?t=65152')
    ) as k(id, nombre, unidad, url)
),

paro_registrado as (
    select
        'economia_paro_registrado_100hab' as metrica_id,
        'Paro registrado por 100 habitantes de 16 a 64 años' as nombre,
        mes as periodo,
        por_100_16_64 as valor,
        'por 100 hab. de 16 a 64 años' as unidad,
        'SEPE' as fuente,
        'https://sede.sepe.gob.es/es/portaltrabaja/resources/sede/datos_abiertos/datos/Paro_por_municipios_2026_csv.csv' as url_fuente,
        '/economia/paro/' as pagina,
        'Mensual' as frecuencia
    from {{ ref('mercado_paro_registrado') }}
    where nivel = 'pais'
),

-- ---------------------------------------------------------------- IPC
ipc as (
    select
        'economia_' || k.id as metrica_id,
        k.nombre,
        i.mes as periodo,
        case k.id
            when 'ipc_subyacente' then i.subyacente
            when 'ipc_energia' then i.energia
            when 'ipc_alimentos_sin_elaborar' then i.alimentos_sin_elaborar
            when 'ipc_subida_desde_2019' then case when i.mes >= date '2019-01-01' then i.indice_2019 - 100 end
            when 'ipc_subida_desde_2008' then case when i.mes >= date '2008-01-01' then i.indice_2008 - 100 end
        end as valor,
        k.unidad,
        'INE' as fuente,
        k.url as url_fuente,
        '/economia/ipc/' as pagina,
        'Mensual' as frecuencia
    from {{ ref('mercado_ipc_mensual') }} i
    cross join (values
        ('ipc_subyacente', 'Inflación subyacente (variación anual)', '%', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76130'),
        ('ipc_energia', 'IPC de la energía (variación anual)', '%', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76130'),
        ('ipc_alimentos_sin_elaborar', 'IPC de alimentos sin elaborar (variación anual)', '%', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76130'),
        ('ipc_subida_desde_2019', 'Subida acumulada de precios desde 2019', '% sobre la media de 2019', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76125'),
        ('ipc_subida_desde_2008', 'Subida acumulada de precios desde 2008', '% sobre la media de 2008', 'https://www.ine.es/jaxiT3/Tabla.htm?t=76125')
    ) as k(id, nombre, unidad, url)
),

ipc_anual as (
    select
        'economia_ipc_media_anual' as metrica_id,
        'Inflación media anual' as nombre,
        make_date(anio, 1, 1) as periodo,
        100 * (indice_medio / lag(indice_medio) over (order by anio) - 1) as valor,
        '%' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=76125' as url_fuente,
        '/economia/ipc/' as pagina,
        'Anual' as frecuencia
    from (
        select anio, avg(indice) as indice_medio, count(*) as meses
        from {{ ref('mercado_ipc_mensual') }}
        group by anio
    ) a
    where meses = 12
),

ipca_diferencial as (
    select
        'economia_ipca_diferencial_zona_euro' as metrica_id,
        'Diferencia de inflación con la zona euro (IPCA)' as nombre,
        e.mes as periodo,
        e.tasa_anual - z.tasa_anual as valor,
        'pp' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/prc_hicp_minr/default/table' as url_fuente,
        '/economia/ipc/' as pagina,
        'Mensual' as frecuencia
    from {{ ref('mercado_ipca_ue') }} e
    join {{ ref('mercado_ipca_ue') }} z on z.mes = e.mes and z.geo = 'EA20'
    where e.geo = 'ES'
),

-- ---------------------------------------------------------------- Precios de la energía
ipc_electricidad as (
    select
        'economia_ipc_electricidad' as metrica_id,
        'Precio de la electricidad en el IPC (variación anual)' as nombre,
        mes as periodo,
        var_anual as valor,
        '%' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=76128' as url_fuente,
        '/economia/ipc/' as pagina,
        'Mensual' as frecuencia
    from {{ ref('mercado_energia_ipc') }}
    where producto = 'Electricidad'
),

carburantes as (
    select
        case producto when 'Gasolina 95' then 'economia_gasolina95_real' else 'economia_gasoleo_real' end as metrica_id,
        case producto when 'Gasolina 95' then 'Precio de la gasolina 95 con impuestos (real)'
                      else 'Precio del gasóleo de automoción con impuestos (real)' end as nombre,
        fecha as periodo,
        eur_litro_real as valor,
        '€/l (' || (select txt from eur) || ')' as unidad,
        'Comisión Europea' as fuente,
        'https://energy.ec.europa.eu/data-and-analysis/weekly-oil-bulletin_en' as url_fuente,
        '/economia/ipc/' as pagina,
        'Semanal' as frecuencia
    from {{ ref('mercado_energia_carburantes') }}
    where cod_pais = 'ES' and producto in ('Gasolina 95', 'Gasóleo de automoción')
),

luz_hogares as (
    select
        'economia_luz_hogares_real' as metrica_id,
        'Precio de la luz para los hogares con impuestos (real)' as nombre,
        fecha as periodo,
        eur_kwh_real as valor,
        '€/kWh (' || (select txt from eur) || ')' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/nrg_pc_204/default/table' as url_fuente,
        '/economia/ipc/' as pagina,
        'Semestral' as frecuencia
    from {{ ref('mercado_energia_hogares') }}
    where energia = 'Electricidad' and pais = 'España'
),

-- ---------------------------------------------------------------- Empresas
empresas as (
    select
        'economia_empresas_1000hab' as metrica_id,
        'Empresas activas por 1.000 habitantes' as nombre,
        make_date(anio, 1, 1) as periodo,
        empresas_1000hab as valor,
        'por 1.000 hab' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=302' as url_fuente,
        '/economia/empresas/' as pagina,
        'Anual' as frecuencia
    from {{ ref('empresas_dirce_territorio') }}
    where nivel = 'pais'
),

sociedades as (
    select
        'economia_sociedades_creadas_100k' as metrica_id,
        'Sociedades mercantiles creadas (últimos 12 meses)' as nombre,
        fecha as periodo,
        constituidas_12m_100k as valor,
        'por 100.000 hab' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=13912' as url_fuente,
        '/economia/empresas/' as pagina,
        'Mensual' as frecuencia
    from {{ ref('empresas_sociedades_mensual') }}
    where cod = '00'
    union all
    select
        'economia_sociedades_disueltas_100k',
        'Sociedades mercantiles disueltas (últimos 12 meses)',
        fecha,
        disueltas_12m_100k,
        'por 100.000 hab',
        'INE',
        'https://www.ine.es/jaxiT3/Tabla.htm?t=13912',
        '/economia/empresas/',
        'Mensual'
    from {{ ref('empresas_sociedades_mensual') }}
    where cod = '00'
),

autonomos as (
    select
        'economia_autonomos_pct' as metrica_id,
        'Autónomos (ocupados por cuenta propia)' as nombre,
        fecha as periodo,
        pct_cuenta_propia as valor,
        '% de los ocupados' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=65316' as url_fuente,
        '/economia/empresas/' as pagina,
        'Trimestral' as frecuencia
    from {{ ref('empresas_autonomos') }}
    where cod = '00'
),

concursos as (
    select
        'economia_concursos_1000emp' as metrica_id,
        'Deudores concursados por 1.000 empresas' as nombre,
        make_date(anio, 1, 1) as periodo,
        concursos_1000emp as valor,
        'por 1.000 empresas' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=2992' as url_fuente,
        '/economia/empresas/' as pagina,
        'Anual' as frecuencia
    from {{ ref('empresas_concursos') }}
    where cod = '00' and anio >= 2005
),

id as (
    select
        'economia_id_pct_pib' as metrica_id,
        'Gasto en I+D (% del PIB)' as nombre,
        make_date(anio, 1, 1) as periodo,
        pct_pib as valor,
        '% del PIB' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdtot/default/table' as url_fuente,
        '/economia/empresas/' as pagina,
        'Anual' as frecuencia
    from {{ ref('empresas_id_paises') }}
    where geo = 'ES' and sector = 'Total'
    union all
    select
        'economia_id_eur_hab_real',
        'Gasto en I+D por habitante (real)',
        make_date(anio, 1, 1),
        eur_hab_real,
        '€/hab (' || (select txt from eur) || ')',
        'Eurostat',
        'https://ec.europa.eu/eurostat/databrowser/view/rd_e_gerdtot/default/table',
        '/economia/empresas/',
        'Anual'
    from {{ ref('empresas_id_paises') }}
    where geo = 'ES' and sector = 'Total'
),

-- ---------------------------------------------------------------- Turismo
turismo as (
    select
        'economia_' || k.id as metrica_id,
        k.nombre,
        t.mes as periodo,
        case k.id
            when 'turistas_por_hab_12m' then t.turistas_por_hab_12m
            when 'gasto_por_turista_real_12m' then t.gasto_medio_persona_real_12m
            when 'gasto_turistas_pib_12m' then t.gasto_pct_pib_12m
            when 'pernoct_hotel_1000hab_12m' then t.pernoct_hotel_1000hab_12m
        end as valor,
        replace(k.unidad, '{eur}', (select txt from eur)) as unidad,
        'INE' as fuente,
        k.url as url_fuente,
        '/economia/turismo/' as pagina,
        'Mensual' as frecuencia
    from {{ ref('turismo_mensual') }} t
    cross join (values
        ('turistas_por_hab_12m', 'Turistas internacionales por habitante (últimos 12 meses)', 'turistas por hab', 'https://www.ine.es/jaxiT3/Tabla.htm?t=10822'),
        ('gasto_por_turista_real_12m', 'Gasto por turista y viaje (real, últimos 12 meses)', '€ por turista ({eur})', 'https://www.ine.es/jaxiT3/Tabla.htm?t=10838'),
        ('gasto_turistas_pib_12m', 'Gasto de los turistas internacionales (% del PIB, últimos 12 meses)', '% del PIB', 'https://www.ine.es/jaxiT3/Tabla.htm?t=10838'),
        ('pernoct_hotel_1000hab_12m', 'Noches de hotel por 1.000 habitantes (últimos 12 meses)', 'por 1.000 hab', 'https://www.ine.es/jaxiT3/Tabla.htm?t=2074')
    ) as k(id, nombre, unidad, url)
),

viviendas_turisticas as (
    select
        'economia_viviendas_turisticas_1000hab' as metrica_id,
        'Viviendas turísticas por 1.000 habitantes' as nombre,
        periodo,
        viviendas_1000hab as valor,
        'por 1.000 hab' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=39363' as url_fuente,
        '/economia/turismo/' as pagina,
        'Semestral' as frecuencia
    from {{ ref('turismo_viviendas') }}
    where nivel = 'pais'
),

todas as (
    select * from pib_hab
    union all select * from pib_ue
    union all select * from pib_trim
    union all select * from comercio
    union all select * from saldo_exterior
    union all select * from sectores
    union all select * from salarios
    union all select * from epa
    union all select * from paro_registrado
    union all select * from ipc
    union all select * from ipc_anual
    union all select * from ipca_diferencial
    union all select * from ipc_electricidad
    union all select * from carburantes
    union all select * from luz_hogares
    union all select * from empresas
    union all select * from sociedades
    union all select * from autonomos
    union all select * from concursos
    union all select * from id
    union all select * from turismo
    union all select * from viviendas_turisticas
)

select
    cast(metrica_id as varchar) as metrica_id,
    cast(nombre as varchar) as nombre,
    cast(periodo as date) as periodo,
    cast(valor as double) as valor,
    cast(unidad as varchar) as unidad,
    cast(fuente as varchar) as fuente,
    cast(url_fuente as varchar) as url_fuente,
    cast('Economía' as varchar) as tema,
    cast(pagina as varchar) as pagina,
    cast(frecuencia as varchar) as frecuencia
from todas
where valor is not null
  and not isnan(cast(valor as double))
  and periodo is not null
