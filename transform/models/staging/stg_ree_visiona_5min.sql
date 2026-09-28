-- Curva de 5 minutos del visor de REE con los campos originales traducidos a
-- tecnologías homogéneas entre sistemas y épocas (tabla de equivalencias en
-- models/marts/electricidad_5min.sql) y las emisiones de CO2.
--
-- Balance que cierra la península (comprobado sobre los datos, error medio ~40 MW):
--   dem = eol + nuc + gf + car + cc + vap + hid + aut + sol_fot + sol_ter
--         + bat + cons_bat + inter + icb
-- donde:
--   * hid es TODA la hidráulica neta: gnhd (hidráulica convencional) + turbinación
--     de bombeo + conb (consumo de bombeo, negativo). El campo `turb` del visor se
--     queda corto: hid - gnhd - conb tiene el perfil de la turbinación (máximo a las
--     21 h) y es ~500 MW mayor que `turb`, así que la turbinación se toma de ahí.
--   * aut ("Resto régimen especial") = bio + cogenResto + un resto sin desglosar
--     (~50-250 MW, con perfil anti-solar: cogeneración/residuos que bajan a mediodía)
--     desde abril de 2026 y antes de 2018. Entre 2018 y marzo de 2026 aut es 0 o no
--     cuadra y se usa cogenResto; en esos años queda un residuo de balance de ~200-400 MW
--     que REE no desglosa (ese "resto"), así que generación + saldo < demanda por ese margen.
--   * AUTOCONSUMO: la curva DEMANDAAU incluye una estimación del autoconsumo fotovoltaico
--     tanto en `dem` como en `sol_fot` (desde ~2025). `sol` es la solar SIN autoconsumo,
--     así que autoconsumo = sol_fot + sol_ter - sol. Para que la serie sea homogénea y
--     comparable con las estadísticas oficiales de REE (demanda b.c., que no incluye el
--     autoconsumo), se resta de la demanda y de la solar FV. Comprobado: la demanda
--     resultante reproduce la potencia máxima instantánea oficial de REE.
-- Andorra va al revés en REE: `impAnd` es lo que SALE hacia Andorra y `expAnd` lo que
-- entra (inter ≈ suma por fronteras con error medio < 10 MW solo si se invierte).
with k as (
    -- factores de emisión del visor (t CO2/MWh), propios de cada sistema
    select
        sistema,
        max(case when tecnologia = 'car' then t_co2_mwh end) as f_car,
        max(case when tecnologia = 'cc' then t_co2_mwh end) as f_cc,
        max(case when tecnologia = 'gf' then t_co2_mwh end) as f_gf,
        max(case when tecnologia = 'vap' then t_co2_mwh end) as f_vap,
        max(case when tecnologia = 'cogenResto' then t_co2_mwh end) as f_cogen_resto,
        max(case when tecnologia = 'aut' then t_co2_mwh end) as f_aut,
        max(case when tecnologia = 'cogen' then t_co2_mwh end) as f_cogen,
        max(case when tecnologia = 'tnr' then t_co2_mwh end) as f_tnr,
        max(case when tecnologia = 'resid' then t_co2_mwh end) as f_resid,
        max(case when tecnologia = 'residNr' then t_co2_mwh end) as f_resid_nr,
        max(case when tecnologia = 'genAux' then t_co2_mwh end) as f_gen_aux,
        max(case when tecnologia = 'die' then t_co2_mwh end) as f_die,
        max(case when tecnologia = 'gas' then t_co2_mwh end) as f_gas
    from {{ source('raw_ree_visiona', 'ree_coeficientes_co2') }}
    group by sistema
),

r as (
    select
        sistema, ts_utc, ts_local, dem,
        coalesce(eol, 0) as eol, coalesce(nuc, 0) as nuc, coalesce(gf, 0) as gf, coalesce(car, 0) as car,
        coalesce(cc, 0) as cc, coalesce(vap, 0) as vap, coalesce(hid, 0) as hid, coalesce(gnhd, 0) as gnhd,
        coalesce(turb, 0) as turb, coalesce(conb, 0) as conb, coalesce(aut, 0) as aut, coalesce(bio, 0) as bio,
        coalesce(cogen_resto, 0) as cogen_resto, coalesce(sol, 0) as sol, coalesce(sol_fot, 0) as sol_fot,
        coalesce(sol_ter, 0) as sol_ter, coalesce(bat, 0) as bat, coalesce(cons_bat, 0) as cons_bat,
        coalesce(inter, 0) as inter, coalesce(icb, 0) as icb,
        imp_fra, exp_fra, imp_por, exp_por, imp_mar, exp_mar, imp_and, exp_and,
        coalesce(imp_tot, 0) as imp_tot, coalesce(exp_tot, 0) as exp_tot,
        coalesce(die, 0) as die, coalesce(gas, 0) as gas, coalesce(cb, 0) as cb, coalesce(fot, 0) as fot,
        coalesce(tnr, 0) as tnr, coalesce(trn, 0) as trn, coalesce(otr_ren, 0) as otr_ren,
        coalesce(resid, 0) as resid, coalesce(gen_aux, 0) as gen_aux, coalesce(cogen, 0) as cogen,
        coalesce(resid_nr, 0) as resid_nr, coalesce(resid_ren, 0) as resid_ren,
        -- desglose de bombeo disponible (península ~2022+, Canarias)
        (coalesce(gnhd, 0) <> 0 or coalesce(conb, 0) <> 0 or coalesce(turb, 0) <> 0) as hay_bombeo,
        -- desglose solar disponible (península 2016+)
        (coalesce(sol_fot, 0) <> 0 or coalesce(sol_ter, 0) <> 0) as hay_solar,
        -- desglose por frontera disponible (península, finales de 2024+) y coherente con
        -- el saldo total: algunos días (p. ej. 18/09/2024) el visor repite un mismo valor
        -- en todas las fronteras; esos instantes se dejan en null (la tabla horaria los
        -- completa con ESIOS)
        (coalesce(imp_tot, 0) <> 0 or coalesce(exp_tot, 0) <> 0)
        and abs(
            coalesce(inter, 0)
            - (abs(coalesce(imp_fra, 0)) + abs(coalesce(imp_por, 0)) + abs(coalesce(imp_mar, 0)) + abs(coalesce(exp_and, 0))
               - abs(coalesce(exp_fra, 0)) - abs(coalesce(exp_por, 0)) - abs(coalesce(exp_mar, 0)) - abs(coalesce(imp_and, 0)))
        ) <= 300
        and not (coalesce(imp_fra, 0) <> 0 and imp_fra = imp_por and imp_por = imp_mar) as hay_fronteras
    from {{ source('raw_ree_visiona', 'ree_visiona_5min') }}
    where dem is not null
),

m as (
    select
        r.*,
        -- turbinación neta de bombeo (hid - gnhd - conb), repartida en turbinación
        -- (>= 0) y consumo extra si sale negativa, para que el balance siga cuadrando
        hid - gnhd - conb as bombeo_turb_neto,
        -- aut solo se usa cuando de verdad contiene bio + cogenResto (2012-2018 y abril de
        -- 2026 en adelante); en 2025 el visor rellena aut con otra cosa que no cuadra
        case when sistema = 'peninsula' and aut > 0 and aut >= 0.95 * (bio + cogen_resto) then aut - bio else cogen_resto end as cogen_pen,
        -- autoconsumo FV estimado por REE (solo península, ver cabecera)
        case when sistema = 'peninsula' and hay_solar and sol > 0 then greatest(sol_fot + sol_ter - sol, 0) else 0 end as autoconsumo
    from r
)

select
    m.sistema,
    m.ts_utc,
    m.ts_local,
    m.dem - autoconsumo as demanda_mw,
    m.eol as eolica,
    case m.sistema when 'peninsula' then case when hay_solar then sol_fot - autoconsumo else sol end else fot end as solar_fv,
    case m.sistema when 'peninsula' then case when hay_solar then sol_ter else 0 end when 'baleares' then trn else 0 end as solar_termica,
    case
        when m.sistema = 'baleares' then 0
        when hay_bombeo then gnhd
        else hid  -- sin desglose: hidráulica neta de bombeo
    end as hidraulica,
    case
        when m.sistema = 'baleares' or not hay_bombeo then null
        else greatest(bombeo_turb_neto, 0)
    end as turbinacion_bombeo,
    case
        when m.sistema = 'baleares' or not hay_bombeo then null
        else -conb + greatest(-bombeo_turb_neto, 0)
    end as consumo_bombeo,
    case when m.sistema = 'peninsula' then nuc else 0 end as nuclear,
    car as carbon,
    cc as ciclo_combinado,
    case m.sistema
        when 'peninsula' then cogen_pen
        when 'baleares' then cogen + resid_nr + resid
        else 0
    end as cogeneracion_residuos,
    case when m.sistema = 'peninsula' then bat else 0 end as baterias_descarga,
    case when m.sistema = 'peninsula' then -least(cons_bat, 0) else 0 end as baterias_carga,
    case when m.sistema = 'peninsula' then 0 else die end as diesel,
    case when m.sistema = 'peninsula' then 0 else gas end as turbina_gas,
    vap as motores_vapor,
    case m.sistema
        when 'peninsula' then bio
        when 'baleares' then otr_ren + resid_ren
        else 0
    end as otras_renovables,
    case m.sistema
        when 'peninsula' then gf
        when 'baleares' then tnr + gen_aux
        else 0
    end as otras_no_renovables,
    case when m.sistema = 'peninsula' then inter end as intercambio_neto,
    case when m.sistema = 'peninsula' and hay_fronteras then abs(coalesce(imp_fra, 0)) end as imp_francia,
    case when m.sistema = 'peninsula' and hay_fronteras then abs(coalesce(exp_fra, 0)) end as exp_francia,
    case when m.sistema = 'peninsula' and hay_fronteras then abs(coalesce(imp_por, 0)) end as imp_portugal,
    case when m.sistema = 'peninsula' and hay_fronteras then abs(coalesce(exp_por, 0)) end as exp_portugal,
    case when m.sistema = 'peninsula' and hay_fronteras then abs(coalesce(imp_mar, 0)) end as imp_marruecos,
    case when m.sistema = 'peninsula' and hay_fronteras then abs(coalesce(exp_mar, 0)) end as exp_marruecos,
    -- Andorra invertida (ver cabecera)
    case when m.sistema = 'peninsula' and hay_fronteras then abs(coalesce(exp_and, 0)) end as imp_andorra,
    case when m.sistema = 'peninsula' and hay_fronteras then abs(coalesce(imp_and, 0)) end as exp_andorra,
    -- enlace Península-Baleares, + = hacia Baleares (icb es negativo cuando sale de la península)
    case m.sistema when 'peninsula' then -icb when 'baleares' then cb end as enlace_baleares,
    autoconsumo as autoconsumo_fv_mw,
    -- emisiones (t CO2/h): campos originales x factores del propio sistema
    car * coalesce(f_car, 0)
    + cc * coalesce(f_cc, 0)
    + vap * coalesce(f_vap, 0)
    + gf * coalesce(f_gf, 0)
    + die * coalesce(f_die, 0)
    + gas * coalesce(f_gas, 0)
    + gen_aux * coalesce(f_gen_aux, 0)
    + cogen * coalesce(f_cogen, 0)
    + tnr * coalesce(f_tnr, 0)
    + resid * coalesce(f_resid, 0)
    + resid_nr * coalesce(f_resid_nr, 0)
    + case when m.sistema = 'peninsula'
           then cogen_pen * coalesce(case when bio = 0 and cogen_resto = 0 then f_aut else f_cogen_resto end, 0)
           else 0 end as co2_t_h
from m
left join k on k.sistema = m.sistema
