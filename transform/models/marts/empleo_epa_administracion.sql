-- Asalariados del sector público por tipo de administración, trimestral desde
-- 2002 (INE, EPA, tabla 65193). Es una encuesta: incluye las empresas e
-- instituciones públicas, que el Registro Central de Personal no cuenta.
select
    date_trunc('quarter', cast(epoch_ms(fecha) + interval 12 hour as date)) as trimestre,
    case split_part(serie, '. ', 4)
        when 'Total' then 'Total'
        when 'Central' then 'Administración central'
        when 'Seguridad Social' then 'Seguridad Social'
        when 'Comunidad Autónoma' then 'Comunidades autónomas'
        when 'Local' then 'Administración local'
        when 'Empresa e Institución Pública' then 'Empresas e instituciones públicas'
        else 'Otras / no sabe'
    end as administracion,
    sum(valor * 1000) as asalariados
from {{ source('raw_empleo', 'ine_epa_asalariados_publicos') }}
where serie like 'Asalariado sector público. Ambos sexos. Total. %. Valor absoluto.%'
  and valor is not null
group by all
