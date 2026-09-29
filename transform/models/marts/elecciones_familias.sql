-- Voto y escaños por familia política en España, cada comunidad y cada provincia
-- (Ministerio del Interior, infoelectoral, ficheros 07/08; familias: seeds
-- elecciones_partidos_reglas + partidos_familias, bloques: seed elecciones_bloques).
--
-- La familia se asigna a cada candidatura provincial por sus propias siglas
-- (PSC-PSOE -> PSOE, En Comú Podem -> IU, Podemos y Sumar...) y se suma hacia arriba,
-- así que los totales de España y de cada comunidad cuadran con las provincias.
--   pct          votos / votos válidos (candidaturas + blanco), en %
--   pct_escanos  escaños / escaños repartidos, en % (null si el ámbito no reparte)
-- Se incluyen todas las familias con voto en el proceso y ámbito.
with prov as (
    select *
    from {{ ref('elecciones_votos_territorio') }}
    where nivel = 'provincia'
),

territorio as (
    select cod_prov, cod_ccaa from {{ ref('territorios_provincias') }}
),

esc_europeas as (
    select proceso, familia, sum(escanos) as escanos
    from {{ ref('elecciones_votos_territorio') }}
    where nivel = 'pais' and tipo = '07'
    group by all
),

agregado as (
    select proceso, tipo, anio, 'provincia' as nivel, v.cod, familia, sum(votos) as votos, sum(escanos) as escanos
    from prov v
    group by all
    union all
    select proceso, tipo, anio, 'ccaa', t.cod_ccaa, familia, sum(votos), sum(escanos)
    from prov v
    join territorio t on t.cod_prov = v.cod
    group by all
    union all
    select p.proceso, p.tipo, p.anio, 'pais', '00', p.familia, sum(p.votos),
        -- Europeas: los escaños solo están en el total nacional
        coalesce(any_value(e.escanos), sum(p.escanos))
    from prov p
    left join esc_europeas e on e.proceso = p.proceso and e.familia = p.familia
    group by p.proceso, p.tipo, p.anio, p.familia
),

totales as (
    select proceso, nivel, cod, validos, escanos as escanos_total
    from {{ ref('elecciones_participacion') }}
)

select
    a.proceso,
    a.tipo,
    a.anio,
    a.nivel,
    a.cod,
    a.familia,
    b.siglas_familia,
    b.color,
    b.bloque,
    b.orden as orden_familia,
    cast(a.votos as bigint) as votos,
    100.0 * a.votos / nullif(t.validos, 0) as pct,
    cast(a.escanos as integer) as escanos,
    case when t.escanos_total > 0 then 100.0 * a.escanos / t.escanos_total end as pct_escanos
from agregado a
join totales t using (proceso, nivel, cod)
left join {{ ref('elecciones_bloques') }} b on b.familia = a.familia
