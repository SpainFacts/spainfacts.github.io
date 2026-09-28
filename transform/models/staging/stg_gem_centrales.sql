-- Unidades y fases de centrales eléctricas en España (Global Energy Monitor,
-- Global Integrated Power Tracker). Tipado, tecnología y estado en castellano.
-- La provincia (cod_prov/cod_ccaa) se asigna en la ingesta por coordenadas.
with base as (
    select
        gem_unit_phase_id,
        gem_location_id,
        plant_project_name,
        nullif(trim(plant_project_name_local), '') as plant_project_name_local,
        nullif(trim(unit_phase_name), '') as unit_phase_name,
        try_cast(capacity_mw as double) as capacity_mw,
        lower(trim(status)) as status,
        lower(trim(type)) as type,
        lower(coalesce(technology, '')) as technology,
        technology as technology_original,
        lower(coalesce(fuel_combustion_only, '')) as fuel,
        lower(coalesce(chp, '')) as chp,
        try_cast(try_cast(start_year as double) as integer) as start_year,
        try_cast(try_cast(retired_year as double) as integer) as retired_year,
        try_cast(latitude as double) as latitude,
        try_cast(longitude as double) as longitude,
        location_accuracy,
        nullif(trim(city), '') as city,
        nullif(trim(local_area_taluk_county), '') as local_area,
        nullif(trim(owner_s), '') as owner_s,
        nullif(trim(operator_s), '') as operator_s,
        nullif(trim(parent_s), '') as parent_s,
        gem_wiki_url,
        cod_prov,
        cod_ccaa,
        geo_asignacion
    from {{ source('raw_gem', 'gem_centrales') }}
),

clasificado as (
    select
        *,
        case
            when type = 'utility-scale solar' and technology like '%thermal%' then 'Solar termoeléctrica'
            when type = 'utility-scale solar' then 'Solar fotovoltaica'
            when type = 'wind' and technology like 'offshore%' then 'Eólica marina'
            when type = 'wind' then 'Eólica terrestre'
            when type = 'hydropower' and technology like '%pumped%' then 'Bombeo'
            when type = 'hydropower' then 'Hidráulica'
            when type = 'nuclear' then 'Nuclear'
            when type = 'coal' then 'Carbón'
            when type = 'bioenergy' and fuel like '%refuse%' then 'Residuos'
            when type = 'bioenergy' then 'Bioenergía'
            -- Cogeneración industrial: unidades con calor útil (chp = yes) de gas
            -- natural y menos de 150 MW. Los grandes ciclos marcados como CHP
            -- (Bahía de Bizkaia, Tarragona, Campo de Gibraltar) y los grupos
            -- insulares de fuel/gasóleo quedan en su tecnología.
            when type = 'oil/gas' and chp = 'yes' and capacity_mw < 150
                and fuel like '%natural gas%' and fuel not like '%fossil liquids%' then 'Cogeneración'
            when type = 'oil/gas' and technology = 'combined cycle' then 'Ciclo combinado'
            when type = 'oil/gas' and technology in ('gas turbine', 'iccc', 'internal combustion') then 'Turbina de gas / motores'
            when type = 'oil/gas' and technology = 'steam turbine' then 'Turbina de vapor (fuel / gas)'
            else 'Otras'
        end as tecnologia,
        case status
            when 'operating' then 'En operación'
            when 'construction' then 'En construcción'
            when 'pre-construction' then 'En tramitación'
            when 'announced' then 'Anunciada'
            when 'shelved' then 'Paralizada'
            when 'shelved - inferred 2 y' then 'Paralizada (sin noticias en 2 años)'
            when 'mothballed' then 'En reserva (hibernada)'
            when 'cancelled' then 'Cancelada'
            when 'cancelled - inferred 4 y' then 'Cancelada (sin noticias en 4 años)'
            when 'retired' then 'Retirada'
            else status
        end as estado_es,
        case
            when status = 'operating' then 'En operación'
            when status = 'construction' then 'En construcción'
            when status = 'pre-construction' then 'En tramitación'
            when status = 'announced' then 'Anunciada'
            when status like 'shelved%' or status = 'mothballed' then 'Paralizada'
            when status like 'cancelled%' then 'Cancelada'
            when status = 'retired' then 'Retirada'
        end as estado_grupo
    from base
)

select
    c.gem_unit_phase_id as id_unidad,
    c.gem_location_id as id_central,
    c.plant_project_name as nombre,
    c.plant_project_name_local as nombre_local,
    c.unit_phase_name as unidad,
    c.capacity_mw as potencia_mw,
    c.tecnologia,
    t.color,
    t.orden as orden_tecnologia,
    t.renovable,
    c.type as tipo_gem,
    c.technology_original as tecnologia_gem,
    nullif(c.fuel, '') as combustible_gem,
    c.status as estado_gem,
    c.estado_es,
    c.estado_grupo,
    case c.estado_grupo
        when 'En operación' then 1
        when 'En construcción' then 2
        when 'En tramitación' then 3
        when 'Anunciada' then 4
        when 'Paralizada' then 5
        when 'Cancelada' then 6
        when 'Retirada' then 7
    end as orden_estado,
    c.start_year as anio_inicio,
    -- En unidades retiradas es el año de cierre; en las que siguen operando,
    -- el cierre previsto (p. ej. Alcúdia 2030, nucleares no traen fecha)
    c.retired_year as anio_retiro,
    c.latitude as lat,
    c.longitude as lon,
    c.location_accuracy = 'exact' as ubicacion_exacta,
    coalesce(c.city, c.local_area) as municipio,
    c.owner_s as propietario,
    c.operator_s as operador,
    c.parent_s as matriz,
    c.gem_wiki_url as url_gem,
    c.cod_prov,
    p.nombre as provincia,
    c.cod_ccaa,
    a.nombre as ccaa,
    c.geo_asignacion
from clasificado c
left join {{ ref('tecnologias_electricas') }} t on t.tecnologia = c.tecnologia
left join {{ ref('territorios_provincias') }} p on p.cod_prov = c.cod_prov
left join {{ ref('territorios_ccaa') }} a on a.cod_ccaa = c.cod_ccaa
