-- Indicador de transparencia: ¿consta en el Tribunal de Cuentas la rendición de
-- cada obligación de los ayuntamientos? Una fila por ayuntamiento, obligación y
-- ejercicio. Fuente: Plataforma de Rendición de Cuentas de las Entidades Locales
-- (TCu + OCEX), ver ingestion/tcu.py.
--
-- Plazos legales (ejercicio N):
--   cuenta_general   15/10/N+1  arts. 212.5 y 223.2 TRLRHL (RDLeg 2/2004)
--   control_interno  30/04/N+1  art. 218.3 TRLRHL e Instrucción TCu 19/12/2019 (BOE-A-2020-680)
--   contratos        fin de febrero de N+1  art. 335 LCSP e Instrucción TCu 28/06/2018
--                    (BOE-A-2018-9585); sin contratos basta una certificación negativa
--
-- estado:
--   en_plazo           rendida con fecha de envío <= plazo, o rendida antes de que venza
--   fuera_plazo        rendida después del plazo (solo Cuenta General: única con fecha de envío)
--   rendida_sin_fecha  consta rendida, pero no se conoce la fecha de envío
--   no_rendida         no consta rendida a la fecha de extracción, con el plazo vencido
--   no_vencido         no consta rendida y el plazo aún no ha vencido
--   no_aplica          el portal indica que la obligación no aplica a la entidad
--
-- Responsabilidad: gobierno municipal en funciones el día del plazo (alcaldes_historia).
-- País Vasco y Navarra no están en la plataforma (sus propios órganos de control).
--
-- Casado con el INE: código MEH o MAP de la ficha censal (ingestion/tcu.py) y, si
-- falta o no existe en el INE, nombre normalizado + provincia (sin tildes, artículo
-- pospuesto "Bruc, El" = "El Bruc", cada parte de los nombres bilingües "A/B").
{% set articulos = "el|la|los|las|l''|els|les|lo|o|a|os|as|sa|ses|es|s''" %}
{% set normaliza -%}
regexp_replace(
    regexp_replace(
        regexp_replace(lower(strip_accents(trim(__E__))), '^(.*), ({{ articulos }})$', '\2 \1'),
        '^(.*) \(({{ articulos }})\)$', '\2 \1'),
    '[^a-z0-9]', '', 'g')
{%- endset %}

with entidades as (
    select *
    from {{ source('raw_tcu', 'tcu_entidades') }}
    where tipo = 'A'
),

ine as (
    select cod_mun, municipio, cod_prov, cod_ccaa, vigente
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
),

-- variantes de nombre del INE: completo y cada parte de "Castellano/Otra lengua"
nombres_ine as (
    select distinct cod_mun, cod_prov, {{ normaliza | replace('__E__', 'parte') }} as nombre_norm
    from (
        select cod_mun, cod_prov, municipio as parte from ine
        union all
        select cod_mun, cod_prov, unnest(string_split(municipio, '/')) from ine where municipio like '%/%'
    )
),

nombres_ine_unicos as (
    select cod_prov, nombre_norm, min(cod_mun) as cod_mun
    from nombres_ine
    group by all
    having count(distinct cod_mun) = 1
),

nombres_tcu as (
    select distinct e.id_entidad, e.cod_prov, {{ normaliza | replace('__E__', 'parte') }} as nombre_norm
    from entidades e,
         unnest(list_distinct([e.nombre, e.municipio_censo] || string_split(e.nombre, '/'))) as t(parte)
    where parte is not null
),

por_nombre as (
    select t.id_entidad, min(n.cod_mun) as cod_mun
    from nombres_tcu t
    join nombres_ine_unicos n using (cod_prov, nombre_norm)
    group by t.id_entidad
    having count(distinct n.cod_mun) = 1
),

-- nombre de cada entidad del portal normalizado (para comparar con candidatos)
nombre_tcu_principal as (
    select id_entidad, {{ normaliza | replace('__E__', 'nombre') }} as nombre_norm
    from entidades
),

candidatos as (
    select
        e.id_entidad,
        e.cod_mun as cod_codigo,
        e.metodo_cod_mun,
        ic.cod_mun is not null as codigo_existe,
        -- el código de la ficha se da por bueno si el nombre del INE coincide
        exists (
            select 1 from nombres_tcu t join nombres_ine n using (nombre_norm)
            where t.id_entidad = e.id_entidad and n.cod_mun = e.cod_mun
        ) as codigo_confirmado,
        coalesce(jaro_winkler_similarity(np.nombre_norm,
            {{ normaliza | replace('__E__', 'ic.municipio') }}), 0) >= 0.9 as codigo_parecido,
        p.cod_mun as cod_nombre,
        inif.cod_mun as cod_nif,
        coalesce(jaro_winkler_similarity(np.nombre_norm,
            {{ normaliza | replace('__E__', 'inif.municipio') }}), 0) >= 0.85 as nif_confirmado
    from entidades e
    join nombre_tcu_principal np on np.id_entidad = e.id_entidad
    left join ine ic on ic.cod_mun = e.cod_mun and ic.cod_prov = e.cod_prov
    left join ine inif on inif.cod_mun = e.cod_mun_nif and inif.cod_prov = e.cod_prov
    left join por_nombre p on p.id_entidad = e.id_entidad
),

-- Orden: código MEH/MAP con el mismo nombre en el INE > nombre + provincia >
-- código con nombre parecido > NIF con nombre parecido (el NIF no sigue la
-- numeración del INE; solo se usa si todo lo demás falla)
casado as (
    select
        e.*,
        case
            when c.codigo_existe and c.codigo_confirmado then c.cod_codigo
            when c.cod_nombre is not null then c.cod_nombre
            when c.codigo_existe and c.codigo_parecido then c.cod_codigo
            when c.nif_confirmado then c.cod_nif
        end as cod_mun_ine,
        case
            when c.codigo_existe and c.codigo_confirmado then c.metodo_cod_mun
            when c.cod_nombre is not null then 'nombre_provincia'
            when c.codigo_existe and c.codigo_parecido then c.metodo_cod_mun || '_nombre_parecido'
            when c.nif_confirmado then 'nif_nombre_parecido'
        end as metodo_casado
    from entidades e
    join candidatos c on c.id_entidad = e.id_entidad
),

-- Si dos entidades del portal caen en el mismo municipio, se queda la activa
-- con más obligaciones rendidas (la otra suele ser un duplicado histórico).
entidad_municipio as (
    select c.*
    from casado c
    left join (
        select id_entidad, count(*) as rendidas
        from {{ source('raw_tcu', 'tcu_obligaciones') }}
        where estado = 'rendida'
        group by id_entidad
    ) r on r.id_entidad = c.id_entidad
    where c.cod_mun_ine is not null
    qualify row_number() over (
        partition by c.cod_mun_ine
        order by coalesce(c.activa, true) desc, coalesce(r.rendidas, 0) desc, c.id_entidad
    ) = 1
),

obligaciones as (
    select
        o.*,
        case o.obligacion
            when 'cuenta_general' then make_date(cast(o.ejercicio as integer) + 1, 10, 15)
            when 'control_interno' then make_date(cast(o.ejercicio as integer) + 1, 4, 30)
            when 'contratos' then cast(make_date(cast(o.ejercicio as integer) + 1, 3, 1) - interval 1 day as date)
        end as fecha_limite
    from {{ source('raw_tcu', 'tcu_obligaciones') }} o
),

base as (
    select
        e.cod_mun_ine as cod_mun,
        e.id_entidad,
        e.metodo_casado,
        o.obligacion,
        cast(o.ejercicio as integer) as ejercicio,
        o.fecha_limite,
        o.estado_portal,
        o.estado as estado_fuente,
        o.fecha_envio,
        o.fecha_extraccion,
        o.fecha_limite < o.fecha_extraccion as vencido
    from obligaciones o
    join entidad_municipio e on e.id_entidad = o.id_entidad
),

clasificado as (
    select
        *,
        case
            when estado_fuente = 'no_aplica' then 'no_aplica'
            when estado_fuente in ('rendida', 'rendida_no_disponible') then
                case
                    when fecha_envio is not null and fecha_envio <= fecha_limite then 'en_plazo'
                    when fecha_envio is not null then 'fuera_plazo'
                    when not vencido then 'en_plazo'
                    else 'rendida_sin_fecha'
                end
            when not vencido then 'no_vencido'
            else 'no_rendida'
        end as estado
    from base
),

poblacion as (
    select cod_mun, anio, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

con_poblacion as (
    select
        c.*,
        coalesce(p.poblacion, u.poblacion) as poblacion
    from clasificado c
    left join poblacion p on p.cod_mun = c.cod_mun and p.anio = c.ejercicio
    left join (
        select cod_mun, poblacion from poblacion
        qualify row_number() over (partition by cod_mun order by anio desc) = 1
    ) u on u.cod_mun = c.cod_mun
),

gobierno as (
    select
        c.cod_mun,
        c.obligacion,
        c.ejercicio,
        h.alcalde,
        h.partido_original,
        h.familia,
        h.color,
        row_number() over (partition by c.cod_mun, c.obligacion, c.ejercicio order by h.fecha_posesion desc) as n
    from clasificado c
    join {{ ref('alcaldes_historia') }} h
      on h.cod_mun = c.cod_mun
     and h.fecha_posesion <= c.fecha_limite
     and (h.fecha_fin is null or h.fecha_fin > c.fecha_limite)
)

select
    c.cod_mun,
    m.municipio,
    m.cod_prov,
    tp.nombre as provincia,
    m.cod_ccaa,
    tc.nombre as ccaa,
    c.id_entidad,
    c.metodo_casado,
    c.obligacion,
    cast(c.ejercicio as integer) as anio,
    c.fecha_limite,
    c.estado_portal,
    c.estado,
    case when c.fecha_envio > c.fecha_limite then datediff('day', c.fecha_limite, c.fecha_envio) end as dias_retraso,
    c.fecha_envio,
    c.poblacion,
    case
        when c.poblacion < 1000 then '<1.000'
        when c.poblacion < 5000 then '1.000-5.000'
        when c.poblacion < 20000 then '5.000-20.000'
        when c.poblacion < 50000 then '20.000-50.000'
        when c.poblacion < 100000 then '50.000-100.000'
        else '>100.000'
    end as tramo_poblacion,
    case
        when c.poblacion < 1000 then 1
        when c.poblacion < 5000 then 2
        when c.poblacion < 20000 then 3
        when c.poblacion < 50000 then 4
        when c.poblacion < 100000 then 5
        else 6
    end as tramo_orden,
    c.vencido and c.estado <> 'no_aplica' and m.cod_prov not in ('01', '20', '31', '48') as aplica_indicador,
    c.estado = 'no_rendida' and c.vencido and m.cod_prov not in ('01', '20', '31', '48') as incumple,
    case when c.vencido and c.estado <> 'no_aplica' and m.cod_prov not in ('01', '20', '31', '48')
        then (case when c.estado = 'no_rendida' then 100 else 0 end) end as incumple_pct,
    g.alcalde as alcalde_en_plazo,
    g.partido_original as lista_en_plazo,
    coalesce(g.familia, 'Sin dato de alcalde') as familia_en_plazo,
    coalesce(g.color, '#9ca3af') as color_familia,
    c.fecha_extraccion,
    c.cod_mun || '-' || c.obligacion || '-' || c.ejercicio as clave
from con_poblacion c
left join gobierno g
  on g.cod_mun = c.cod_mun and g.obligacion = c.obligacion and g.ejercicio = c.ejercicio and g.n = 1
left join ine m on m.cod_mun = c.cod_mun
left join {{ ref('territorios') }} tp on tp.nivel = 'provincia' and tp.cod = m.cod_prov
left join {{ ref('territorios') }} tc on tc.nivel = 'ccaa' and tc.cod = m.cod_ccaa
