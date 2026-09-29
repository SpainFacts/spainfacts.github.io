-- Censo de observatorios públicos (observatoriospublicos.es) con el nivel de la
-- administración que los crea, la comunidad cuando el ámbito la identifica y el
-- estado sin inventar: el censo solo marca como cerrados unos pocos; si no dice
-- nada, el estado es "Sin información" (no "Inactivo").
with base as (
    select
        o.nombre,
        lower(coalesce(o.ambito, 'unknown')) as ambito,
        o.anio_creacion,
        lower(cast(r.activo_texto as varchar)) as activo_texto,
        lower(coalesce(r.tipo, '')) as tipo
    from {{ ref('stg_observatorios') }} o
    left join (
        select nombre, any_value(activo_texto) as activo_texto, any_value(tipo) as tipo
        from {{ source('raw', 'observatorios_publicos') }}
        group by nombre
    ) r using (nombre)
),

-- Ámbitos que nombran un territorio -> código INE de la comunidad y nivel
territorio as (
    select * from (values
        ('andalucia', '01', 'Autonómico'), ('aragon', '02', 'Autonómico'), ('asturias', '03', 'Autonómico'),
        ('islas_baleares', '04', 'Autonómico'), ('menorca', '04', 'Provincial o insular'), ('canarias', '05', 'Autonómico'),
        ('cantabria', '06', 'Autonómico'), ('castilla_y_leon', '07', 'Autonómico'), ('castilla_la_mancha', '08', 'Autonómico'),
        ('cataluna', '09', 'Autonómico'), ('barcelona', '09', 'Provincial o insular'), ('comunidad_valenciana', '10', 'Autonómico'),
        ('extremadura', '11', 'Autonómico'), ('galicia', '12', 'Autonómico'), ('comunidad_de_madrid', '13', 'Autonómico'),
        ('region_de_murcia', '14', 'Autonómico'), ('navarra', '15', 'Autonómico'), ('pais_vasco', '16', 'Autonómico'),
        ('bizkaia', '16', 'Provincial o insular'), ('gipuzkoa', '16', 'Provincial o insular'), ('la_rioja', '17', 'Autonómico'),
        ('ceuta', '18', 'Autonómico'), ('melilla', '19', 'Autonómico')
    ) t(ambito, cod_ccaa, nivel)
)

select
    b.nombre,
    coalesce(t.nivel, case b.ambito
        when 'estatal' then 'Estatal'
        when 'autonómico' then 'Autonómico'
        when 'provincial' then 'Provincial o insular'
        when 'local' then 'Local'
        when 'municipal' then 'Local'
        else 'Sin clasificar'
    end) as nivel,
    t.cod_ccaa,
    n.nombre as comunidad,
    b.anio_creacion,
    case
        when b.activo_texto in ('si', 'sí', 'yes', 'true', '1') then 'Activo'
        when b.activo_texto in ('no', 'false', '0') then 'Inactivo'
        else 'Sin información'
    end as estado,
    case when b.tipo like 'mixto%' then 'Mixto (público-privado)' when b.tipo like 'p%blico' then 'Público' else 'Sin información' end as tipo
from base b
left join territorio t using (ambito)
left join (select distinct cod, nombre from {{ ref('territorios') }} where nivel = 'ccaa') n on n.cod = t.cod_ccaa
