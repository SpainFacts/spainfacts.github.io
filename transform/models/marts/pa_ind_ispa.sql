-- Índice propio de publicidad activa: retribuciones de los cargos electos
-- facilitadas al ISPA (Información Salarial de Puestos de la Administración,
-- Secretaría de Estado de Función Pública). Ver docs/elaboracion-propia/ispa_retribuciones.md.
--
-- Una fila por ayuntamiento y año de las retribuciones (todos los municipios
-- del padrón de ese año; Ceuta y Melilla como Comunidad autónoma C18/C19).
--   no_consta  figura en «ayuntamientos_sin_remitir.xlsx» de esa edición (última
--              foto guardada). x_marca: remitida_sin_firma «(*)» / informacion_dudosa «(**)».
--   consta     no figura en el listado.
--   no_aplica  Navarra: remite por la plataforma ISPA Navarra (procedimiento especial
--              acordado en la Comisión Coordinadora del Convenio Económico), que no
--              entra en el listado estatal.
-- El listado no trae código INE: se casa por nombre + provincia (claves de
-- pa_nombres.sql) y, si hay varios candidatos, por la población más parecida.
-- Los nombres que no casan se ven en x_no_casados_edicion (por edición) y en
-- docs/elaboracion-propia/ispa_retribuciones.md.

with listado as (
    select *
    from {{ source('raw_pa_registros', 'ispa_sin_remitir') }}
    qualify fecha_foto = max(fecha_foto) over (partition by edicion)
),

provincias as (
    select cod as cod_prov, nombre, unnest({{ pa_claves_debiles('nombre') }}) as clave
    from {{ ref('territorios') }}
    where nivel = 'provincia'
),

listado_prov as (
    select l.*, p.cod_prov
    from listado l
    left join (
        select distinct l2.provincia_nombre, p.cod_prov
        from (select distinct provincia_nombre from listado) l2
        join provincias p on list_contains({{ pa_claves_debiles('l2.provincia_nombre') }}, p.clave)
    ) p using (provincia_nombre)
),

ultimo_padron as (select max(anio) as anio from {{ ref('poblacion_municipios') }}),

municipios as (
    select p.anio, p.cod_mun, p.municipio, p.cod_prov, p.cod_ccaa, p.poblacion
    from {{ ref('poblacion_municipios') }} p
    where p.sexo = 'Total'
),

anios as (
    select distinct edicion, anio_retribuciones,
        least(anio_retribuciones, (select anio from ultimo_padron)) as anio_padron
    from listado
),

universo as (
    select a.edicion, a.anio_retribuciones, m.*
    from anios a
    join municipios m on m.anio = a.anio_padron
),

-- Municipios renombrados que el ISPA sigue listando con el nombre antiguo
-- (revisados a mano, ver docs/elaboracion-propia/ispa_retribuciones.md)
alias (cod_prov, nombre_ispa, cod_mun) as (
    values
        ('46', 'Algimia de Alfara', '46030'),
        ('46', 'Benisanó', '46067'),
        ('46', 'Benisuera', '46069'),
        ('46', 'Villanueva de Castellón', '46257'),
        ('08', 'Bigues i Riells', '08023'),
        ('17', 'Brunyola', '17028'),
        ('17', 'Calonge', '17034'),
        ('17', 'Castell-Platja d''Aro', '17048'),
        ('17', 'Masarac', '17100'),
        ('24', 'Candín', '24036'),
        ('06', 'Guadiana del Caudillo', '06903'),
        ('10', 'Higuera', '10097'),
        ('50', 'Jarque', '50130'),
        ('26', 'Lumbreras', '26091'),
        ('40', 'Pradales', '40161'),
        ('09', 'Santa María Rivarredonda', '09353'),
        ('22', 'Torla', '22230'),
        ('48', 'Sopelana', '48085'),
        ('48', 'Arrankudiaga', '48009')
),

-- candidatos por alias (score -1), clave fuerte (0) o débil (1)
candidatos as (
    select l.edicion, l.provincia_nombre, l.municipio_nombre, l.poblacion_fichero,
        u.cod_mun, u.poblacion, -1 as score
    from listado_prov l
    join alias a on a.cod_prov = l.cod_prov and {{ pa_clave('a.nombre_ispa') }} = {{ pa_clave('l.municipio_nombre') }}
    join universo u on u.edicion = l.edicion and u.cod_mun = a.cod_mun
    union all
    select l.edicion, l.provincia_nombre, l.municipio_nombre, l.poblacion_fichero,
        u.cod_mun, u.poblacion, 0 as score
    from listado_prov l
    join universo u
      on u.edicion = l.edicion and u.cod_prov = l.cod_prov
     and len(list_intersect({{ pa_claves_fuertes('l.municipio_nombre') }}, {{ pa_claves_fuertes('u.municipio') }})) > 0
    union all
    select l.edicion, l.provincia_nombre, l.municipio_nombre, l.poblacion_fichero,
        u.cod_mun, u.poblacion, 1 as score
    from listado_prov l
    join universo u
      on u.edicion = l.edicion and u.cod_prov = l.cod_prov
     and len(list_intersect({{ pa_claves_debiles('l.municipio_nombre') }}, {{ pa_claves_debiles('u.municipio') }})) > 0
),

casados as (
    select *
    from candidatos
    qualify row_number() over (
        partition by edicion, provincia_nombre, municipio_nombre
        order by score, abs(coalesce(poblacion_fichero, poblacion) - poblacion), cod_mun
    ) = 1
),

listado_casado as (
    select l.*, c.cod_mun, c.score as score_casado
    from listado_prov l
    left join casados c using (edicion, provincia_nombre, municipio_nombre)
),

-- un municipio casado dos veces (dos filas del listado) cuenta una vez
por_municipio as (
    select edicion, cod_mun,
        min(fecha_foto) as fecha_foto,
        -- si alguna fila no trae marca, el ayuntamiento está sin remitir sin matiz
        case when bool_or(marca is null) then null else min(marca) end as marca,
        min(municipio_nombre) as nombre_ispa,
        max(url_fuente) as url_fuente
    from listado_casado
    where cod_mun is not null
    group by all
),

no_casados as (
    select edicion, count(*) as n
    from listado_casado
    where cod_mun is null
    group by all
),

fotos as (
    select edicion, max(fecha_foto) as fecha_foto, max(url_fuente) as url_fuente, count(*) as n_listado
    from listado group by all
),

base as (
    select
        u.*,
        f.fecha_foto,
        f.url_fuente,
        f.n_listado,
        coalesce(nc.n, 0) as n_no_casados,
        pm.cod_mun is not null as listado,
        pm.marca,
        pm.nombre_ispa
    from universo u
    join fotos f using (edicion)
    left join por_municipio pm on pm.edicion = u.edicion and pm.cod_mun = u.cod_mun
    left join no_casados nc on nc.edicion = u.edicion
)

select
    'ispa_retribuciones' as obligacion,
    'Retribuciones de los cargos electos facilitadas al ISPA' as obligacion_nombre,
    'DA 3ª Real Decreto-ley 20/2012; art. 7.4.d Orden HAP/2105/2012 (redacción de la Orden HAP/2082/2014); plazo de las instrucciones anuales de ISPA (30 de abril)' as base_legal,
    case when cod_prov in ('51', '52') then 'Comunidad autónoma' else 'Ayuntamiento' end as tipo_entidad,
    case cod_prov when '51' then 'C18' when '52' then 'C19' else cod_mun end as cod_entidad,
    municipio as nombre_entidad,
    case when cod_prov in ('51', '52') then null else cod_mun end as cod_mun,
    cod_prov,
    cod_ccaa,
    cast(anio_retribuciones as varchar) as periodo,
    cast(anio_retribuciones as integer) as anio,
    make_date(cast(anio_retribuciones as integer) + 1, 4, 30) as fecha_plazo,
    case
        when cod_prov = '31' then 'no_aplica'
        when listado then 'no_consta'
        else 'consta'
    end as estado,
    cast(null as integer) as dias_retraso,
    cast(null as integer) as n_total,
    cast(null as integer) as n_fuera_plazo,
    cast(null as double) as mediana_dias,
    cod_prov <> '31' as aplica_indicador,
    case when cod_prov = '31' then 'Navarra: las entidades locales remiten por la plataforma ISPA Navarra, fuera del listado estatal' end as motivo_no_aplica,
    cast(poblacion as integer) as poblacion,
    url_fuente,
    -- extras
    cast(edicion as integer) as x_edicion_ispa,
    fecha_foto as x_fecha_foto,
    marca as x_marca,
    nombre_ispa as x_nombre_ispa,
    cast(n_listado as integer) as x_n_listado_edicion,
    cast(n_no_casados as integer) as x_no_casados_edicion,
    'ispa_retribuciones-' || case cod_prov when '51' then 'C18' when '52' then 'C19' else cod_mun end
        || '-' || cast(anio_retribuciones as varchar) as clave
from base
