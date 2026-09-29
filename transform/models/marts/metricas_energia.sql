-- Catálogo de indicadores de Energía y clima y de Movilidad en formato largo
-- (una fila por metrica_id y periodo), para la página /varios/indicadores/.
-- Cada serie replica la consulta de la tarjeta KPI o gráfica principal de su
-- página, siempre a nivel España. Porcentajes y tasas tal cual; volúmenes por
-- habitante cuando la web los ajusta; precios en euros constantes (mart deflactor).
-- Las series diarias o de 5 minutos se agregan a mes (solo meses completos).

with pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'pais' and sexo = 'Total'
),

pob_max as (
    select max(anio) as anio from pob
),

-- ============================ MIX ELÉCTRICO ============================
elec as (
    select * from {{ ref('clima_electricidad_anual') }}
),

mix as (
    select 'energia_electricidad_renovable' as metrica_id, 'Electricidad renovable (cuota de la generación)' as nombre,
        anio, cuota_renovable_pct as valor, '%' as unidad
    from elec
    union all
    select 'energia_co2_por_kwh', 'CO₂ por kWh generado', anio, g_co2_kwh, 'g CO₂eq/kWh' from elec
    union all
    select 'energia_consumo_electrico_hab', 'Consumo eléctrico por habitante', anio, demanda_kwh_hab, 'kWh/hab' from elec
    union all
    select 'energia_electricidad_carbon', 'Carbón (cuota de la generación eléctrica)', anio, cuota_carbon_pct, '%' from elec
),

-- ======================= POTENCIA RENOVABLE (índice) =======================
potencia as (
    select
        case tecnologia when 'Solar Fotovoltaica' then 'energia_potencia_solar_fv' else 'energia_potencia_eolica' end as metrica_id,
        case tecnologia when 'Solar Fotovoltaica' then 'Potencia solar fotovoltaica instalada' else 'Potencia eólica instalada' end as nombre,
        cast("año" as integer) as anio,
        potencia_mw / 1000.0 as valor
    from {{ ref('energia_potencia_instalada') }}
    where tecnologia in ('Solar Fotovoltaica', 'Eólica')
),

-- ============================== EMISIONES ==============================
emis as (
    select * from {{ ref('clima_emisiones_anual') }}
),

emisiones as (
    select 'energia_emisiones_gei_hab' as metrica_id, 'Emisiones de gases de efecto invernadero por habitante' as nombre,
        anio, t_hab as valor, 't CO₂eq/hab' as unidad, 'MITECO / Eurostat' as fuente
    from emis
    union all
    select 'energia_emisiones_gei_var_1990', 'Emisiones de GEI frente a 1990', anio, var_1990_pct, '% vs 1990', 'MITECO / Eurostat' from emis
    union all
    select 'energia_emisiones_intensidad_pib', 'Intensidad de emisiones de la economía', anio, kg_por_euro, 'kg CO₂eq por € de PIB real', 'MITECO / Eurostat' from emis
    union all
    select 'energia_emisiones_hab_vs_ue', 'Emisiones por habitante de España frente a la UE', anio, 100.0 * t_hab / t_hab_ue, '% de la media UE-27', 'Eurostat'
    from emis where t_hab_ue is not null
),

-- ============================ ELECTRIFICACIÓN ============================
electrificacion as (
    select
        case cod_sector
            when 'FC_E' then 'energia_electrificacion_consumo_final'
            when 'FC_OTH_HH_E' then 'energia_electrificacion_hogares'
            when 'FC_IND_E' then 'energia_electrificacion_industria'
            when 'FC_TRA_E' then 'energia_electrificacion_transporte'
        end as metrica_id,
        case cod_sector
            when 'FC_E' then 'Electricidad en el consumo final de energía'
            when 'FC_OTH_HH_E' then 'Electricidad en el consumo de energía de los hogares'
            when 'FC_IND_E' then 'Electricidad en el consumo de energía de la industria'
            when 'FC_TRA_E' then 'Electricidad en el consumo de energía del transporte'
        end as nombre,
        anio,
        100.0 * cuota_electricidad as valor
    from {{ ref('electrificacion_sectores') }}
    where cod_sector in ('FC_E', 'FC_OTH_HH_E', 'FC_IND_E', 'FC_TRA_E')
),

-- ============================== EMBALSES ==============================
-- Misma comparación que embalses_estado_actual (misma semana ISO del año
-- anterior y media de esa semana en los 10 años previos), para cada semana.
emb as (
    select * from {{ ref('embalses_semanal') }} where nivel = 'pais'
),

emb_comp as (
    select
        u.fecha,
        u.pct_llenado,
        round(u.pct_llenado - max(case when s.anio = u.anio - 1 then s.pct_llenado end), 1) as dif_anio,
        round(u.pct_llenado - round(avg(case when s.anio between u.anio - 10 and u.anio - 1 then s.pct_llenado end), 1), 1) as dif_media
    from emb u
    left join emb s on s.semana = u.semana and s.anio < u.anio
    group by u.fecha, u.anio, u.pct_llenado
),

embalses as (
    select 'energia_reserva_hidrica' as metrica_id, 'Reserva hídrica (llenado de los embalses)' as nombre, fecha, pct_llenado as valor, '%' as unidad from emb_comp
    union all
    select 'energia_reserva_hidrica_vs_anio_anterior', 'Reserva hídrica frente a hace un año', fecha, dif_anio, 'p.p.' from emb_comp
    union all
    select 'energia_reserva_hidrica_vs_media_10', 'Reserva hídrica frente a la media de 10 años', fecha, dif_media, 'p.p.' from emb_comp
),

-- ============================== INCENDIOS ==============================
inc as (
    select * from {{ ref('incendios_anual') }}
),

incendios as (
    select 'energia_incendios_superficie' as metrica_id, 'Superficie quemada en incendios forestales' as nombre, anio, ha_quemadas as valor, 'ha' as unidad from inc
    union all
    select 'energia_incendios_numero', 'Incendios forestales cartografiados', anio, n_incendios, 'incendios' from inc
    union all
    select 'energia_incendios_natura2000', 'Superficie quemada dentro de la Red Natura 2000', anio, pct_natura2000, '%' from inc
),

-- ================================ CALOR ================================
-- Diario → mensual, solo meses completos.
calor_mes as (
    select
        date_trunc('month', fecha) as mes,
        avg(anomalia_tmax_media) as anomalia,
        count(*) as dias
    from {{ ref('calor_espana_diario') }}
    group by 1
),

calor_max_mes as (
    select date_trunc('month', fecha) as mes, max(tmax) as tmax, count(distinct fecha) as dias
    from {{ ref('calor_maxima_diaria') }}
    group by 1
),

calor as (
    select 'energia_calor_anomalia_tmax' as metrica_id, 'Anomalía de la temperatura máxima (media nacional)' as nombre,
        mes, anomalia as valor, '°C vs 1991-2020' as unidad
    from calor_mes
    where dias = day(last_day(mes))
    union all
    select 'energia_calor_tmax_maxima', 'Temperatura máxima más alta registrada', mes, tmax, '°C'
    from calor_max_mes
    where dias = day(last_day(mes))
),

-- ============================ ALMACENAMIENTO ============================
alm_pot as (
    select
        mes,
        sum(mw) filter (where tipo = 'bombeo_puro') as bombeo_mw,
        sum(mw) filter (where tipo = 'baterias_hibridadas') as baterias_mw
    from {{ ref('almacenamiento_potencia') }}
    group by mes
),

alm_anual as (
    select
        cast(year(mes) as integer) as anio,
        count(*) as meses,
        sum(bombeo_turbinado_gwh) as bombeo_turbinado_gwh
    from {{ ref('almacenamiento_mensual') }}
    group by 1
),

alm_acceso as (
    select date_trunc('month', fecha_fichero) as mes, sum(otorgada_mw) / 1000.0 as gw
    from {{ ref('almacenamiento_acceso') }}
    group by 1
),

almacenamiento as (
    select 'energia_bombeo_potencia' as metrica_id, 'Bombeo puro instalado' as nombre, mes as periodo, bombeo_mw as valor,
        'MW' as unidad, 'REE (ESIOS)' as fuente, 'https://www.esios.ree.es/' as url_fuente, 'Mensual' as frecuencia
    from alm_pot
    union all
    select 'energia_baterias_potencia', 'Baterías junto a renovables (potencia)', mes, baterias_mw,
        'MW', 'REE (ESIOS)', 'https://www.esios.ree.es/', 'Mensual'
    from alm_pot
    union all
    select 'energia_bombeo_energia_devuelta', 'Energía devuelta por el bombeo', make_date(anio, 1, 1), bombeo_turbinado_gwh / 1000.0,
        'TWh', 'REE', 'https://www.ree.es/es/datos/balance/balance-electrico', 'Anual'
    from alm_anual where meses = 12
    union all
    select 'energia_almacenamiento_acceso', 'Almacenamiento con permiso de acceso a la red', mes, gw,
        'GW', 'REE', 'https://www.ree.es/es/clientes/generador/acceso-conexion/conoce-la-capacidad-de-acceso', 'Mensual'
    from alm_acceso
),

-- =============================== CENTRALES ===============================
cen as (
    select * from {{ ref('centrales_por_anio') }}
),

cen_operacion as (
    select anio, sum(sum(mw_alta - mw_baja)) over (order by anio) / 1000.0 as gw
    from cen
    where anio <= year(current_date)
    group by anio
),

cen_carbon as (
    select anio, sum(sum(mw_baja)) over (order by anio) / 1000.0 as gw
    from cen
    where tecnologia = 'Carbón' and anio >= 2018 and anio <= year(current_date)
    group by anio
),

centrales as (
    select 'energia_centrales_operacion' as metrica_id, 'Potencia de las centrales en operación' as nombre, anio, gw as valor
    from cen_operacion where anio >= 2000
    union all
    select 'energia_carbon_cerrado', 'Potencia de carbón cerrada desde 2018', anio, gw from cen_carbon
),

-- ==================== SISTEMA ELÉCTRICO (directo y récords) ====================
-- Curva de REE cada 5 minutos agregada por día y aquí a mes (meses completos).
ed as (
    select * from {{ ref('electricidad_diaria') }}
),

ed_meses_completos as (
    select date_trunc('month', fecha) as mes
    from ed
    where sistema = 'peninsula'
    group by 1
    having count(*) = day(last_day(min(fecha)))
),

ed_mes as (
    select
        date_trunc('month', e.fecha) as mes,
        max(e.demanda_max_mw) filter (where e.sistema = 'peninsula') as demanda_max_mw,
        100.0 * sum(e.renovable_mwh) / sum(e.generacion_total_mwh) as pct_renovable,
        avg(e.precio_spot_medio_eur_mwh) filter (where e.sistema = 'peninsula') as precio_nominal
    from ed e
    join ed_meses_completos c on c.mes = date_trunc('month', e.fecha)
    group by 1
),

electricidad as (
    select 'energia_demanda_maxima_peninsula' as metrica_id, 'Demanda eléctrica máxima del mes (península)' as nombre,
        mes, demanda_max_mw as valor, 'MW' as unidad, '/energia-clima/records/' as pagina
    from ed_mes
    union all
    select 'energia_renovable_mensual', 'Generación renovable del mes', mes, pct_renovable, '%', '/energia-clima/directo/'
    from ed_mes
    union all
    select 'energia_precio_mayorista_real', 'Precio medio del mercado mayorista (real)', m.mes, m.precio_nominal * d.factor,
        '€/MWh (€ de ' || d.anio_base || ')', '/energia-clima/directo/'
    from ed_mes m
    join {{ ref('deflactor') }} d on d.anio = year(m.mes)
),

-- ============================ COCHE ELÉCTRICO ============================
matr as (
    select
        mes,
        sum(matriculaciones) filter (where energia = 'bev') / sum(matriculaciones) as cuota_bev,
        sum(matriculaciones) filter (where energia in ('bev', 'phev')) / sum(matriculaciones) as cuota_enchufables,
        sum(matriculaciones) filter (where energia in ('bev', 'phev', 'hev')) / sum(matriculaciones) as cuota_electrificados,
        sum(co2_medio * matriculaciones) filter (where co2_medio is not null)
            / sum(matriculaciones) filter (where co2_medio is not null) as co2_medio
    from {{ ref('movilidad_matriculaciones_mensual') }}
    where grupo = 'turismo' and nuevo_usado = 'N'
    group by mes
),

coche as (
    select 'movilidad_cuota_electricos' as metrica_id, 'Turismos nuevos eléctricos puros' as nombre, mes, 100.0 * cuota_bev as valor, '% de las matriculaciones' as unidad from matr
    union all
    select 'movilidad_cuota_enchufables', 'Turismos nuevos enchufables (eléctricos + híbridos enchufables)', mes, 100.0 * cuota_enchufables, '% de las matriculaciones' from matr
    union all
    select 'movilidad_cuota_electrificados', 'Turismos nuevos electrificados (incluidos híbridos)', mes, 100.0 * cuota_electrificados, '% de las matriculaciones' from matr
    union all
    select 'movilidad_co2_turismos_nuevos', 'Emisiones medias de CO₂ de los turismos nuevos', mes, co2_medio, 'g CO₂/km' from matr
),

-- ================================ PARQUE ================================
pq as (
    select * from {{ ref('movilidad_parque_resumen') }}
),

parque as (
    select 'movilidad_turismos_1000hab' as metrica_id, 'Turismos en circulación por 1.000 habitantes' as nombre, mes, turismos_1000 as valor, 'por 1.000 hab' as unidad from pq
    union all
    select 'movilidad_parque_enchufables', 'Turismos enchufables en circulación', mes, pct_enchufables, '% del parque de turismos' from pq
    union all
    select 'movilidad_parque_sin_etiqueta', 'Turismos sin etiqueta ambiental', mes, pct_sin_distintivo, '% del parque de turismos' from pq
),

-- ================================ RECARGA ================================
-- Serie diaria del NAP → último día de cada mes.
rec_dia as (
    select
        fecha,
        sum(puntos) as puntos,
        sum(puntos) filter (where tramo_potencia like 'rápida%' or tramo_potencia like 'ultrarrápida%') as rapidos
    from {{ ref('movilidad_recarga_evolucion') }}
    group by fecha
),

rec_mes as (
    select
        date_trunc('month', r.fecha) as mes,
        arg_max(r.puntos, r.fecha) as puntos,
        arg_max(r.rapidos, r.fecha) as rapidos
    from rec_dia r
    group by 1
),

rec as (
    select
        r.mes,
        r.puntos,
        r.rapidos,
        p.poblacion,
        (select arg_max(q.enchufables, q.mes) from pq q where q.mes <= r.mes) as enchufables
    from rec_mes r
    join pob p on p.anio = least(year(r.mes), (select anio from pob_max))
),

recarga as (
    select 'movilidad_puntos_recarga_100k' as metrica_id, 'Puntos de recarga públicos por 100.000 habitantes' as nombre,
        mes, 100000.0 * puntos / poblacion as valor, 'por 100.000 hab' as unidad
    from rec
    union all
    select 'movilidad_puntos_recarga_rapidos_100k', 'Puntos de recarga rápidos (50 kW o más) por 100.000 habitantes',
        mes, 100000.0 * rapidos / poblacion, 'por 100.000 hab'
    from rec
    union all
    select 'movilidad_enchufables_por_punto', 'Coches enchufables por punto de recarga público',
        mes, 1.0 * enchufables / puntos, 'turismos por punto'
    from rec
),

-- =========================== TRANSPORTE PÚBLICO ===========================
tr as (
    select cast(date_trunc('month', t.mes) as date) as mes, t.clave, t.viajeros, p.poblacion
    from {{ ref('movilidad_transporte_modos') }} t
    join pob p on p.anio = least(year(t.mes), (select anio from pob_max))
    where t.clave in ('total', 'metro', 'alta_velocidad')
),

tr_ave_anual as (
    select year(mes) as anio, sum(viajeros) as viajeros, count(*) as meses, any_value(poblacion) as poblacion
    from tr
    where clave = 'alta_velocidad'
    group by 1
),

transporte as (
    select 'movilidad_viajes_transporte_publico_hab' as metrica_id, 'Viajes en transporte público por habitante' as nombre,
        mes as periodo, viajeros / poblacion as valor, 'viajes/hab al mes' as unidad, 'Mensual' as frecuencia
    from tr where clave = 'total'
    union all
    select 'movilidad_viajes_metro_hab', 'Viajes en metro por habitante', mes, viajeros / poblacion, 'viajes/hab al mes', 'Mensual'
    from tr where clave = 'metro'
    union all
    select 'movilidad_viajes_alta_velocidad_1000hab', 'Viajes en alta velocidad por 1.000 habitantes',
        make_date(cast(anio as integer), 1, 1), 1000.0 * viajeros / poblacion, 'por 1.000 hab al año', 'Anual'
    from tr_ave_anual where meses = 12
),

-- ================================ UNIÓN ================================
todo as (
    select metrica_id, nombre, make_date(anio, 1, 1) as periodo, valor, unidad,
        'REE' as fuente, 'https://www.ree.es/es/datos/apidatos' as url_fuente,
        'Energía y clima' as tema, '/energia-clima/mix-electrico/' as pagina, 'Anual' as frecuencia
    from mix

    union all by name
    select metrica_id, nombre, make_date(anio, 1, 1) as periodo, valor, 'GW' as unidad,
        'Eurostat' as fuente, 'https://ec.europa.eu/eurostat/databrowser/view/nrg_inf_epc' as url_fuente,
        'Energía y clima' as tema, '/energia-clima/' as pagina, 'Anual' as frecuencia
    from potencia

    union all by name
    select metrica_id, nombre, make_date(anio, 1, 1) as periodo, valor, unidad, fuente,
        case when fuente = 'Eurostat' then 'https://ec.europa.eu/eurostat/databrowser/view/env_air_gge/default/table'
             else 'https://www.miteco.gob.es/es/calidad-y-evaluacion-ambiental/temas/sistema-espanol-de-inventario-sei-/inventario-gei.html' end as url_fuente,
        'Energía y clima' as tema, '/energia-clima/emisiones/' as pagina, 'Anual' as frecuencia
    from emisiones

    union all by name
    select metrica_id, nombre, make_date(anio, 1, 1) as periodo, valor, '% de la energía consumida' as unidad,
        'Eurostat' as fuente, 'https://ec.europa.eu/eurostat/databrowser/view/nrg_bal_c' as url_fuente,
        'Energía y clima' as tema, '/energia-clima/electrificacion/' as pagina, 'Anual' as frecuencia
    from electrificacion

    union all by name
    select metrica_id, nombre, fecha as periodo, valor, unidad,
        'MITECO' as fuente, 'https://www.miteco.gob.es/es/agua/temas/evaluacion-de-los-recursos-hidricos/boletin-hidrologico.html' as url_fuente,
        'Energía y clima' as tema, '/energia-clima/embalses/' as pagina, 'Semanal' as frecuencia
    from embalses

    union all by name
    select metrica_id, nombre, make_date(anio, 1, 1) as periodo, valor, unidad,
        'EFFIS (Copernicus)' as fuente, 'https://forest-fire.emergency.copernicus.eu/' as url_fuente,
        'Energía y clima' as tema, '/energia-clima/incendios/' as pagina, 'Anual' as frecuencia
    from incendios

    union all by name
    select metrica_id, nombre, mes as periodo, valor, unidad,
        'AEMET' as fuente, 'https://opendata.aemet.es/' as url_fuente,
        'Energía y clima' as tema, '/energia-clima/calor/' as pagina, 'Mensual' as frecuencia
    from calor

    union all by name
    select *, 'Energía y clima' as tema, '/energia-clima/almacenamiento/' as pagina
    from almacenamiento

    union all by name
    select metrica_id, nombre, make_date(anio, 1, 1) as periodo, valor, 'GW' as unidad,
        'Global Energy Monitor' as fuente, 'https://globalenergymonitor.org/projects/global-integrated-power-tracker/' as url_fuente,
        'Energía y clima' as tema, '/energia-clima/centrales/' as pagina, 'Anual' as frecuencia
    from centrales

    union all by name
    select metrica_id, nombre, mes as periodo, valor, unidad,
        'REE' as fuente, 'https://demanda.ree.es/' as url_fuente,
        'Energía y clima' as tema, pagina, 'Mensual' as frecuencia
    from electricidad

    union all by name
    select metrica_id, nombre, mes as periodo, valor, unidad,
        'DGT' as fuente, 'https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html' as url_fuente,
        'Movilidad' as tema, '/movilidad/coche-electrico/' as pagina, 'Mensual' as frecuencia
    from coche

    union all by name
    select metrica_id, nombre, mes as periodo, valor, unidad,
        'DGT' as fuente, 'https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html' as url_fuente,
        'Movilidad' as tema, '/movilidad/parque/' as pagina, 'Mensual' as frecuencia
    from parque

    union all by name
    select metrica_id, nombre, mes as periodo, valor, unidad,
        'MITECO / DGT (NAP)' as fuente, 'https://nap.dgt.es/dataset/puntos-de-recarga-electrica-para-vehiculos' as url_fuente,
        'Movilidad' as tema, '/movilidad/recarga/' as pagina, 'Mensual' as frecuencia
    from recarga

    union all by name
    select *, 'INE' as fuente, 'https://www.ine.es/jaxiT3/Tabla.htm?t=20239' as url_fuente,
        'Movilidad' as tema, '/movilidad/transporte-publico/' as pagina
    from transporte
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
from todo
where valor is not null
  and isfinite(cast(valor as double))
