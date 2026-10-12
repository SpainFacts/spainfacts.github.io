-- España en el mundo: series de todos los países (y de los agregados Mundo, UE-27, zona euro
-- y OCDE) en los indicadores de ámbito 'mundo' del seed internacional_indicadores, en
-- formato largo por indicador, país y año (desde 1990). Fuentes: Banco Mundial (WDI), FMI
-- (deuda y saldo públicos), Our World in Data (electricidad renovable, turistas, satisfacción
-- con la vida, IDH, coches eléctricos de la AIE) y OCDE (vivienda social, pocos países).
-- cod_pais ISO alfa-2 y pais en castellano del seed paises_iso; region es la región del
-- Banco Mundial. Los agregados del Banco Mundial están ponderados (no son medias simples).
-- El nombre, la unidad y el sentido de cada indicador están en internacional_resumen.
select
    s.indicador_id,
    p.cod_pais,
    p.pais,
    nullif(p.region, '') as region,
    p.es_europa,
    p.es_ue,
    p.es_agregado,
    s.anio,
    cast(s.valor as double) as valor
from {{ ref('stg_internacional_series') }} s
join {{ ref('internacional_indicadores') }} c on c.ambito = 'mundo' and c.indicador_id = s.indicador_id
join {{ ref('paises_iso') }} p on p.iso3 = s.cod_pais
where s.ambito = 'mundo'
  and s.anio >= 1990
  and s.valor is not null
  and isfinite(s.valor)
