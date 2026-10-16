-- Km de carretera por provincia en el último año publicado (Anuario del Ministerio de
-- Transportes): por titular y tipo de vía, por 100.000 habitantes y por 100 km² de superficie.
with km as (
    select * from {{ source('raw_carreteras', 'carreteras_longitud_provincia') }}
    where anio = (select max(anio) from {{ source('raw_carreteras', 'carreteras_longitud_provincia') }})
),

por_prov as (
    select
        cod_prov,
        any_value(anio) as anio,
        sum(km) as km_total,
        sum(km) filter (where titular = 'estado') as km_estado,
        sum(km) filter (where titular = 'comunidad') as km_comunidad,
        sum(km) filter (where titular = 'diputacion') as km_diputacion,
        sum(km) filter (where tipo in ('peaje', 'autovia', 'multicarril')) as km_gran_capacidad,
        sum(km) filter (where tipo = 'peaje') as km_peaje,
        sum(km) filter (where tipo = 'peaje' and titular = 'estado') as km_peaje_estado,
        sum(km) filter (where tipo = 'autovia') as km_autovia,
        sum(km) filter (where tipo = 'multicarril') as km_multicarril,
        sum(km) filter (where tipo = 'convencional') as km_convencional
    from km
    group by cod_prov
),

poblacion as (
    select cod as cod_prov, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'provincia' and sexo = 'Total'
    qualify row_number() over (partition by cod order by anio desc) = 1
),

-- Superficie en km² (la misma tabla que mapas_territorio)
superficie (cod_prov, km2) as (
    values
    ('01', 3029), ('02', 14940), ('03', 5818), ('04', 8770), ('05', 8046), ('06', 21764),
    ('07', 4990), ('08', 7748), ('09', 14297), ('10', 19864), ('11', 7444), ('12', 6637),
    ('13', 19814), ('14', 13785), ('15', 7965), ('16', 17136), ('17', 5904), ('18', 12650),
    ('19', 12215), ('20', 1986), ('21', 10128), ('22', 15638), ('23', 13494), ('24', 15581),
    ('25', 12156), ('26', 5051), ('27', 9853), ('28', 8027), ('29', 7308), ('30', 11328),
    ('31', 10389), ('32', 7287), ('33', 10605), ('34', 8046), ('35', 4078), ('36', 4488),
    ('37', 12348), ('38', 3379), ('39', 5345), ('40', 6930), ('41', 14024), ('42', 10305),
    ('43', 6308), ('44', 14804), ('45', 15367), ('46', 10808), ('47', 8106), ('48', 2213),
    ('49', 10569), ('50', 17284), ('51', 18), ('52', 13)
)

select
    t.cod_prov,
    t.nombre as provincia,
    t.cod_ccaa,
    k.anio,
    coalesce(k.km_total, 0) as km_total,
    coalesce(k.km_estado, 0) as km_estado,
    coalesce(k.km_comunidad, 0) as km_comunidad,
    coalesce(k.km_diputacion, 0) as km_diputacion,
    coalesce(k.km_gran_capacidad, 0) as km_gran_capacidad,
    coalesce(k.km_peaje, 0) as km_peaje,
    coalesce(k.km_peaje_estado, 0) as km_peaje_estado,
    coalesce(k.km_autovia, 0) as km_autovia,
    coalesce(k.km_multicarril, 0) as km_multicarril,
    coalesce(k.km_convencional, 0) as km_convencional,
    100.0 * k.km_peaje / nullif(k.km_gran_capacidad, 0) as peaje_pct_gran_capacidad,
    100000.0 * k.km_total / nullif(h.poblacion, 0) as km_por_100k_hab,
    100000.0 * k.km_gran_capacidad / nullif(h.poblacion, 0) as km_gran_capacidad_por_100k_hab,
    100.0 * k.km_total / nullif(s.km2, 0) as km_por_100_km2,
    100.0 * k.km_gran_capacidad / nullif(s.km2, 0) as km_gran_capacidad_por_100_km2,
    h.poblacion,
    s.km2 as superficie_km2
from {{ ref('territorios_provincias') }} t
left join por_prov k on k.cod_prov = t.cod_prov
left join poblacion h on h.cod_prov = t.cod_prov
left join superficie s on s.cod_prov = t.cod_prov
