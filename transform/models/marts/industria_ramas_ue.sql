-- Ramas industriales: cuánto pesa España en la UE (Eurostat, estadísticas estructurales de
-- empresas sbs_ovw_act, raw.eurostat_industria_sbs; población nama_10_pe). Una fila por rama NACE
-- y año (2021-último).
--   *_ue: el agregado EU27_2020 de Eurostat (estimación que incluye los países con dato
--     confidencial; viene redondeado, p. ej. 200.000 M€). Si falta, la suma de los países que
--     publican el dato, y `nota` lo dice.
--   cuota_*_pct: España / UE. puesto_*: posición de España entre los países que publican el dato
--     (n_paises_*); lider_*: país primero.
--   cuota_poblacion_pct: peso de España en la población de la UE ese año;
--   veces_peso_poblacion: cuota de la cifra de negocios / cuota de población (1 = lo que le tocaría
--     por habitantes; >1 especialización).
--   peso_manuf_es_pct / peso_manuf_ue_pct: valor añadido de la rama sobre el de todas las
--     manufacturas (C) en España y en la UE; indice_especializacion = cociente de ambos.
--   cifra_negocios_es_real_meur: cifra de negocios de España en millones de euros constantes de
--     anio_base (main.deflactor). Las cuotas UE no necesitan deflactar.
--   es_ultimo_anio: último año con dato de España y de la UE para la cifra de negocios.
with sbs as (
    select cast(anio as integer) as anio, pais, rama, indicador, valor
    from {{ source('raw_industria', 'eurostat_industria_sbs') }}
    where valor is not null
),

nombres as (
    select * from (values
        ('B', 'Industrias extractivas', 'seccion', 1),
        ('C', 'Industria manufacturera (total)', 'seccion', 2),
        ('D', 'Energía eléctrica, gas y vapor', 'seccion', 3),
        ('E', 'Agua, saneamiento y residuos', 'seccion', 4),
        ('C10', 'Alimentación', 'division', 10),
        ('C11', 'Bebidas', 'division', 11),
        ('C12', 'Tabaco', 'division', 12),
        ('C13', 'Textil', 'division', 13),
        ('C14', 'Confección', 'division', 14),
        ('C15', 'Cuero y calzado', 'division', 15),
        ('C16', 'Madera y corcho', 'division', 16),
        ('C17', 'Papel', 'division', 17),
        ('C18', 'Artes gráficas', 'division', 18),
        ('C19', 'Refino de petróleo', 'division', 19),
        ('C20', 'Química', 'division', 20),
        ('C21', 'Farmacia', 'division', 21),
        ('C22', 'Caucho y plásticos', 'division', 22),
        ('C23', 'Minerales no metálicos (cerámica, vidrio, cemento)', 'division', 23),
        ('C233', 'Cerámica para la construcción', 'grupo', 231),
        ('C2331', 'Azulejos y baldosas cerámicas', 'clase', 232),
        ('C235', 'Cemento, cal y yeso', 'grupo', 233),
        ('C24', 'Metalurgia', 'division', 24),
        ('C241', 'Siderurgia (hierro, acero y ferroaleaciones)', 'grupo', 241),
        ('C25', 'Productos metálicos', 'division', 25),
        ('C26', 'Informática, electrónica y óptica', 'division', 26),
        ('C27', 'Material y equipo eléctrico', 'division', 27),
        ('C28', 'Maquinaria y equipo', 'division', 28),
        ('C2811', 'Motores y turbinas (incl. aerogeneradores)', 'clase', 281),
        ('C29', 'Automóvil (vehículos, remolques y componentes)', 'division', 29),
        ('C291', 'Fabricación de vehículos de motor', 'grupo', 291),
        ('C293', 'Componentes de automoción', 'grupo', 293),
        ('C30', 'Otro material de transporte', 'division', 30),
        ('C301', 'Construcción naval', 'grupo', 301),
        ('C302', 'Material ferroviario', 'grupo', 302),
        ('C303', 'Aeronáutica y espacio', 'grupo', 303),
        ('C31', 'Muebles', 'division', 31),
        ('C32', 'Otras manufacturas', 'division', 32),
        ('C33', 'Reparación e instalación de maquinaria', 'division', 33)
    ) as t(rama, rama_nombre, nivel, orden)
),

con_es as (
    select s.*, e.valor as valor_es
    from sbs s
    left join sbs e on e.anio = s.anio and e.rama = s.rama and e.indicador = s.indicador and e.pais = 'ES'
    where s.indicador in ('NETTUR_MEUR', 'AV_MEUR', 'EMP_NR')
),

por_indicador as (
    select
        anio,
        rama,
        indicador,
        max(case when pais = 'ES' then valor end) as es,
        max(case when pais = 'EU27_2020' then valor end) as ue_agregado,
        sum(case when pais <> 'EU27_2020' then valor end) as ue_suma_paises,
        count(case when pais <> 'EU27_2020' then valor end) as n_paises,
        arg_max(pais, valor) filter (where pais <> 'EU27_2020') as lider,
        -- puesto de España entre los países con dato: los que la superan + 1
        1 + count(*) filter (where pais not in ('EU27_2020', 'ES') and valor > valor_es) as puesto_calc
    from con_es
    group by all
),

ancho as (
    select
        anio,
        rama,
        max(case when indicador = 'NETTUR_MEUR' then es end) as cifra_negocios_es_meur,
        max(case when indicador = 'NETTUR_MEUR' then coalesce(ue_agregado, ue_suma_paises) end) as cifra_negocios_ue_meur,
        bool_or(indicador = 'NETTUR_MEUR' and ue_agregado is null) as cn_ue_es_suma,
        max(case when indicador = 'NETTUR_MEUR' and es is not null then puesto_calc end) as puesto_cifra_negocios,
        max(case when indicador = 'NETTUR_MEUR' then n_paises end) as n_paises_cifra_negocios,
        max(case when indicador = 'NETTUR_MEUR' then lider end) as lider_cifra_negocios,
        max(case when indicador = 'AV_MEUR' then es end) as valor_anadido_es_meur,
        max(case when indicador = 'AV_MEUR' then coalesce(ue_agregado, ue_suma_paises) end) as valor_anadido_ue_meur,
        bool_or(indicador = 'AV_MEUR' and ue_agregado is null) as va_ue_es_suma,
        max(case when indicador = 'AV_MEUR' and es is not null then puesto_calc end) as puesto_valor_anadido,
        max(case when indicador = 'AV_MEUR' then n_paises end) as n_paises_valor_anadido,
        max(case when indicador = 'EMP_NR' then es end) as empleo_es,
        max(case when indicador = 'EMP_NR' then coalesce(ue_agregado, ue_suma_paises) end) as empleo_ue,
        max(case when indicador = 'EMP_NR' and es is not null then puesto_calc end) as puesto_empleo
    from por_indicador
    group by all
),

manuf as (
    select anio, valor_anadido_es_meur as va_c_es, valor_anadido_ue_meur as va_c_ue
    from ancho where rama = 'C'
),

poblacion as (
    select
        cast(anio as integer) as anio,
        100.0 * max(case when pais = 'ES' then miles end) / max(case when pais = 'EU27_2020' then miles end)
            as cuota_poblacion_pct
    from {{ source('raw_industria', 'eurostat_industria_poblacion') }}
    group by 1
),

ultimo as (
    select rama, max(anio) as anio
    from ancho
    where cifra_negocios_es_meur is not null and cifra_negocios_ue_meur is not null
    group by 1
)

select
    a.rama,
    n.rama_nombre,
    n.nivel,
    n.orden,
    a.anio,
    a.anio = u.anio as es_ultimo_anio,
    a.cifra_negocios_es_meur,
    a.cifra_negocios_es_meur * d.factor as cifra_negocios_es_real_meur,
    d.anio_base,
    a.cifra_negocios_ue_meur,
    100.0 * a.cifra_negocios_es_meur / nullif(a.cifra_negocios_ue_meur, 0) as cuota_cifra_negocios_pct,
    a.puesto_cifra_negocios,
    a.n_paises_cifra_negocios,
    a.lider_cifra_negocios,
    pl.pais_nombre as lider_cifra_negocios_nombre,
    a.valor_anadido_es_meur,
    a.valor_anadido_ue_meur,
    100.0 * a.valor_anadido_es_meur / nullif(a.valor_anadido_ue_meur, 0) as cuota_valor_anadido_pct,
    a.puesto_valor_anadido,
    a.n_paises_valor_anadido,
    a.empleo_es,
    100.0 * a.empleo_es / nullif(a.empleo_ue, 0) as cuota_empleo_pct,
    a.puesto_empleo,
    p.cuota_poblacion_pct,
    (100.0 * a.cifra_negocios_es_meur / nullif(a.cifra_negocios_ue_meur, 0)) / p.cuota_poblacion_pct
        as veces_peso_poblacion,
    -- B, D y E no forman parte de las manufacturas (C): sin peso manufacturero
    case when a.rama like 'C%' then 100.0 * a.valor_anadido_es_meur / nullif(m.va_c_es, 0) end as peso_manuf_es_pct,
    case when a.rama like 'C%' then 100.0 * a.valor_anadido_ue_meur / nullif(m.va_c_ue, 0) end as peso_manuf_ue_pct,
    case when a.rama like 'C%' then (a.valor_anadido_es_meur / nullif(m.va_c_es, 0)) / nullif(a.valor_anadido_ue_meur / nullif(m.va_c_ue, 0), 0) end
        as indice_especializacion,
    concat_ws('; ',
        case when a.cn_ue_es_suma then 'UE de cifra de negocios = suma de los países con dato (sin agregado de Eurostat)' end,
        case when a.va_ue_es_suma then 'UE de valor añadido = suma de los países con dato' end,
        case when a.n_paises_cifra_negocios < 27
             then 'puesto entre ' || a.n_paises_cifra_negocios || ' países con dato publicado (el resto es confidencial)' end
    ) as nota
from ancho a
left join nombres n using (rama)
left join manuf m using (anio)
left join poblacion p using (anio)
left join ultimo u using (rama)
left join {{ ref('deflactor') }} d on d.anio = a.anio
left join {{ ref('industria_paises') }} pl on pl.pais = a.lider_cifra_negocios
where a.cifra_negocios_es_meur is not null or a.valor_anadido_es_meur is not null
