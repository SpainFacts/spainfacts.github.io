# Plan de limpieza, lote 3 (30 tablas)

Patrones comunes que se citan abajo para no repetirlos:

- **Nombre de territorio**: `left join {{ ref('territorios') }} t on t.nivel = <nivel> and t.cod = <cod>` y se añade `nivel` + `nombre` (o `ccaa`) al lado del código. Las páginas ya hacen ese join a mano; no se rompe nada.
- **Euros reales**: `valor * d.factor` con `left join {{ ref('deflactor') }} d on d.anio = <anio>`, más `d.anio_base as anio_euros` (ejemplo: `empresas_sociedades_anual`, `industria_ccaa_ramas`).
- **Por habitante**: `poblacion_territorios` (nivel `pais`/`ccaa`, `sexo = 'Total'`, desde 1996) con `least(anio, max_anio)`; para países UE existe población en `raw_industria.eurostat_industria_poblacion` (miles, columna `pais`) y Eurostat `demo_gind` (usada en `clima_emisiones_paises`).
- **`anio` DOUBLE**: varias tablas sacan `anio` y `trimestre` como DOUBLE (se ve con DESCRIBE en `empleo_salarios_deciles` y `empresas_autonomos`). Se castea a INTEGER en el mart; las páginas ya hacen `CAST(anio AS INTEGER)`, así que es inocuo.

---

### empleo_salarios_ccaa
- **Modelo:** transform/models/marts/empleo_salarios_ccaa.sql · **Páginas:** cuentas-publicas/empleo-publico, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 2
- **Problemas:** solo `cod_ccaa` (con `00` = España mezclado con comunidades); salarios en euros corrientes de 2022 sin `anio_euros` ni versión real; la brecha público/privado se calcula en la página; faltan Ceuta y Melilla (el INE no las publica en esta serie).
- **Cambio propuesto:** añadir `nivel`, `cod`, `nombre` (territorios), `salario_*_real` y `anio_euros`, y `brecha_publico_pct`. Por habitante no aplica (son medias por asalariado).
```sql
case when n.cod_ccaa='00' then 'pais' else 'ccaa' end as nivel, n.cod_ccaa as cod, t.nombre,
max(valor) filter (where control='Control de la empresa público') * d.factor as salario_publico_real,
100.0*(max(.. público ..)/max(.. privado ..)-1) as brecha_publico_pct, d.anio_base as anio_euros
```
- **Páginas:** conservar `cod_ccaa`, `salario_publico`, `salario_privado`. empleo-publico puede pasar a `nombre` y `brecha_publico_pct` (quita un join y un cálculo, ×8 traducciones, opcional).
- **Ficha:** desaparece la nota «solo código INE / 00 es España»; el territorio pasa a `nivel`/`cod`/`nombre`.
- **Esfuerzo/riesgo:** bajo, solo se añaden columnas a una tabla de 18 filas.

### empleo_salarios_deciles
- **Modelo:** transform/models/marts/empleo_salarios_deciles.sql · **Páginas:** cuentas-publicas/empleo-publico, economia/salarios (8 traducciones) · **Prioridad:** 1
- **Problemas:** `salario_mensual` en euros corrientes (el chat compara 2006 con 2024 sin deflactar; las páginas lo deflactan a mano con `mother.deflactor` en 3 sitios); `decil = 0` es la media mezclada con los deciles 1-10; `anio` y `decil` son DOUBLE.
- **Cambio propuesto:** añadir `salario_mensual_real`, `anio_euros`, `decil_nombre` (`Media`, `D1`...`D10`) y `es_media` BOOLEAN. No hay por habitante (es salario medio).
```sql
valor * d.factor as salario_mensual_real, d.anio_base as anio_euros,
case decil when 0 then 'Media' else 'D' || cast(decil as integer) end as decil_nombre, decil = 0 as es_media
-- join deflactor d on d.anio = cast(anio as integer)
```
- **Páginas:** conservar `jornada`, `decil`, `sector`, `salario_mensual`, `anio`. empleo-publico (`brecha`, `serie_*`) y salarios.md pueden sustituir su `JOIN deflactor` por `salario_mensual_real` (opcional, ×8 traducciones cada una).
- **Ficha:** `decil` deja de tener la excepción «0 es la media» (dimensión `decil_nombre` con total `Media`); medida principal pasa a `salario_mensual_real` (campo `real` de la medida actual).
- **Esfuerzo/riesgo:** bajo, columnas nuevas sobre una tabla pequeña; riesgo nulo mientras no se retire `decil`.

### empleo_territorio
- **Modelo:** transform/models/marts/empleo_territorio.sql · **Páginas:** empleo-publico, index (portada), territorios/[ccaa]/index y [provincia] (16 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod` (provincia y comunidad comparten dígitos, hay que fijar `nivel`); `administracion = 'Total'` convive con sus partes (aceptado por la convención); falta `anio`.
- **Cambio propuesto:** añadir `nombre` y `anio`. Ya trae `por_1000_hab` y `poblacion`; no hay euros.
```sql
t.nombre, cast(year(e.fecha) as integer) as anio
-- left join {{ ref('territorios') }} t on t.nivel = e.nivel and t.cod = e.cod
```
- **Páginas:** conservar `nivel`, `cod`, `administracion`, `efectivos`, `por_1000_hab`, `fecha`. Ninguna necesita cambiar (las de territorio ya traen el nombre de otro sitio).
- **Ficha:** `territorio.nombre` pasa de null a `nombre`.
- **Esfuerzo/riesgo:** bajo, join con una dimensión de 72 filas.

### empresas_autonomos
- **Modelo:** transform/models/marts/empresas_autonomos.sql · **Páginas:** economia/empresas, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 2
- **Problemas:** `trimestre = 0` (media anual) mezclado con los trimestres 1-4, y todas las páginas filtran `trimestre = 0`; solo `cod`; `anio`/`trimestre` DOUBLE; cifras en miles de personas junto a `pct_*`.
- **Cambio propuesto:** fase 1, añadir `nivel`, `nombre`, `tipo_periodo` (`Media anual`/`Trimestre`) y `es_media_anual` BOOLEAN. Fase 2 (cuando las páginas migren), partir en `empresas_autonomos` (trimestral) y `empresas_autonomos_anual` (media). El pct ya es relativo, no hace falta por habitante.
```sql
case when trimestre = 0 then 'Media anual' else 'Trimestre' end as tipo_periodo, trimestre = 0 as es_media_anual,
case when cod='00' then 'pais' else 'ccaa' end as nivel, t.nombre
```
- **Páginas:** conservar `cod`, `anio`, `trimestre`, `periodo`, `fecha`, `pct_*`, `cuenta_propia`. Para la fase 2 las 2 páginas (×8 con traducciones) cambian `FROM` a la tabla anual y quitan `trimestre = 0`.
- **Ficha:** tras la fase 2 desaparece el filtro `trimestre distinto 0`; tras la fase 1 pasa a dimensión `tipo_periodo` con `defecto`.
- **Esfuerzo/riesgo:** bajo la fase 1, medio la fase 2 (hay que tocar páginas y traducciones).

### empresas_concursos
- **Modelo:** transform/models/marts/empresas_concursos.sql · **Páginas:** economia/empresas (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod` (`00` junto a comunidades); la serie termina en 2020 (el INE no publica más), no se dice en la tabla.
- **Cambio propuesto:** añadir `nivel` y `nombre`; se mantiene `concursos_100k` y `concursos_1000emp`. Documentar el fin de serie en la ficha, no en columnas.
```sql
case when b.cod='00' then 'pais' else 'ccaa' end as nivel, t.nombre
```
- **Páginas:** conservar `cod`, `anio`, `concursos`, `concursos_100k`, `concursos_1000emp`. Sin cambios.
- **Ficha:** desaparece «solo código».
- **Esfuerzo/riesgo:** bajo.

### empresas_dirce_sector
- **Modelo:** transform/models/marts/empresas_dirce_sector.sql · **Páginas:** economia/empresas (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod`; sin fila total (se suman los 11 sectores; la convención lo admite). Ya trae `por_1000hab` y `pct`.
- **Cambio propuesto:** añadir `nivel` y `nombre`. Opcional: renombrar `por_1000hab` a `por_1000_hab` como columna nueva igual (convención `_por_1000_hab`).
```sql
case when a.cod='00' then 'pais' else 'ccaa' end as nivel, t.nombre, 1000.0*a.empresas/p.poblacion as por_1000_hab
```
- **Páginas:** conservar `cod`, `sector`, `empresas`, `pct`, `por_1000hab`, `anio`.
- **Ficha:** desaparece «solo código».
- **Esfuerzo/riesgo:** bajo.

### empresas_dirce_tamano
- **Modelo:** transform/models/marts/empresas_dirce_tamano.sql · **Páginas:** economia/empresas (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod`; no tiene tasa por habitante (el sector hermano sí); sin fila total (se suman cinco tramos).
- **Cambio propuesto:** añadir `nivel`, `nombre` y `por_1000_hab` (empresas del tramo por 1.000 habitantes, mismo patrón que `empresas_dirce_sector`).
```sql
1000.0 * a.empresas / p.poblacion as por_1000_hab
-- left join pob p on p.cod = a.cod and p.anio = least(a.anio, r.max_anio)
```
- **Páginas:** conservar `cod`, `tamano`, `orden`, `empresas`, `pct`, `anio`.
- **Ficha:** desaparece «sin nombres»; medida nueva `por_1000_hab`.
- **Esfuerzo/riesgo:** bajo.

### empresas_dirce_territorio
- **Modelo:** transform/models/marts/empresas_dirce_territorio.sql · **Páginas:** economia/empresas, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 3
- **Problemas:** ya tiene `nivel`+`cod`+`empresas_1000hab`, pero sin `nombre`; `personas_fisicas + sociedades` no suman `empresas` (faltan otras formas jurídicas) y nada lo dice; `crecimiento` sin sufijo `_pct`.
- **Cambio propuesto:** añadir `nombre`, `otras_formas` (= empresas - personas_fisicas - sociedades) y `crecimiento_pct`; `empresas_1000hab` también como `por_1000_hab` si se quiere uniformar.
```sql
t.empresas - t.personas_fisicas - t.sociedades as otras_formas, crecimiento as crecimiento_pct
```
- **Páginas:** conservar `nivel`, `cod`, `anio`, `empresas`, `empresas_1000hab`, `pct_personas_fisicas`, `crecimiento`. Ya la usa también `empresas_concursos` (dbt), no se rompe.
- **Ficha:** desaparece «personas físicas más sociedades no suman»; se pierde «solo código».
- **Esfuerzo/riesgo:** bajo.

### empresas_id_ccaa
- **Modelo:** transform/models/marts/empresas_id_ccaa.sql · **Páginas:** economia/empresas, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod` (`00` = España mezclado con comunidades); `sector = 'Total'` suma Empresas+AAPP+Universidades+IPSFL, hay que filtrar siempre. Euros reales y por habitante ya existen (`eur_hab_real`, `anio_euros`), así que no se toca nada del principio rector.
- **Cambio propuesto:** añadir `nivel` y `nombre`. Opcional: `es_total_sector` BOOLEAN para que el chat no sume sectores.
```sql
case when n.cod='00' then 'pais' else 'ccaa' end as nivel, t.nombre, t.sectperf = 'TOTAL' as es_total_sector
```
- **Páginas:** conservar todo lo que usan (`cod`, `anio`, `sector`, `pct_pib`, `eur_hab_real`, `investigadores_1000ocup`, `anio_euros`).
- **Ficha:** desaparece «códigos sin nombres».
- **Esfuerzo/riesgo:** bajo.

### empresas_sociedades_anual
- **Modelo:** transform/models/marts/empresas_sociedades_anual.sql · **Páginas:** economia/empresas, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 3
- **Problemas:** solo falta nombre; ya trae por 100.000 hab y euros reales con `anio_euros` (es el modelo de referencia). `capital_real` y `capital_nominal` van en euros, no en miles (ya documentado).
- **Cambio propuesto:** añadir `nivel` y `nombre`; nada más. Nombres `capital_real` / `capital_nominal` se quedan (renombrar a `_eur_real` costaría 8 páginas por cosmética).
```sql
case when a.cod='00' then 'pais' else 'ccaa' end as nivel, t.nombre
```
- **Páginas:** conservar todas sus columnas; sin cambios.
- **Ficha:** desaparece «códigos sin nombres».
- **Esfuerzo/riesgo:** bajo.

### empresas_sociedades_mensual
- **Modelo:** transform/models/marts/empresas_sociedades_mensual.sql · **Páginas:** economia/empresas (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod` sin nombre; las columnas `_12m` son sumas móviles (no sumar) y nada en el nombre lo avisa. Real y por habitante ya están (`capital_real`, `*_12m_100k`).
- **Cambio propuesto:** añadir `nivel`, `nombre` y `capital_real_12m_hab` (capital 12 meses en euros reales por habitante, para cumplir el principio en la serie móvil).
```sql
case when meses_12 = 12 then capital_real_12m / poblacion end as capital_real_12m_hab
```
- **Páginas:** conservar `fecha`, `anio`, `mes`, `constituidas_12m*`, `disueltas_12m*`. Es dependencia dbt de `empresas_sociedades_anual` (usa `cod`, `anio`, `constituidas`, `disueltas`, `capital_nominal`): no tocarlos.
- **Ficha:** desaparece «códigos sin nombres»; el aviso de sumas móviles se queda en notas.
- **Esfuerzo/riesgo:** bajo.

### empresas_tamano_ue
- **Modelo:** transform/models/marts/empresas_tamano_ue.sql · **Páginas:** economia/empresas (4 traducciones) · **Prioridad:** 3
- **Problemas:** el código de país va en `geo` (convención: `cod_pais`) y el nombre en `pais`; `vab_meur` en euros corrientes sin real ni por habitante. Los `pct_*` son los que usa la página y ya son relativos.
- **Cambio propuesto:** añadir `cod_pais` (= geo) y `vab_meur_real` con el deflactor (la tabla es de 2021-2024); el por habitante necesitaría población de cada país, que existe en `raw_industria.eurostat_industria_poblacion` solo para los países que ya están en la UE-27, así que se puede para los 10 países pero no para `EU27_2020` como fila agregada sin sumarla (hay `EU27_2020` en esa tabla: sirve).
```sql
a.geo as cod_pais, a.vab_meur * d.factor as vab_meur_real, a.vab_meur * 1e6 / (p.miles*1000) as vab_eur_hab
```
- **Páginas:** conservar `geo`, `pais`, `tamano`, `orden`, `pct_empresas`, `pct_empleo`, `pct_vab`, `anio`.
- **Ficha:** `territorio.codigo` pasa de `geo` a `cod_pais`.
- **Esfuerzo/riesgo:** bajo, un join por país y año.

### energia_emisiones_gei
- **Modelo:** transform/models/marts/energia_emisiones_gei.sql (staging `stg_energia_emisiones_gei`) · **Páginas:** energia-clima/index (4 traducciones) · **Prioridad:** 1
- **Problemas:** solo cifras absolutas (Mt) sin por habitante, contra el principio rector; el año se llama `año` (con eñe, obliga a entrecomillar en SQL); sin fila total (se suma). Sirve de origen para ingestion/emisiones.py.
- **Cambio propuesto:** añadir `anio` INTEGER, `t_co2eq_hab` y `total_t_co2eq_hab` por sector con la población ya calculada en `clima_emisiones_anual` (Eurostat demo_gind, desde 1990; `poblacion_territorios` solo llega a 1996).
```sql
s.anio as "año", s.anio as anio,
round(s.mt_co2eq * 1e6 / c.poblacion, 3) as t_co2eq_hab
-- left join {{ ref('clima_emisiones_anual') }} c on c.anio = s.anio
```
- **Páginas:** conservar `año`, `sector`, `millones_toneladas_co2eq`, `porcentaje_total`. La gráfica por sector de energia-clima/index debería pasar a `t_co2eq_hab` (por habitante) con el total en el tooltip; las 4 traducciones copian el SQL.
- **Ficha:** desaparece «datos absolutos, no por habitante»; la medida principal pasa a `t_co2eq_hab`, y el tiempo a `anio` (se pierde la columna `año` como excepción).
- **Esfuerzo/riesgo:** medio, cambia el mensaje de una gráfica y 4 páginas; el mart es trivial.

### energia_mix_electrico
- **Modelo:** transform/models/marts/energia_mix_electrico.sql (staging `stg_energia_generacion`) · **Páginas:** energia-clima/index, energia-clima/mix-electrico (8 traducciones) · **Prioridad:** 2
- **Problemas:** `año` con eñe; solo TWh absolutos, sin kWh por habitante; `porcentaje_total` en 0-100 pero la página mix-electrico lo divide por 100 para formatear (aceptable, solo es formato).
- **Cambio propuesto:** añadir `anio` y `generacion_kwh_hab` (población `poblacion_territorios` nivel `pais`, 2007-2025 cubierto); el porcentaje ya es la medida relativa.
```sql
g.anio as anio, round(sum(g.generacion_twh) * 1e9 / any_value(p.poblacion), 0) as generacion_kwh_hab
-- left join pob p on p.anio = g.anio
```
- **Páginas:** conservar `año`, `tecnologia`, `tipo_fuente`, `generacion_twh`, `porcentaje_total`. La gráfica de áreas de energia-clima/index podría pasar a kWh/hab (opcional).
- **Ficha:** desaparece la excepción `tiempo.columna = año`; medida nueva `generacion_kwh_hab`.
- **Esfuerzo/riesgo:** bajo, solo columnas nuevas.

### energia_potencia_instalada
- **Modelo:** transform/models/marts/energia_potencia_instalada.sql (staging `stg_energia_potencia`) · **Páginas:** energia-clima/index, energia-clima/mix-electrico (8 traducciones) · **Prioridad:** 2
- **Problemas:** `año` con eñe; MW absolutos sin W por habitante; es un stock (no se suma entre años) y solo por nombre en notas; la dbt `metricas_energia` depende de ella.
- **Cambio propuesto:** añadir `anio` y `potencia_w_hab` (MW x 1e6 / población). Mantener `fuente`. No tocar `metricas_energia`.
```sql
a.anio as anio, round(a.potencia_mw * 1e6 / p.poblacion, 1) as potencia_w_hab
```
- **Páginas:** conservar `año`, `tecnologia`, `tipo`, `potencia_mw`, `porcentaje_total`, `fuente`; las gráficas de solar y eólica del índice pueden pasar a W/hab (opcional).
- **Ficha:** desaparece la excepción `año`; medida nueva `potencia_w_hab`.
- **Esfuerzo/riesgo:** bajo.

### energia_resumen_anual_mix
- **Modelo:** transform/models/marts/energia_resumen_anual_mix.sql · **Páginas:** energia-clima/index (4 traducciones) · **Prioridad:** 2
- **Problemas:** `año` con eñe; TWh sin por habitante; solapa en fuente y años con `energia_mix_electrico` (el total y la cuota renovable salen de las mismas filas), pero la portada usa `SELECT *`, así que no se puede fusionar sin cambiar la página.
- **Cambio propuesto:** añadir `anio`, `generacion_kwh_hab` y `demanda_kwh_hab`. No borrar: las páginas leen `SELECT *` y las KPI dependen de las columnas actuales.
```sql
g.anio as anio, g.total_twh * 1e9 / p.poblacion as generacion_kwh_hab, d.demanda_twh * 1e9 / p.poblacion as demanda_kwh_hab
```
- **Páginas:** conservar todas (`SELECT *`, `cuota_renovable_pct`, `cuota_libre_emisiones_pct`, `año`).
- **Ficha:** desaparece la excepción `año`; medida nueva por habitante.
- **Esfuerzo/riesgo:** bajo.

### gobierno_decretos_ley
- **Modelo:** transform/models/marts/gobierno_decretos_ley.sql · **Páginas:** transparencia/decretos-ley (4 traducciones) · **Prioridad:** —
- **Problemas:** ninguno de datos: es una lista de decretos uno por uno (fecha, presidente, familia, estado, enlace) que la página enseña tal cual y de la que cuelga `gobierno_presidencias_resumen` (`rdl_derogados`). La ficha dice `usar: false`, pero podría contestar «cuántos decretos derogó Sánchez».
- **Cambio propuesto:** no tocar el modelo. Sí cambiar la ficha a `usar: true` con tiempo `fecha_disposicion`, dimensiones `estado`, `presidente`, `familia`, y la cifra principal como recuento (sin columna numérica, así que hay que decidir si el chat acepta tablas de eventos).
- **Páginas:** conservar todas las columnas (`numero_oficial`, `estado`, `presidente`, `familia`, `titulo`, `url_html`).
- **Ficha:** `usar` de false a true (decisión del dueño).
- **Esfuerzo/riesgo:** bajo, sin tocar dbt; el riesgo es de chat (contar filas).

### gobierno_indultos_mensual
- **Modelo:** transform/models/marts/gobierno_indultos_mensual.sql · **Páginas:** transparencia/indultos (4 traducciones) · **Prioridad:** 2
- **Problemas:** fila anómala del año 1200 (`mes = 1200-11-01`, 2 indultos, sin presidente) que contamina mínimos y rankings; sin filas de ceros en meses sin indulto; el último mes (julio 2026) puede estar incompleto sin marca; `mes` en lugar de `fecha` (convención).
- **Cambio propuesto:** filtrar `fecha_disposicion >= '1977-07-01'` en el mart, añadir `fecha` (= mes) y `es_parcial` BOOLEAN para el mes en curso. Rellenar meses sin indulto con 0 no es necesario si la ficha avisa; si se quiere, `generate_series` por mes.
```sql
where tipo = 'indulto' and fecha_disposicion >= date '1977-07-01'
... , m.mes as fecha, m.mes = date_trunc('month', current_date) as es_parcial
```
- **Páginas:** conservar `mes`, `anio`, `indultos`, `presidente`, `familia`. La página `indultos.md` calcula el pico con esta tabla; sin la fila de 1200 el resultado no cambia.
- **Ficha:** desaparece la nota «excluir anio >= 1977»; `tiempo.parcial` queda cubierto por `es_parcial`.
- **Esfuerzo/riesgo:** bajo, un filtro y dos columnas.

### gobierno_presidencias_resumen
- **Modelo:** transform/models/marts/gobierno_presidencias_resumen.sql · **Páginas:** transparencia/decretos-ley, indultos (8 traducciones) · **Prioridad:** —
- **Problemas:** diez filas, 7 presidentes y 3 partidos en la misma columna `grupo` distinguidas por `nivel`: no sumar niveles (ya lo cumple `nivel`); sin periodo (agregado de toda la democracia). Formato correcto para una tabla de ranking.
- **Cambio propuesto:** dejar como está. Es ya una tabla «dimensión + medidas por año gobernado» que cumple la convención de `nivel`. Solo añadir a la ficha que `rdl_por_anio` es lo comparable (ya en notas).
- **Páginas:** conservar `nivel`, `grupo`, `familia`, `orden`, `anios`, `rdl*`, `leyes*`, `indultos*`.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** bajo (cero).

### gobierno_presupuestos
- **Modelo:** transform/models/marts/gobierno_presupuestos.sql · **Páginas:** transparencia/presupuestos (4 traducciones) · **Prioridad:** 3
- **Problemas:** el tiempo se llama `ejercicio` (convención `anio`); el ejercicio en curso está abierto (`Prorrogado (en curso)`) y `dias_prorroga` crece hasta hoy, sin `es_parcial`; no tiene euros ni habitantes (es de calendario, el principio no aplica).
- **Cambio propuesto:** añadir `anio` (= ejercicio) y `es_parcial` (= en_curso, ya existe como `en_curso`; aliasar). Mantener `ejercicio`, `en_plazo` y `en_curso`.
```sql
b.ejercicio as anio, b.en_curso as es_parcial
```
- **Páginas:** conservar `ejercicio`, `situacion`, `en_plazo`, `en_curso`, `dias_prorroga`, `presidente_responsable`, `partido_responsable`, `presidente_1_enero`, `url_html`. Sin cambios.
- **Ficha:** `tiempo.columna` pasa de `ejercicio` a `anio`.
- **Esfuerzo/riesgo:** bajo.

### gobiernos_presidentes
- **Modelo:** transform/seeds/gobiernos_presidentes.csv (seed; `column_types` ya con `desde`/`hasta` DATE) · **Páginas:** transparencia/comparacion-internacional, varios/observatorios (8 traducciones) · **Prioridad:** —
- **Problemas:** ninguno. Es una tabla de referencia (presidentes estatales y autonómicos con fechas y familia política) de la que cuelgan al menos 12 modelos (medios, construcción, vivienda, observatorios, transparencia). La convención solo nombra `territorios` y `deflactor` como referencia; esta es la tercera.
- **Cambio propuesto:** no tocar ni borrar. Añadir `gobiernos_presidentes` a la lista de tablas de referencia de CONVENCIONES.md y dejar la ficha como `usar: false` (o `true` para «quién presidía X en tal año»). Para el nivel autonómico, `cod` ya es INE (01-19); el nombre de comunidad se saca con territorios.
- **Páginas:** conservar `nivel`, `cod`, `desde`, `hasta`, `presidente`, `familia`.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** bajo (cero).

### industria_ccaa_ramas
- **Modelo:** transform/models/marts/industria_ccaa_ramas.sql · **Páginas:** economia/industria (4 traducciones) · **Prioridad:** 3
- **Problemas:** `ccaa` con formato INE («Madrid, Comunidad de», «Rioja, La»); mezcla ramas agregadas y finas (ya trae `es_agregado`); sin fila de España (correcto: la suma de comunidades con secreto no es el total); por habitante y real ya existen (`cifra_negocios_hab_real`).
- **Cambio propuesto:** cambiar el valor de `ccaa` por el nombre de `territorios` (ninguna página lo lee, todas hacen el join con `cod_ccaa`) y mantener el resto.
```sql
t.nombre as ccaa
-- left join {{ ref('territorios') }} t on t.nivel = 'ccaa' and t.cod = c.cod_ccaa
```
- **Páginas:** conservar `cod_ccaa`, `rama`, `es_agregado`, `anio`, `cuota_espana_pct`, `peso_en_industria_ccaa_pct`, `veces_peso_poblacion`, `puesto_en_espana`, `n_ccaa_con_dato`. Sin cambios.
- **Ficha:** desaparece «nombres con formato INE».
- **Esfuerzo/riesgo:** bajo.

### industria_exportaciones_ue
- **Modelo:** transform/models/marts/industria_exportaciones_ue.sql · **Páginas:** economia/industria (4 traducciones) · **Prioridad:** 2
- **Problemas:** `exportacion_es_real_meur` es la medida principal pero absoluta (sin euros reales por habitante, contra el principio); `destino` con códigos crudos `WORLD` / `EXT_EU27_2020` (WORLD incluye el comercio intra-UE, trampa de 394.000 M€); `exportacion_es_eur`/`exportacion_ue_eur` en euros y no en millones; capítulos y partidas en la misma columna (`es_capitulo` ya los distingue).
- **Cambio propuesto:** añadir `exportacion_es_real_eur_hab` (con población de España), `destino_nombre` (`Mundo (incluye UE)` / `Fuera de la UE`) y `exportacion_es_meur`. No cambiar `destino`.
```sql
a.exportacion_es_eur / 1e6 as exportacion_es_meur,
a.exportacion_es_eur * d.factor / p.poblacion as exportacion_es_real_eur_hab,
case a.destino when 'WORLD' then 'Mundo (incluye UE)' else 'Fuera de la UE' end as destino_nombre
```
- **Páginas:** conservar todo lo que usa la página (`partida`, `cuota_pct`, `puesto`, `puesto_sin_nl_be`, `lider_nombre`, `veces_peso_poblacion`, `exportacion_es_real_meur`, `es_ultimo_anio`, `destino`). La tabla de exportaciones podría mostrar `exportacion_es_real_eur_hab` en vez del total.
- **Ficha:** `dimension destino` gana nombre legible (defecto sigue siendo `WORLD`); medida principal pasa a euros reales por habitante.
- **Esfuerzo/riesgo:** bajo, columnas nuevas; población ES de `poblacion_territorios` (nivel `pais`).

### industria_ipi
- **Modelo:** transform/models/marts/industria_ipi.sql · **Páginas:** economia/industria (4 traducciones) · **Prioridad:** 2
- **Problemas:** tres series mezcladas por `fuente` (eurostat por país, ine por comunidad, ine_divisiones por división); España duplicada (`cod` `00` INE y `ES` Eurostat) y códigos ISO e INE en la misma columna `cod`; el total es `B-D` en Eurostat y «Total industria» en INE; el chat necesita el `defecto: ine`. Es un índice: no se deflacta ni se divide por población (ya anotado en el modelo).
- **Cambio propuesto:** añadir `nivel` normalizado (`pais`/`ccaa`), `cod_pais` (ISO, `ES` para las dos Españas), `es_total` BOOLEAN y mantener `nombre` con el de `territorios` en INE. Fase 2 opcional: partir en `industria_ipi_paises` (Eurostat) e `industria_ipi_ine` (INE + divisiones) cuando la página lea de las nuevas.
```sql
rama in ('B-D','Total industria') as es_total,
case when fuente='eurostat' then e.pais when cod='00' then 'ES' end as cod_pais
```
- **Páginas:** la página filtra `fuente = 'eurostat' AND rama = 'B-D' AND cod IN ('ES',...)`; conservar `fuente`, `rama`, `cod`, `nombre`, `indice`, `anio`. Para fase 2 solo 2 consultas (×4 traducciones) cambian de `FROM`.
- **Ficha:** desaparece el `defecto: ine` si se parte; si no, se queda como dimensión `fuente`.
- **Esfuerzo/riesgo:** bajo la fase 1, medio la fase 2.

### industria_ipi_mensual
- **Modelo:** transform/models/marts/industria_ipi_mensual.sql · **Páginas:** economia/industria (4 traducciones) · **Prioridad:** 3
- **Problemas:** `cod_ccaa` con `00` = España (mejor `nivel`/`cod`); `nombre` con formato INE («Madrid, Comunidad de»); `mes` en lugar de `fecha` y sin `anio`; destinos de bienes de consumo anidados (duradero/no duradero dentro de consumo) sin marca.
- **Cambio propuesto:** añadir `nivel`, `cod`, `fecha`, `anio`, `es_subdestino` BOOLEAN y cambiar `nombre` por el de territorios (la página no lo usa).
```sql
case when c.cod_ccaa='00' then 'pais' else 'ccaa' end as nivel, c.cod_ccaa as cod,
mes as fecha, cast(year(mes) as integer) as anio,
destino in ('Bienes de consumo duradero','Bienes de consumo no duradero') as es_subdestino
```
- **Páginas:** conservar `cod_ccaa`, `destino`, `mes`, `indice`, `variacion_anual_pct`, `variacion_acumulada_pct`, `es_ultimo_mes`.
- **Ficha:** desaparece «nombres con formato INE»; tiempo `fecha`.
- **Esfuerzo/riesgo:** bajo.

### industria_ramas_ue
- **Modelo:** transform/models/marts/industria_ramas_ue.sql · **Páginas:** economia/industria (4 traducciones) · **Prioridad:** 3
- **Problemas:** ya trae euros reales (`cifra_negocios_es_real_meur`, `anio_base`) y cuotas sobre UE; falta el equivalente por habitante (principio rector) y el nivel de la rama está en texto (`nivel`: seccion/division/grupo/clase, ya existe); la nota de «UE parcial» solo en `nota`.
- **Cambio propuesto:** añadir `cifra_negocios_es_real_eur_hab` (población de `poblacion_territorios`, España) y `ue_es_parcial` BOOLEAN (= `nota is not null`).
```sql
cifra_negocios_es_real_meur * 1e6 / p.poblacion as cifra_negocios_es_real_eur_hab, nota is not null as ue_es_parcial
```
- **Páginas:** conservar `rama`, `rama_nombre`, `nivel`, `cuota_cifra_negocios_pct`, `puesto_cifra_negocios`, `lider_cifra_negocios_nombre`, `veces_peso_poblacion`, `cifra_negocios_es_real_meur`, `peso_manuf_*`, `indice_especializacion`, `cuota_poblacion_pct`, `nota`, `es_ultimo_anio`. Sin cambios obligatorios.
- **Ficha:** medida principal pasa a euros reales por habitante.
- **Esfuerzo/riesgo:** bajo.

### inmigracion_flujos
- **Modelo:** transform/models/marts/inmigracion_flujos.sql · **Páginas:** ninguna en castellano (0 traducciones; solo la ficha y `schema_migracion.yml`; `metricas_sociedad` usa la tabla hermana `inmigracion_flujos_anuales`) · **Prioridad:** 3
- **Problemas:** ninguna página ni componente la usa y solo cubre 18 nacionalidades principales (no suman el total) y 3,5 años (175 filas); último trimestre incompleto sin marca; `trimestre` en vez de `fecha`/`anio`. No la propongo borrar: es la única serie trimestral por nacionalidad.
- **Cambio propuesto:** añadir `fecha` (= trimestre), `anio` y `es_parcial` (último trimestre). Ya trae `*_1000` por habitante.
```sql
trimestre as fecha, cast(year(trimestre) as integer) as anio, trimestre = max(trimestre) over () as es_parcial
```
- **Páginas:** ninguna usa la tabla; sin riesgo para páginas.
- **Ficha:** `tiempo.columna` pasa a `fecha`; `parcial` se apoya en `es_parcial`.
- **Esfuerzo/riesgo:** bajo.

### inmigracion_nacionalizaciones
- **Modelo:** transform/models/marts/inmigracion_nacionalizaciones.sql · **Páginas:** sociedad/index, sociedad/inmigracion (8 traducciones) · **Prioridad:** 2
- **Problemas:** solo `cod` (`00` = España junto a comunidades); `nacionalidad_previa` mezcla países, continentes («De Africa», «De América del Norte») y agregados UE en la misma columna (la página los excluye con 4 `NOT LIKE`); `por_1000_extranjeros` solo existe para `Total`.
- **Cambio propuesto:** añadir `nivel`, `nombre` y `es_grupo` BOOLEAN (igual que `inmigracion_saldos`), con la misma lógica de nombres de agregado; la página puede sustituir sus filtros por `NOT es_grupo`.
```sql
nacionalidad_previa like 'De %' or nacionalidad_previa like 'País de%' or nacionalidad_previa like 'Resto%'
  or nacionalidad_previa like 'Otro país%' or nacionalidad_previa = 'Total' as es_grupo,
case when n.cod_ccaa='00' then 'pais' else 'ccaa' end as nivel, t.nombre
```
- **Páginas:** conservar `anio`, `cod`, `nacionalidad_previa`, `nacionalizaciones`, `por_1000_extranjeros`. `nac_origen` en sociedad/inmigracion pasa a `WHERE NOT es_grupo` (×8 traducciones, opcional); es dependencia dbt de `mapas_personas` y `metricas_sociedad`: no tocar.
- **Ficha:** desaparece «solo código» y «mezcla países y grupos»; dimensión con `es_grupo`.
- **Esfuerzo/riesgo:** bajo, lista de agregados cerrada y verificable con una consulta.

### inmigracion_poblacion
- **Modelo:** transform/models/marts/inmigracion_poblacion.sql · **Páginas:** sociedad/inmigracion (4 traducciones) · **Prioridad:** 1
- **Problemas:** `pct_extranjeros` es una fracción 0-1 (la página la multiplica por 100 en `pob_espana`; en el mapa de comunidades se formatea como pct), contra «porcentajes 0-100 con sufijo `_pct`»: el chat da 0,12 en vez de 12 %; solo `cod`; las zonas de origen no suman el total.
- **Cambio propuesto:** añadir `pct_extranjeros_pct` (0-100), `nombre`, y `pct_otros_origen` o dejar la advertencia. No quitar `pct_extranjeros` hasta que las páginas migren. Ya trae `poblacion`, así que cada zona se puede dar `_pct`.
```sql
100.0 * extranjeros / poblacion as pct_extranjeros_pct, t.nombre
```
- **Páginas:** conservar `anio`, `nivel`, `cod`, `poblacion`, `extranjeros`, `pct_extranjeros`, `ue`, `resto_europa`, `africa`, `america_norte`, `centroamerica_caribe`, `sudamerica`, `asia`. Migrar `pob_espana` (`100 * pct_extranjeros AS valor`) y `ccaa` a la columna nueva (4 traducciones).
- **Ficha:** desaparece «pct_extranjeros viene como fracción»; medida principal `pct_extranjeros_pct`. Retirada de la columna vieja cuando ninguna página la use (la usa también `nacionalizaciones` por `extranjeros`, esa se queda).
- **Esfuerzo/riesgo:** bajo.

### inmigracion_saldos
- **Modelo:** transform/models/marts/inmigracion_saldos.sql · **Páginas:** sociedad/inmigracion (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod`; `nacionalidad` mezcla países, grupos continentales y Española/Extranjera/Total (ya hay `es_grupo`); a nivel comunidad solo existen Total/Española/Extranjera; solo 2021-2024. Ya trae `saldo_1000` (por habitante).
- **Cambio propuesto:** añadir `nombre` (territorios; en `nivel = 'pais'` es España) y `cod_pais` solo si se acepta un mapa nacionalidad→ISO (no hay seed para los nombres INE; si no, no se propone). Dependencias dbt: `demografia_anual`, `mapas_personas`.
```sql
t.nombre  -- left join territorios t on t.nivel = case t.nivel when 'pais' ... end
```
- **Páginas:** conservar `nivel`, `cod`, `anio`, `nacionalidad`, `es_grupo`, `saldo_exterior`, `saldo_1000`. Sin cambios.
- **Ficha:** desaparece «solo código».
- **Esfuerzo/riesgo:** bajo; el mapa a ISO sería esfuerzo medio y no lo recomiendo ahora.

---

## Resumen del lote

Prioridad 1: 3 (`empleo_salarios_deciles`, `energia_emisiones_gei`, `inmigracion_poblacion`).
Prioridad 2: 9 (`empleo_salarios_ccaa`, `empresas_autonomos`, `energia_mix_electrico`, `energia_potencia_instalada`, `energia_resumen_anual_mix`, `gobierno_indultos_mensual`, `industria_exportaciones_ue`, `industria_ipi`, `inmigracion_nacionalizaciones`).
Prioridad 3: 15 (`empleo_territorio`, `empresas_concursos`, `empresas_dirce_sector`, `empresas_dirce_tamano`, `empresas_dirce_territorio`, `empresas_id_ccaa`, `empresas_sociedades_anual`, `empresas_sociedades_mensual`, `empresas_tamano_ue`, `gobierno_presupuestos`, `industria_ccaa_ramas`, `industria_ipi_mensual`, `industria_ramas_ue`, `inmigracion_flujos`, `inmigracion_saldos`).
Dejar como está (—): 3 (`gobierno_decretos_ley`, `gobierno_presidencias_resumen`, `gobiernos_presidentes`).
Borrar: 0.
