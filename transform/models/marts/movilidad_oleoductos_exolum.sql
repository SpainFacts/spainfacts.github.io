-- Red de oleoductos de Exolum por año (seed de los informes de la CNMC): combustible que sale de
-- sus almacenes, en total y por habitante, transporte y reparto entre oleoducto, barco y camión.
select
    e.anio,
    e.salidas_mm3,
    e.salidas_carburantes_mm3,
    1e6 * e.salidas_mm3 * 1000 / nullif(h.poblacion, 0) as salidas_litros_hab,
    e.transporte as transporte_mt,
    e.oleoducto_pct,
    e.buque_pct,
    e.camion_pct,
    e.red_km,
    e.distancia_media_oleoducto_km,
    e.fuente_url
from {{ ref('oleoductos_exolum_cnmc') }} e
left join {{ ref('poblacion_territorios') }} h
    on h.anio = e.anio and h.nivel = 'pais' and h.sexo = 'Total'
