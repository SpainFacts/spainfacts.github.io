-- Votos y escaños por candidatura en España, cada comunidad y cada provincia, para
-- todas las elecciones cargadas (Ministerio del Interior, infoelectoral: ficheros
-- 07/08 de ámbito superior al municipio, tabla raw.elecciones_ambitos_votos).
--
-- Se parte siempre del nivel provincial (circunscripción en el Congreso; en
-- Europeas y Municipales, agregación provincial) y se suma hacia arriba con los
-- códigos INE (los códigos de comunidad de Interior no coinciden con los del INE):
--   provincia  cada candidatura tal cual
--   ccaa       candidaturas agrupadas por su cabecera de acumulación autonómica
--   pais       candidaturas agrupadas por su cabecera de acumulación nacional
--              (p. ej. PSC-PSOE suma en PSOE; las listas provinciales de SUMAR, en SUMAR)
-- Las provincias incluyen el voto CERA (residentes en el extranjero).
-- En el Parlamento Europeo la circunscripción es única: los escaños solo figuran en
-- el registro nacional del fichero 08, que se usa para el nivel 'pais'.
-- Tabla intermedia (no se publica en Evidence): la usan elecciones_familias,
-- elecciones_participacion y elecciones_partidos.
with cand as (
    select * from {{ ref('elecciones_candidaturas') }}
),

prov as (
    select
        v.proceso,
        v.tipo,
        cast(v.anio as integer) as anio,
        v.cod_prov,
        p.cod_ccaa,
        v.cod_candidatura,
        nullif(c.cod_acum_autonomico, '000000') as acum_aut,
        nullif(c.cod_acum_nacional, '000000') as acum_nac,
        v.votos,
        v.escanos
    from {{ source('raw_elecciones', 'elecciones_ambitos_votos') }} v
    join {{ ref('territorios_provincias') }} p on p.cod_prov = v.cod_prov
    left join cand c on c.proceso = v.proceso and c.cod_candidatura = v.cod_candidatura
    where v.cod_prov <> '99' and v.distrito = '9' and v.vuelta = 1
),

escanos_nacionales as (
    select proceso, cod_candidatura, sum(escanos) as escanos
    from {{ source('raw_elecciones', 'elecciones_ambitos_votos') }}
    where tipo = '07' and cod_ccaa_mir = '99' and cod_prov = '99' and vuelta = 1
    group by all
),

niveles as (
    select proceso, tipo, anio, 'provincia' as nivel, cod_prov as cod,
        cod_candidatura, sum(votos) as votos, sum(escanos) as escanos
    from prov
    group by all
    union all
    select proceso, tipo, anio, 'ccaa', cod_ccaa,
        coalesce(acum_aut, cod_candidatura), sum(votos), sum(escanos)
    from prov
    group by all
    union all
    select p.proceso, p.tipo, p.anio, 'pais', '00',
        p.cand_nac, sum(p.votos), coalesce(any_value(e.escanos), sum(p.escanos))
    from (select *, coalesce(acum_nac, cod_candidatura) as cand_nac from prov) p
    left join escanos_nacionales e on e.proceso = p.proceso and e.cod_candidatura = p.cand_nac
    group by p.proceso, p.tipo, p.anio, p.cand_nac
)

select
    n.proceso,
    n.tipo,
    n.anio,
    n.nivel,
    n.cod,
    n.cod_candidatura,
    c.siglas,
    c.denominacion,
    c.familia,
    c.siglas_familia,
    c.color,
    c.bloque,
    c.orden_familia,
    cast(n.votos as bigint) as votos,
    cast(n.escanos as integer) as escanos
from niveles n
left join cand c on c.proceso = n.proceso and c.cod_candidatura = n.cod_candidatura
where n.votos > 0 or n.escanos > 0
