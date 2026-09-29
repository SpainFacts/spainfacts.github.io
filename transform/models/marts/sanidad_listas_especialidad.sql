-- Listas de espera del SNS por especialidad (Ministerio de Sanidad, SISLE-SNS, informes
-- semestrales desde diciembre de 2013), total nacional:
--   tipo 'quirurgica': 14 especialidades quirúrgicas; pacientes en espera estructural, tasa
--                      por 1.000 hab., % con más de 6 meses y tiempo medio de espera (días).
--   tipo 'consultas':  10 especialidades de consultas externas (primera consulta); pacientes por
--                      1.000 hab., % con cita a más de 60 días y tiempo medio de espera (días).
-- Se excluye la fila TOTAL (está en sanidad_listas_espera).
select
    cast(fecha_corte as date) as fecha,
    cast(left(fecha_corte, 4) as integer) as anio,
    tipo,
    case especialidad
        when 'Angiología /Cir. Vascular' then 'Angiología y cirugía vascular'
        when 'ORL' then 'Otorrinolaringología'
        when 'C.Gral y A.Digestivo' then 'Cirugía general y digestiva'
        when 'Cirugía General y de Digestivo' then 'Cirugía general y digestiva'
        when 'Cirugía Cardiaca' then 'Cirugía cardiaca'
        when 'Cirugía Maxilofacial' then 'Cirugía maxilofacial'
        when 'Cirugía Pediátrica' then 'Cirugía pediátrica'
        when 'Cirugía Plástica' then 'Cirugía plástica'
        when 'Cirugía Torácica' then 'Cirugía torácica'
        else especialidad
    end as especialidad,
    pacientes,
    tasa_1000,
    pct_espera_larga,
    dias_medio
from {{ source('raw_sanidad', 'sanidad_sisle_especialidad') }}
where especialidad <> 'TOTAL' and fecha_corte >= '2013-12-31'
