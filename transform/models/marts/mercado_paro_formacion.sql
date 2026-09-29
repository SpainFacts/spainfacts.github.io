-- Tasa de paro por nivel de formación alcanzado y sexo, población de 16 y más
-- años, media anual desde 2014 (INE, EPA, tabla 66000). orden: de menor a
-- mayor nivel de estudios; nivel_corto para las gráficas.
with base as (
    select
        cast(anyo as integer) as anio,
        string_split(rtrim(serie, '. '), '. ') as partes,
        valor
    from {{ source('raw_mercado', 'ine_epa_paro_formacion') }}
    where valor is not null
)

select
    anio,
    partes[3] as sexo,
    partes[5] as nivel,
    case partes[5]
        when 'Total' then 'Total'
        when 'Analfabetos' then 'Sin estudios'
        when 'Estudios primarios incompletos' then 'Primaria incompleta'
        when 'Educación primaria' then 'Primaria'
        when 'Primera etapa de Educación Secundaria y similar' then 'ESO o similar'
        when 'Segunda etapa de educación secundaria, con orientación general' then 'Bachillerato'
        when 'Segunda etapa de educación secundaria con orientación profesional (incluye educación postsecundaria no superior)' then 'FP de grado medio'
        when 'Educación superior' then 'Estudios superiores'
    end as nivel_corto,
    case partes[5]
        when 'Total' then 0
        when 'Analfabetos' then 1
        when 'Estudios primarios incompletos' then 2
        when 'Educación primaria' then 3
        when 'Primera etapa de Educación Secundaria y similar' then 4
        when 'Segunda etapa de educación secundaria, con orientación general' then 5
        when 'Segunda etapa de educación secundaria con orientación profesional (incluye educación postsecundaria no superior)' then 6
        when 'Educación superior' then 7
    end as orden,
    valor as tasa_paro
from base
where partes[4] = '16 y más años'
