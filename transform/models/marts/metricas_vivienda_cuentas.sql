-- Indicadores de seguimiento (formato largo) de las secciones Vivienda, Cuentas
-- públicas, Transparencia y Varios (observatorios), a nivel España.
-- Una fila por (metrica_id, periodo). Replica la lógica de las tarjetas KPI de:
--   /vivienda/ (precios, alquiler, compraventas, construcción, esfuerzo)
--   /cuentas-publicas/ (portada, gastos, ingresos, pensiones, empleo público)
--   /transparencia/ y /varios/observatorios/
-- Importes por habitante y en euros constantes del año base de main.deflactor
-- (igual que en la web); tasas, porcentajes y ratios tal cual.
-- No incluye las series del Tribunal de Cuentas (rastreo aún parcial) ni los
-- datos puntuales sin serie temporal (rankings, extremos por comunidad).

with base as (
    select max(anio_base) as anio_base from {{ ref('deflactor') }}
),

-- ---------------------------------------------------------------- Vivienda
precio_tasado as (
    select
        'vivienda_precio_m2_real' as metrica_id,
        'Valor tasado de la vivienda por m² (real)' as nombre,
        fecha as periodo,
        euros_m2_real as valor,
        '€/m² (€ de ' || anio_base || ')' as unidad,
        'Ministerio de Vivienda' as fuente,
        'https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000' as url_fuente,
        'Vivienda' as tema,
        '/vivienda/precios/' as pagina,
        'Trimestral' as frecuencia
    from {{ ref('vivienda_precio_tasado') }}
    where nivel = 'pais'
),

ipv as (
    select
        'vivienda_ipv_interanual_real' as metrica_id,
        'Subida real del precio de la vivienda (IPV, interanual)' as nombre,
        fecha as periodo,
        interanual_real as valor,
        '%' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=25171' as url_fuente,
        'Vivienda' as tema,
        '/vivienda/precios/' as pagina,
        'Trimestral' as frecuencia
    from {{ ref('vivienda_ipv') }}
    where nivel = 'pais' and tipo = 'General'
    union all
    select
        'vivienda_ipv_indice_real',
        'Índice de precios de vivienda (real, 2015 = 100)',
        fecha,
        indice_real,
        'índice (2015 = 100)',
        'INE',
        'https://www.ine.es/jaxiT3/Tabla.htm?t=25171',
        'Vivienda',
        '/vivienda/precios/',
        'Trimestral'
    from {{ ref('vivienda_ipv') }}
    where nivel = 'pais' and tipo = 'General'
),

alquiler as (
    select
        'vivienda_alquiler_mensual_real' as metrica_id,
        'Alquiler mediano de un piso (real)' as nombre,
        make_date(anio, 1, 1) as periodo,
        alquiler_mes_mediana_real as valor,
        '€/mes (€ de ' || anio_base || ')' as unidad,
        'Ministerio de Vivienda (SERPAVI)' as fuente,
        'https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi' as url_fuente,
        'Vivienda' as tema,
        '/vivienda/alquiler/' as pagina,
        'Anual' as frecuencia
    from {{ ref('vivienda_alquiler') }}
    where nivel = 'pais' and tipologia = 'Colectiva'
    union all
    select
        'vivienda_alquiler_m2_real',
        'Alquiler mediano por m² (real)',
        make_date(anio, 1, 1),
        alquiler_m2_mediana_real,
        '€/m² al mes (€ de ' || anio_base || ')',
        'Ministerio de Vivienda (SERPAVI)',
        'https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi',
        'Vivienda',
        '/vivienda/alquiler/',
        'Anual'
    from {{ ref('vivienda_alquiler') }}
    where nivel = 'pais' and tipologia = 'Colectiva'
    union all
    select
        'vivienda_pisos_alquilados_1000',
        'Pisos alquilados declarados en el IRPF',
        make_date(anio, 1, 1),
        alquiladas_1000,
        'por 1.000 hab',
        'Ministerio de Vivienda (SERPAVI)',
        'https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi',
        'Vivienda',
        '/vivienda/alquiler/',
        'Anual'
    from {{ ref('vivienda_alquiler') }}
    where nivel = 'pais' and tipologia = 'Colectiva'
),

mercado_mensual as (
    select
        'vivienda_compraventas_12m_1000' as metrica_id,
        'Compraventas de viviendas (12 meses)' as nombre,
        fecha as periodo,
        compraventas_12m_1000 as valor,
        'por 1.000 hab' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=6150' as url_fuente,
        'Vivienda' as tema,
        '/vivienda/compraventas/' as pagina,
        'Mensual' as frecuencia
    from {{ ref('vivienda_mercado_mensual') }}
    where nivel = 'pais'
    union all
    select
        'vivienda_hipotecas_12m_1000',
        'Hipotecas sobre viviendas (12 meses)',
        fecha,
        hipotecas_12m_1000,
        'por 1.000 hab',
        'INE',
        'https://www.ine.es/jaxiT3/Tabla.htm?t=13896',
        'Vivienda',
        '/vivienda/compraventas/',
        'Mensual'
    from {{ ref('vivienda_mercado_mensual') }}
    where nivel = 'pais'
),

mercado_anual as (
    select
        'vivienda_hipoteca_media_real' as metrica_id,
        'Hipoteca media sobre vivienda (real)' as nombre,
        make_date(anio, 1, 1) as periodo,
        importe_medio_real as valor,
        '€ (€ de ' || anio_base || ')' as unidad,
        'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=13896' as url_fuente,
        'Vivienda' as tema,
        '/vivienda/compraventas/' as pagina,
        'Anual' as frecuencia
    from {{ ref('vivienda_mercado_anual') }}
    where nivel = 'pais' and meses_hipotecas = 12
    union all
    select
        'vivienda_pct_compraventas_nueva',
        'Vivienda nueva sobre el total de compraventas',
        make_date(anio, 1, 1),
        pct_nueva,
        '%',
        'INE',
        'https://www.ine.es/jaxiT3/Tabla.htm?t=6150',
        'Vivienda',
        '/vivienda/compraventas/',
        'Anual'
    from {{ ref('vivienda_mercado_anual') }}
    where nivel = 'pais' and meses = 12
),

obra_nueva as (
    select
        'vivienda_terminadas_1000' as metrica_id,
        'Viviendas libres terminadas' as nombre,
        make_date(anio, 1, 1) as periodo,
        terminadas_1000 as valor,
        'por 1.000 hab' as unidad,
        'Ministerio de Vivienda' as fuente,
        'https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=32000000' as url_fuente,
        'Vivienda' as tema,
        '/vivienda/construccion/' as pagina,
        'Anual' as frecuencia
    from {{ ref('vivienda_obra_nueva') }}
    where nivel = 'pais' and iniciadas_1000 is not null
    union all
    select
        'vivienda_iniciadas_1000',
        'Viviendas libres iniciadas',
        make_date(anio, 1, 1),
        iniciadas_1000,
        'por 1.000 hab',
        'Ministerio de Vivienda',
        'https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=32000000',
        'Vivienda',
        '/vivienda/construccion/',
        'Anual'
    from {{ ref('vivienda_obra_nueva') }}
    where nivel = 'pais' and iniciadas_1000 is not null
),

esfuerzo as (
    select
        'vivienda_anios_salario_90m2' as metrica_id,
        'Años de salario para comprar 90 m²' as nombre,
        make_date(anio, 1, 1) as periodo,
        anios_salario as valor,
        'años' as unidad,
        'Ministerio de Vivienda / INE' as fuente,
        'https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000' as url_fuente,
        'Vivienda' as tema,
        '/vivienda/esfuerzo/' as pagina,
        'Anual' as frecuencia
    from {{ ref('vivienda_esfuerzo') }}
    where nivel = 'pais'
    union all
    select
        'vivienda_alquiler_pct_salario',
        'Alquiler sobre el salario bruto medio',
        make_date(anio, 1, 1),
        pct_alquiler,
        '%',
        'Ministerio de Vivienda / INE',
        'https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi',
        'Vivienda',
        '/vivienda/esfuerzo/',
        'Anual'
    from {{ ref('vivienda_esfuerzo') }}
    where nivel = 'pais'
),

-- ------------------------------------------------------- Cuentas públicas
balance as (
    select
        b.anio,
        b.ingresos_eur_hab_real as ingresos_hab_real,
        b.gastos_eur_hab_real as gastos_hab_real,
        b.saldo_eur_hab_real as saldo_hab_real,
        b.saldo_deficit_pib,
        b.anio_base
    from {{ ref('cuentas_balance_anual') }} b
    where b.poblacion > 0
),

cuentas_balance as (
    select
        'cuentas_ingresos_hab_real' as metrica_id,
        'Ingresos públicos por habitante (real)' as nombre,
        make_date(anio, 1, 1) as periodo,
        ingresos_hab_real as valor,
        '€/hab (€ de ' || anio_base || ')' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main' as url_fuente,
        'Cuentas públicas' as tema,
        '/cuentas-publicas/' as pagina,
        'Anual' as frecuencia
    from balance
    union all
    select
        'cuentas_gasto_hab_real', 'Gasto público por habitante (real)', make_date(anio, 1, 1), gastos_hab_real,
        '€/hab (€ de ' || anio_base || ')', 'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main',
        'Cuentas públicas', '/cuentas-publicas/', 'Anual'
    from balance
    union all
    select
        'cuentas_saldo_hab_real', 'Déficit / superávit público por habitante (real)', make_date(anio, 1, 1), saldo_hab_real,
        '€/hab (€ de ' || anio_base || ')', 'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main',
        'Cuentas públicas', '/cuentas-publicas/', 'Anual'
    from balance
    union all
    select
        'cuentas_deficit_pib', 'Déficit / superávit público sobre el PIB', make_date(anio, 1, 1), saldo_deficit_pib,
        '% del PIB', 'Eurostat', 'https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main',
        'Cuentas públicas', '/cuentas-publicas/', 'Anual'
    from balance
),

cuentas_gastos as (
    select
        case g.funcion_cofog
            when 'Protección Social y Pensiones' then 'cuentas_gasto_proteccion_social_hab_real'
            when 'Sanidad Pública' then 'cuentas_gasto_sanidad_hab_real'
            when 'Educación' then 'cuentas_gasto_educacion_hab_real'
        end as metrica_id,
        case g.funcion_cofog
            when 'Protección Social y Pensiones' then 'Gasto público en pensiones y protección social por habitante (real)'
            when 'Sanidad Pública' then 'Gasto público en sanidad por habitante (real)'
            when 'Educación' then 'Gasto público en educación por habitante (real)'
        end as nombre,
        make_date(g.anio, 1, 1) as periodo,
        g.gasto_eur_hab_real as valor,
        '€/hab (€ de ' || g.anio_base || ')' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp' as url_fuente,
        'Cuentas públicas' as tema,
        '/cuentas-publicas/gastos/' as pagina,
        'Anual' as frecuencia
    from {{ ref('cuentas_gastos') }} g
    where g.gasto_eur_hab_real is not null
      and g.funcion_cofog in ('Protección Social y Pensiones', 'Sanidad Pública', 'Educación')
),

cuentas_ingresos as (
    select
        case i.categoria
            when 'Cotizaciones Sociales' then 'cuentas_ingreso_cotizaciones_hab_real'
            when 'IRPF y Patrimonio' then 'cuentas_ingreso_irpf_hab_real'
            when 'IVA' then 'cuentas_ingreso_iva_hab_real'
        end as metrica_id,
        case i.categoria
            when 'Cotizaciones Sociales' then 'Cotizaciones sociales por habitante (real)'
            when 'IRPF y Patrimonio' then 'IRPF y Patrimonio por habitante (real)'
            when 'IVA' then 'IVA por habitante (real)'
        end as nombre,
        make_date(i.anio, 1, 1) as periodo,
        i.ingreso_eur_hab_real as valor,
        '€/hab (€ de ' || i.anio_base || ')' as unidad,
        'Eurostat' as fuente,
        'https://ec.europa.eu/eurostat/databrowser/view/gov_10a_taxag' as url_fuente,
        'Cuentas públicas' as tema,
        '/cuentas-publicas/ingresos/' as pagina,
        'Anual' as frecuencia
    from {{ ref('cuentas_ingresos') }} i
    where i.ingreso_eur_hab_real is not null
      and i.categoria in ('Cotizaciones Sociales', 'IRPF y Patrimonio', 'IVA')
),

pensiones as (
    select
        'pensiones_media_jubilacion_real' as metrica_id,
        'Pensión media de jubilación (real)' as nombre,
        cast(fecha as date) as periodo,
        pension_media_jubilacion_real as valor,
        '€/mes (€ de ' || cast(anio_euros as integer) || ')' as unidad,
        'Seguridad Social' as fuente,
        'https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24' as url_fuente,
        'Cuentas públicas' as tema,
        '/cuentas-publicas/pensiones/' as pagina,
        'Mensual' as frecuencia
    from {{ ref('pensiones_mensual') }}
    union all
    select
        'pensiones_afiliados_por_pension',
        'Afiliados a la Seguridad Social por pensión',
        cast(fecha as date),
        afiliados_por_pension,
        'afiliados por pensión',
        'Seguridad Social',
        'https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST8/EST10/EST290/EST291',
        'Cuentas públicas',
        '/cuentas-publicas/pensiones/',
        'Mensual'
    from {{ ref('pensiones_mensual') }}
    union all
    select
        'pensiones_gasto_pib',
        'Gasto público en pensiones de vejez y supervivencia',
        make_date(cast(anio as integer), 1, 1),
        gasto_vejez_supervivientes_pib,
        '% del PIB',
        'Eurostat',
        'https://ec.europa.eu/eurostat/databrowser/view/gov_10a_exp',
        'Cuentas públicas',
        '/cuentas-publicas/pensiones/',
        'Anual'
    from {{ ref('pensiones_gasto_pib') }}
    where geo = 'ES'
    union all
    select
        'pensiones_por_1000_hab',
        'Pensiones contributivas por 1.000 habitantes',
        make_date(cast(anio as integer), 1, 1),
        pensiones_por_1000_hab,
        'por 1.000 hab',
        'Seguridad Social',
        'https://www.seg-social.es/wps/portal/wss/internet/EstadisticasPresupuestosEstudios/Estadisticas/EST23/EST24',
        'Cuentas públicas',
        '/cuentas-publicas/pensiones/',
        'Anual'
    from {{ ref('pensiones_anual') }}
    where meses = 12
),

-- Deflactor solo con años completos de IPC, como en la página de empleo público.
deflactor_completo as (
    select cast(anio as integer) as anio, factor, anio_base
    from {{ ref('deflactor') }}
    where meses = 12
),

empleo as (
    select
        'empleo_publico_por_1000_hab' as metrica_id,
        'Empleados públicos (Registro Central de Personal)' as nombre,
        cast(fecha as date) as periodo,
        por_1000_hab as valor,
        'por 1.000 hab' as unidad,
        'Ministerio para la Transformación Digital y de la Función Pública' as fuente,
        'https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html' as url_fuente,
        'Cuentas públicas' as tema,
        '/cuentas-publicas/empleo-publico/' as pagina,
        'Semestral' as frecuencia
    from {{ ref('empleo_territorio') }}
    where nivel = 'pais' and administracion = 'Total'
    union all
    select
        'empleo_publico_cuota_ccaa',
        'Empleados públicos que trabajan en las comunidades autónomas',
        cast(fecha as date),
        100.0 * sum(efectivos) filter (where administracion = 'Comunidades autónomas') / sum(efectivos),
        '%',
        'Ministerio para la Transformación Digital y de la Función Pública',
        'https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html',
        'Cuentas públicas',
        '/cuentas-publicas/empleo-publico/',
        'Semestral'
    from {{ ref('empleo_efectivos') }}
    group by fecha
    union all
    select
        'empleo_publico_coste_hab_real',
        'Remuneración de los empleados públicos por habitante (real)',
        make_date(c.anio, 1, 1),
        c.eur_hab_real,
        '€/hab (€ de ' || c.anio_base || ')',
        'Eurostat',
        'https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main',
        'Cuentas públicas',
        '/cuentas-publicas/empleo-publico/',
        'Anual'
    from {{ ref('empleo_coste') }} c
    where c.cod_sector = 'S13' and c.eur_hab_real is not null
    union all
    select
        'empleo_publico_salario_real',
        'Salario medio mensual bruto en el sector público, jornada completa (real)',
        make_date(cast(s.anio as integer), 1, 1),
        max(s.salario_mensual) filter (where s.sector = 'Público') * any_value(d.factor),
        '€/mes (€ de ' || any_value(d.anio_base) || ')',
        'INE',
        'https://www.ine.es/jaxiT3/Tabla.htm?t=66250',
        'Cuentas públicas',
        '/cuentas-publicas/empleo-publico/',
        'Anual'
    from {{ ref('empleo_salarios_deciles') }} s
    join deflactor_completo d on d.anio = cast(s.anio as integer)
    where s.jornada = 'Jornada a tiempo completo' and s.decil_nombre = 'Total'
    group by s.anio
),

-- ----------------------------------------------------------- Transparencia
liquidaciones as (
    select
        anio,
        count(*) filter (where incumple) as incumplen,
        1000.0 * coalesce(sum(poblacion) filter (where incumple), 0) / sum(poblacion) as afectados_por_1000
    from {{ ref('transparencia_liquidaciones') }}
    where aplica_indicador
    group by anio
),

transparencia_liq as (
    select
        'transparencia_liquidaciones_sin_remitir' as metrica_id,
        'Ayuntamientos sin remitir la liquidación del presupuesto' as nombre,
        make_date(cast(anio as integer), 1, 1) as periodo,
        incumplen as valor,
        'ayuntamientos' as unidad,
        'Ministerio de Hacienda (CONPREL)' as fuente,
        'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL' as url_fuente,
        'Transparencia' as tema,
        '/transparencia/' as pagina,
        'Anual' as frecuencia
    from liquidaciones
    union all
    select
        'transparencia_liquidaciones_afectados_1000',
        'Vecinos de ayuntamientos sin liquidación remitida',
        make_date(cast(anio as integer), 1, 1),
        afectados_por_1000,
        'por 1.000 hab',
        'Ministerio de Hacienda (CONPREL)',
        'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL',
        'Transparencia',
        '/transparencia/',
        'Anual'
    from liquidaciones
),

pie_meses as (
    select distinct periodo from {{ ref('transparencia_pie_mensual') }}
),

pie as (
    -- Retenidos en el mes y retenido en los 12 meses hasta el mes (euros
    -- constantes), igual que pie_serie_12m de la página; el acumulado solo
    -- desde que hay 12 meses de historia.
    select
        m.periodo,
        count(distinct p.cod_mun) filter (where p.periodo = m.periodo) as retenidos_mes,
        sum(p.importe_eur * coalesce(d.factor, 1)) / 1e6 as millones_12m_real,
        m.periodo >= (select min(periodo) from pie_meses) + interval 11 month as con_12m
    from pie_meses m
    join {{ ref('transparencia_pie_mensual') }} p
      on p.periodo > m.periodo - interval 12 month and p.periodo <= m.periodo
    left join {{ ref('deflactor') }} d on cast(d.anio as integer) = cast(year(p.periodo) as integer)
    group by m.periodo
),

transparencia_pie as (
    select
        'transparencia_pie_retenidos_mes' as metrica_id,
        'Ayuntamientos con la participación en tributos del Estado retenida' as nombre,
        cast(periodo as date) as periodo,
        retenidos_mes as valor,
        'ayuntamientos' as unidad,
        'Ministerio de Hacienda (OVEELL)' as fuente,
        'https://www.hacienda.gob.es/es-ES/Areas%20Tematicas/Administracion%20Electronica/OVEELL/Paginas/Noticias.aspx' as url_fuente,
        'Transparencia' as tema,
        '/transparencia/' as pagina,
        'Mensual' as frecuencia
    from pie
    union all
    select
        'transparencia_pie_retenido_12m_real',
        'Participación en tributos retenida a ayuntamientos (12 meses, real)',
        cast(pie.periodo as date),
        millones_12m_real,
        'M€ (€ de ' || base.anio_base || ')',
        'Ministerio de Hacienda (OVEELL)',
        'https://www.hacienda.gob.es/es-ES/Areas%20Tematicas/Administracion%20Electronica/OVEELL/Paginas/Noticias.aspx',
        'Transparencia',
        '/transparencia/',
        'Mensual'
    from pie
    cross join base
    where con_12m
),

pmp as (
    select
        fecha_trimestre,
        count(*) filter (where aplica_indicador and not reporta) as no_comunican,
        1000.0 * coalesce(sum(poblacion) filter (where aplica_indicador and not reporta), 0)
            / sum(poblacion) filter (where aplica_indicador) as afectados_por_1000,
        count(*) filter (where supera_30) as supera_30
    from {{ ref('transparencia_pmp') }}
    group by fecha_trimestre
),

transparencia_pmp as (
    select
        'transparencia_pmp_sin_comunicar' as metrica_id,
        'Ayuntamientos sin comunicar el periodo medio de pago' as nombre,
        cast(fecha_trimestre as date) as periodo,
        no_comunican as valor,
        'ayuntamientos' as unidad,
        'Ministerio de Hacienda (PMP_NET)' as fuente,
        'https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/' as url_fuente,
        'Transparencia' as tema,
        '/transparencia/' as pagina,
        'Trimestral' as frecuencia
    from pmp
    union all
    select
        'transparencia_pmp_afectados_1000',
        'Vecinos de ayuntamientos sin periodo medio de pago comunicado',
        cast(fecha_trimestre as date),
        afectados_por_1000,
        'por 1.000 hab',
        'Ministerio de Hacienda (PMP_NET)',
        'https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/',
        'Transparencia',
        '/transparencia/',
        'Trimestral'
    from pmp
    union all
    select
        'transparencia_pmp_mas_30_dias',
        'Ayuntamientos que pagan a proveedores en más de 30 días',
        cast(fecha_trimestre as date),
        supera_30,
        'ayuntamientos',
        'Ministerio de Hacienda (PMP_NET)',
        'https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/',
        'Transparencia',
        '/transparencia/',
        'Trimestral'
    from pmp
),

-- ------------------------------------------------------ Varios: observatorios
obs_anio as (
    select
        cast(anio_creacion as integer) as anio,
        count(*) as creados,
        sum(count(*)) over (order by cast(anio_creacion as integer)) as acumulados
    from {{ ref('observatorios_detalle') }}
    where anio_creacion is not null
    group by cast(anio_creacion as integer)
),

observatorios as (
    select
        'observatorios_creados' as metrica_id,
        'Observatorios públicos creados en el año' as nombre,
        make_date(anio, 1, 1) as periodo,
        creados as valor,
        'observatorios' as unidad,
        'observatoriospublicos.es' as fuente,
        'https://observatoriospublicos.es/' as url_fuente,
        'Varios' as tema,
        '/varios/observatorios/' as pagina,
        'Anual' as frecuencia
    from obs_anio
    union all
    select
        'observatorios_acumulados',
        'Observatorios públicos creados (acumulado)',
        make_date(anio, 1, 1),
        acumulados,
        'observatorios',
        'observatoriospublicos.es',
        'https://observatoriospublicos.es/',
        'Varios',
        '/varios/observatorios/',
        'Anual'
    from obs_anio
),

unido as (
    select * from precio_tasado
    union all by name select * from ipv
    union all by name select * from alquiler
    union all by name select * from mercado_mensual
    union all by name select * from mercado_anual
    union all by name select * from obra_nueva
    union all by name select * from esfuerzo
    union all by name select * from cuentas_balance
    union all by name select * from cuentas_gastos
    union all by name select * from cuentas_ingresos
    union all by name select * from pensiones
    union all by name select * from empleo
    union all by name select * from transparencia_liq
    union all by name select * from transparencia_pie
    union all by name select * from transparencia_pmp
    union all by name select * from observatorios
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
from unido
where valor is not null and periodo is not null and not isnan(cast(valor as double))
