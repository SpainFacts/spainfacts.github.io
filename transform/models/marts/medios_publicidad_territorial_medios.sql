-- Reparto de la publicidad institucional autonómica y municipal por grupo
-- mediático: comunidad (o ayuntamiento) × año × grupo, con los 100 primeros
-- grupos de cada territorio y año. Base: medios_publicidad_territorial_gasto,
-- filas con medio identificado (cabecera, emisora o soporte) y sin la
-- creatividad/producción; el grupo sale de la tabla de equivalencias
-- medios_grupos_equivalencias (p. ej. «VANGUARDIA, LA» y «RAC 1» -> Grupo Godó)
-- y, si el medio no está en ella, es el propio medio. Incluye los desgloses por
-- medio que no suman el total del año (Navarra y País Vasco), porque son la
-- única información por medio de esas comunidades. El Ayuntamiento de
-- Barcelona no publica cabeceras y no aparece. Euros constantes (main.deflactor)
-- y por habitante del territorio. pct_medios = % sobre lo asignado a medios
-- identificados ese año en ese territorio; es_medio_publico marca RTVE, CCMA,
-- EITB, À Punt, Telemadrid, CARTV, RTRM y FORTA; tipo_grupo separa plataformas
-- (Google, Meta, TikTok...) de los grupos de comunicación. Importes tal cual de
-- cada fuente (con o sin IVA según la comunidad: ver iva_incluido y la nota de
-- medios_publicidad_territorial_anual); el reparto en % sí es comparable.
with base as (
    select * from {{ ref('medios_publicidad_territorial_gasto') }}
    where medio is not null
        and coalesce(tipo_medio_norm, '') <> 'creatividad_produccion'
        and anio <= 2025
),

agg as (
    select
        cod_ccaa, nivel, coalesce(cod_municipio, '') as cod_municipio, anio, grupo,
        any_value(tipo_grupo) as tipo_grupo,
        bool_or(es_medio_publico) as es_medio_publico,
        sum(importe_eur) as importe_eur,
        sum(importe_eur) filter (where es_empresa_publica) as importe_empresas_eur,
        count(distinct medio) as n_medios,
        case when count(distinct coalesce(cast(iva_incluido as varchar), 'nd')) = 1
            then any_value(iva_incluido) end as iva_incluido,
        string_agg(distinct base, ' / ') as base
    from base
    group by 1, 2, 3, 4, 5
),

top_medios as (
    select cod_ccaa, nivel, coalesce(cod_municipio, '') as cod_municipio, anio, grupo,
        string_agg(medio, ' · ' order by imp desc) filter (where rn <= 3) as medios_principales
    from (
        select cod_ccaa, nivel, cod_municipio, anio, grupo, medio, sum(importe_eur) as imp,
            row_number() over (partition by cod_ccaa, nivel, cod_municipio, anio, grupo order by sum(importe_eur) desc) as rn
        from base
        group by 1, 2, 3, 4, 5, 6
    )
    group by 1, 2, 3, 4, 5
),

tot as (
    select cod_ccaa, nivel, cod_municipio, anio, sum(importe_eur) as total_medios_eur
    from agg group by 1, 2, 3, 4
),

pob_ccaa as (
    select cod, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }} where nivel = 'ccaa' and sexo = 'Total'
),

pob_mun as (
    select cod_mun, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_municipios') }} where sexo = 'Total'
),

rango as (
    select (select min(anio) from pob_ccaa) as cmin, (select max(anio) from pob_ccaa) as cmax,
        (select min(anio) from pob_mun) as mmin, (select max(anio) from pob_mun) as mmax
),

ranking as (
    select a.*,
        t.total_medios_eur,
        row_number() over (partition by a.cod_ccaa, a.nivel, a.cod_municipio, a.anio order by a.importe_eur desc) as rango
    from agg a
    join tot t using (cod_ccaa, nivel, cod_municipio, anio)
)

select
    r.cod_ccaa,
    tc.nombre as comunidad,
    r.nivel,
    nullif(r.cod_municipio, '') as cod_municipio,
    case when r.nivel = 'local' then case r.cod_municipio when '28079' then 'Madrid' when '08019' then 'Barcelona'
        else r.cod_municipio end else tc.nombre end as territorio,
    r.anio,
    cast(r.rango as integer) as rango,
    r.grupo,
    coalesce(r.tipo_grupo, 'sin clasificar') as tipo_grupo,
    r.es_medio_publico,
    cast(r.n_medios as integer) as n_medios,
    tm.medios_principales,
    r.importe_eur * d.factor as importe_eur_real,
    r.importe_eur * d.factor / (case when r.nivel = 'local' then pm.poblacion else pc.poblacion end) as eur_hab_real,
    100.0 * r.importe_eur / nullif(r.total_medios_eur, 0) as pct_medios,
    r.importe_eur as importe_eur_nominal,
    r.importe_empresas_eur as importe_empresas_publicas_eur_nominal,
    r.total_medios_eur as total_medios_eur_nominal,
    r.iva_incluido,
    r.base,
    case
        when r.cod_ccaa in ('15', '16') then 'Desglose por medio que no cruza con el organismo pagador (Navarra: tablas por tipo de medio; País Vasco: suma de las campañas del año en gobiernovasco.marketing).'
        when r.cod_ccaa = '14' then 'Contratos de Murcia: el «medio» puede agrupar varios soportes de un mismo contrato.'
        when r.cod_ccaa = '10' then 'Comunitat Valenciana: nombres de medio extraídos de PDF; algunos pueden venir partidos o unidos.'
        when r.cod_ccaa = '09' and r.nivel = 'autonomico' then 'Cataluña: el soporte digital lleva un punto final («ARA.», «LAVANGUARDIA.»); se agrupa por la tabla de equivalencias.'
        else null
    end as nota
from ranking r
cross join rango rg
join {{ ref('territorios_ccaa') }} tc on tc.cod_ccaa = r.cod_ccaa
left join pob_ccaa pc on r.nivel = 'autonomico' and pc.cod = r.cod_ccaa
    and pc.anio = greatest(least(r.anio, rg.cmax), rg.cmin)
left join pob_mun pm on r.nivel = 'local' and pm.cod_mun = r.cod_municipio
    and pm.anio = greatest(least(r.anio, rg.mmax), rg.mmin)
left join {{ ref('deflactor') }} d on d.anio = r.anio
left join top_medios tm on tm.cod_ccaa = r.cod_ccaa and tm.nivel = r.nivel
    and tm.cod_municipio = r.cod_municipio and tm.anio = r.anio and tm.grupo = r.grupo
where r.rango <= 100
order by r.cod_ccaa, r.nivel, r.cod_municipio, r.anio, r.rango
