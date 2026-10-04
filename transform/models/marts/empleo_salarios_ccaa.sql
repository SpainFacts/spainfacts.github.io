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
-- brecha_publico_pct = cuánto más (o menos) cobra de media el público que el privado, en %.
-- Es una sola edición (2022): no lleva euros reales. Ceuta y Melilla no las publica el INE.
select
    b.anio,
    case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
    n.cod_ccaa as cod,
    t.nombre,
    max(valor) filter (where control = 'Control de la empresa público') as salario_publico,
    max(valor) filter (where control = 'Control de la empresa privado') as salario_privado,
    max(valor) filter (where control = 'Total') as salario_total,
    100.0 * (max(valor) filter (where control = 'Control de la empresa público')
        / max(valor) filter (where control = 'Control de la empresa privado') - 1) as brecha_publico_pct
from base b
join {{ ref('ine_ccaa_nombres') }} n on n.nombre_ine = b.territorio
left join {{ ref('territorios') }} t
    on t.nivel = case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end and t.cod = n.cod_ccaa
group by all
