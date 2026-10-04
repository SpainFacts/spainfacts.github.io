-- Beneficiarios (personas jurídicas) de las subvenciones a medios de comunicación,
-- una fila por NIF y año de concesión. Los totales del periodo de cada beneficiario
-- (total_*, rango, forma jurídica, administraciones...) están en
-- medios_subvenciones_totales: aquí no se repiten, así que sumar esta tabla es siempre
-- correcto.
-- Fuente: BDNS (IGAE), concesiones de las convocatorias de la lista curada, y BOPV
-- para el Gobierno Vasco (medios_subvenciones_concesiones); fuente = 'bdns', 'bopv'
-- o 'bdns+bopv'. En el BOPV el NIF sale de la seed medios_subvenciones_pv_nif: los
-- beneficiarios del BOPV sin NIF identificado no aparecen aquí (sí en los agregados).
-- - Se agrupan las concesiones por NIF (mayúsculas, sin espacios); el nombre es el
--   de la concesión más reciente (la razón social cambia entre registros).
-- - Sin personas físicas (NIF enmascarado o DNI/NIE): solo cuentan en agregados.
-- - es_parcial: el último año con datos está incompleto (la BDNS solo muestra cuatro
--   años naturales).
with conc as (
    select * from {{ ref('medios_subvenciones_concesiones') }}
    where not es_persona_fisica and beneficiario_nif is not null
),

ultimo as (select max(anio) as anio_max from {{ ref('medios_subvenciones_concesiones') }}),

nombres as (
    select beneficiario_nif as nif, arg_max(beneficiario_nombre, fecha_concesion) as nombre
    from conc
    group by 1
)

select
    c.beneficiario_nif as nif,
    n.nombre,
    cast(c.anio as integer) as anio,
    c.anio = u.anio_max as es_parcial,
    sum(c.importe_eur) as importe_eur_nominal,
    sum(c.importe_eur_real) as importe_eur_real,
    cast(count(*) as integer) as n_concesiones,
    string_agg(distinct c.fuente, '+' order by c.fuente) as fuente
from conc c
join nombres n on n.nif = c.beneficiario_nif
cross join ultimo u
group by c.beneficiario_nif, n.nombre, c.anio, u.anio_max
order by c.beneficiario_nif, c.anio
