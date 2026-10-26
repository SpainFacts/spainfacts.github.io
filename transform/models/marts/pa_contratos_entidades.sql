{{ config(materialized='ephemeral') }}
-- Base común de los tres indicadores de contratación del índice propio de
-- publicidad activa (pa_ind_contratos_adjudicacion, _formalizacion, _menores).
-- Ver docs/elaboracion-propia/contratos.md.
--
-- 1. De órgano a entidad: suma de los órganos atribuidos a cada entidad
--    (ingestion/pa_contratos.py ya atribuye cada órgano por su NIF/DIR3) y
--    mediana exacta a partir de los histogramas de días de cada órgano.
-- 2. Cataluña sale solo de la PSCP (sus entidades no publican en PLACSP y la
--    agregación de PLACSP duplica la PSCP sin fecha de adjudicación ni menores);
--    el resto, solo de PLACSP.
-- 3. Universo completo por año: todos los ayuntamientos del padrón (Ceuta y
--    Melilla como comunidad autónoma), las 41 diputaciones (38 provinciales y 3
--    forales), los 11 cabildos y consells y las 19 comunidades y ciudades
--    autónomas, cruzado con las tres obligaciones.
-- 4. aplica_indicador = false:
--    - País Vasco y Navarra (forales): no publican en PLACSP (plataformas propias
--      KontratazioA y Portal de Contratación de Navarra, no cubiertas todavía).
--    - Comunidades con plataforma propia agregada a PLACSP (Andalucía, Galicia,
--      Madrid, La Rioja): la agregación no trae fecha de adjudicación ni menores,
--      así que su adjudicación y sus menores no se pueden medir; la formalización sí.
--    - Entidades locales cuyos anuncios llegan solo por una plataforma agregada
--      (no tienen perfil ni menores en PLACSP ese año): mismo motivo.
--    - Consell Insular de Formentera: es también el ayuntamiento (07024).
--    - 2018: año de entrada en vigor de la LCSP (9-mar-2018); expedientes anteriores
--      se rigen por el TRLCSP (DT 1ª). La serie comparable empieza en 2019.
--    - 2020: plazos suspendidos por el estado de alarma (DA 3ª RD 463/2020).
--    - Cataluña antes de 2022 (menores, antes de 2023): la PSCP está incompleta.

with src as (
    select
        o.*,
        case
            when o.tipo_entidad = 'Ayuntamiento' then substr(o.cod_entidad, 1, 2)
            when o.tipo_entidad in ('Diputación provincial', 'Cabildo o consell insular') then substr(o.cod_entidad, 2, 2)
        end as cod_prov_e
    from {{ source('raw_pa_contratos', 'pa_contratos_organos') }} o
),

provincias as (
    select cod as cod_prov, cod_ccaa, nombre from {{ ref('territorios') }} where nivel = 'provincia'
),

con_ccaa as (
    select s.*,
        coalesce(p.cod_ccaa, case when s.tipo_entidad = 'Comunidad autónoma' then substr(s.cod_entidad, 2, 2) end) as cod_ccaa_e
    from src s
    left join provincias p on p.cod_prov = s.cod_prov_e
),

filtrado as (
    select * from con_ccaa
    where (fuente = 'pscp') = (cod_ccaa_e = '09')
),

hist as (
    select f.obligacion, f.cod_entidad, cast(f.anio as integer) as anio,
        cast(split_part(x.par, ':', 1) as integer) as dias,
        cast(split_part(x.par, ':', 2) as bigint) as n
    from filtrado f, unnest(string_split(f.dias_hist, ',')) as x(par)
    where f.dias_hist is not null and f.dias_hist <> ''
),

hist_entidad as (
    select obligacion, cod_entidad, anio, dias, sum(n) as n from hist group by all
),

acumulado as (
    select *,
        sum(n) over (partition by obligacion, cod_entidad, anio order by dias rows between unbounded preceding and current row) as acum,
        sum(n) over (partition by obligacion, cod_entidad, anio) as tot
    from hist_entidad
),

-- mediana como median(): media de los elementos centrales (posiciones 0-based
-- (tot-1)//2 y tot//2)
mediana as (
    select obligacion, cod_entidad, anio,
        (min(dias) filter (where acum > (tot - 1) // 2) + min(dias) filter (where acum > tot // 2)) / 2.0 as mediana_dias
    from acumulado
    group by all
),

agregado as (
    select
        obligacion, cod_entidad, cast(anio as integer) as anio,
        any_value(tipo_entidad) as tipo_entidad,
        sum(n_total) as n_total,
        sum(n_fuera_plazo) as n_fuera_plazo,
        sum(n_sin_anuncio) as n_sin_anuncio,
        sum(n_negativos) as n_negativos,
        sum(n_pendientes) as n_pendientes,
        sum(n_sin_fecha) as n_sin_fecha,
        count(distinct organo_clave) filter (where n_total > 0) as n_organos,
        max(fecha_corte) as fecha_corte,
        string_agg(distinct fuente, ',') as fuente,
        string_agg(distinct conjuntos, ',') as conjuntos
    from filtrado
    group by all
),

-- dónde publica cada entidad cada año (en cualquiera de las tres obligaciones)
presencia as (
    select cod_entidad, cast(anio as integer) as anio,
        bool_or(fuente = 'pscp' or conjuntos like '%perfiles%' or conjuntos like '%menores%') as publica_en_placsp,
        bool_or(conjuntos like '%agregadas%') as publica_en_agregada,
        -- licitaciones (adjudicación o formalización) en el perfil alojado en PLACSP o en la PSCP
        bool_or(obligacion <> 'contratos_menores' and (fuente = 'pscp' or conjuntos like '%perfiles%') and n_total > 0) as publica_en_perfil
    from filtrado
    group by all
),

cortes as (
    select fuente, max(fecha_corte) as fecha_corte, min(cast(anio as integer)) as anio_min, max(cast(anio as integer)) as anio_max
    from src group by all
),

anios as (
    select distinct cast(anio as integer) as anio from src
),

ultimo_padron as (select max(anio) as anio from {{ ref('poblacion_municipios') }}),

padron as (
    select anio, cod_mun, municipio, cod_prov, cod_ccaa, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total'
),

islas (cod_entidad, nombre, cod_prov) as (
    values
        ('I07001', 'Consell Insular de Formentera', '07'),
        ('I07006', 'Consell Insular d''Eivissa', '07'),
        ('I07008', 'Consell Insular de Mallorca', '07'),
        ('I07009', 'Consell Insular de Menorca', '07'),
        ('I35002', 'Cabildo Insular de Fuerteventura', '35'),
        ('I35004', 'Cabildo Insular de Gran Canaria', '35'),
        ('I35007', 'Cabildo Insular de Lanzarote y La Graciosa', '35'),
        ('I38003', 'Cabildo Insular de La Gomera', '38'),
        ('I38005', 'Cabildo Insular de El Hierro', '38'),
        ('I38010', 'Cabildo Insular de La Palma', '38'),
        ('I38011', 'Cabildo Insular de Tenerife', '38')
),

entidades as (
    -- ayuntamientos (Ceuta y Melilla van como comunidad autónoma)
    select a.anio, 'Ayuntamiento' as tipo_entidad, p.cod_mun as cod_entidad, p.municipio as nombre_entidad,
        p.cod_mun, p.cod_prov, p.cod_ccaa, p.poblacion
    from anios a
    join padron p on p.anio = least(a.anio, (select anio from ultimo_padron))
    where p.cod_prov not in ('51', '52')
    union all
    select a.anio, 'Diputación provincial', 'D' || pr.cod_prov,
        case when pr.cod_prov in ('01', '20', '48') then 'Diputación Foral de ' else 'Diputación Provincial de ' end || pr.nombre,
        null, pr.cod_prov, pr.cod_ccaa,
        (select sum(poblacion) from padron x where x.cod_prov = pr.cod_prov and x.anio = least(a.anio, (select anio from ultimo_padron)))
    from anios a
    cross join provincias pr
    where pr.cod_prov not in ('07', '26', '28', '30', '31', '33', '35', '38', '39', '51', '52')
    union all
    select a.anio, 'Cabildo o consell insular', i.cod_entidad, i.nombre, null, i.cod_prov, pr.cod_ccaa, null
    from anios a
    cross join islas i
    join provincias pr on pr.cod_prov = i.cod_prov
    union all
    select a.anio, 'Comunidad autónoma', 'C' || c.cod, c.nombre, null, null, c.cod,
        (select sum(poblacion) from padron x where x.cod_ccaa = c.cod and x.anio = least(a.anio, (select anio from ultimo_padron)))
    from anios a
    cross join (select cod, nombre from {{ ref('territorios') }} where nivel = 'ccaa') c
),

obligaciones (obligacion, obligacion_nombre, base_legal, plazo_desc) as (
    values
        ('contratos_adjudicacion', 'Adjudicaciones publicadas en el perfil del contratante en 15 días',
         'art. 151.1 Ley 9/2017, de Contratos del Sector Público (LCSP): la adjudicación se publica en el perfil de contratante en el plazo de 15 días (naturales, DA 12ª LCSP)',
         '15 días'),
        ('contratos_formalizacion', 'Formalizaciones publicadas en el perfil del contratante en 15 días',
         'art. 154.1 LCSP: la formalización se publica en el perfil de contratante en un plazo no superior a 15 días tras el perfeccionamiento del contrato (días naturales, DA 12ª LCSP)',
         '15 días'),
        ('contratos_menores', 'Contratos menores publicados cada trimestre',
         'art. 63.4 LCSP (publicación de los contratos menores «al menos trimestralmente»); plazo de elaboración propia por analogía con el art. 154.4 LCSP: hasta el último día del mes siguiente al cierre del trimestre de adjudicación',
         'último día del mes siguiente al trimestre')
),

universo as (
    select e.*, o.*
    from entidades e cross join obligaciones o
)

select
    u.obligacion,
    u.obligacion_nombre,
    u.base_legal,
    u.tipo_entidad,
    u.cod_entidad,
    u.nombre_entidad,
    u.cod_mun,
    u.cod_prov,
    u.cod_ccaa,
    cast(u.anio as varchar) as periodo,
    u.anio,
    -- plazo del último elemento del año: 15 de enero (adjudicación, formalización) o
    -- 31 de enero (menores del cuarto trimestre) del año siguiente
    case when u.obligacion = 'contratos_menores' then make_date(u.anio + 1, 1, 31)
         else make_date(u.anio + 1, 1, 15) end as fecha_plazo,
    ap.aplica_indicador,
    ap.motivo_no_aplica,
    a.n_total,
    a.n_fuera_plazo,
    m.mediana_dias,
    ct.fecha_corte,
    a.n_sin_anuncio,
    a.n_negativos,
    a.n_pendientes,
    a.n_sin_fecha,
    a.n_organos,
    a.fuente,
    a.conjuntos,
    coalesce(pz.publica_en_placsp, false) as publica_en_placsp,
    coalesce(pz.publica_en_agregada, false) as publica_en_agregada,
    coalesce(pz.publica_en_perfil, false) as publica_en_perfil,
    cast(u.poblacion as integer) as poblacion,
    case when u.cod_ccaa = '09'
        then 'https://analisi.transparenciacatalunya.cat/Sector-P-blic/Contractaci-p-blica-a-Catalunya-publicacions-a-la-/ybgg-dgi6'
        else 'https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx'
    end as url_fuente
from universo u
left join agregado a on a.obligacion = u.obligacion and a.cod_entidad = u.cod_entidad and a.anio = u.anio
left join mediana m on m.obligacion = u.obligacion and m.cod_entidad = u.cod_entidad and m.anio = u.anio
left join presencia pz on pz.cod_entidad = u.cod_entidad and pz.anio = u.anio
left join cortes ct on ct.fuente = case when u.cod_ccaa = '09' then 'pscp' else 'placsp' end
cross join lateral (
    select
        case
            when u.anio < 2019 then false
            when u.anio = 2020 then false
            when u.cod_ccaa = '09' and (u.anio < 2022 or (u.anio < 2023 and u.obligacion = 'contratos_menores')) then false
            when u.cod_ccaa in ('15', '16') then false
            when u.cod_entidad = 'I07001' then false
            when u.obligacion in ('contratos_adjudicacion', 'contratos_menores')
                 and u.cod_entidad in ('C01', 'C12', 'C13', 'C17') then false
            when u.obligacion in ('contratos_adjudicacion', 'contratos_menores') and u.cod_ccaa <> '09'
                 and coalesce(pz.publica_en_agregada, false) and not coalesce(pz.publica_en_placsp, false) then false
            else true
        end as aplica_indicador,
        case
            when u.anio < 2019 then 'La LCSP entró en vigor el 9 de marzo de 2018 y los expedientes iniciados antes se rigen por el TRLCSP (disposición transitoria 1ª): 2018 no es comparable'
            when u.anio = 2020 then 'Estado de alarma: plazos administrativos suspendidos del 14 de marzo al 1 de junio de 2020 (DA 3ª RD 463/2020); 2020 no es comparable'
            when u.cod_ccaa = '09' and (u.anio < 2022 or (u.anio < 2023 and u.obligacion = 'contratos_menores'))
                then 'Cataluña: la PSCP solo recoge de forma completa las adjudicaciones y formalizaciones desde 2022 y los menores desde 2023'
            when u.cod_ccaa = '16' then 'País Vasco: sus entidades publican en KontratazioA (plataforma propia, no cubierta todavía), no en PLACSP'
            when u.cod_ccaa = '15' then 'Navarra: sus entidades publican en el Portal de Contratación de Navarra (no cubierto todavía), no en PLACSP'
            when u.cod_entidad = 'I07001' then 'El Consell Insular de Formentera es también el ayuntamiento: se mide como Ayuntamiento de Formentera (07024)'
            when u.obligacion in ('contratos_adjudicacion', 'contratos_menores')
                 and u.cod_entidad in ('C01', 'C12', 'C13', 'C17')
                then 'Plataforma autonómica propia agregada a PLACSP: la agregación no trae la fecha de adjudicación ni los contratos menores'
            when u.obligacion in ('contratos_adjudicacion', 'contratos_menores') and u.cod_ccaa <> '09'
                 and coalesce(pz.publica_en_agregada, false) and not coalesce(pz.publica_en_placsp, false)
                then 'Publica en una plataforma autonómica agregada a PLACSP, que no trae la fecha de adjudicación ni los contratos menores'
        end as motivo_no_aplica
) ap
