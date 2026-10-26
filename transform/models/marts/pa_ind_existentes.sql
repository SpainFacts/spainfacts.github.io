-- Índice propio de publicidad activa: los indicadores de remisión que SpainFacts ya
-- medía (página /transparencia/cuentas-municipales), en el formato común de los
-- modelos pa_ind_* (ver docs/elaboracion-propia/indice.md). Solo ayuntamientos.
--
--   liquidacion_hacienda   liquidación del presupuesto en CONPREL (art. 15.3 Orden HAP/2105/2012,
--                          plazo 31-mar del año siguiente). Dato binario: consta o no consta,
--                          sin fecha de remisión.
--   presupuesto_hacienda   presupuesto del ejercicio remitido a Hacienda: retención de la PIE por
--                          no remitirlo antes del 1 de julio (DA 87ª Ley 22/2021). No retenido =
--                          en plazo; retenido y regularizado después = fuera de plazo; sigue
--                          retenido = no consta.
--   lineas_fundamentales   líneas fundamentales del presupuesto (anio = ejercicio del
--                          presupuesto; plazo 15-sep del año anterior), mismo criterio.
--   pmp_comunicacion       periodo medio de pago comunicado a Hacienda cada trimestre (RD 635/2014):
--                          n_total = trimestres del año, n_fuera_plazo = trimestres sin comunicar.
--   cuenta_general_tcu     Cuenta General rendida al Tribunal de Cuentas (arts. 212.5 y 223.2
--                          TRLRHL, plazo 15-oct del año siguiente), con fecha de envío.
--   control_interno_tcu    información de control interno (art. 218.3 TRLRHL, 30-abr).
--   contratos_tcu          relación anual de contratos (art. 335 LCSP, fin de febrero).
--
-- La retención de la PIE por la liquidación no se incluye: es una consecuencia de la
-- misma obligación que liquidacion_hacienda y la contaría dos veces.

with liquidacion as (
    select
        'liquidacion_hacienda' as obligacion,
        'Liquidación del presupuesto remitida a Hacienda' as obligacion_nombre,
        'art. 15.3 Orden HAP/2105/2012; art. 193.5 TRLRHL' as base_legal,
        cod_mun, cod_prov, cod_ccaa, municipio as nombre_entidad,
        cast(anio as varchar) as periodo,
        cast(anio as integer) as anio,
        fecha_plazo,
        case when not aplica_indicador then 'no_aplica'
             when remitida then 'consta'
             else 'no_consta' end as estado,
        cast(null as integer) as dias_retraso,
        cast(null as integer) as n_total,
        cast(null as integer) as n_fuera_plazo,
        cast(null as double) as mediana_dias,
        aplica_indicador,
        motivo_exclusion as motivo_no_aplica,
        cast(poblacion as integer) as poblacion,
        'https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL' as url_fuente
    from {{ ref('transparencia_liquidaciones') }}
),

pie as (
    select
        case seccion when 'presupuesto' then 'presupuesto_hacienda' else 'lineas_fundamentales' end as obligacion,
        case seccion when 'presupuesto' then 'Presupuesto del año remitido a Hacienda'
             else 'Líneas fundamentales del presupuesto remitidas a Hacienda' end as obligacion_nombre,
        case seccion when 'presupuesto' then 'DA 87ª Ley 22/2021 (retención si no se remite antes del 1 de julio); art. 15.2 Orden HAP/2105/2012'
             else 'DA 87ª Ley 22/2021 (antes del 15 de septiembre); art. 15.1 Orden HAP/2105/2012' end as base_legal,
        cod_mun, cod_prov, cod_ccaa, municipio as nombre_entidad,
        cast(anio as varchar) as periodo,
        cast(anio as integer) as anio,
        case seccion when 'presupuesto' then make_date(cast(anio as integer), 7, 1)
             else make_date(cast(anio as integer) - 1, 9, 15) end as fecha_plazo,
        case when not aplica_indicador then 'no_aplica'
             when not campania_completa then 'no_aplica'
             when not retenido then 'en_plazo'
             when sigue_retenido then 'no_consta'
             else 'fuera_plazo' end as estado,
        -- aproximación: la retención es mensual; meses retenido x 30
        case when retenido and not sigue_retenido then cast(meses_retenido * 30 as integer) end as dias_retraso,
        cast(null as integer) as n_total,
        cast(null as integer) as n_fuera_plazo,
        cast(null as double) as mediana_dias,
        aplica_indicador and campania_completa as aplica_indicador,
        coalesce(motivo_exclusion, case when not campania_completa then 'Campaña de retenciones incompleta al inicio de la serie' end) as motivo_no_aplica,
        cast(poblacion as integer) as poblacion,
        'https://www.hacienda.gob.es/es-ES/CDI/Paginas/OVEELL/OVEELL.aspx' as url_fuente
    from {{ ref('transparencia_pie') }}
    where seccion in ('presupuesto', 'lineas_fundamentales')
),

pmp as (
    select
        'pmp_comunicacion' as obligacion,
        'Periodo medio de pago comunicado a Hacienda cada trimestre' as obligacion_nombre,
        'RD 635/2014 (mod. RD 1040/2017); art. 16.8 Orden HAP/2105/2012' as base_legal,
        cod_mun, any_value(cod_prov) as cod_prov, any_value(cod_ccaa) as cod_ccaa, any_value(municipio) as nombre_entidad,
        cast(anio as varchar) as periodo,
        cast(anio as integer) as anio,
        max(fecha_plazo) as fecha_plazo,
        case when not bool_and(aplica_indicador) then 'no_aplica'
             when count(*) < 4 then 'no_vencido'
             else 'con_registros' end as estado,
        cast(null as integer) as dias_retraso,
        cast(count(*) as integer) as n_total,
        cast(count(*) filter (where not reporta) as integer) as n_fuera_plazo,
        cast(null as double) as mediana_dias,
        bool_and(aplica_indicador) as aplica_indicador,
        any_value(motivo_exclusion) as motivo_no_aplica,
        cast(max(poblacion) as integer) as poblacion,
        'https://www.hacienda.gob.es/es-ES/CDI/Paginas/PeriodoMedioPago/PMP.aspx' as url_fuente
    from {{ ref('transparencia_pmp') }}
    group by cod_mun, anio
),

tcu as (
    select
        obligacion || '_tcu' as obligacion,
        case obligacion
            when 'cuenta_general' then 'Cuenta General rendida al Tribunal de Cuentas'
            when 'control_interno' then 'Control interno remitido al Tribunal de Cuentas'
            else 'Relación anual de contratos remitida al Tribunal de Cuentas' end as obligacion_nombre,
        case obligacion
            when 'cuenta_general' then 'arts. 212.5 y 223.2 TRLRHL (RDLeg 2/2004)'
            when 'control_interno' then 'art. 218.3 TRLRHL; Instrucción TCu 19/12/2019'
            else 'art. 335 LCSP; Instrucción TCu 28/06/2018' end as base_legal,
        cod_mun, cod_prov, cod_ccaa, municipio as nombre_entidad,
        cast(anio as varchar) as periodo,
        cast(anio as integer) as anio,
        fecha_limite as fecha_plazo,
        case when not aplica_indicador or estado = 'no_aplica' then 'no_aplica'
             when estado = 'no_rendida' then 'no_consta'
             when estado = 'rendida_sin_fecha' then 'consta'
             else estado end as estado,
        cast(dias_retraso as integer) as dias_retraso,
        cast(null as integer) as n_total,
        cast(null as integer) as n_fuera_plazo,
        cast(null as double) as mediana_dias,
        aplica_indicador and estado <> 'no_aplica' as aplica_indicador,
        case when not aplica_indicador then 'País Vasco y Navarra rinden a su propio órgano de control' end as motivo_no_aplica,
        cast(poblacion as integer) as poblacion,
        'https://www.rendiciondecuentas.es/es/consultadeentidadesycuentas/' as url_fuente
    from {{ ref('transparencia_tcu') }}
    where cod_mun is not null
),

unido as (
    select * from liquidacion
    union all select * from pie
    union all select * from pmp
    union all select * from tcu
)

select
    obligacion, obligacion_nombre, base_legal,
    'Ayuntamiento' as tipo_entidad,
    cod_mun as cod_entidad,
    nombre_entidad,
    cod_mun, cod_prov, cod_ccaa,
    periodo, anio, fecha_plazo, estado, dias_retraso, n_total, n_fuera_plazo, mediana_dias,
    aplica_indicador, motivo_no_aplica, poblacion, url_fuente,
    obligacion || '|' || cod_mun || '|' || periodo as clave
from unido
