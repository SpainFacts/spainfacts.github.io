-- Candidaturas de cada proceso electoral (Ministerio del Interior, fichero 03 del
-- área de descargas de infoelectoral) con su familia política y bloque.
--
-- clave: siglas en mayúsculas, sin tildes y con los signos cambiados por espacios
-- (la misma normalización que stg_alcaldes / partidos_familias); si todas las
-- palabras son de una letra se juntan ('P.S.O.E.' -> 'PSOE', 'E.A.J.-P.N.V.' -> 'EAJPNV').
-- siglas: las del fichero salvo en ese caso, en que se usan juntas ('P.P.' -> 'PP');
-- siglas_originales conserva el texto de Interior.
-- Familia: primera regla del seed elecciones_partidos_reglas (por `orden`) cuya expresión
-- regular casa con la clave y cuyo tipo/años incluyen el proceso; si ninguna casa,
-- la etiqueta exacta del seed partidos_familias (fila genérica, sin mandato ni
-- municipio); si tampoco, 'Otros partidos' en Congreso/Europeas e 'Independientes
-- y locales' en Municipales. Color, siglas de familia y bloque: seed elecciones_bloques.
with cand as (
    select
        proceso,
        tipo,
        cast(anio as integer) as anio,
        cod_candidatura,
        siglas,
        denominacion,
        cod_acum_provincial,
        cod_acum_autonomico,
        cod_acum_nacional,
        trim(regexp_replace(upper(strip_accents(coalesce(siglas, ''))), '[^A-Z0-9]+', ' ', 'g')) as clave0
    from {{ source('raw_elecciones', 'elecciones_candidaturas') }}
),

claves as (
    select
        *,
        case
            when regexp_matches(clave0, '^([A-Z0-9] )+[A-Z0-9]$') then replace(clave0, ' ', '')
            else clave0
        end as clave
    from cand
),

por_regla as (
    select c.proceso, c.cod_candidatura, r.familia, r.orden
    from claves c
    join {{ ref('elecciones_partidos_reglas') }} r
        on regexp_matches(c.clave, r.patron)
        and (r.tipos is null or list_contains(string_split(r.tipos, '|'), c.tipo))
        and (r.anio_desde is null or c.anio >= r.anio_desde)
        and (r.anio_hasta is null or c.anio <= r.anio_hasta)
    qualify row_number() over (partition by c.proceso, c.cod_candidatura order by r.orden) = 1
),

alcaldes as (
    select partido_original, familia
    from {{ ref('partidos_familias') }}
    where mandato is null and cod_mun is null
),

asignada as (
    select
        c.*,
        coalesce(
            r.familia,
            a.familia,
            case when c.tipo = '04' then 'Independientes y locales' else 'Otros partidos' end
        ) as familia,
        case
            when r.familia is not null then 'regla ' || r.orden
            when a.familia is not null then 'partidos_familias'
            else 'por defecto'
        end as origen_familia
    from claves c
    left join por_regla r using (proceso, cod_candidatura)
    -- en Congreso y Europeas no se heredan las familias locales del seed de alcaldes
    left join alcaldes a
        on a.partido_original = c.clave
        and (c.tipo = '04' or a.familia not in ('Independientes y locales', 'Sin detalle en la fuente', 'Comisión gestora'))
)

select
    s.proceso,
    s.tipo,
    s.anio,
    s.cod_candidatura,
    case when s.clave <> s.clave0 then s.clave else s.siglas end as siglas,
    s.siglas as siglas_originales,
    s.denominacion,
    s.clave,
    s.cod_acum_provincial,
    s.cod_acum_autonomico,
    s.cod_acum_nacional,
    s.familia,
    b.siglas_familia,
    b.color,
    b.bloque,
    b.orden as orden_familia,
    s.origen_familia
from asignada s
left join {{ ref('elecciones_bloques') }} b on b.familia = s.familia
