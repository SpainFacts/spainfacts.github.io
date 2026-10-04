-- Totales de cada beneficiario (persona jurídica) de las subvenciones a medios de
-- comunicación: una fila por NIF con todo lo concedido en el periodo (2022-...), su
-- puesto, su forma jurídica y las administraciones que le conceden. El detalle por año
-- está en medios_subvenciones_beneficiarios.
-- Fuente: BDNS (IGAE), concesiones de las convocatorias de la lista curada
-- (medios_subvenciones_concesiones).
-- - Se agrupan las concesiones por NIF (mayúsculas, sin espacios); el nombre es el
--   de la concesión más reciente (la razón social cambia entre registros).
-- - Sin personas físicas (NIF enmascarado o DNI/NIE): solo cuentan en agregados.
-- - forma_juridica sale de la letra del NIF (A sociedad anónima, B limitada,
--   F cooperativa, G asociación o fundación, J sociedad civil, ...).
-- - rango = puesto por importe real total 2022-... (1 = el que más recibe).
-- - administraciones = órganos concedentes distintos (nivel2 de la BDNS:
--   ministerio, comunidad o entidad local).
with conc as (
    select * from {{ ref('medios_subvenciones_concesiones') }}
    where not es_persona_fisica and beneficiario_nif is not null
),

totales as (
    select beneficiario_nif as nif,
        arg_max(beneficiario_nombre, fecha_concesion) as nombre,
        sum(importe_eur) as total_eur_nominal,
        sum(importe_eur_real) as total_eur_real,
        count(*) as total_concesiones,
        count(distinct cod_bdns) as n_convocatorias,
        min(anio) as primer_anio,
        max(anio) as ultimo_anio,
        string_agg(distinct coalesce(concedente_nivel2, concedente_nivel1), '; ' order by coalesce(concedente_nivel2, concedente_nivel1)) as administraciones,
        count(distinct coalesce(concedente_nivel2, concedente_nivel1)) as n_administraciones,
        string_agg(distinct cod_ccaa, ',' order by cod_ccaa) as cod_ccaa_concedentes,
        string_agg(distinct tipo_ayuda, ',' order by tipo_ayuda) as tipos_ayuda
    from conc
    group by 1
)

select
    t.nif,
    t.nombre,
    case left(t.nif, 1)
        when 'A' then 'Sociedad anónima'
        when 'B' then 'Sociedad limitada'
        when 'F' then 'Cooperativa'
        when 'G' then 'Asociación o fundación'
        when 'J' then 'Sociedad civil'
        when 'E' then 'Comunidad de bienes'
        when 'V' then 'Otras sociedades'
        when 'Q' then 'Organismo público'
        when 'P' then 'Entidad local'
        when 'S' then 'Órgano de la Administración'
        when 'R' then 'Entidad religiosa'
        when 'U' then 'Unión temporal de empresas'
        when 'N' then 'Entidad extranjera'
        else 'Otra'
    end as forma_juridica,
    t.total_eur_nominal,
    t.total_eur_real,
    cast(t.total_concesiones as integer) as total_concesiones,
    cast(t.n_convocatorias as integer) as n_convocatorias,
    cast(t.primer_anio as integer) as primer_anio,
    cast(t.ultimo_anio as integer) as ultimo_anio,
    t.administraciones,
    cast(t.n_administraciones as integer) as n_administraciones,
    t.cod_ccaa_concedentes,
    t.tipos_ayuda,
    cast(dense_rank() over (order by t.total_eur_real desc, t.nif) as integer) as rango
from totales t
order by rango
