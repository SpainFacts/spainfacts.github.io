-- Salario medio mensual bruto del empleo principal por decil, sector público o
-- privado y jornada, anual desde 2006 (INE, EPA, tabla 66250). El decil se
-- calcula sobre todos los asalariados: el público se concentra en los altos.
-- decil_nombre = 'Total' es la media de todos los asalariados (decil NULL); 'D1'..'D10'
-- son los deciles. salario_mensual_real en euros constantes de anio_euros.
with base as (
    select
        cast(anio as integer) as anio,
        split_part(serie, '. ', 1) as jornada,
        try_cast(split_part(serie, '. ', 4) as integer) as decil,
        case split_part(serie, '. ', 6)
            when 'Asalariado sector público' then 'Público'
            when 'Asalariado sector privado' then 'Privado'
            else 'Total'
        end as sector,
        valor as salario_mensual
    from (
        select anyo as anio, serie, valor
        from {{ source('raw_empleo', 'ine_epa_salarios_deciles') }}
        where serie like '%Total Nacional. Dato base.%Salario medio.%'
          and valor is not null
    )
)

select
    b.anio,
    b.jornada,
    b.decil,
    case when b.decil is null then 'Total' else 'D' || cast(b.decil as varchar) end as decil_nombre,
    b.sector,
    b.salario_mensual,
    b.salario_mensual * d.factor as salario_mensual_real,
    d.anio_base as anio_euros
from base b
left join {{ ref('deflactor') }} d on d.anio = b.anio
