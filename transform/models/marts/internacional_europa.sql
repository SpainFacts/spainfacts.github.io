-- España en Europa: series de Eurostat de todos los países europeos que publica (UE-27, AELC,
-- Reino Unido y candidatos) y de la UE-27 (EU27_2020) en los indicadores de ámbito 'europa'
-- del seed internacional_indicadores, en formato largo por indicador, país y año (desde
-- 1990). Mismas definiciones para todos los países (EPA/LFS, EU-SILC, cuentas nacionales,
-- PDE...), así que se comparan mejor que las del Banco Mundial. Las semestrales (precio de
-- la luz, salario mínimo) son la media de los dos semestres de cada año. cod_pais ISO
-- alfa-2 (Grecia = GR) y pais en castellano del seed paises_iso. El nombre, la unidad y el
-- sentido de cada indicador están en internacional_resumen.
select
    s.indicador_id,
    p.cod_pais,
    p.pais,
    p.es_ue,
    p.es_agregado,
    s.anio,
    cast(s.valor as double) as valor
from {{ ref('stg_internacional_series') }} s
join {{ ref('internacional_indicadores') }} c on c.ambito = 'europa' and c.indicador_id = s.indicador_id
join {{ ref('paises_iso') }} p on p.iso3 = s.cod_pais
where s.ambito = 'europa'
  and (p.es_europa or p.cod_pais = 'EU27_2020')
  and s.anio >= 1990
  and s.valor is not null
  and isfinite(s.valor)
