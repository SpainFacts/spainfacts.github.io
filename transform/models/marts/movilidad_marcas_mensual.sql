-- Vehículos NUEVOS matriculados por mes, grupo, energía, canal, marca y grupo
-- empresarial (DGT, MATRABA). Marca y grupo resueltos en stg_dgt_matriculaciones_marcas.
-- Códigos con su etiqueta, como movilidad_matriculaciones_mensual.
select
    m.mes,
    cast(year(m.mes) as integer) as anio,
    m.grupo,
    g.etiqueta as grupo_etiqueta,
    m.energia,
    e.etiqueta as energia_etiqueta,
    m.canal,
    c.etiqueta as canal_etiqueta,
    m.marca,
    m.grupo_empresarial,
    sum(m.matriculaciones) as matriculaciones
from {{ ref('stg_dgt_matriculaciones_marcas') }} m
left join {{ ref('movilidad_grupos') }} g on g.grupo = m.grupo
left join {{ ref('movilidad_energias') }} e on e.energia = m.energia
left join {{ ref('movilidad_canales') }} c on c.canal = m.canal
where m.grupo in ('turismo', 'motocicleta', 'furgoneta', 'camion', 'autobus')
group by all
