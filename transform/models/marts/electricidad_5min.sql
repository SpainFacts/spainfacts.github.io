{{ config(materialized='table') }}
-- Demanda y generación por tecnología cada 5 minutos (MW) en la península,
-- Baleares y Canarias, del visor de demanda de REE (demanda.ree.es).
-- CONTRATO: el snapshot en directo (workers/ y el componente del directo)
-- depende de estas columnas y nombres; no renombrar sin avisar.
--
-- Convenciones de signo: todas las columnas de tecnología son MW >= 0 salvo
--   intercambio_neto  (+ = importación neta de la península, - = exportación)
--   enlace_baleares   (+ = de la península hacia Baleares)
--   hidraulica        (antes del desglose de bombeo, ~2022, es la hidráulica NETA
--                      de REE y puede ser negativa de noche por el bombeo)
-- Los consumos (consumo_bombeo, baterias_carga) y las exportaciones por frontera
-- se dan en positivo.
--
-- Equivalencias con los campos del visor (península | Baleares | Canarias):
--   demanda_mw             dem | dem | dem
--   eolica                 eol | eol | eol
--   solar_fv               solFot (antes de 2016: sol, toda la solar) | fot | fot
--   solar_termica          solTer | trn | -
--   hidraulica             gnhd si hay desglose de bombeo; si no hid (neta) | - | ídem península
--   turbinacion_bombeo     max(hid - gnhd - conb, 0) cuando hay desglose (el campo turb
--                          del visor se queda corto; ver stg_ree_visiona_5min) | - | ídem
--   consumo_bombeo         -conb + max(-(hid - gnhd - conb), 0) | - | ídem
--   nuclear                nuc | - | -
--   carbon                 car | car | -
--   ciclo_combinado        cc | cc | cc
--   cogeneracion_residuos  aut - bio cuando aut >= bio + cogenResto ("resto régimen especial" =
--                          bio + cogenResto + resto sin desglosar: <2018 y abr-2026+); si no,
--                          cogenResto | cogen + residNr + resid | -
--   baterias_descarga      bat | - | -
--   baterias_carga         -consBat | - | -
--   diesel                 - | die | die
--   turbina_gas            - | gas | gas
--   motores_vapor          vap (turbina de vapor) | - | vap
--   otras_renovables       bio (biocombustibles/biomasa) | otrRen + residRen | -
--   otras_no_renovables    gf (fuel/gas) | tnr + genAux | -
--   intercambio_neto       inter | - | -
--   imp_/exp_<país>        impFra/expFra, impPor/expPor, impMar/expMar y, INVERTIDO, expAnd/impAnd
--                          (REE publica Andorra al revés); solo desde finales de 2024, antes null
--   enlace_baleares        -icb | cb | -
--
-- Renovable (criterio de REE en su visor y en sus estadísticas): eólica, solar FV,
-- solar térmica, hidráulica (sin bombeo), otras renovables (biomasa/biocombustibles,
-- residuos renovables). La turbinación de bombeo NO es renovable (es energía
-- almacenada) ni tampoco las baterías.
-- generacion_total_mw = suma de todas las tecnologías de generación (incluidas
-- turbinación y descarga de baterías), sin intercambios ni consumos de bombeo/baterías.
-- pct_renovable = renovable_mw / generacion_total_mw * 100.
-- Con estas equivalencias el balance cierra (error medio < 25 MW en la península salvo
-- 2018-mar 2026, con un resto no desglosado de ~200-400 MW):
--   demanda_mw ≈ generacion_total_mw + intercambio_neto - enlace_baleares
--                - consumo_bombeo - baterias_carga            (península)
--   demanda_mw ≈ generacion_total_mw + enlace_baleares       (Baleares)
-- co2_t_h: emisiones con los factores del visor de CADA sistema (coeficientesCO2, t CO2/MWh);
-- intensidad_gco2_kwh = co2_t_h / generacion_total_mw * 1000.
with b as (
    select
        *,
        eolica + solar_fv + solar_termica + hidraulica + nuclear + carbon + ciclo_combinado
            + cogeneracion_residuos + coalesce(turbinacion_bombeo, 0) + baterias_descarga
            + diesel + turbina_gas + motores_vapor + otras_renovables + otras_no_renovables as generacion_total_mw,
        eolica + solar_fv + solar_termica + hidraulica + otras_renovables as renovable_mw
    from {{ ref('stg_ree_visiona_5min') }}
)

select
    sistema,
    ts_utc,
    ts_local,
    demanda_mw,
    eolica,
    solar_fv,
    solar_termica,
    hidraulica,
    nuclear,
    carbon,
    ciclo_combinado,
    cogeneracion_residuos,
    turbinacion_bombeo,
    consumo_bombeo,
    baterias_descarga,
    baterias_carga,
    diesel,
    turbina_gas,
    motores_vapor,
    otras_renovables,
    otras_no_renovables,
    intercambio_neto,
    imp_francia,
    exp_francia,
    imp_portugal,
    exp_portugal,
    imp_marruecos,
    exp_marruecos,
    imp_andorra,
    exp_andorra,
    enlace_baleares,
    generacion_total_mw,
    renovable_mw,
    case when generacion_total_mw > 0 then least(greatest(100 * renovable_mw / generacion_total_mw, 0), 100) end as pct_renovable,
    co2_t_h,
    case when generacion_total_mw > 0 then 1000 * co2_t_h / generacion_total_mw end as intensidad_gco2_kwh
from b
