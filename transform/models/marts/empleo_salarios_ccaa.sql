-- Salario medio anual bruto por comunidad según el control de la empresa
-- (público/privado), Encuesta Cuatrienal de Estructura Salarial 2022 (INE,
-- tabla 36887). "Público" = empresas y organismos controlados por las AAPP
-- que cotizan al Régimen General: no incluye a los funcionarios de MUFACE.
with base as (
    select
        anyo as anio,
        split_part(serie, '. ', 1) as territorio,
        split_part(serie, '. ', 3) as control,
        valor
    from {{ source('raw_empleo', 'ine_ees_salarios_control') }}
    where serie like '%. Dato base. %. Total. Salario medio bruto.%'
      and valor is not null
)
select
    b.anio,
    n.cod_ccaa,
    max(valor) filter (where control = 'Control de la empresa público') as salario_publico,
    max(valor) filter (where control = 'Control de la empresa privado') as salario_privado,
    max(valor) filter (where control = 'Total') as salario_total
from base b
join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = b.territorio
group by all
