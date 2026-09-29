-- Resultado nacional de cada candidatura en el Congreso y el Parlamento Europeo
-- (Ministerio del Interior, infoelectoral, ficheros 07/08), agrupando las listas
-- provinciales por su cabecera de acumulación nacional (PSC-PSOE en PSOE, etc.).
--   pct               votos / votos válidos (candidaturas + blanco), en %
--   pct_escanos       escaños / escaños repartidos (350 en el Congreso), en %
--   votos_por_escano  votos de la candidatura / escaños obtenidos (null sin escaños)
--   ventaja           pct_escanos - pct: puntos de escaños por encima (o debajo) de su
--                     porcentaje de voto; mide cuánto le favorece el sistema electoral
-- Solo candidaturas con al menos un 0,1 % de los votos válidos o algún escaño.
with votos as (
    select * from {{ ref('elecciones_votos_territorio') }}
    where nivel = 'pais' and tipo in ('02', '07')
),

tot as (
    select proceso, validos, escanos as escanos_total, fecha, tipo_nombre
    from {{ ref('elecciones_participacion') }}
    where nivel = 'pais'
)

select
    v.proceso,
    v.tipo,
    t.tipo_nombre,
    v.anio,
    t.fecha,
    v.cod_candidatura,
    v.siglas,
    v.denominacion,
    v.familia,
    v.siglas_familia,
    v.color,
    v.bloque,
    v.orden_familia,
    v.votos,
    100.0 * v.votos / nullif(t.validos, 0) as pct,
    v.escanos,
    100.0 * v.escanos / nullif(t.escanos_total, 0) as pct_escanos,
    case when v.escanos > 0 then v.votos::double / v.escanos end as votos_por_escano,
    100.0 * v.escanos / nullif(t.escanos_total, 0) - 100.0 * v.votos / nullif(t.validos, 0) as ventaja
from votos v
join tot t using (proceso)
where v.escanos > 0 or v.votos >= 0.001 * t.validos
