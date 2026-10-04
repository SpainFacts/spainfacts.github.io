-- Confianza en cada tipo de medio en la UE (Eurobarómetro Standard, Comisión
-- Europea): % que «tiende a confiar» en la prensa escrita, la radio, la
-- televisión, internet y las redes sociales online, por país y oleada (raw
-- eurobarometro_confianza_medios, extraído del anexo de datos en PDF de cada
-- oleada que incluye la pregunta: otoño de 2014 a otoño de 2025, sin 2022-23).
-- anio = año de inicio del trabajo de campo. media_ue = fila EU27/EU28 del
-- propio Eurobarómetro (media ponderada por población; EU28 hasta 2019).
-- puesto_ue: posición entre los Estados miembros de la UE de esa oleada
-- (1 = más confianza; el Reino Unido cuenta hasta 2019). En la oleada 102
-- (otoño 2024) faltan las redes sociales. Entre la oleada 96 (invierno
-- 2021-22) y la 102 (otoño 2024) la confianza sube en casi todos los países a
-- la vez; el anexo de la 102 se compara con noviembre de 2019, no con 2022.
with base as (
    select cast(oleada as integer) as oleada, referencia,
        cast(substr(cast(inicio_campo as varchar), 1, 4) as integer) as anio,
        cast(inicio_campo as date) as inicio_campo,
        medio, pais, confia, no_confia, ns_nc
    from {{ source('raw_medios_confianza', 'eurobarometro_confianza_medios') }}
),

ue as (
    select oleada, medio, max(confia) as media_ue
    from base where pais in ('EU27', 'EU28')
    group by 1, 2
),

paises as (
    select b.*, p.nombre_es,
        (b.pais = 'UK' and b.anio <= 2019) or coalesce(p.ue, false) as miembro
    from base b
    left join {{ ref('medios_confianza_paises_dnr') }} p on p.iso2 = b.pais
    where b.pais not in ('EU27', 'EU28')
)

select p.oleada, p.referencia, p.anio, p.inicio_campo,
    case p.medio when 'prensa' then 'Prensa escrita' when 'radio' then 'Radio' when 'television' then 'Televisión'
        when 'internet' then 'Internet' when 'redes_sociales' then 'Redes sociales' end as medio,
    p.pais as iso2, p.nombre_es as pais, p.miembro as ue,
    p.confia, p.no_confia, p.ns_nc, u.media_ue,
    case when p.miembro then cast(rank() over (partition by p.oleada, p.medio, p.miembro order by p.confia desc) as integer) end as puesto_ue,
    cast(count(*) filter (where p.miembro) over (partition by p.oleada, p.medio) as integer) as paises_ue
from paises p
left join ue u on u.oleada = p.oleada and u.medio = p.medio
order by p.oleada, p.medio, p.confia desc
