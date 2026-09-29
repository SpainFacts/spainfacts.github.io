-- Pobreza y renta por grupo de edad en España (ambos sexos), según la Encuesta
-- de Condiciones de Vida del INE: tablas 67240 (AROPE y componentes por edad,
-- desde 2014) y 76844 (renta media por persona y por unidad de consumo por
-- edad). anio = año de la encuesta; la renta es la de anio - 1 y se deflacta
-- con el IPC medio de ese año (euros de anio_base). Series sin alquiler imputado.
with arope as (
    select anyo as anio, split_part(serie, '. ', 2) as edad,
        max(valor) filter (where serie like '%(indicador AROPE)%') as arope,
        max(valor) filter (where serie like '%En riesgo de pobreza%') as tasa_pobreza,
        max(valor) filter (where serie like '%carencia material y social severa%') as carencia_severa
    from {{ source('raw_renta', 'ine_ecv_arope_edad') }}
    where valor is not null and split_part(serie, '. ', 1) = 'Ambos sexos'
    group by all
),

renta as (
    select anyo as anio, split_part(serie, '. ', 2) as edad,
        max(valor) filter (where split_part(serie, '. ', 4) = 'Renta neta media por persona') as renta_persona,
        max(valor) filter (where split_part(serie, '. ', 4) = 'Renta media por unidad de consumo') as renta_uc
    from {{ source('raw_renta', 'ine_ecv_renta_edad') }}
    where valor is not null and split_part(serie, '. ', 1) = 'Ambos sexos'
    group by all
)

select
    cast(coalesce(a.anio, r.anio) as integer) as anio,
    cast(coalesce(a.anio, r.anio) - 1 as integer) as anio_renta,
    coalesce(a.edad, r.edad) as edad,
    case coalesce(a.edad, r.edad)
        when 'Total' then 0 when 'Menores de 16 años' then 1 when 'De 16 a 29 años' then 2
        when 'De 30 a 44 años' then 3 when 'De 45 a 64 años' then 4 when '65 y más años' then 5
    end as orden,
    a.arope,
    a.tasa_pobreza,
    a.carencia_severa,
    r.renta_persona * d.factor as renta_persona_real,
    r.renta_uc * d.factor as renta_uc_real,
    d.anio_base
from arope a
full join renta r on r.anio = a.anio and r.edad = a.edad
left join {{ ref('deflactor') }} d on d.anio = coalesce(a.anio, r.anio) - 1
