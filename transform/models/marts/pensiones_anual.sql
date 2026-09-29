-- Pensiones contributivas en España por año: cuántas hay, cuánto cobran en euros
-- constantes, cuántos afiliados hay por pensión, cuánto pesa la pensión frente al
-- salario y cuánto gasta el Estado en pensiones en % del PIB.
-- Fuentes: Seguridad Social (pensiones en vigor y afiliados medios; mart
-- pensiones_territorio, fila España), INE (ETCL, mart economia_salarios_anual:
-- coste salarial medio por trabajador y mes, pagas extra prorrateadas) y Eurostat
-- (mart pensiones_gasto_pib).
-- tasa_sustitucion_aprox = pensión media de jubilación prorrateada en 12 meses
--   (x 14 / 12, porque se cobran 14 pagas) / salario medio bruto mensual, en %.
--   Es una aproximación: compara la pensión media de todos los jubilados con el
--   salario medio de hoy, no la primera pensión con el último salario de cada uno.
-- Los importes están en euros del año base del deflactor (IPC general del INE).
select
    p.anio,
    p.meses,
    p.pensiones,
    p.pensiones_jubilacion,
    p.pension_media,
    p.pension_media_jubilacion,
    p.pension_media_real,
    p.pension_media_jubilacion_real,
    p.pension_media_jubilacion_real * 14 / 12 as pension_jubilacion_prorrateada_real,
    p.poblacion,
    p.poblacion_65,
    p.pensiones_por_1000_hab,
    p.pensiones_por_100_mayores,
    p.jubilaciones_por_100_mayores,
    p.afiliados,
    p.afiliados_por_pension,
    s.salario_real,
    100.0 * (p.pension_media_jubilacion_real * 14 / 12) / s.salario_real as tasa_sustitucion_aprox,
    es.gasto_vejez_pib,
    es.gasto_vejez_supervivientes_pib,
    es.gasto_pensiones_seepros_pib,
    ue.gasto_vejez_pib as gasto_vejez_pib_ue,
    ue.gasto_vejez_supervivientes_pib as gasto_vejez_supervivientes_pib_ue,
    ue.gasto_pensiones_seepros_pib as gasto_pensiones_seepros_pib_ue,
    p.anio_euros
from {{ ref('pensiones_territorio') }} p
left join {{ ref('economia_salarios_anual') }} s
    on s.anio = p.anio and s.jornada = 'Todas' and s.sector = 'Total'
left join {{ ref('pensiones_gasto_pib') }} es on es.anio = p.anio and es.geo = 'ES'
left join {{ ref('pensiones_gasto_pib') }} ue on ue.anio = p.anio and ue.geo = 'EU27_2020'
where p.nivel = 'pais'
order by p.anio
