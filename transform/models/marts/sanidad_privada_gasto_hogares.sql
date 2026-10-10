-- Lo que pagan los hogares de su bolsillo en salud (medicamentos y productos sanitarios, consultas,
-- dentista, óptica, hospital, seguros médicos no: van en otro grupo) por comunidad: INE, Encuesta de
-- Presupuestos Familiares, grupo de gasto 06 «Sanidad», en euros corrientes y constantes.
--   serie_epf 'ecoicop'   tabla 73991 (clasificación actual ECOICOP), 2016-último año: la de defecto.
--   serie_epf 'base_2006' tabla 28486 (base 2006), 2006-2023. Las dos se solapan en 2016-2023 con
--             diferencias pequeñas por el cambio de clasificación y de base de población (censo
--             2021): no encadenar sin decirlo.
--   gasto_persona_eur / gasto_hogar_eur: gasto medio anual por persona y por hogar;
--   peso_gasto_pct: % del gasto total de los hogares que va a sanidad.
--   _real: con el deflactor (IPC medio anual), euros de anio_base.
with base as (
    select
        serie_epf,
        cast(cod_ccaa as varchar) as cod_ccaa,
        cast(anio as integer) as anio,
        max(case when medida = 'Gasto medio por persona' then valor end) as gasto_persona_eur,
        max(case when medida = 'Gasto medio por hogar' then valor end) as gasto_hogar_eur,
        max(case when medida = 'Distribución porcentual' then valor end) as peso_gasto_pct
    from {{ source('raw_sanidad_privada', 'ine_sp_epf') }}
    where cod_ccaa is not null and valor is not null
    group by all
)

select
    b.cod_ccaa,
    case when b.cod_ccaa = '00' then 'España' else t.nombre end as ccaa,
    b.anio,
    b.serie_epf,
    b.gasto_persona_eur,
    b.gasto_persona_eur * d.factor as gasto_persona_eur_real,
    b.gasto_hogar_eur,
    b.gasto_hogar_eur * d.factor as gasto_hogar_eur_real,
    b.peso_gasto_pct,
    d.anio_base
from base b
left join {{ ref('deflactor') }} d on d.anio = b.anio
left join {{ ref('territorios') }} t on t.nivel = 'ccaa' and t.cod = b.cod_ccaa
