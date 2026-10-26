-- Índice propio de publicidad activa: presupuesto prorrogado de las entidades
-- locales según el avance de presupuestos de CONPREL (Hacienda, SGFAL).
-- Ver docs/elaboracion-propia/presupuesto_prorrogado.md.
--
-- Plazo: el presupuesto general se aprueba definitivamente antes del 31 de
-- diciembre del año anterior (art. 169.2 TRLRHL); si no, se prorroga el del
-- ejercicio anterior (art. 169.6 TRLRHL).
-- Una fila por entidad y ejercicio, con la ÚLTIMA foto guardada de ese ejercicio
-- (el avance solo se sirve para el año en curso: el histórico empieza con la
-- primera foto, 2026). Columna «Estado Inf. (*)» del avance:
--   CP          -> fuera_plazo  (presupuesto prorrogado en la fecha de la foto)
--   C / E       -> consta       (presupuesto del ejercicio comunicado; fecha de aprobación desconocida)
--   N / ausente -> no_consta    (sin información del presupuesto en la foto)
-- Universo: ayuntamientos del padrón, diputaciones provinciales y forales (D + provincia),
-- cabildos y consells insulares (I + provincia + ordinal DIR3 L03) y Ceuta y Melilla
-- (Comunidad autónoma C18/C19, tipo Z00 en CONPREL).
-- Territorios forales (Álava, Gipuzkoa, Bizkaia y Navarra): aplica_indicador = false;
-- sus entidades remiten la información presupuestaria a la diputación foral o al
-- Gobierno de Navarra y en el avance figuran casi todas con N.

with fotos as (
    select *
    from {{ source('raw_pa_registros', 'conprel_presupuestos_avance') }}
    qualify fecha_foto = max(fecha_foto) over (partition by ejercicio)
),

primeras as (
    select ejercicio, cod_prov, cod_corp, tipo, min(fecha_foto) as primera_foto,
        arg_min(estado_inf, fecha_foto) as estado_primera_foto
    from {{ source('raw_pa_registros', 'conprel_presupuestos_avance') }}
    group by all
),

ejercicios as (
    select ejercicio, max(fecha_foto) as fecha_foto, max(url_fuente) as url_fuente
    from fotos group by all
),

ultimo_padron as (select max(anio) as anio from {{ ref('poblacion_municipios') }}),

padron as (
    select * from {{ ref('poblacion_municipios') }} where sexo = 'Total'
),

-- Cabildos y consells: CONPREL numera 001-004 por orden alfabético; el código del
-- índice usa el ordinal del DIR3 (L03 + provincia + ordinal), comprobado en el
-- registro de órganos de PLACSP (L03070001 Formentera, L03380011 Tenerife...).
islas (cod_prov, cod_corp, cod_entidad, nombre) as (
    values
        ('07', '001', 'I07006', 'Consell Insular d''Eivissa'),
        ('07', '002', 'I07008', 'Consell Insular de Mallorca'),
        ('07', '003', 'I07009', 'Consell Insular de Menorca'),
        ('07', '004', 'I07001', 'Consell Insular de Formentera'),
        ('35', '001', 'I35002', 'Cabildo Insular de Fuerteventura'),
        ('35', '002', 'I35004', 'Cabildo Insular de Gran Canaria'),
        ('35', '003', 'I35007', 'Cabildo Insular de Lanzarote y La Graciosa'),
        ('38', '001', 'I38003', 'Cabildo Insular de La Gomera'),
        ('38', '002', 'I38005', 'Cabildo Insular de El Hierro'),
        ('38', '003', 'I38010', 'Cabildo Insular de La Palma'),
        ('38', '004', 'I38011', 'Cabildo Insular de Tenerife')
),

provincias as (
    select cod as cod_prov, cod_ccaa, nombre from {{ ref('territorios') }} where nivel = 'provincia'
),

universo as (
    -- ayuntamientos
    select e.ejercicio, 'Ayuntamiento' as tipo_entidad, p.cod_mun as cod_entidad, p.municipio as nombre_entidad,
        p.cod_mun, p.cod_prov, p.cod_ccaa, p.poblacion,
        p.cod_prov as k_prov, substr(p.cod_mun, 3, 3) as k_corp, 'A00' as k_tipo
    from ejercicios e
    join padron p on p.anio = least(e.ejercicio, (select anio from ultimo_padron))
    where p.cod_prov not in ('51', '52')
    union all
    -- Ceuta y Melilla
    select e.ejercicio, 'Comunidad autónoma', case p.cod_prov when '51' then 'C18' else 'C19' end, p.municipio,
        null, p.cod_prov, p.cod_ccaa, p.poblacion,
        p.cod_prov, substr(p.cod_mun, 3, 3), 'Z00'
    from ejercicios e
    join padron p on p.anio = least(e.ejercicio, (select anio from ultimo_padron))
    where p.cod_prov in ('51', '52')
    union all
    -- diputaciones provinciales y forales (no hay en las uniprovinciales ni en las islas)
    select e.ejercicio, 'Diputación provincial', 'D' || pr.cod_prov,
        case when pr.cod_prov in ('01', '20', '48') then 'Diputación Foral de ' else 'Diputación Provincial de ' end || pr.nombre,
        null, pr.cod_prov, pr.cod_ccaa,
        (select sum(poblacion) from padron pa where pa.anio = least(e.ejercicio, (select anio from ultimo_padron)) and pa.cod_prov = pr.cod_prov),
        pr.cod_prov, '000', 'D00'
    from ejercicios e
    cross join provincias pr
    where pr.cod_prov not in ('07', '26', '28', '30', '31', '33', '35', '38', '39', '51', '52')
    union all
    -- cabildos y consells (población de la isla: no se calcula, null)
    select e.ejercicio, 'Cabildo o consell insular', i.cod_entidad, i.nombre,
        null, i.cod_prov, pr.cod_ccaa, null,
        i.cod_prov, i.cod_corp, 'D00'
    from ejercicios e
    cross join islas i
    join provincias pr on pr.cod_prov = i.cod_prov
),

base as (
    select
        u.*,
        e.fecha_foto,
        e.url_fuente,
        f.estado_inf,
        f.nombre as nombre_conprel,
        pf.primera_foto,
        pf.estado_primera_foto,
        u.cod_prov in ('01', '20', '48', '31') as foral,
        -- el Consell de Formentera hace también de ayuntamiento y comunica como tal (07024)
        u.cod_entidad = 'I07001' as formentera
    from universo u
    join ejercicios e using (ejercicio)
    left join fotos f
      on f.ejercicio = u.ejercicio and f.cod_prov = u.k_prov and f.cod_corp = u.k_corp and f.tipo = u.k_tipo
    left join primeras pf
      on pf.ejercicio = u.ejercicio and pf.cod_prov = u.k_prov and pf.cod_corp = u.k_corp and pf.tipo = u.k_tipo
)

select
    'presupuesto_prorrogado' as obligacion,
    'Presupuesto del año aprobado a tiempo (no prorrogado)' as obligacion_nombre,
    'art. 169.2 TRLRHL (aprobación definitiva antes del 31 de diciembre del año anterior) y art. 169.6 TRLRHL (prórroga)' as base_legal,
    tipo_entidad,
    cod_entidad,
    nombre_entidad,
    cod_mun,
    cod_prov,
    cod_ccaa,
    cast(ejercicio as varchar) as periodo,
    cast(ejercicio as integer) as anio,
    make_date(cast(ejercicio as integer) - 1, 12, 31) as fecha_plazo,
    case
        when foral or formentera then 'no_aplica'
        when estado_inf = 'CP' then 'fuera_plazo'
        when estado_inf in ('C', 'E') then 'consta'
        else 'no_consta'
    end as estado,
    cast(null as integer) as dias_retraso,
    cast(null as integer) as n_total,
    cast(null as integer) as n_fuera_plazo,
    cast(null as double) as mediana_dias,
    not (foral or formentera) as aplica_indicador,
    case
        when formentera then 'El Consell Insular de Formentera es también el ayuntamiento y comunica su presupuesto como tal (07024)'
        when cod_prov = '31' then 'Régimen foral (Navarra): la información presupuestaria se remite al Gobierno de Navarra; en CONPREL casi todas figuran sin datos'
        when foral then 'Régimen foral (País Vasco): la información presupuestaria se remite a la diputación foral; en CONPREL casi todas figuran sin datos'
    end as motivo_no_aplica,
    cast(poblacion as integer) as poblacion,
    url_fuente,
    -- extras
    estado_inf as x_estado_inf,
    fecha_foto as x_fecha_foto,
    primera_foto as x_primera_foto,
    estado_primera_foto as x_estado_primera_foto,
    nombre_conprel as x_nombre_conprel,
    'presupuesto_prorrogado-' || cod_entidad || '-' || cast(ejercicio as varchar) as clave
from base
