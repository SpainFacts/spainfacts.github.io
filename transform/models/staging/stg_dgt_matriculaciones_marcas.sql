-- Matriculaciones de vehículos NUEVOS por mes, marca y modelo con la marca resuelta
-- (DGT, MATRABA):
--   * En los vehículos de varias fases (camiones, autobuses, furgonetas camperizadas)
--     la DGT pone como marca la del carrocero que los termina (Castrosua, Tecnove...):
--     se usa la del chasis (marca_base) cuando viene informada, como hace el sector.
--   * Unifica las variantes de una misma marca ("VOLKSWAGEN, VW") y la asigna a su grupo
--     por dueño mayoritario (seed movilidad_marcas_grupos). Las filas con ámbito
--     ('pesados', 'motocicleta') mandan para ese tipo de vehículo: Volvo camiones es
--     AB Volvo y Volvo coches es Geely; Peugeot motos es Mahindra.
--   * Las marcas sin grupo en el seed son su propio grupo (Tesla, Mazda, Suzuki...).
with base as (
    select
        mes,
        grupo,
        energia,
        canal,
        trim(replace(modelo, '¡', '')) as modelo,
        coalesce(
            nullif(trim(replace(marca_base, '¡', '')), ''),
            trim(replace(marca, '¡', ''))
        ) as marca_dgt,
        case
            when grupo in ('camion', 'autobus') then 'pesados'
            when grupo = 'motocicleta' then 'motocicleta'
            else ''
        end as ambito,
        matriculaciones
    from {{ source('raw_movilidad', 'dgt_matriculaciones_modelos') }}
    where nuevo_usado = 'N'
)

select
    b.mes,
    b.grupo,
    b.energia,
    b.canal,
    coalesce(e.marca, g.marca, b.marca_dgt) as marca,
    upper(coalesce(e.grupo, g.grupo, e.marca, g.marca, b.marca_dgt)) as grupo_empresarial,
    b.modelo,
    b.matriculaciones
from base b
left join {{ ref('movilidad_marcas_grupos') }} e
    on e.marca_dgt = b.marca_dgt and e.ambito = b.ambito and b.ambito <> ''
left join {{ ref('movilidad_marcas_grupos') }} g
    on g.marca_dgt = b.marca_dgt and coalesce(g.ambito, '') = ''
where b.marca_dgt <> ''
