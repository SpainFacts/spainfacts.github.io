-- Indicadores territoriales (comunidad y provincia) para el explorador de mapas
-- (/varios/mapas/), temas: Vivienda, Cuentas públicas, Transparencia, Energía y
-- clima, Movilidad y Varios. Formato largo: una fila por indicador, territorio y
-- año. Códigos INE (cod_ccaa '01'..'19', cod_prov '01'..'52').
-- Principio rector: importes por habitante y en euros reales (deflactor del IPC,
-- euros del último año completo); totales convertidos en tasas por habitante.
-- Los porcentajes van en escala 0-100.


with pob as (
    select nivel, cod, anio, cast(poblacion as double) as poblacion
    from {{ ref('poblacion_territorios') }}
    where sexo = 'Total' and nivel in ('ccaa', 'provincia')
),

pob_max as (
    select max(anio) as anio from pob
),

defl as (
    select anio, factor, anio_base from {{ ref('deflactor') }}
),

base_real as (
    select max(anio_base) as anio_base from defl
),

provincias as (
    select cod as cod_prov, cod_ccaa from {{ ref('territorios') }} where nivel = 'provincia'
),

-- Superficie de cada provincia en km², calculada sobre static/geo/provincias.geojson
-- (límites del IGN, área elipsoidal); coincide con la superficie oficial del INE.
superficie_prov (cod_prov, km2) as (
    values
    ('01', 3029), ('02', 14940), ('03', 5818), ('04', 8770), ('05', 8046), ('06', 21764),
    ('07', 4990), ('08', 7748), ('09', 14297), ('10', 19864), ('11', 7444), ('12', 6637),
    ('13', 19814), ('14', 13785), ('15', 7965), ('16', 17136), ('17', 5904), ('18', 12650),
    ('19', 12215), ('20', 1986), ('21', 10128), ('22', 15638), ('23', 13494), ('24', 15581),
    ('25', 12156), ('26', 5051), ('27', 9853), ('28', 8027), ('29', 7308), ('30', 11328),
    ('31', 10389), ('32', 7287), ('33', 10605), ('34', 8046), ('35', 4078), ('36', 4488),
    ('37', 12348), ('38', 3379), ('39', 5345), ('40', 6930), ('41', 14024), ('42', 10305),
    ('43', 6308), ('44', 14804), ('45', 15367), ('46', 10808), ('47', 8106), ('48', 2213),
    ('49', 10569), ('50', 17284), ('51', 18), ('52', 13)
),

-- =====================================================================
-- VIVIENDA
-- =====================================================================
viv_precio as (
    select
        'vivienda_precio_m2' as ind, nivel, cod, anio,
        avg(euros_m2_real) as valor,
        'Precio de la vivienda libre por m² (tasación, real)' as nombre,
        '€/m² (€ de ' || max(anio_base) || ')' as unidad,
        'neutro' as sentido,
        case when count(*) < 4 then 'Media de los ' || count(*) || ' trimestres publicados del año'
             else 'Media anual de los cuatro trimestres' end as nota
    from {{ ref('vivienda_precio_tasado') }}
    where nivel in ('ccaa', 'provincia') and euros_m2_real is not null
    group by nivel, cod, anio
),

viv_alquiler as (
    select 'vivienda_alquiler_mes' as ind, nivel, cod, anio, alquiler_mes_mediana_real as valor,
        'Alquiler mensual mediano (vivienda colectiva, real)' as nombre,
        '€/mes (€ de ' || anio_base || ')' as unidad, 'negativo' as sentido,
        'Mediana de los contratos con fianza depositada (SERPAVI)' as nota
    from {{ ref('vivienda_alquiler') }}
    where nivel in ('ccaa', 'provincia') and tipologia = 'Colectiva'
    union all
    select 'vivienda_alquiler_m2', nivel, cod, anio, alquiler_m2_mediana_real,
        'Alquiler mediano por m² (vivienda colectiva, real)',
        '€/m² al mes (€ de ' || anio_base || ')', 'negativo',
        'Mediana de los contratos con fianza depositada (SERPAVI)'
    from {{ ref('vivienda_alquiler') }}
    where nivel in ('ccaa', 'provincia') and tipologia = 'Colectiva'
    union all
    select 'vivienda_alquiladas_1000', nivel, cod, anio, alquiladas_1000,
        'Viviendas colectivas en alquiler por 1.000 habitantes',
        'por 1.000 hab', 'neutro',
        'Viviendas con contrato de alquiler y fianza depositada (SERPAVI)'
    from {{ ref('vivienda_alquiler') }}
    where nivel in ('ccaa', 'provincia') and tipologia = 'Colectiva'
),

viv_esfuerzo as (
    select 'vivienda_esfuerzo_compra' as ind, nivel, cod, anio, anios_salario as valor,
        'Años de salario para comprar una vivienda de 90 m²' as nombre,
        'años de salario' as unidad, 'negativo' as sentido,
        'Precio tasado de 90 m² dividido entre el salario medio anual' as nota
    from {{ ref('vivienda_esfuerzo') }}
    where nivel = 'ccaa'
    union all
    select 'vivienda_esfuerzo_alquiler', nivel, cod, anio, pct_alquiler,
        'Porcentaje del salario que se va en el alquiler',
        '%', 'negativo',
        'Alquiler mediano anual sobre el salario medio anual'
    from {{ ref('vivienda_esfuerzo') }}
    where nivel = 'ccaa'
),

viv_mercado as (
    select 'vivienda_compraventas_1000' as ind, nivel, cod, anio, compraventas_1000 as valor,
        'Compraventas de vivienda por 1.000 habitantes' as nombre,
        'por 1.000 hab' as unidad, 'neutro' as sentido,
        'Solo años completos' as nota
    from {{ ref('vivienda_mercado_anual') }}
    where nivel in ('ccaa', 'provincia') and meses = 12
    union all
    select 'vivienda_pct_nueva', nivel, cod, anio, pct_nueva,
        'Compraventas de vivienda nueva (% del total)', '%', 'neutro', 'Solo años completos'
    from {{ ref('vivienda_mercado_anual') }}
    where nivel in ('ccaa', 'provincia') and meses = 12
    union all
    select 'vivienda_hipotecas_1000', nivel, cod, anio, hipotecas_1000,
        'Hipotecas sobre vivienda por 1.000 habitantes', 'por 1.000 hab', 'neutro', 'Solo años completos'
    from {{ ref('vivienda_mercado_anual') }}
    where nivel in ('ccaa', 'provincia') and meses_hipotecas = 12
    union all
    select 'vivienda_hipoteca_media', nivel, cod, anio, importe_medio_real,
        'Importe medio de la hipoteca sobre vivienda (real)',
        '€ (€ de ' || anio_base || ')', 'neutro', 'Solo años completos'
    from {{ ref('vivienda_mercado_anual') }}
    where nivel in ('ccaa', 'provincia') and meses_hipotecas = 12
),

viv_obra as (
    select 'vivienda_iniciadas_1000' as ind, nivel, cod, anio, iniciadas_1000 as valor,
        'Viviendas libres iniciadas por 1.000 habitantes' as nombre,
        'por 1.000 hab' as unidad, 'positivo' as sentido, null as nota
    from {{ ref('vivienda_obra_nueva') }}
    where nivel in ('ccaa', 'provincia')
    union all
    select 'vivienda_terminadas_1000', nivel, cod, anio, terminadas_1000,
        'Viviendas libres terminadas por 1.000 habitantes', 'por 1.000 hab', 'positivo', null
    from {{ ref('vivienda_obra_nueva') }}
    where nivel in ('ccaa', 'provincia')
),

viv_turisticas_base as (
    select *
    from {{ ref('turismo_viviendas') }}
    where nivel in ('ccaa', 'provincia')
    qualify periodo = max(periodo) over (partition by anio)
),

viv_turisticas as (
    select 'vivienda_turisticas_1000' as ind, nivel, cod, anio, viviendas_1000hab as valor,
        'Viviendas turísticas por 1.000 habitantes' as nombre,
        'por 1.000 hab' as unidad, 'neutro' as sentido,
        'Última medición del año (' || strftime(periodo, '%m/%Y') || ')' as nota
    from viv_turisticas_base
    union all
    select 'vivienda_turisticas_pct', nivel, cod, anio, pct_viviendas,
        'Viviendas turísticas (% del total de viviendas)', '%', 'neutro',
        'Última medición del año (' || strftime(periodo, '%m/%Y') || ')'
    from viv_turisticas_base
),

-- =====================================================================
-- CUENTAS PÚBLICAS
-- =====================================================================
ccaa_cuentas as (
    select
        r.anio, r.cod_ccaa as cod,
        r.gastos_no_financieros / p.poblacion * f.factor as gasto_hab,
        r.ingresos_no_financieros / p.poblacion * f.factor as ingreso_hab,
        r.saldo_no_financiero / p.poblacion * f.factor as saldo_hab
    from {{ ref('ccaa_cuentas_resumen') }} r
    join pob p on p.nivel = 'ccaa' and p.cod = r.cod_ccaa
        and p.anio = least(r.anio, (select anio from pob_max))
    join defl f on f.anio = cast(r.anio as integer)
),

cp_ccaa_cuentas as (
    select 'cuentas_ccaa_gasto_hab' as ind, 'ccaa' as nivel, cod, anio, gasto_hab as valor,
        'Gasto no financiero de la comunidad por habitante (real)' as nombre,
        'neutro' as sentido,
        'Liquidación consolidada, obligaciones reconocidas (capítulos 1-7)' as nota
    from ccaa_cuentas
    union all
    select 'cuentas_ccaa_ingreso_hab', 'ccaa', cod, anio, ingreso_hab,
        'Ingreso no financiero de la comunidad por habitante (real)', 'neutro',
        'Liquidación consolidada, derechos reconocidos (capítulos 1-7)'
    from ccaa_cuentas
    union all
    select 'cuentas_ccaa_saldo_presupuestario_hab', 'ccaa', cod, anio, saldo_hab,
        'Saldo presupuestario no financiero por habitante (real)', 'positivo',
        'Ingresos menos gastos no financieros liquidados; negativo = déficit'
    from ccaa_cuentas
),

ccaa_deuda_anual as (
    select d.anio, d.cod_ccaa as cod, d.trimestre, d.deuda_pct_pib,
        d.deuda_eur / p.poblacion * f.factor as deuda_hab
    from {{ ref('ccaa_deuda') }} d
    join pob p on p.nivel = 'ccaa' and p.cod = d.cod_ccaa
        and p.anio = least(d.anio, (select anio from pob_max))
    join defl f on f.anio = cast(d.anio as integer)
    qualify row_number() over (partition by d.cod_ccaa, d.anio order by d.fecha desc) = 1
),

cp_ccaa_deuda as (
    select 'cuentas_ccaa_deuda_hab' as ind, 'ccaa' as nivel, cod, anio, deuda_hab as valor,
        'Deuda de la comunidad por habitante (PDE, real)' as nombre,
        'negativo' as sentido,
        'Último trimestre publicado del año (' || trimestre || '.º)' as nota
    from ccaa_deuda_anual
    union all
    select 'cuentas_ccaa_deuda_pib', 'ccaa', cod, anio, deuda_pct_pib,
        'Deuda de la comunidad (% del PIB regional)', 'negativo',
        'Último trimestre publicado del año (' || trimestre || '.º)'
    from ccaa_deuda_anual
    where deuda_pct_pib is not null
),

cp_ccaa_saldo as (
    select 'cuentas_ccaa_saldo_pib' as ind, 'ccaa' as nivel, s.cod_ccaa as cod, s.anio,
        s.saldo_pct_pib as valor,
        'Déficit (-) o superávit (+) de la comunidad (% del PIB regional)' as nombre,
        '%' as unidad, 'positivo' as sentido,
        'Capacidad/necesidad de financiación (SEC 2010); PIB implícito en la deuda' as nota
    from {{ ref('ccaa_saldo') }} s
    union all
    select 'cuentas_ccaa_saldo_hab', 'ccaa', s.cod_ccaa, s.anio,
        s.saldo_eur / p.poblacion * f.factor,
        'Déficit (-) o superávit (+) de la comunidad por habitante (real)',
        null, 'positivo',
        'Capacidad/necesidad de financiación (SEC 2010)'
    from {{ ref('ccaa_saldo') }} s
    join pob p on p.nivel = 'ccaa' and p.cod = s.cod_ccaa
        and p.anio = least(s.anio, (select anio from pob_max))
    join defl f on f.anio = cast(s.anio as integer)
),

deuda_local as (
    select cast(d.anio as integer) as anio, d.cod_prov, v.cod_ccaa,
        d.deuda_eur, d.deuda_ayuntamientos_eur
    from {{ ref('local_deuda_provincia') }} d
    join provincias v on v.cod_prov = d.cod_prov
    qualify row_number() over (partition by d.cod_prov, d.anio order by d.fecha desc) = 1
),

deuda_local_niveles as (
    select anio, 'provincia' as nivel, cod_prov as cod,
        deuda_eur, deuda_ayuntamientos_eur
    from deuda_local
    union all
    select anio, 'ccaa', cod_ccaa, sum(deuda_eur), sum(deuda_ayuntamientos_eur)
    from deuda_local
    group by anio, cod_ccaa
),

cp_deuda_local as (
    select 'cuentas_deuda_local_hab' as ind, d.nivel, d.cod, d.anio,
        d.deuda_eur / p.poblacion * f.factor as valor,
        'Deuda de las entidades locales por habitante (real)' as nombre,
        'negativo' as sentido,
        'Ayuntamientos, diputaciones, cabildos, consells y demás entidades locales; a 31 de diciembre' as nota
    from deuda_local_niveles d
    join pob p on p.nivel = d.nivel and p.cod = d.cod
        and p.anio = least(d.anio, (select anio from pob_max))
    join defl f on f.anio = d.anio
    union all
    select 'cuentas_deuda_ayuntamientos_hab', d.nivel, d.cod, d.anio,
        d.deuda_ayuntamientos_eur / p.poblacion * f.factor,
        'Deuda de los ayuntamientos por habitante (real)', 'negativo',
        'A 31 de diciembre'
    from deuda_local_niveles d
    join pob p on p.nivel = d.nivel and p.cod = d.cod
        and p.anio = least(d.anio, (select anio from pob_max))
    join defl f on f.anio = d.anio
),

empleo_anual as (
    select year(fecha) as anio, fecha, nivel, cod, administracion, por_1000_hab
    from {{ ref('empleo_territorio') }}
    where nivel in ('ccaa', 'provincia') and por_1000_hab is not null
    qualify fecha = max(fecha) over (partition by year(fecha))
),

cp_empleo as (
    select
        case administracion
            when 'Total' then 'empleo_publico_1000'
            when 'Estado' then 'empleo_publico_estado_1000'
            when 'Comunidades autónomas' then 'empleo_publico_autonomico_1000'
            when 'Entidades locales' then 'empleo_publico_local_1000'
        end as ind,
        nivel, cod, anio, por_1000_hab as valor,
        case administracion
            when 'Total' then 'Empleados públicos por 1.000 habitantes'
            when 'Estado' then 'Empleados públicos de la Administración del Estado por 1.000 habitantes'
            when 'Comunidades autónomas' then 'Empleados públicos autonómicos por 1.000 habitantes'
            when 'Entidades locales' then 'Empleados públicos locales por 1.000 habitantes'
        end as nombre,
        'por 1.000 hab' as unidad, 'neutro' as sentido,
        'Registro Central de Personal, edición de ' || strftime(fecha, '%m/%Y')
            || ' (la última del año); provincia del puesto de trabajo' as nota
    from empleo_anual
    where administracion in ('Total', 'Estado', 'Comunidades autónomas', 'Entidades locales')
),

cp_gasto_personal as (
    select 'empleo_gasto_personal_ccaa_hab' as ind, g.nivel, g.cod, g.anio,
        g.gasto_personal_ccaa_hab * f.factor as valor,
        'Gasto de personal de la comunidad por habitante (real)' as nombre,
        'neutro' as sentido,
        'Capítulo 1 de la liquidación consolidada de la comunidad' as nota
    from {{ ref('empleo_gasto_personal_territorio') }} g
    join defl f on f.anio = cast(g.anio as integer)
    where g.nivel = 'ccaa' and g.gasto_personal_ccaa_hab is not null
    union all
    select 'empleo_gasto_personal_aytos_hab', g.nivel, g.cod, g.anio,
        g.gasto_personal_ayuntamientos_hab * f.factor,
        'Gasto de personal de los ayuntamientos por habitante (real)', 'neutro',
        'Capítulo 1 de los ayuntamientos con datos en CONPREL, por habitante de esos municipios; sin Álava ni Navarra (régimen foral)'
    from {{ ref('empleo_gasto_personal_territorio') }} g
    join defl f on f.anio = cast(g.anio as integer)
    where g.nivel in ('ccaa', 'provincia') and g.gasto_personal_ayuntamientos_hab is not null
),

cp_epa as (
    select 'empleo_publico_cuota_epa' as ind, 'ccaa' as nivel, cod_ccaa as cod,
        cast(year(trimestre) as integer) as anio,
        100 * avg(cuota_publico) as valor,
        'Asalariados del sector público (% del total de asalariados, EPA)' as nombre,
        '%' as unidad, 'neutro' as sentido,
        case when count(*) < 4 then 'Media de los ' || count(*) || ' trimestres publicados del año'
             else 'Media anual de los cuatro trimestres' end as nota
    from {{ ref('empleo_epa_ccaa') }}
    where cod_ccaa between '01' and '19' and cuota_publico is not null
    group by cod_ccaa, year(trimestre)
),

cp_salarios as (
    select 'empleo_salario_publico' as ind, 'ccaa' as nivel, s.cod_ccaa as cod,
        cast(s.anio as integer) as anio,
        s.salario_publico * f.factor as valor,
        'Salario medio anual en el sector público (real)' as nombre,
        'neutro' as sentido,
        'Encuesta cuatrienal de Estructura Salarial; salario bruto anual por trabajador' as nota
    from {{ ref('empleo_salarios_ccaa') }} s
    join defl f on f.anio = cast(s.anio as integer)
    where s.cod_ccaa between '01' and '19' and s.salario_publico is not null
    union all
    select 'empleo_brecha_salarial_publico', 'ccaa', s.cod_ccaa, cast(s.anio as integer),
        100 * (s.salario_publico / s.salario_privado - 1),
        'Diferencia del salario público sobre el privado', 'neutro',
        'Encuesta cuatrienal de Estructura Salarial; positivo = el sector público cobra más'
    from {{ ref('empleo_salarios_ccaa') }} s
    where s.cod_ccaa between '01' and '19' and s.salario_publico is not null and s.salario_privado > 0
),

-- =====================================================================
-- TRANSPARENCIA (ayuntamientos obligados; los forales quedan fuera)
-- =====================================================================
liq as (
    select anio, cod_prov, cod_ccaa, incumple
    from {{ ref('transparencia_liquidaciones') }}
    where aplica_indicador
),

tr_liquidaciones as (
    select 'transparencia_liquidacion_no_remitida' as ind, 'provincia' as nivel, cod_prov as cod, anio,
        100.0 * avg(incumple::int) as valor
    from liq where cod_prov is not null group by all
    union all
    select 'transparencia_liquidacion_no_remitida', 'ccaa', cod_ccaa, anio, 100.0 * avg(incumple::int)
    from liq where cod_ccaa is not null group by all
),

pmp as (
    select anio, cod_prov, cod_ccaa, reporta, supera_30, pmp_dias
    from {{ ref('transparencia_pmp') }}
    where aplica_indicador
),

pmp_niveles as (
    select anio, 'provincia' as nivel, cod_prov as cod,
        100.0 * avg((not reporta)::int) as no_reporta,
        100.0 * avg(supera_30::int) filter (where reporta) as supera_30,
        median(pmp_dias) filter (where reporta) as pmp_mediano
    from pmp where cod_prov is not null group by all
    union all
    select anio, 'ccaa', cod_ccaa,
        100.0 * avg((not reporta)::int),
        100.0 * avg(supera_30::int) filter (where reporta),
        median(pmp_dias) filter (where reporta)
    from pmp where cod_ccaa is not null group by all
),

pmp_trimestres as (
    select anio, count(distinct trimestre) as n from {{ ref('transparencia_pmp') }} group by anio
),

tr_pmp as (
    select 'transparencia_pmp_no_comunicado' as ind, n.nivel, n.cod, n.anio, n.no_reporta as valor,
        'Ayuntamientos que no comunican su periodo medio de pago (%)' as nombre,
        case when t.n < 4 then 'Media de los ' || t.n || ' trimestres publicados del año'
             else 'Media de los cuatro trimestres del año' end as nota
    from pmp_niveles n join pmp_trimestres t using (anio)
    union all
    select 'transparencia_pmp_mas_30_dias', n.nivel, n.cod, n.anio, n.supera_30,
        'Ayuntamientos que pagan a proveedores en más de 30 días (% de los que lo comunican)',
        case when t.n < 4 then 'Media de los ' || t.n || ' trimestres publicados del año'
             else 'Media de los cuatro trimestres del año' end
    from pmp_niveles n join pmp_trimestres t using (anio)
    where n.supera_30 is not null
    union all
    select 'transparencia_pmp_mediano', n.nivel, n.cod, n.anio, n.pmp_mediano,
        'Periodo medio de pago a proveedores del ayuntamiento mediano',
        'Mediana de los ayuntamientos que lo comunican, todos los trimestres del año; el máximo legal es 30 días'
    from pmp_niveles n
    where n.pmp_mediano is not null
),

pie as (
    select anio, cod_prov, cod_ccaa, retenido, campania_completa
    from {{ ref('transparencia_pie') }}
    where aplica_indicador and seccion = 'liquidacion'
),

tr_pie as (
    select 'transparencia_pie_retenida' as ind, 'provincia' as nivel, cod_prov as cod,
        cast(anio as integer) as anio, 100.0 * avg(retenido::int) as valor,
        bool_and(campania_completa) as completa
    from pie where cod_prov is not null group by all
    union all
    select 'transparencia_pie_retenida', 'ccaa', cod_ccaa, cast(anio as integer),
        100.0 * avg(retenido::int), bool_and(campania_completa)
    from pie where cod_ccaa is not null group by all
),

-- =====================================================================
-- ENERGÍA Y CLIMA
-- =====================================================================
centrales as (
    select cod_prov, cod_ccaa, estado_grupo, renovable, potencia_mw
    from {{ ref('centrales_unidades') }}
    where potencia_mw is not null
),

centrales_niveles as (
    select 'provincia' as nivel, cod_prov as cod,
        sum(potencia_mw) filter (where estado_grupo = 'En operación') as operacion,
        sum(potencia_mw) filter (where estado_grupo = 'En operación' and renovable) as renovable,
        sum(potencia_mw) filter (where estado_grupo in ('En construcción', 'En tramitación', 'Anunciada')) as cartera
    from centrales where cod_prov is not null group by all
    union all
    select 'ccaa', cod_ccaa,
        sum(potencia_mw) filter (where estado_grupo = 'En operación'),
        sum(potencia_mw) filter (where estado_grupo = 'En operación' and renovable),
        sum(potencia_mw) filter (where estado_grupo in ('En construcción', 'En tramitación', 'Anunciada'))
    from centrales where cod_ccaa is not null group by all
),

centrales_hab as (
    select c.*, p.poblacion, cast(year(current_date) as integer) as anio
    from centrales_niveles c
    join pob p on p.nivel = c.nivel and p.cod = c.cod and p.anio = (select anio from pob_max)
),

en_centrales as (
    select 'energia_potencia_hab' as ind, nivel, cod, anio,
        1000 * coalesce(operacion, 0) / poblacion as valor,
        'Potencia eléctrica instalada en operación por habitante' as nombre,
        'kW por habitante' as unidad, 'neutro' as sentido,
        'Situación actual (Global Energy Monitor); centrales de 1 MW o más en general' as nota
    from centrales_hab
    union all
    select 'energia_potencia_renovable_hab', nivel, cod, anio,
        1000 * coalesce(renovable, 0) / poblacion,
        'Potencia renovable en operación por habitante', 'kW por habitante', 'positivo',
        'Situación actual (Global Energy Monitor)'
    from centrales_hab
    union all
    select 'energia_pct_renovable', nivel, cod, anio,
        100 * coalesce(renovable, 0) / operacion,
        'Potencia renovable (% de la potencia en operación)', '%', 'positivo',
        'Situación actual (Global Energy Monitor)'
    from centrales_hab
    where operacion > 0
    union all
    select 'energia_potencia_cartera_hab', nivel, cod, anio,
        1000 * coalesce(cartera, 0) / poblacion,
        'Potencia en construcción, tramitación o anunciada por habitante', 'kW por habitante', 'neutro',
        'Situación actual (Global Energy Monitor); proyectos que pueden no llegar a construirse'
    from centrales_hab
),

incendios_anios as (
    select distinct anio from {{ ref('incendios_provincia_anio') }}
),

incendios_prov as (
    select a.anio, v.cod_prov, v.cod_ccaa, s.km2, coalesce(i.ha_quemadas, 0) as ha
    from incendios_anios a
    cross join provincias v
    join superficie_prov s on s.cod_prov = v.cod_prov
    left join {{ ref('incendios_provincia_anio') }} i on i.anio = a.anio and i.cod_prov = v.cod_prov
),

en_incendios as (
    select 'energia_incendios_pct_superficie' as ind, 'provincia' as nivel, cod_prov as cod, anio,
        100 * ha / (km2 * 100) as valor
    from incendios_prov
    union all
    select 'energia_incendios_pct_superficie', 'ccaa', cod_ccaa, anio,
        100 * sum(ha) / (sum(km2) * 100)
    from incendios_prov
    group by cod_ccaa, anio
),

calor_prov as (
    select
        anio, cod_prov,
        avg(anomalia_tmax) as anomalia_tmax,
        count(*) filter (where supera_p90) as dias_p90,
        max(fecha) as ultima_fecha
    from {{ ref('calor_provincia_diario') }}
    group by anio, cod_prov
    -- mismo criterio que calor_anual: se descartan provincia-años con muchos huecos
    having count(anomalia_tmax) >= 0.8 * (max(dia_anio) - min(dia_anio) + 1)
),

en_calor as (
    select 'energia_calor_anomalia_tmax' as ind, 'provincia' as nivel, cod_prov as cod, anio,
        anomalia_tmax as valor,
        'Anomalía media de la temperatura máxima frente a 1991-2020' as nombre,
        '°C' as unidad, 'negativo' as sentido,
        case when ultima_fecha < make_date(anio, 12, 28)
             then 'Año en curso, hasta el ' || strftime(ultima_fecha, '%d/%m/%Y')
             else 'Estación de referencia de AEMET en la provincia' end as nota
    from calor_prov
    where anomalia_tmax is not null
    union all
    select 'energia_calor_dias_p90', 'provincia', cod_prov, anio, dias_p90,
        'Días de calor inusual (máxima por encima del percentil 90)', 'días', 'negativo',
        case when ultima_fecha < make_date(anio, 12, 28)
             then 'Año en curso, hasta el ' || strftime(ultima_fecha, '%d/%m/%Y')
             else 'Percentil 90 de la máxima de ese día en 1991-2020' end
    from calor_prov
),

calefaccion as (
    select 'provincia' as nivel, cod_prov as cod,
        cast(viviendas as double) as viviendas, electricidad, gas_natural, petroleo
    from {{ ref('electrificacion_calefaccion_provincia') }}
    where cod_prov <> '00' and viviendas > 0
    union all
    select 'ccaa', cod_ccaa, sum(viviendas), sum(electricidad), sum(gas_natural), sum(petroleo)
    from {{ ref('electrificacion_calefaccion_provincia') }}
    where cod_prov <> '00' and cod_ccaa is not null
    group by cod_ccaa
),

en_calefaccion as (
    select 'energia_calefaccion_electrica' as ind, nivel, cod, 2021 as anio,
        100 * electricidad / viviendas as valor,
        'Viviendas con calefacción eléctrica (%)' as nombre, 'positivo' as sentido
    from calefaccion where electricidad is not null
    union all
    select 'energia_calefaccion_gas', nivel, cod, 2021, 100 * gas_natural / viviendas,
        'Viviendas con calefacción de gas natural (%)', 'neutro'
    from calefaccion where gas_natural is not null
    union all
    select 'energia_calefaccion_petroleo', nivel, cod, 2021, 100 * petroleo / viviendas,
        'Viviendas con calefacción de gasóleo u otros derivados del petróleo (%)', 'negativo'
    from calefaccion where petroleo is not null
),

-- =====================================================================
-- MOVILIDAD
-- =====================================================================
parque as (
    select mes, cod_prov, cod_ccaa, energia, distintivo, antiguedad, cast(vehiculos as double) as vehiculos
    from {{ ref('movilidad_parque_provincia') }}
    where grupo = 'turismo'
),

parque_niveles as (
    select mes, 'provincia' as nivel, cod_prov as cod,
        sum(vehiculos) as turismos,
        sum(vehiculos) filter (where energia in ('bev', 'phev')) as enchufables,
        sum(vehiculos) filter (where energia = 'bev') as bev,
        sum(vehiculos) filter (where distintivo = 'SIN') as sin_etiqueta,
        sum(vehiculos) filter (where antiguedad = '20+') as mas_20
    from parque group by all
    union all
    select mes, 'ccaa', cod_ccaa,
        sum(vehiculos),
        sum(vehiculos) filter (where energia in ('bev', 'phev')),
        sum(vehiculos) filter (where energia = 'bev'),
        sum(vehiculos) filter (where distintivo = 'SIN'),
        sum(vehiculos) filter (where antiguedad = '20+')
    from parque where cod_ccaa is not null group by all
),

parque_hab as (
    select n.*, cast(year(n.mes) as integer) as anio, p.poblacion,
        'Parque de turismos de la DGT a ' || strftime(n.mes, '%m/%Y') as nota
    from parque_niveles n
    join pob p on p.nivel = n.nivel and p.cod = n.cod
        and p.anio = least(year(n.mes), (select anio from pob_max))
    where n.turismos > 0
    qualify n.mes = max(n.mes) over (partition by year(n.mes))
),

mov_parque as (
    select 'movilidad_turismos_1000' as ind, nivel, cod, anio, 1000 * turismos / poblacion as valor,
        'Turismos por 1.000 habitantes' as nombre, 'por 1.000 hab' as unidad, 'neutro' as sentido, nota
    from parque_hab
    union all
    select 'movilidad_parque_pct_enchufables', nivel, cod, anio, 100 * coalesce(enchufables, 0) / turismos,
        'Turismos enchufables en el parque (% eléctricos e híbridos enchufables)', '%', 'positivo', nota
    from parque_hab
    union all
    select 'movilidad_parque_pct_bev', nivel, cod, anio, 100 * coalesce(bev, 0) / turismos,
        'Turismos 100 % eléctricos en el parque (%)', '%', 'positivo', nota
    from parque_hab
    union all
    select 'movilidad_parque_pct_sin_etiqueta', nivel, cod, anio, 100 * coalesce(sin_etiqueta, 0) / turismos,
        'Turismos sin etiqueta ambiental (%)', '%', 'negativo', nota
    from parque_hab
    union all
    select 'movilidad_parque_pct_mas_20', nivel, cod, anio, 100 * coalesce(mas_20, 0) / turismos,
        'Turismos con más de 20 años (%)', '%', 'negativo', nota
    from parque_hab
),

matric as (
    select mes, cod_prov, cod_ccaa, energia, canal, cast(matriculaciones as double) as matriculaciones
    from {{ ref('movilidad_matriculaciones_provincia') }}
    where nuevo_usado = 'N'
),

matric_meses as (
    select year(mes) as anio, count(distinct mes) as meses, max(mes) as ultimo_mes
    from matric group by 1
),

matric_niveles as (
    select cast(year(mes) as integer) as anio, 'provincia' as nivel, cod_prov as cod,
        sum(matriculaciones) as total,
        sum(matriculaciones) filter (where energia in ('bev', 'phev')) as enchufables,
        sum(matriculaciones) filter (where energia = 'bev') as bev,
        sum(matriculaciones) filter (where energia = 'diesel') as diesel,
        sum(matriculaciones) filter (where canal = 'particular') as part_total,
        sum(matriculaciones) filter (where canal = 'particular' and energia in ('bev', 'phev')) as part_enchufables
    from matric group by all
    union all
    select cast(year(mes) as integer), 'ccaa', cod_ccaa,
        sum(matriculaciones),
        sum(matriculaciones) filter (where energia in ('bev', 'phev')),
        sum(matriculaciones) filter (where energia = 'bev'),
        sum(matriculaciones) filter (where energia = 'diesel'),
        sum(matriculaciones) filter (where canal = 'particular'),
        sum(matriculaciones) filter (where canal = 'particular' and energia in ('bev', 'phev'))
    from matric where cod_ccaa is not null group by all
),

matric_hab as (
    select n.*, p.poblacion,
        case when m.meses < 12
             then 'Año en curso: enero-' || strftime(m.ultimo_mes, '%m/%Y') || '; turismos nuevos, provincia del titular'
             else 'Turismos nuevos, según la provincia del domicilio del titular' end as nota
    from matric_niveles n
    join matric_meses m on m.anio = n.anio
    join pob p on p.nivel = n.nivel and p.cod = n.cod
        and p.anio = least(n.anio, (select anio from pob_max))
    where n.total > 0
),

mov_matric as (
    select 'movilidad_matriculaciones_1000' as ind, nivel, cod, anio, 1000 * total / poblacion as valor,
        'Turismos nuevos matriculados por 1.000 habitantes' as nombre,
        'por 1.000 hab' as unidad, 'neutro' as sentido, nota
    from matric_hab
    union all
    select 'movilidad_matric_pct_enchufables', nivel, cod, anio, 100 * coalesce(enchufables, 0) / total,
        'Turismos nuevos enchufables (% de las matriculaciones)', '%', 'positivo', nota
    from matric_hab
    union all
    select 'movilidad_matric_pct_bev', nivel, cod, anio, 100 * coalesce(bev, 0) / total,
        'Turismos nuevos 100 % eléctricos (% de las matriculaciones)', '%', 'positivo', nota
    from matric_hab
    union all
    select 'movilidad_matric_pct_diesel', nivel, cod, anio, 100 * coalesce(diesel, 0) / total,
        'Turismos nuevos diésel (% de las matriculaciones)', '%', 'negativo', nota
    from matric_hab
    -- Solo particulares: las flotas se matriculan donde tienen sede (Madrid y municipios
    -- con el impuesto de circulación más bajo) y deforman el reparto territorial.
    union all
    select 'movilidad_matric_particulares_1000', nivel, cod, anio, 1000 * coalesce(part_total, 0) / poblacion,
        'Turismos nuevos de particulares por 1.000 habitantes', 'por 1.000 hab', 'neutro', nota
    from matric_hab
    union all
    select 'movilidad_matric_particulares_pct_enchufables', nivel, cod, anio,
        100 * coalesce(part_enchufables, 0) / part_total,
        'Turismos nuevos enchufables de particulares (% de sus matriculaciones)', '%', 'positivo', nota
    from matric_hab
    where part_total > 0
),

recarga_fecha as (
    select max(fecha) as fecha from {{ ref('movilidad_recarga_evolucion') }}
),

recarga_niveles as (
    select 'provincia' as nivel, cod_prov as cod,
        cast(puntos as double) as puntos, cast(puntos_rapidos as double) as rapidos,
        cast(turismos_enchufables as double) as enchufables
    from {{ ref('movilidad_recarga_provincia') }}
    union all
    select 'ccaa', cod_ccaa, sum(puntos), sum(puntos_rapidos), sum(turismos_enchufables)
    from {{ ref('movilidad_recarga_provincia') }}
    where cod_ccaa is not null
    group by cod_ccaa
),

recarga_hab as (
    select r.*, p.poblacion,
        cast(year(coalesce((select fecha from recarga_fecha), current_date)) as integer) as anio,
        'Puntos de acceso público en el Punto de Acceso Nacional a '
            || strftime(coalesce((select fecha from recarga_fecha), current_date), '%d/%m/%Y') as nota
    from recarga_niveles r
    join pob p on p.nivel = r.nivel and p.cod = r.cod and p.anio = (select anio from pob_max)
),

mov_recarga as (
    select 'movilidad_recarga_100k' as ind, nivel, cod, anio, 1e5 * puntos / poblacion as valor,
        'Puntos de recarga públicos por 100.000 habitantes' as nombre,
        'por 100.000 hab' as unidad, 'positivo' as sentido, nota
    from recarga_hab
    union all
    select 'movilidad_recarga_rapida_100k', nivel, cod, anio, 1e5 * coalesce(rapidos, 0) / poblacion,
        'Puntos de recarga rápida (50 kW o más) por 100.000 habitantes', 'por 100.000 hab', 'positivo', nota
    from recarga_hab
    union all
    select 'movilidad_enchufables_por_punto', nivel, cod, anio, enchufables / puntos,
        'Turismos enchufables por punto de recarga público', 'turismos por punto', 'negativo', nota
    from recarga_hab
    where puntos > 0 and enchufables is not null
),

-- =====================================================================
-- VARIOS
-- =====================================================================
obs_anios as (
    select range as anio
    from range(
        (select greatest(min(anio_creacion), (select min(anio) from pob)) from {{ ref('observatorios_detalle') }}),
        (select max(anio_creacion) from {{ ref('observatorios_detalle') }}) + 1
    )
),

obs as (
    select a.anio, t.cod,
        count(o.nombre) as observatorios
    from obs_anios a
    cross join (select cod from {{ ref('territorios') }} where nivel = 'ccaa') t
    left join {{ ref('observatorios_detalle') }} o
        on o.cod_ccaa = t.cod and o.anio_creacion <= a.anio
    group by a.anio, t.cod
),

varios_obs as (
    select 'varios_observatorios_millon' as ind, 'ccaa' as nivel, o.cod, cast(o.anio as integer) as anio,
        1e6 * o.observatorios / p.poblacion as valor
    from obs o
    join pob p on p.nivel = 'ccaa' and p.cod = o.cod
        and p.anio = least(o.anio, (select anio from pob_max))
),

-- =====================================================================
-- UNIÓN
-- =====================================================================
todo as (
    select *, 'Vivienda' as tema, 'Ministerio de Vivienda' as fuente,
        'https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000' as url_fuente,
        '/vivienda/precios/' as pagina
    from viv_precio
    union all by name
    select *, 'Vivienda' as tema, 'Ministerio de Vivienda (SERPAVI)' as fuente,
        'https://www.mivau.gob.es/vivienda/alquila-bien-es-tu-derecho/serpavi' as url_fuente,
        '/vivienda/alquiler/' as pagina
    from viv_alquiler
    union all by name
    select *, 'Vivienda' as tema, 'Ministerio de Vivienda / INE' as fuente,
        'https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000' as url_fuente,
        '/vivienda/esfuerzo/' as pagina
    from viv_esfuerzo
    union all by name
    select *, 'Vivienda' as tema, 'INE' as fuente,
        case when ind in ('vivienda_hipotecas_1000', 'vivienda_hipoteca_media')
             then 'https://www.ine.es/jaxiT3/Tabla.htm?t=13896'
             else 'https://www.ine.es/jaxiT3/Tabla.htm?t=6150' end as url_fuente,
        '/vivienda/compraventas/' as pagina
    from viv_mercado
    union all by name
    select *, 'Vivienda' as tema, 'Ministerio de Vivienda' as fuente,
        'https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=32000000' as url_fuente,
        '/vivienda/construccion/' as pagina
    from viv_obra
    union all by name
    select *, 'Vivienda' as tema, 'INE' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=39363' as url_fuente, '/economia/turismo/' as pagina
    from viv_turisticas
    union all by name
    select *, 'Cuentas públicas' as tema,
        '€/hab (€ de ' || (select anio_base from base_real) || ')' as unidad,
        'Ministerio de Hacienda' as fuente,
        'https://serviciostelematicosext.hacienda.gob.es/sgcief/publicacionliquidaciones/aspx/menuinicio.aspx' as url_fuente,
        '/territorios/' as pagina
    from cp_ccaa_cuentas
    union all by name
    select *, 'Cuentas públicas' as tema,
        case when ind = 'cuentas_ccaa_deuda_pib' then '% del PIB'
             else '€/hab (€ de ' || (select anio_base from base_real) || ')' end as unidad,
        'Banco de España' as fuente,
        'https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html' as url_fuente,
        '/territorios/' as pagina
    from cp_ccaa_deuda
    union all by name
    select * replace (coalesce(unidad, '€/hab (€ de ' || (select anio_base from base_real) || ')') as unidad),
        'Cuentas públicas' as tema, 'Banco de España' as fuente,
        'https://www.bde.es/webbe/es/estadisticas/temas/administraciones-publicas.html' as url_fuente,
        '/territorios/' as pagina
    from cp_ccaa_saldo
    union all by name
    select *, 'Cuentas públicas' as tema,
        '€/hab (€ de ' || (select anio_base from base_real) || ')' as unidad,
        'Ministerio de Hacienda' as fuente,
        'https://www.hacienda.gob.es/es-ES/CDI/Paginas/SistemasFinanciacionDeuda/InformacionEELLs/DeudaViva.aspx' as url_fuente,
        '/territorios/' as pagina
    from cp_deuda_local
    union all by name
    select *, 'Cuentas públicas' as tema, 'Registro Central de Personal' as fuente,
        'https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html' as url_fuente,
        '/cuentas-publicas/empleo-publico/' as pagina
    from cp_empleo
    union all by name
    select *, 'Cuentas públicas' as tema,
        '€/hab (€ de ' || (select anio_base from base_real) || ')' as unidad,
        case when ind = 'empleo_gasto_personal_aytos_hab' then 'Ministerio de Hacienda (CONPREL)'
             else 'Ministerio de Hacienda' end as fuente,
        case when ind = 'empleo_gasto_personal_aytos_hab'
             then 'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL'
             else 'https://serviciostelematicosext.hacienda.gob.es/sgcief/publicacionliquidaciones/aspx/menuinicio.aspx' end as url_fuente,
        '/cuentas-publicas/empleo-publico/' as pagina
    from cp_gasto_personal
    union all by name
    select *, 'Cuentas públicas' as tema, 'INE (EPA)' as fuente,
        'https://www.ine.es/jaxiT3/Tabla.htm?t=65193' as url_fuente,
        '/cuentas-publicas/empleo-publico/' as pagina
    from cp_epa
    union all by name
    select *, 'Cuentas públicas' as tema,
        case when ind = 'empleo_salario_publico'
             then '€ al año (€ de ' || (select anio_base from base_real) || ')' else '%' end as unidad,
        'INE' as fuente, 'https://www.ine.es/jaxiT3/Tabla.htm?t=36887' as url_fuente,
        '/cuentas-publicas/empleo-publico/' as pagina
    from cp_salarios
    union all by name
    select *, 'Transparencia' as tema,
        'Ayuntamientos que no remitieron a Hacienda la liquidación del presupuesto (%)' as nombre,
        '%' as unidad, 'negativo' as sentido, 'Ministerio de Hacienda' as fuente,
        'https://serviciostelematicosext.hacienda.gob.es/sgcief/publicacionliquidaciones/aspx/menuinicio.aspx' as url_fuente,
        '/transparencia/' as pagina,
        'Ejercicio liquidado; plazo: 31 de marzo del año siguiente. Sin País Vasco ni Navarra (régimen foral)' as nota
    from tr_liquidaciones
    union all by name
    select *, 'Transparencia' as tema,
        case when ind = 'transparencia_pmp_mediano' then 'días' else '%' end as unidad,
        'negativo' as sentido, 'Ministerio de Hacienda' as fuente,
        'https://serviciostelematicosext.hacienda.gob.es/sgcief/pmp_net/' as url_fuente,
        '/transparencia/' as pagina
    from tr_pmp
    union all by name
    select * exclude (completa), 'Transparencia' as tema,
        'Ayuntamientos con retención de la participación en los tributos del Estado por no remitir la liquidación (%)' as nombre,
        '%' as unidad, 'negativo' as sentido, 'Ministerio de Hacienda' as fuente,
        'https://www.hacienda.gob.es/es-ES/Areas%20Tematicas/Administracion%20Electronica/OVEELL/Paginas/Noticias.aspx' as url_fuente,
        '/transparencia/' as pagina,
        case when completa then 'Retención en la campaña de ese ejercicio. Sin País Vasco ni Navarra (régimen foral)'
             else 'Campaña incompleta en los datos. Sin País Vasco ni Navarra (régimen foral)' end as nota
    from tr_pie
    union all by name
    select *, 'Energía y clima' as tema, 'Global Energy Monitor' as fuente,
        'https://globalenergymonitor.org/projects/global-integrated-power-tracker/' as url_fuente,
        '/energia-clima/centrales/' as pagina
    from en_centrales
    union all by name
    select *, 'Energía y clima' as tema,
        'Superficie quemada (% de la superficie del territorio)' as nombre,
        '%' as unidad, 'negativo' as sentido, 'Copernicus EFFIS' as fuente,
        'https://forest-fire.emergency.copernicus.eu/' as url_fuente,
        '/energia-clima/incendios/' as pagina,
        'Incendios cartografiados por satélite (sobre todo de 30 ha o más); 0 si no hubo ninguno' as nota
    from en_incendios
    union all by name
    select *, 'Energía y clima' as tema, 'AEMET' as fuente,
        'https://opendata.aemet.es/' as url_fuente, '/energia-clima/calor/' as pagina
    from en_calor
    union all by name
    select *, 'Energía y clima' as tema, '%' as unidad, 'INE (ECEPOV 2021)' as fuente,
        'https://www.ine.es/jaxi/Tabla.htm?tpx=56784' as url_fuente,
        '/energia-clima/electrificacion/' as pagina,
        'Viviendas principales con calefacción según el combustible; encuesta muestral de 2021' as nota
    from en_calefaccion
    union all by name
    select *, 'Movilidad' as tema, 'DGT' as fuente,
        'https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/parque-vehiculos-mensual.html' as url_fuente,
        '/movilidad/parque/' as pagina
    from mov_parque
    union all by name
    select *, 'Movilidad' as tema, 'DGT' as fuente,
        'https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html' as url_fuente,
        '/movilidad/coche-electrico/' as pagina
    from mov_matric
    union all by name
    select *, 'Movilidad' as tema, 'MITECO / DGT (NAP)' as fuente,
        'https://nap.dgt.es/dataset/puntos-de-recarga-electrica-para-vehiculos' as url_fuente,
        '/movilidad/recarga/' as pagina
    from mov_recarga
    union all by name
    select *, 'Varios' as tema, 'Observatorios públicos por millón de habitantes' as nombre,
        'por millón de hab' as unidad, 'neutro' as sentido, 'ObservatoriosPublicos.es' as fuente,
        'https://observatoriospublicos.es/' as url_fuente, '/varios/observatorios/' as pagina,
        'Acumulado de los creados hasta ese año (activos o no) con sede en la comunidad; sin los estatales' as nota
    from varios_obs
)

select
    x.ind || case x.nivel when 'ccaa' then '_ccaa' else '_prov' end as indicador_id,
    x.nombre,
    x.tema,
    case x.nivel when 'ccaa' then 'Comunidad' else 'Provincia' end as nivel,
    x.cod,
    t.nombre as territorio,
    cast(x.anio as integer) as anio,
    cast(x.valor as double) as valor,
    x.unidad,
    x.sentido,
    x.fuente,
    x.url_fuente,
    x.pagina,
    x.nota
from todo x
join {{ ref('territorios') }} t on t.nivel = x.nivel and t.cod = x.cod
where x.valor is not null
    and isfinite(x.valor)
    and x.cod is not null
    and x.cod <> '00'
    and x.nivel in ('ccaa', 'provincia')
