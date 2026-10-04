-- Resumen de cada elección en España, cada comunidad y cada provincia (Ministerio
-- del Interior, infoelectoral, ficheros 07/08): censo, participación, votos
-- blancos y nulos, candidatura más votada y fragmentación.
--
--   votantes        votos a candidaturas + en blanco + nulos
--   participacion   votantes / censo de escrutinio (incluye el CERA), en %
--   validos         votos a candidaturas + en blanco (base de los % de voto, como
--                   en los resultados oficiales)
--   nep_votos       número efectivo de partidos (Laakso-Taagepera) sobre los votos
--                   a candidaturas: 1 / suma(p_i^2)
--   nep_escanos     lo mismo sobre los escaños (solo donde se reparten escaños)
--   gallagher       índice de desproporcionalidad de Gallagher, en puntos:
--                   raíz(1/2 · suma((%votos_i - %escaños_i)^2)), con %votos sobre válidos
--   ganador_*       candidatura más votada (agrupada por su cabecera de acumulación
--                   en comunidades y España, ver elecciones_votos_territorio)
-- Los totales se suman desde las provincias (códigos INE). En Municipales los escaños
-- son concejales y las provincias incluyen los municipios de menos de 250 habitantes.
with prov as (
    select
        a.proceso,
        a.tipo,
        cast(a.anio as integer) as anio,
        a.cod_prov,
        p.cod_ccaa,
        a.censo_ine,
        a.censo_escrutinio,
        a.votos_blanco,
        a.votos_nulos,
        a.votos_candidaturas,
        a.escanos
    from {{ source('raw_elecciones', 'elecciones_ambitos') }} a
    join {{ ref('territorios_provincias') }} p on p.cod_prov = a.cod_prov
    where a.cod_prov <> '99' and a.distrito = '9' and a.vuelta = 1
),

totales as (
    select proceso, tipo, anio, 'provincia' as nivel, cod_prov as cod,
        sum(censo_ine) as censo_ine, sum(censo_escrutinio) as censo, sum(votos_blanco) as blancos,
        sum(votos_nulos) as nulos, sum(votos_candidaturas) as votos_candidaturas, sum(escanos) as escanos
    from prov group by all
    union all
    select proceso, tipo, anio, 'ccaa', cod_ccaa,
        sum(censo_ine), sum(censo_escrutinio), sum(votos_blanco), sum(votos_nulos), sum(votos_candidaturas), sum(escanos)
    from prov group by all
    union all
    select p.proceso, p.tipo, p.anio, 'pais', '00',
        sum(p.censo_ine), sum(p.censo_escrutinio), sum(p.votos_blanco), sum(p.votos_nulos), sum(p.votos_candidaturas),
        -- Europeas: circunscripción única, escaños en el registro nacional
        coalesce(any_value(n.escanos), sum(p.escanos))
    from prov p
    left join (
        select proceso, escanos
        from {{ source('raw_elecciones', 'elecciones_ambitos') }}
        where tipo = '07' and cod_ccaa_mir = '99' and cod_prov = '99' and vuelta = 1
    ) n using (proceso)
    group by p.proceso, p.tipo, p.anio
),

votos as (
    select * from {{ ref('elecciones_votos_territorio') }}
),

frag as (
    select
        v.proceso,
        v.nivel,
        v.cod,
        1.0 / nullif(sum(power(v.votos::double / nullif(t.votos_candidaturas, 0), 2)), 0) as nep_votos,
        case when max(t.escanos) > 0 then
            1.0 / nullif(sum(power(v.escanos::double / t.escanos, 2)), 0)
        end as nep_escanos,
        case when max(t.escanos) > 0 then
            sqrt(0.5 * sum(power(
                100.0 * v.votos / nullif(t.votos_candidaturas + t.blancos, 0)
                - 100.0 * v.escanos / t.escanos, 2)))
        end as gallagher,
        count(*) filter (where v.escanos > 0) as candidaturas_con_escano
    from votos v
    join totales t using (proceso, nivel, cod)
    group by all
),

ganador as (
    select proceso, nivel, cod,
        siglas as ganador_siglas,
        familia as ganador_familia,
        siglas_familia as ganador_siglas_familia,
        color as ganador_color,
        bloque as ganador_bloque,
        votos as ganador_votos,
        escanos as ganador_escanos
    from votos
    qualify row_number() over (partition by proceso, nivel, cod order by votos desc, escanos desc) = 1
),

segundo as (
    select proceso, nivel, cod, siglas as segundo_siglas, votos as segundo_votos
    from votos
    qualify row_number() over (partition by proceso, nivel, cod order by votos desc, escanos desc) = 2
),

procesos as (
    select proceso, fecha, tipo_nombre from {{ source('raw_elecciones', 'elecciones_procesos') }}
)

select
    t.proceso,
    t.tipo,
    pr.tipo_nombre,
    t.anio,
    pr.fecha,
    t.nivel,
    t.cod,
    tt.nombre,
    pr.tipo_nombre || ', ' || ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'][month(pr.fecha)] || ' de ' || year(pr.fecha) as eleccion,
    cast(t.censo_ine as bigint) as censo_ine,
    cast(t.censo as bigint) as censo,
    cast(t.blancos + t.nulos + t.votos_candidaturas as bigint) as votantes,
    100.0 * (t.blancos + t.nulos + t.votos_candidaturas) / nullif(t.censo, 0) as participacion,
    cast(t.blancos + t.votos_candidaturas as bigint) as validos,
    cast(t.blancos as bigint) as blancos,
    cast(t.nulos as bigint) as nulos,
    100.0 * t.blancos / nullif(t.blancos + t.votos_candidaturas, 0) as pct_blancos,
    100.0 * t.nulos / nullif(t.blancos + t.nulos + t.votos_candidaturas, 0) as pct_nulos,
    cast(t.votos_candidaturas as bigint) as votos_candidaturas,
    cast(t.escanos as integer) as escanos,
    f.nep_votos,
    f.nep_escanos,
    f.gallagher,
    cast(f.candidaturas_con_escano as integer) as candidaturas_con_escano,
    g.ganador_siglas,
    g.ganador_familia,
    g.ganador_siglas_familia,
    g.ganador_color,
    g.ganador_bloque,
    g.ganador_votos,
    100.0 * g.ganador_votos / nullif(t.blancos + t.votos_candidaturas, 0) as ganador_pct,
    g.ganador_escanos,
    s.segundo_siglas,
    100.0 * s.segundo_votos / nullif(t.blancos + t.votos_candidaturas, 0) as segundo_pct
from totales t
left join procesos pr using (proceso)
left join frag f using (proceso, nivel, cod)
left join ganador g using (proceso, nivel, cod)
left join segundo s using (proceso, nivel, cod)
left join {{ ref('territorios') }} tt on tt.nivel = t.nivel and tt.cod = t.cod
