-- Dónde se matriculan las flotas: turismos nuevos de empresas, renting y alquiler
-- (rent a car) por año y municipio del domicilio del titular, frente a su población,
-- y el impuesto de circulación (IVTM) que pagan allí frente a la capital de su
-- provincia (DGT, MATRABA; INE, padrón; Ministerio de Hacienda, tipos de gravamen).
--
-- El IVTM es municipal y cada ayuntamiento puede subir la tarifa mínima hasta el doble:
-- las flotas se domicilian en una delegación abierta en municipios con el impuesto más
-- bajo. El ahorro estimado es el del primer año de los turismos matriculados ese año, con
-- la tarifa de un turismo de 8 a 11,99 caballos fiscales (la mayoría de los coches
-- actuales) y sin bonificaciones; el coche paga el impuesto cada año que sigue allí.
-- Solo se conservan los municipios con 100 o más turismos de flota en el año.
with flota as (
    select
        cast(year(mes) as integer) as anio,
        cod_mun,
        cod_prov,
        sum(matriculaciones) filter (where canal in ('empresa', 'renting', 'alquiler')) as flota,
        sum(matriculaciones) filter (where canal = 'particular') as particulares
    from {{ source('raw_movilidad', 'dgt_matriculaciones') }}
    where grupo = 'turismo' and nuevo_usado = 'N' and cod_mun is not null
    group by all
),

nacional as (
    select anio, sum(flota) as flota_espana from flota group by anio
),

pob as (
    select cod_mun, municipio, anio, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

pob_max as (select max(anio) as anio from pob),

-- Capital de la provincia con la que se compara cada municipio (las de las provincias
-- donde se concentran las flotas; para las demás no hay comparación).
capitales(cod_prov, cod_capital) as (
    values ('28', '28079'), ('08', '08019'), ('35', '35016'), ('07', '07040'), ('29', '29067'),
           ('03', '03014'), ('12', '12040'), ('45', '45168'), ('30', '30030'), ('46', '46250')
),

ivtm as (
    select cod_mun, turismo_8_12
    from {{ ref('movilidad_ivtm_municipios') }}
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
),

ivtm_anio as (select max(anio) as anio from {{ ref('movilidad_ivtm_municipios') }})

select
    f.anio,
    f.cod_mun,
    p.municipio,
    f.cod_prov,
    pr.nombre as provincia,
    p.poblacion,
    f.flota,
    f.particulares,
    f.flota / nullif(p.poblacion, 0) as flota_por_habitante,
    100.0 * f.flota / n.flota_espana as cuota_flota_espana_pct,
    i.turismo_8_12 as ivtm_turismo,
    pc.municipio as capital,
    ic.turismo_8_12 as ivtm_turismo_capital,
    ic.turismo_8_12 - i.turismo_8_12 as ahorro_por_coche,
    f.flota * (ic.turismo_8_12 - i.turismo_8_12) as ahorro_estimado,
    (select anio from ivtm_anio) as ivtm_anio
from flota f
join nacional n using (anio)
left join pob p on p.cod_mun = f.cod_mun
    and p.anio = least(f.anio, (select anio from pob_max))
left join {{ ref('territorios_provincias') }} pr on pr.cod_prov = f.cod_prov
left join capitales c on c.cod_prov = f.cod_prov
left join pob pc on pc.cod_mun = c.cod_capital and pc.anio = (select anio from pob_max)
left join ivtm i on i.cod_mun = f.cod_mun
left join ivtm ic on ic.cod_mun = c.cod_capital
where f.flota >= 100
