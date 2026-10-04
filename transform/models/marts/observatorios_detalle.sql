-- Censo de observatorios públicos (observatoriospublicos.es) con:
--   * nivel de la administración que los crea;
--   * comunidad (y municipio o provincia cuando se puede): primero el ámbito del
--     censo; si no lo identifica, el nombre del observatorio cruzado con los
--     municipios del INE (nombre completo como palabra; los nombres cortos solo si
--     el municipio tiene 5.000 hab. o más; gana el nombre más largo y, a igualdad,
--     el más poblado), después islas/provincias y gentilicios de comunidad
--     (seed observatorios_claves_territorio);
--   * estado sin inventar: si el censo no dice nada, "Sin información";
--   * partido que gobernaba cuando se creó (1 de julio del año de creación): el
--     del Gobierno de España para los estatales, el de la presidencia autonómica
--     para los autonómicos (seed gobiernos_presidentes) y el del alcalde para los
--     locales ubicados en un municipio (alcaldes_historia). Los provinciales o
--     insulares y los que no tienen año no se atribuyen.
with base as (
    select
        o.nombre,
        lower(coalesce(o.ambito, 'unknown')) as ambito,
        o.anio_creacion,
        lower(cast(r.activo_texto as varchar)) as activo_texto,
        lower(coalesce(r.tipo, '')) as tipo,
        lower(strip_accents(o.nombre)) as nombre_norm
    from {{ ref('stg_observatorios') }} o
    left join (
        select nombre, any_value(activo_texto) as activo_texto, any_value(tipo) as tipo
        from {{ source('raw', 'observatorios_publicos') }}
        group by nombre
    ) r using (nombre)
),

-- Ámbitos del censo que nombran un territorio
territorio_ambito as (
    select * from (values
        ('andalucia', '01', 'Autonómico'), ('aragon', '02', 'Autonómico'), ('asturias', '03', 'Autonómico'),
        ('islas_baleares', '04', 'Autonómico'), ('menorca', '04', 'Provincial o insular'), ('canarias', '05', 'Autonómico'),
        ('cantabria', '06', 'Autonómico'), ('castilla_y_leon', '07', 'Autonómico'), ('castilla_la_mancha', '08', 'Autonómico'),
        ('cataluna', '09', 'Autonómico'), ('barcelona', '09', 'Provincial o insular'), ('comunidad_valenciana', '10', 'Autonómico'),
        ('extremadura', '11', 'Autonómico'), ('galicia', '12', 'Autonómico'), ('comunidad_de_madrid', '13', 'Autonómico'),
        ('region_de_murcia', '14', 'Autonómico'), ('navarra', '15', 'Autonómico'), ('pais_vasco', '16', 'Autonómico'),
        ('bizkaia', '16', 'Provincial o insular'), ('gipuzkoa', '16', 'Provincial o insular'), ('la_rioja', '17', 'Autonómico'),
        ('ceuta', '18', 'Autonómico'), ('melilla', '19', 'Autonómico')
    ) t(ambito, cod_ccaa, nivel)
),

niveles as (
    select
        b.*,
        coalesce(t.nivel, case b.ambito
            when 'estatal' then 'Estatal'
            when 'autonómico' then 'Autonómico'
            when 'provincial' then 'Provincial o insular'
            when 'local' then 'Local'
            when 'municipal' then 'Local'
            else 'Sin clasificar'
        end) as nivel,
        t.cod_ccaa as cod_ccaa_ambito
    from base b
    left join territorio_ambito t using (ambito)
),

-- Variantes de nombre de cada municipio: "Alcoi/Alcoy" -> dos; "Coruña, A" -> "a coruña";
-- "Vitoria-Gasteiz" -> también "vitoria" y "gasteiz"
municipios as (
    select cod_mun, cod_prov, cod_ccaa, poblacion, municipio
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total' and anio = (select max(anio) from {{ ref('poblacion_municipios') }})
),

variantes_base as (
    select m.*, trim(unnest(string_split(m.municipio, '/'))) as variante
    from municipios m
),

variantes_orden as (
    select *,
        lower(strip_accents(case
            when regexp_matches(variante, ', (A|O|As|Os|El|La|Los|Las|Les|Els|Es|Sa|Ses|Lo)$')
                then regexp_extract(variante, ', (\w+)$', 1) || ' ' || regexp_replace(variante, ', \w+$', '')
            when regexp_matches(variante, ', L''$')
                then 'l''' || regexp_replace(variante, ', L''$', '')
            else variante
        end)) as v
    from variantes_base
),

variantes as (
    select distinct cod_mun, cod_prov, cod_ccaa, poblacion, v from variantes_orden
    union
    select distinct cod_mun, cod_prov, cod_ccaa, poblacion, trim(unnest(string_split(v, '-'))) as v
    from variantes_orden where v like '%-%'
),

candidatos_mun as (
    select n.nombre, v.cod_mun, v.cod_prov, v.cod_ccaa,
        row_number() over (partition by n.nombre order by length(v.v) desc, v.poblacion desc) as rk
    from niveles n
    join variantes v
      on length(v.v) >= 4
     and (length(v.v) >= 10 or v.poblacion >= 5000)
     and regexp_matches(n.nombre_norm, '(^|[^a-z])' || regexp_replace(v.v, '([.()\[\]*+?^$|\\])', '\\\1', 'g') || '($|[^a-z])')
     -- "la cuenca", "una ribera"...: con artículo delante es un nombre común, no el municipio
     and not regexp_matches(n.nombre_norm, '(^|[^a-z])(la|las|una) ' || regexp_replace(v.v, '([.()\[\]*+?^$|\\])', '\\\1', 'g') || '($|[^a-z])')
    where n.nivel <> 'Estatal'
),

claves as (
    select n.nombre, c.cod_prov, c.cod_ccaa,
        row_number() over (partition by n.nombre order by c.cod_prov is null, length(c.patron) desc) as rk
    from niveles n
    join {{ ref('observatorios_claves_territorio') }} c
      on regexp_matches(n.nombre_norm, c.patron)
    where n.nivel <> 'Estatal'
),

ubicados as (
    select
        n.*,
        m.cod_mun as cod_mun_nombre,
        coalesce(m.cod_prov, k.cod_prov) as cod_prov,
        -- en los autonómicos manda el gentilicio ("de Castilla y León") sobre una ciudad del nombre
        case when n.nivel = 'Autonómico' then coalesce(n.cod_ccaa_ambito, k.cod_ccaa, m.cod_ccaa)
             else coalesce(n.cod_ccaa_ambito, m.cod_ccaa, k.cod_ccaa) end as cod_ccaa,
        case
            when n.nivel = 'Estatal' then 'No aplica'
            when n.cod_ccaa_ambito is not null then 'Ámbito del censo'
            when n.nivel = 'Autonómico' and k.cod_ccaa is not null then 'Comunidad en el nombre'
            when m.cod_mun is not null then 'Municipio en el nombre'
            when k.cod_prov is not null then 'Isla o provincia en el nombre'
            when k.cod_ccaa is not null then 'Comunidad en el nombre'
            else 'Sin ubicar'
        end as metodo_ubicacion
    from niveles n
    left join candidatos_mun m on m.nombre = n.nombre and m.rk = 1
    left join claves k on k.nombre = n.nombre and k.rk = 1
),

-- Un municipio solo cuenta como sede si el observatorio es local (o sin clasificar)
con_municipio as (
    select *,
        case when nivel in ('Local', 'Sin clasificar') then cod_mun_nombre end as cod_mun,
        make_date(anio_creacion, 7, 1) as fecha_ref
    from ubicados
),

gobiernos as (
    select nivel, cod, desde, coalesce(hasta, date '2100-01-01') as hasta, presidente, familia
    from {{ ref('gobiernos_presidentes') }}
),

colores as (
    select familia, any_value(color) as color
    from {{ ref('alcaldes_historia') }}
    where familia is not null and color is not null
    group by familia
),

alcaldes as (
    select cod_mun, fecha_posesion, coalesce(fecha_fin, date '2100-01-01') as fecha_fin, alcalde, familia
    from {{ ref('alcaldes_historia') }}
),

atribucion as (
    select
        c.nombre,
        case
            when c.anio_creacion is null then null
            when c.nivel = 'Estatal' then ge.familia
            when c.nivel = 'Autonómico' then ga.familia
            when c.cod_mun is not null then al.familia
        end as partido,
        case
            when c.anio_creacion is null then null
            when c.nivel = 'Estatal' then ge.presidente
            when c.nivel = 'Autonómico' then ga.presidente
            when c.cod_mun is not null then al.alcalde
        end as gobernante,
        case
            when c.anio_creacion is null then 'Sin año de creación'
            when c.nivel = 'Estatal' and ge.familia is not null then 'Gobierno de España'
            when c.nivel = 'Autonómico' and ga.familia is not null then 'Presidencia autonómica'
            when c.cod_mun is not null and al.familia is not null then 'Alcaldía'
            when c.nivel = 'Provincial o insular' then 'Diputación o cabildo (sin datos)'
            else 'Sin atribuir'
        end as metodo_partido,
        -- ¿cambió el gobierno ese mismo año? La atribución por año es entonces dudosa
        case
            when c.nivel = 'Estatal' then exists (select 1 from gobiernos g where g.nivel = 'estatal' and year(g.desde) = c.anio_creacion and g.desde > make_date(c.anio_creacion, 1, 1))
            when c.nivel = 'Autonómico' then exists (select 1 from gobiernos g where g.nivel = 'autonomico' and g.cod = c.cod_ccaa and year(g.desde) = c.anio_creacion and g.desde > make_date(c.anio_creacion, 1, 1))
            else false
        end as cambio_en_el_anio
    from con_municipio c
    left join gobiernos ge on ge.nivel = 'estatal' and c.fecha_ref >= ge.desde and c.fecha_ref < ge.hasta
    left join gobiernos ga on ga.nivel = 'autonomico' and ga.cod = c.cod_ccaa and c.fecha_ref >= ga.desde and c.fecha_ref < ga.hasta
    left join alcaldes al on al.cod_mun = c.cod_mun and c.fecha_ref >= al.fecha_posesion and c.fecha_ref < al.fecha_fin
    qualify row_number() over (partition by c.nombre order by al.fecha_posesion desc nulls last) = 1
)

select
    c.nombre,
    c.nivel,
    c.cod_ccaa,
    nc.nombre as ccaa,
    c.cod_prov,
    pr.nombre as provincia,
    c.cod_mun,
    mu.municipio,
    c.metodo_ubicacion,
    c.anio_creacion,
    case
        when c.activo_texto in ('si', 'sí', 'yes', 'true', '1') then 'Activo'
        when c.activo_texto in ('no', 'false', '0') then 'Inactivo'
        else 'Sin información'
    end as estado,
    case when c.tipo like 'mixto%' then 'Mixto (público-privado)' when c.tipo like 'p%blico' then 'Público' else 'Sin información' end as tipo,
    a.partido,
    a.gobernante,
    a.metodo_partido,
    a.cambio_en_el_anio,
    col.color as color_partido
from con_municipio c
left join atribucion a using (nombre)
left join (select distinct cod, nombre from {{ ref('territorios') }} where nivel = 'ccaa') nc on nc.cod = c.cod_ccaa
left join (select distinct cod, nombre from {{ ref('territorios') }} where nivel = 'provincia') pr on pr.cod = c.cod_prov
left join municipios mu on mu.cod_mun = c.cod_mun
left join colores col on col.familia = a.partido
