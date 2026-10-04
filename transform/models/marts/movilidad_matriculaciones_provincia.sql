-- Turismos matriculados por mes, provincia del domicilio del vehículo, energía
-- nuevo/usado y canal (DGT, MATRABA). Las flotas (renting, alquiler) se matriculan
-- donde tienen sede, muchas en municipios con el impuesto de circulación más bajo.
-- matriculaciones_por_1000_hab es aditiva (sumar filas de un periodo da la tasa de ese
-- periodo): matriculaciones / población de la provincia (padrón del año de la fecha, el
-- último para los años sin padrón) por mil. No lleva la población para que no se sume.
-- es_flota marca los canales donde la sede del titular no es donde se usa el coche
-- (renting, alquiler y empresa); servicio_publico (taxi, VTC) no cuenta como flota.
with base as (
    select
        m.mes,
        m.cod_prov,
        p.cod_ccaa,
        p.nombre as provincia,
        m.energia,
        e.etiqueta_corta as energia_etiqueta,
        e.orden as energia_orden,
        m.nuevo_usado,
        m.canal,
        sum(m.matriculaciones) as matriculaciones
    from {{ source('raw_movilidad', 'dgt_matriculaciones') }} m
    join {{ ref('territorios_provincias') }} p on p.cod_prov = m.cod_prov
    left join {{ ref('movilidad_energias') }} e on e.energia = m.energia
    where m.grupo = 'turismo'
    group by all
),

pob as (
    select cod, anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'provincia' and sexo = 'Total'
),

ultimo as (select max(anio) as anio from pob)

select
    b.mes,
    b.cod_prov,
    b.cod_ccaa,
    b.provincia,
    c.nombre as ccaa,
    b.energia,
    b.energia_etiqueta,
    b.energia_orden,
    b.nuevo_usado,
    b.canal,
    b.canal in ('renting', 'alquiler', 'empresa') as es_flota,
    b.matriculaciones,
    1000.0 * b.matriculaciones / nullif(p.poblacion, 0) as matriculaciones_por_1000_hab
from base b
join ultimo u on true
left join pob p on p.cod = b.cod_prov and p.anio = least(cast(year(b.mes) as integer), u.anio)
left join {{ ref('territorios_ccaa') }} c on c.cod_ccaa = b.cod_ccaa
