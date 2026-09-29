-- Modelo largo de métricas: una fila por (metrica_id, periodo).
-- Lo consumen la tabla /varios/indicadores/ y las fichas de indicador.
-- metricas_base trae las series originales; cada metricas_<seccion>.sql las de su apartado.

select * from {{ ref('metricas_base') }}
union all by name
select * from {{ ref('metricas_economia') }}
union all by name
select * from {{ ref('metricas_sociedad') }}
union all by name
select * from {{ ref('metricas_energia') }}
union all by name
select * from {{ ref('metricas_vivienda_cuentas') }}
