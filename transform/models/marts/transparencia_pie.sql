-- Retención de la participación en los tributos del Estado (PIE) por no
-- remitir información a Hacienda (art. 36 Ley 2/2011; DA 87ª Ley 22/2021).
--
-- Panel: una fila por ayuntamiento, ejercicio de referencia (anio) y sección,
-- para TODOS los ayuntamientos existentes ese año (retenido = false si no
-- aparece en ninguna lista de esa campaña), para poder calcular tasas.
-- Una "campaña" es el conjunto de listas mensuales de una sección y ejercicio
-- (p. ej. liquidación de 2021: de junio de 2023 a mayo de 2024).
--
-- Gobierno: el alcalde en funciones el día 1 del primer mes en que aparece
-- retenido (primer_mes); para los no retenidos, el día 1 del primer mes de la
-- campaña. OJO: la retención de la liquidación empieza unos 26 meses después
-- del plazo de remisión (31/03 del año siguiente), así que el alcalde al inicio
-- de la retención puede no ser el que debía remitirla.
--
-- Territorios forales (Álava, Gipuzkoa, Bizkaia y Navarra): no reciben la
-- participación en los tributos del Estado por la vía común (Concierto y
-- Convenio económicos), así que nunca figuran en las listas: aplica_indicador
-- = false. Ceuta y Melilla no son ayuntamientos (tipo ZZ) y no se incluyen.
-- campania_completa = false para la campaña ya empezada cuando arranca la
-- serie (octubre de 2016): solo se ven sus últimos meses.
with mensual as (
    select * from {{ ref('transparencia_pie_mensual') }}
    where ejercicio_referencia is not null
),

campanias as (
    select
        seccion,
        ejercicio_referencia as anio,
        min(periodo) as inicio_campania,
        max(periodo) as fin_campania,
        min(periodo) > (select min(periodo) from mensual) as campania_completa
    from mensual
    group by all
),

ultimo as (
    select max(periodo) as periodo from mensual
),

retenidos as (
    select
        cod_mun,
        seccion,
        ejercicio_referencia as anio,
        count(distinct periodo) as meses_retenido,
        min(periodo) as primer_mes,
        max(periodo) as ultimo_mes,
        sum(importe_eur) as importe_retenido_eur,
        sum(importe_eur_real) as importe_retenido_eur_real,
        bool_or(por_dependientes) as por_dependientes,
        bool_or(ejercicio_inferido) as ejercicio_inferido,
        string_agg(distinct metodo_cruce, ',') as metodo_cruce
    from mensual
    group by all
),

poblacion as (
    select anio, cod_mun, municipio, cod_prov, cod_ccaa, poblacion
    from {{ ref('poblacion_municipios') }}
    where sexo = 'Total' and cod_prov not in ('51', '52')
),

anio_max_pob as (
    select max(anio) as anio from poblacion
),

universo as (
    -- Ayuntamientos existentes en el año de referencia (o el último disponible)
    select k.seccion, k.anio, k.inicio_campania, k.fin_campania, k.campania_completa,
        p.cod_mun, p.municipio, p.cod_prov, p.cod_ccaa, p.poblacion
    from campanias k
    join poblacion p on p.anio = least(k.anio, (select anio from anio_max_pob))
),

panel as (
    select
        coalesce(u.cod_mun, r.cod_mun) as cod_mun,
        coalesce(u.seccion, r.seccion) as seccion,
        coalesce(u.anio, r.anio) as anio,
        u.municipio, u.cod_prov, u.cod_ccaa, u.poblacion,
        u.inicio_campania, u.fin_campania, u.campania_completa,
        r.cod_mun is not null as retenido,
        coalesce(r.meses_retenido, 0) as meses_retenido,
        r.primer_mes,
        r.ultimo_mes,
        r.ultimo_mes = (select periodo from ultimo) as sigue_retenido,
        r.importe_retenido_eur,
        r.importe_retenido_eur_real,
        coalesce(r.por_dependientes, false) as por_dependientes,
        r.ejercicio_inferido,
        r.metodo_cruce,
        coalesce(r.primer_mes, u.inicio_campania) as fecha_gobierno
    from universo u
    full join retenidos r
      on r.cod_mun = u.cod_mun and r.seccion = u.seccion and r.anio = u.anio
),

-- municipio/provincia/población para retenidos fuera del universo (p. ej.
-- municipios desaparecidos): los últimos datos conocidos
ultimo_conocido as (
    select cod_mun, municipio, cod_prov, cod_ccaa, poblacion
    from poblacion
    qualify row_number() over (partition by cod_mun order by anio desc) = 1
),

gobierno as (
    select
        p.cod_mun, p.seccion, p.anio,
        h.alcalde, h.partido_original, h.familia, h.color,
        row_number() over (partition by p.cod_mun, p.seccion, p.anio order by h.fecha_posesion desc) as n
    from panel p
    join {{ ref('alcaldes_historia') }} h
      on h.cod_mun = p.cod_mun
     and h.fecha_posesion <= p.fecha_gobierno
     and (h.fecha_fin is null or h.fecha_fin > p.fecha_gobierno)
),

completo as (
    select
        p.cod_mun,
        coalesce(p.municipio, c.municipio) as municipio,
        coalesce(p.cod_prov, c.cod_prov, left(p.cod_mun, 2)) as cod_prov,
        coalesce(p.cod_ccaa, c.cod_ccaa) as cod_ccaa,
        p.anio,
        p.seccion,
        coalesce(p.poblacion, c.poblacion) as poblacion,
        p.* exclude (cod_mun, municipio, cod_prov, cod_ccaa, poblacion, anio, seccion)
    from panel p
    left join ultimo_conocido c on p.municipio is null and c.cod_mun = p.cod_mun
)

select
    c.cod_mun,
    c.municipio,
    c.cod_prov,
    tp.nombre as provincia,
    c.cod_ccaa,
    tc.nombre as ccaa,
    c.anio,
    c.seccion,
    case c.seccion
        when 'liquidacion' then 'Liquidación del presupuesto'
        when 'presupuesto' then 'Presupuesto del ejercicio'
        when 'lineas_fundamentales' then 'Líneas fundamentales del presupuesto'
    end as seccion_nombre,
    c.poblacion,
    case
        when c.poblacion < 1000 then '<1.000'
        when c.poblacion < 5000 then '1.000-5.000'
        when c.poblacion < 20000 then '5.000-20.000'
        when c.poblacion < 50000 then '20.000-50.000'
        when c.poblacion < 100000 then '50.000-100.000'
        else '>100.000'
    end as tramo_poblacion,
    case
        when c.poblacion < 1000 then 1
        when c.poblacion < 5000 then 2
        when c.poblacion < 20000 then 3
        when c.poblacion < 50000 then 4
        when c.poblacion < 100000 then 5
        else 6
    end as tramo_orden,
    c.retenido,
    c.meses_retenido,
    c.primer_mes,
    c.ultimo_mes,
    coalesce(c.sigue_retenido, false) as sigue_retenido,
    c.importe_retenido_eur,
    c.importe_retenido_eur_real,
    c.importe_retenido_eur / nullif(c.poblacion, 0) as importe_retenido_eur_hab,
    c.importe_retenido_eur_real / nullif(c.poblacion, 0) as importe_retenido_eur_hab_real,
    (select max(anio_base) from {{ ref('deflactor') }}) as anio_base,
    c.por_dependientes,
    c.ejercicio_inferido,
    c.metodo_cruce,
    c.inicio_campania,
    c.fin_campania,
    coalesce(c.campania_completa, false) as campania_completa,
    c.cod_prov not in ('01', '20', '48', '31') as aplica_indicador,
    case when c.cod_prov not in ('01', '20', '48', '31') then (case when c.retenido then 100 else 0 end) end as retenido_pct,
    case when c.cod_prov in ('01', '20', '48', '31')
        then 'Régimen foral: no recibe la participación en tributos del Estado por la vía común'
    end as motivo_exclusion,
    c.fecha_gobierno,
    g.alcalde,
    g.partido_original as lista,
    coalesce(g.familia, 'Sin dato de alcalde') as familia,
    coalesce(g.color, '#9ca3af') as color_familia,
    c.cod_mun || '-' || c.anio || '-' || c.seccion as clave
from completo c
left join gobierno g
  on g.cod_mun = c.cod_mun and g.seccion = c.seccion and g.anio = c.anio and g.n = 1
left join {{ ref('territorios') }} tp on tp.nivel = 'provincia' and tp.cod = c.cod_prov
left join {{ ref('territorios') }} tc on tc.nivel = 'ccaa' and tc.cod = c.cod_ccaa
