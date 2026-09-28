-- Salario medio mensual bruto del empleo principal por decil, sector público o
-- privado y jornada, anual desde 2006 (INE, EPA, tabla 66250). El decil se
-- calcula sobre todos los asalariados: el público se concentra en los altos.
select
    anio,
    split_part(serie, '. ', 1) as jornada,
    case split_part(serie, '. ', 4) when 'Total' then 0 else try_cast(split_part(serie, '. ', 4) as integer) end as decil,
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
