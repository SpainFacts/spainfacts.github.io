-- Índice propio de publicidad activa: ley de presupuestos de cada comunidad
-- autónoma aprobada antes del 1 de enero del ejercicio. Ver
-- docs/elaboracion-propia/ley_presupuestos_ccaa.md.
--
-- Fuente: sumarios del BOE, sección I, leyes de los departamentos autonómicos
-- (raw.boe_leyes_ccaa). Es «ley de presupuestos del ejercicio» la que en su título
-- es «Ley [Foral] N/AAAA, de D de MES, de/del/por la que se aprueban [los] Presupuesto(s)
-- [Generales] ... para [el] [año|ejercicio] AAAA» y no es una modificación, un
-- crédito extraordinario o una ley de medidas.
-- Fecha que cuenta: la de la ley (fecha_disposicion del BOE = fecha de sanción y
-- promulgación que figura en el título). Es la más cercana a la aprobación que
-- exigen los estatutos («si la ley de presupuestos no se aprobara antes del
-- primer día del ejercicio... se considerarán automáticamente prorrogados») y es
-- igual en todas las comunidades. La publicación en el diario autonómico (días
-- después) va en x_fecha_publicacion_diario; la del BOE (semanas después) no se usa.
--   en_plazo     ley fechada antes del 1 de enero del ejercicio (dias_retraso = 0)
--   fuera_plazo  ley fechada el 1 de enero o después (dias_retraso = fecha − 1 de enero)
--   no_consta    sin ley de presupuestos del ejercicio: presupuesto prorrogado, con la
--                prórroga comprobada en una fuente oficial (prorrogas_verificadas)
--   no_vencido   ejercicios futuros cuyo plazo (31-dic) aún no ha pasado
--   no_aplica    Ceuta y Melilla: su presupuesto lo aprueba el Pleno de la Asamblea,
--                no es una ley; y ejercicios vencidos sin ley en el BOE cuya prórroga
--                aún no se ha comprobado (el BOE no republica todas las leyes
--                autonómicas: faltan, p. ej., Cataluña 2017 y Murcia 2001-2005, que se
--                añaden a mano en leyes_manual)
-- Ejercicios desde 2000 (sumarios leídos desde el 1-sep-1999).

with leyes as (
    select
        identificador,
        cod_ccaa,
        titulo,
        cast(fecha_publicacion_boe as date) as fecha_publicacion_boe,
        cast(fecha_disposicion as date) as fecha_disposicion,
        cast(fecha_publicacion_diario as date) as fecha_publicacion_diario,
        diario_autonomico,
        numero_oficial,
        url_html,
        -- ejercicio: el año del título («para el año 2025»). Si el título no lo dice
        -- (Cantabria, Ley 8/2001 «de Presupuestos Generales de la Comunidad Autónoma
        -- de Cantabria.»), el año siguiente si la ley es de octubre a diciembre y el
        -- mismo si es de enero a septiembre.
        coalesce(
            try_cast(nullif(regexp_extract(titulo,
                '(?i)\bpara\s+(?:el\s+|los\s+)?(?:año\s+|ejercicio\s+|ejercicios\s+)?(?:del\s+año\s+|económico\s+)?(\d{4})\b', 1), '') as integer),
            cast(extract(year from cast(fecha_disposicion as date)) as integer)
                + case when extract(month from cast(fecha_disposicion as date)) >= 10 then 1 else 0 end
        ) as ejercicio
    from {{ source('raw_pa_registros', 'boe_leyes_ccaa') }}
    where regexp_matches(titulo,
            '(?i)^Ley(?:\s+Foral)?(?:\s+del?\s+[^0-9,]{3,60}?)?\s+\d+/\d{4},\s+(?:de\s+)?\d{1,2}\s+de\s+\w+,?\s+(?:de|del|por\s+la\s+que\s+se\s+aprueba[n]?)\s+(?:los\s+|el\s+)?presupuestos?\s')
      and not regexp_matches(titulo, '(?i)modifica|cr[ée]dito|suplemento|medidas|acompañamiento|prórroga|prorroga|liquidaci|organismo|ente\s+p[úu]blico|radio')
),


-- Leyes de presupuestos que el BOE no republicó en la sección I, comprobadas a mano
-- en el diario autonómico (25-oct-2026). fecha_publicacion_diario nula si no se ha
-- podido confirmar.
leyes_manual (cod_ccaa, ejercicio, numero_oficial, fecha_disposicion, diario_autonomico, fecha_publicacion_diario, url_html) as (
    values
        ('02', 2006, '12/2005', date '2005-12-30', 'Boletín Oficial de Aragón', date '2005-12-31', 'https://www.boe.es/buscar/doc.php?lang=es&id=BOA-d-2005-90008'),
        ('09', 2017, '4/2017', date '2017-03-28', 'Diari Oficial de la Generalitat de Catalunya', date '2017-03-30', 'https://www.boe.es/ccaa/dogc/2017/7340/f00001-00134.pdf'),
        ('09', 2026, '10/2026', date '2026-07-09', 'Diari Oficial de la Generalitat de Catalunya', cast(null as date), 'https://www.parlament.cat/web/actualitat/noticies/index.html?p_id=383442160'),
        ('14', 2001, '6/2000', date '2000-12-29', 'Boletín Oficial de la Región de Murcia', date '2000-12-30', 'https://www.carm.es/chac/interleg/ley06-00.pdf'),
        ('14', 2002, '8/2001', date '2001-12-21', 'Boletín Oficial de la Región de Murcia', cast(null as date), 'https://www.carm.es/chac/igmu/Pptos2002Art.pdf'),
        ('14', 2003, '14/2002', date '2002-12-23', 'Boletín Oficial de la Región de Murcia', date '2002-12-31', 'https://www.carm.es/chac/interleg/ley14-02.pdf'),
        ('14', 2005, '10/2004', date '2004-12-29', 'Boletín Oficial de la Región de Murcia', date '2004-12-31', 'https://www.carm.es/chac/igmu/Pptos2005LeyToda.pdf')
),

-- Ejercicios sin ley de presupuestos cuya prórroga está comprobada en una fuente
-- oficial (norma de prórroga en el diario autonómico, preámbulo de una ley posterior,
-- Tribunal Constitucional u órgano de control externo), revisados el 25-oct-2026.
-- Un ejercicio vencido sin ley que no figure aquí queda pendiente de comprobar
-- (aplica_indicador = false) hasta que se añada.
prorrogas_verificadas (cod_ccaa, ejercicio, evidencia) as (
    values
        ('01', 2022, 'Decreto 286/2021, de 28 de diciembre, BOJA 251 de 31-12-2021'),
        ('02', 2019, 'Orden HAP/2068/2018, de 21 de diciembre, BOA 251 de 31-12-2018'),
        ('02', 2025, 'Orden HAP/1608/2024, de 26 de diciembre, BOA de 31-12-2024'),
        ('02', 2026, 'Orden HAP/1848/2025, de 30 de diciembre, BOA 252 de 31-12-2025'),
        ('03', 2008, 'Decreto 286/2007, de 26 de diciembre (prórroga de 2007)'),
        ('03', 2012, 'Decreto 280/2011, BOPA de 31-12-2011; Ley 2/2012, de 26 de julio'),
        ('03', 2014, 'Decreto 127/2013, de 30 de diciembre, BOPA de 31-12-2013; Ley 4/2014, de 6 de junio'),
        ('03', 2016, 'Decreto 207/2015, de 30 de diciembre, BOPA 302 de 31-12-2015'),
        ('03', 2018, 'Decreto 91/2017, de 28 de diciembre, BOPA 300 de 30-12-2017; Ley 4/2018, de 4 de mayo'),
        ('04', 2011, 'Ley 8/2011, de 14 de noviembre, sobre autorizaciones financieras durante la prórroga iniciada el 1-1-2011'),
        ('04', 2026, 'Orden 39/2025, de 23 de diciembre, de prórroga de la Ley 6/2025'),
        ('07', 2019, 'Decreto 51/2018, de 27 de diciembre, BOCYL 250 de 28-12-2018'),
        ('07', 2020, 'Decreto 43/2019, de 26 de diciembre, BOCYL de 27-12-2019'),
        ('07', 2022, 'Decreto 36/2021, de 30 de diciembre, BOCYL 252 de 31-12-2021'),
        ('07', 2025, 'Decreto 28/2024, de 26 de diciembre, BOCYL de 30-12-2024'),
        ('07', 2026, 'Decreto 23/2025, de 30 de diciembre, BOCYL de 31-12-2025'),
        ('08', 2019, 'Decreto 95/2018, de 18 de diciembre, DOCM 253 de 31-12-2018'),
        ('09', 2013, 'Decret 170/2012, de 27 de desembre, DOGC de 31-12-2012'),
        ('09', 2016, 'Decret 252/2015, de 15 de desembre, DOGC 7020 de 17-12-2015'),
        ('09', 2018, 'Instrucció 1/2017, de 12 de desembre, de prórroga de la Llei 4/2017'),
        ('09', 2019, 'Decret 273/2018, de 20 de desembre'),
        ('09', 2021, 'Decret 146/2020, de 15 de desembre, DOGC 8297 de 17-12-2020'),
        ('09', 2024, 'Decret 222/2023, de 19 de desembre, DOGC de 21-12-2023'),
        ('09', 2025, 'Decret 478/2024, de 17 de desembre; Decret llei 8/2025 (pressupostos 2023 prorrogats per al 2025)'),
        ('11', 2025, 'Orden de 6 de febrero de 2025, DOE 26 de 7-2-2025'),
        ('13', 2020, 'Decreto 315/2019, de 27 de diciembre, BOCM de 30-12-2019'),
        ('13', 2021, 'Decreto 122/2020, de 29 de diciembre, BOCM 317 de 30-12-2020'),
        ('13', 2023, 'Decreto 137/2022, de 28 de diciembre, BOCM de 30-12-2022'),
        ('14', 2026, 'Orden de prórroga de la Ley 3/2025, BORM 299 de 29-12-2025'),
        ('15', 2002, 'Rechazo del proyecto (BOPN 2 de 10-1-2002); Cámara de Comptos, Cuentas de 2002'),
        ('15', 2003, 'Segunda prórroga del presupuesto de 2001 (BOPN 96 de 9-11-2004)'),
        ('15', 2013, 'Devolución del proyecto en noviembre de 2012; prórroga de la Ley Foral 19/2011 (Parlamento de Navarra)'),
        ('15', 2014, 'Segunda prórroga del presupuesto de 2012 (Parlamento de Navarra); Decreto-ley Foral 1/2013'),
        ('15', 2015, 'Acuerdo del Gobierno de Navarra de 29-12-2014 de ejecución de la prórroga; Cámara de Comptos (BOPN 139 de 24-11-2016)'),
        ('16', 2001, 'STC 3/2003, FJ 7; Decreto 55/2001, de 27 de marzo'),
        ('16', 2002, 'STC 3/2003, FJ 7 (anula la Ley 1/2002, de 23 de enero, que no es ley de presupuestos)'),
        ('16', 2004, 'Gobierno Vasco, informe anual de la Hacienda vasca 2004 (régimen de prórroga)'),
        ('16', 2013, 'Tribunal Vasco de Cuentas Públicas, Cuenta de la Administración General 2013 (BOPV 148 de 7-8-2015)'),
        ('16', 2019, 'Leyes 1/2019, 2/2019 y 3/2019, de 14 de febrero, de medidas presupuestarias urgentes (BOPV 35 de 19-2-2019)'),
        ('17', 2019, 'Retirada del proyecto el 19-12-2018; Ley 1/2019, de 4 de marzo, de medidas urgentes (BOR 28 de 6-3-2019)')
),

ley_por_ejercicio as (
    select cod_ccaa, ejercicio, identificador, titulo, fecha_publicacion_boe, fecha_disposicion,
        fecha_publicacion_diario, diario_autonomico, numero_oficial, url_html, 'boe' as origen
    from leyes
    where ejercicio between 2000 and extract(year from current_date) + 1
    qualify row_number() over (partition by cod_ccaa, ejercicio order by fecha_disposicion, fecha_publicacion_boe, identificador) = 1
),

ley_final as (
    select * from ley_por_ejercicio
    union all
    select m.cod_ccaa, m.ejercicio, null, null, null, m.fecha_disposicion,
        m.fecha_publicacion_diario, m.diario_autonomico, m.numero_oficial, m.url_html, 'manual'
    from leyes_manual m
    anti join ley_por_ejercicio b on b.cod_ccaa = m.cod_ccaa and b.ejercicio = m.ejercicio
),

ejercicios as (
    select unnest(range(2000, cast(extract(year from current_date) as integer) + 2)) as ejercicio
),

ccaa as (
    select cod as cod_ccaa, nombre from {{ ref('territorios') }} where nivel = 'ccaa'
),

ultimo_padron as (select max(anio) as anio from {{ ref('poblacion_municipios') }}),

poblacion as (
    select anio, cod_ccaa, sum(poblacion) as poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    group by all
),

base as (
    select
        e.ejercicio, c.cod_ccaa, c.nombre, po.poblacion,
        make_date(e.ejercicio, 1, 1) as inicio_ejercicio,
        make_date(e.ejercicio - 1, 12, 31) < current_date as vencido,
        l.fecha_disposicion is not null as hay_ley,
        pv.evidencia as evidencia_prorroga,
        l.* exclude (cod_ccaa, ejercicio)
    from ejercicios e
    cross join ccaa c
    left join ley_final l on l.cod_ccaa = c.cod_ccaa and l.ejercicio = e.ejercicio
    left join prorrogas_verificadas pv on pv.cod_ccaa = c.cod_ccaa and pv.ejercicio = e.ejercicio
    left join poblacion po
      on po.cod_ccaa = c.cod_ccaa and po.anio = least(e.ejercicio, (select anio from ultimo_padron))
),

clasificado as (
    select *,
        case
            when cod_ccaa in ('18', '19') then 'ciudad'
            when hay_ley then 'ley'
            when not vencido then 'no_vencido'
            when evidencia_prorroga is not null then 'prorrogado'
            else 'pendiente'
        end as caso
    from base
)

select
    'ley_presupuestos_ccaa' as obligacion,
    'Ley de presupuestos aprobada antes del 1 de enero' as obligacion_nombre,
    'Estatuto de autonomía y ley de hacienda de cada comunidad (prórroga automática si la ley de presupuestos no se aprueba antes del primer día del ejercicio)' as base_legal,
    'Comunidad autónoma' as tipo_entidad,
    'C' || cod_ccaa as cod_entidad,
    nombre as nombre_entidad,
    cast(null as varchar) as cod_mun,
    case cod_ccaa when '18' then '51' when '19' then '52' end as cod_prov,
    cod_ccaa,
    cast(ejercicio as varchar) as periodo,
    ejercicio as anio,
    make_date(ejercicio - 1, 12, 31) as fecha_plazo,
    case caso
        when 'ciudad' then 'no_aplica'
        when 'pendiente' then 'no_aplica'
        when 'no_vencido' then 'no_vencido'
        when 'prorrogado' then 'no_consta'
        else case when fecha_disposicion < inicio_ejercicio then 'en_plazo' else 'fuera_plazo' end
    end as estado,
    case when hay_ley then cast(greatest(date_diff('day', inicio_ejercicio, fecha_disposicion), 0) as integer) end as dias_retraso,
    cast(null as integer) as n_total,
    cast(null as integer) as n_fuera_plazo,
    cast(null as double) as mediana_dias,
    caso not in ('ciudad', 'pendiente') as aplica_indicador,
    case caso
        when 'ciudad' then 'Ciudad autónoma: el presupuesto lo aprueba el Pleno de la Asamblea, no una ley'
        when 'pendiente' then 'No consta ley de presupuestos en el BOE y la prórroga aún no está comprobada en el diario autonómico'
    end as motivo_no_aplica,
    cast(poblacion as integer) as poblacion,
    coalesce(url_html, 'https://www.boe.es/datosabiertos/api/boe/sumario/') as url_fuente,
    -- extras
    origen as x_origen_ley,
    identificador as x_boe_id,
    titulo as x_titulo,
    numero_oficial as x_numero_ley,
    fecha_disposicion as x_fecha_ley,
    fecha_publicacion_diario as x_fecha_publicacion_diario,
    diario_autonomico as x_diario_autonomico,
    fecha_publicacion_boe as x_fecha_publicacion_boe,
    caso = 'prorrogado' as x_prorrogado_sin_ley,
    evidencia_prorroga as x_evidencia_prorroga,
    'ley_presupuestos_ccaa-C' || cod_ccaa || '-' || cast(ejercicio as varchar) as clave
from clasificado
