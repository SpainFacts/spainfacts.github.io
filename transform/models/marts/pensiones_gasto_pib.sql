-- Gasto público en pensiones en % del PIB por país y año (Eurostat).
--   gasto_vejez_pib: gasto de las administraciones públicas (S13) en la función
--     COFOG GF1002 «Vejez» (gov_10a_exp, TE), que recoge sobre todo las pensiones
--     de jubilación;
--   gasto_supervivientes_pib: COFOG GF1003 «Supervivientes» (viudedad, orfandad);
--   gasto_vejez_supervivientes_pib: suma de ambas;
--   gasto_pensiones_seepros_pib: spr_exp_pens (SEEPROS), todas las pensiones
--     (vejez, anticipadas, parciales, incapacidad, supervivientes...).
-- es_ue: agregado de la UE-27 (EU27_2020); es_miembro_ue: país de la UE-27.
-- Eurostat publica también países del EEE y candidatos; se excluyen los agregados
-- de la zona euro y las UE antiguas. Nombres de países en español.
with nombres (geo, nombre, es_miembro_ue) as (
    values
        ('AL', 'Albania', false),
        ('AT', 'Austria', true),
        ('BA', 'Bosnia y Herzegovina', false),
        ('BE', 'Bélgica', true),
        ('BG', 'Bulgaria', true),
        ('CH', 'Suiza', false),
        ('CY', 'Chipre', true),
        ('CZ', 'Chequia', true),
        ('DE', 'Alemania', true),
        ('DK', 'Dinamarca', true),
        ('EE', 'Estonia', true),
        ('EL', 'Grecia', true),
        ('ES', 'España', true),
        ('EU27_2020', 'UE-27', false),
        ('FI', 'Finlandia', true),
        ('FR', 'Francia', true),
        ('HR', 'Croacia', true),
        ('HU', 'Hungría', true),
        ('IE', 'Irlanda', true),
        ('IS', 'Islandia', false),
        ('IT', 'Italia', true),
        ('LT', 'Lituania', true),
        ('LU', 'Luxemburgo', true),
        ('LV', 'Letonia', true),
        ('ME', 'Montenegro', false),
        ('MK', 'Macedonia del Norte', false),
        ('MT', 'Malta', true),
        ('NL', 'Países Bajos', true),
        ('NO', 'Noruega', false),
        ('PL', 'Polonia', true),
        ('PT', 'Portugal', true),
        ('RO', 'Rumanía', true),
        ('RS', 'Serbia', false),
        ('SE', 'Suecia', true),
        ('SI', 'Eslovenia', true),
        ('SK', 'Eslovaquia', true),
        ('TR', 'Turquía', false),
        ('UK', 'Reino Unido', false),
        ('XK', 'Kosovo', false)
),

cofog as (
    select
        cast(anio as integer) as anio,
        geo,
        any_value(pais) as pais,
        max(case when cofog = 'GF1002' then pc_pib end) as gasto_vejez_pib,
        max(case when cofog = 'GF1003' then pc_pib end) as gasto_supervivientes_pib,
        max(case when cofog = 'GF10' then pc_pib end) as gasto_proteccion_social_pib
    from {{ source('raw_pensiones', 'eurostat_pensiones_cofog') }}
    group by 1, 2
),

seepros as (
    select cast(anio as integer) as anio, geo, any_value(pais) as pais, max(pc_pib) as gasto_pensiones_seepros_pib
    from {{ source('raw_pensiones', 'eurostat_pensiones_gasto') }}
    group by 1, 2
)

select
    coalesce(c.anio, s.anio) as anio,
    coalesce(c.geo, s.geo) as geo,
    coalesce(n.nombre, c.pais, s.pais) as pais,
    coalesce(c.geo, s.geo) = 'EU27_2020' as es_ue,
    coalesce(n.es_miembro_ue, false) as es_miembro_ue,
    c.gasto_vejez_pib,
    c.gasto_supervivientes_pib,
    c.gasto_vejez_pib + c.gasto_supervivientes_pib as gasto_vejez_supervivientes_pib,
    c.gasto_proteccion_social_pib,
    s.gasto_pensiones_seepros_pib
from cofog c
full outer join seepros s on s.anio = c.anio and s.geo = c.geo
left join nombres n on n.geo = coalesce(c.geo, s.geo)
where coalesce(c.geo, s.geo) not like 'EA%'
  and coalesce(c.geo, s.geo) not in ('EU27', 'EU28', 'EU15', 'EU25', 'EU27_2007')
order by 2, 1
