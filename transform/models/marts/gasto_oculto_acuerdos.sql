-- Acuerdos del Consejo de Gobierno de la Comunidad de Madrid que convalidan gasto, modifican
-- el presupuesto o dan cuenta de contratos de emergencia: una fila por acuerdo, 2004 en adelante.
-- Fuente: referencias oficiales de cada sesión (PDF, www.comunidad.madrid/acuerdos-consejo-gobierno;
-- ingestion/gasto_oculto.py separa los acuerdos bajo el epígrafe de su consejería).
-- - tipo: convalidacion (se convalida un gasto ya hecho sin el procedimiento debido: sin
--   contrato en vigor, sin fiscalización previa o de ejercicios anteriores), modificacion_
--   presupuestaria (transferencias, generaciones, ampliaciones, suplementos, créditos
--   extraordinarios que pasan por el Consejo) y emergencia (contratos tramitados por
--   emergencia, sin licitación, de los que se da cuenta).
-- - importe_eur: primer importe en euros del texto (el del gasto convalidado o la modificación);
--   NULL si la referencia no lo cita.
-- - area: la consejería agrupada por materia (los nombres de las consejerías cambian con cada
--   gobierno); ambito_sanidad marca también los acuerdos de otras consejerías sobre el SERMAS u
--   hospitales.
-- Las referencias son un resumen oficial de prensa: no recogen siempre todos los acuerdos (la
-- Cámara de Cuentas cuenta 209 convalidaciones en 2024; ver gasto_oculto_convalidaciones).
with a as (
    select
        id_acuerdo,
        cast(fecha as date) as fecha,
        consejeria,
        tipo,
        subtipo,
        importe_eur,
        texto,
        coalesce(menciona_sermas, false) as menciona_sermas,
        coalesce(menciona_amas, false) as menciona_amas,
        coalesce(menciona_avs, false) as menciona_avs,
        coalesce(menciona_educacion, false) as menciona_educacion,
        url
    from {{ source('raw_gasto_oculto', 'gasto_oculto_cm_acuerdos') }}
    where fecha is not null
)

select
    '13' as cod_ccaa,
    'Comunidad de Madrid' as ccaa,
    id_acuerdo,
    fecha,
    cast(year(fecha) as integer) as anio,
    coalesce(consejeria, 'Sin epígrafe') as consejeria,
    case
        when strip_accents(lower(consejeria)) like '%sanidad%' then 'Sanidad'
        when strip_accents(lower(consejeria)) similar to '.*(educacion|universidad|ciencia).*' then 'Educación y universidades'
        when strip_accents(lower(consejeria)) similar to '.*(familia|asuntos sociales|politicas sociales|politica social|servicios sociales).*' then 'Servicios sociales y familia'
        when strip_accents(lower(consejeria)) similar to '.*(vivienda|transporte|infraestructura).*' then 'Vivienda, transportes e infraestructuras'
        when strip_accents(lower(consejeria)) like '%digitaliza%' then 'Digitalización'
        when strip_accents(lower(consejeria)) similar to '.*(economia|hacienda|empleo).*' then 'Economía, hacienda y empleo'
        when strip_accents(lower(consejeria)) similar to '.*(medio ambiente|agricultura|ordenacion del territorio|sostenibilidad).*' then 'Medio ambiente y agricultura'
        when strip_accents(lower(consejeria)) similar to '.*(cultura|turismo|deporte).*' then 'Cultura, turismo y deporte'
        when strip_accents(lower(consejeria)) similar to '.*(presidencia|justicia|interior|portavoc|administracion local|vicepresidencia).*' then 'Presidencia, justicia e interior'
        when consejeria is null then 'Sin epígrafe'
        else 'Otras'
    end as area,
    tipo,
    subtipo,
    importe_eur,
    importe_eur * d.factor as importe_eur_real,
    d.anio_base,
    strip_accents(lower(consejeria)) like '%sanidad%' or menciona_sermas as ambito_sanidad,
    menciona_sermas,
    menciona_amas,
    menciona_avs,
    menciona_educacion,
    texto,
    url as fuente_url
from a
left join {{ ref('deflactor') }} as d
  on d.anio = cast(year(a.fecha) as integer)
order by fecha, id_acuerdo
