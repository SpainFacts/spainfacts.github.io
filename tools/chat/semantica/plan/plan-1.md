# Plan de limpieza, lote 1 (30 tablas)

Criterio común: todo cambio es **aditivo** (columnas nuevas al lado de las viejas); no se quita ni renombra nada que use una página, así que las páginas y sus copias en en/ca/gl/eu siguen funcionando sin tocarse y el hash `i18n_origen` no cambia. Las tablas con `SELECT *` en `sources/mother/<tabla>.sql` recogen las columnas nuevas solas; las que listan columnas a mano (p. ej. `alcaldes_historia.sql`) hay que ampliarlas.

Patrón dbt reutilizado (ya existe en `construccion_ccaa.sql`, `construccion_afiliados.sql`):

```sql
-- población (último padrón <= año) y euros reales (factor de mother.deflactor, año base = último año completo)
pob as (select cod, cast(anio as integer) as anio, poblacion
        from {{ ref('poblacion_territorios') }} where nivel = 'ccaa' and sexo = 'Total'),
...
from base b
asof left join pob p on p.cod = b.cod_ccaa and p.anio <= b.anio
left join {{ ref('deflactor') }} d on cast(d.anio as integer) = b.anio
-- importe_real = importe * d.factor ; por habitante = importe / p.poblacion
```

Nota global: `mother.deflactor` solo existe desde 2002 (INE IPC). `construccion_deflactor` (ephemeral) ya lo alarga hasta 1996 con el IPCA de Eurostat. Ver decisión 2 del resumen final.

### alcaldes_familias_territorio
- **Modelo:** transform/models/marts/alcaldes_familias_territorio.sql · **Páginas:** ninguna (solo chat y banco de pruebas) · **Prioridad:** 2
- **Problemas:** `cod` sin nombre de territorio (convención: nunca un código sin su nombre); la ficha tiene `territorio.nombre = null`.
- **Cambio propuesto:** añadir `nombre` desde `territorios` (España = `'España'`). Sin tocar `clave`, `n`, `poblacion`.
```sql
left join {{ ref('territorios') }} t on t.nivel = agregado.nivel and t.cod = agregado.cod
-- select ... coalesce(t.nombre, 'España') as nombre
```
  Además absorbe a `alcaldes_resumen_familias` (su fila `nivel = 'pais'` es lo mismo).
- **Páginas:** ninguna la usa; nada que conservar salvo `familia`, `n`, `pct_*`, `clave` (los usa el banco `tools/chat/evaluacion`).
- **Ficha:** `territorio.nombre` pasa de null a `nombre`.
- **Esfuerzo/riesgo:** bajo; un join, ninguna página afectada.

### alcaldes_historia
- **Modelo:** transform/models/marts/alcaldes_historia.sql (export acotado en sources/mother/alcaldes_historia.sql, mandatos >= 2007) · **Páginas:** territorios/municipios, medios/buscador (8 traducciones) · **Prioridad:** —
- **Problemas:** ninguno de datos; la ficha ya la marca `usar: false` (listado sin cifra) y es correcto. `es_actual` solapa con `alcaldes_actuales`, pero lo usa la página.
- **Cambio propuesto:** no tocarla. Es una tabla de listado con territorio ya en `cod_mun` + `municipio`, fechas ISO y booleanos BOOLEAN; cumple las convenciones.
- **Páginas:** conservar `cod_mun, mandato, alcalde, cargo, fecha_posesion, familia, color`.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** nulo.

### alcaldes_resumen_familias
- **Modelo:** transform/models/marts/alcaldes_resumen_familias.sql · **Páginas:** ninguna (solo la pregunta `sql_oro` de tools/chat/evaluacion/preguntas-desarrollo.json, línea 1142-1146) · **Prioridad:** 2 (BORRAR)
- **Problemas:** duplicada: es `alcaldes_familias_territorio` filtrada a `nivel = 'pais'` con otros nombres de columna (`n_ayuntamientos`, `poblacion_gobernada`). Ninguna página, componente, ingestion/ ni orchestration/ la usa (solo `schema_alcaldes.yml`, `sources/mother/alcaldes_resumen_familias.sql` y la ficha).
- **Cambio propuesto:** borrar el modelo, su entrada en `schema_alcaldes.yml`, `sources/mother/alcaldes_resumen_familias.sql` y su ficha en `lote-1.json`. Reescribir la pregunta del banco: `SELECT familia, n, pct_poblacion FROM mother.alcaldes_familias_territorio WHERE nivel='pais' AND familia='PP'`.
- **Páginas:** ninguna.
- **Ficha:** desaparece la ficha entera; en la de `alcaldes_familias_territorio` hay que decir que también sirve para el total de España.
- **Esfuerzo/riesgo:** bajo; solo hay que actualizar el banco de pruebas del chat (verificar que sigue pasando).

### almacenamiento_acceso
- **Modelo:** transform/models/marts/almacenamiento_acceso.sql · **Páginas:** energia-clima/almacenamiento (4 traducciones) · **Prioridad:** 2
- **Problemas:** foto mensual completa (2 ficheros: sumarlos duplica); la página y el chat deben filtrar `fecha_fichero = max(...)`; tiempo en `fecha_fichero` (no `fecha`/`anio`); el nombre se llama `comunidad` (convención: `ccaa`).
- **Cambio propuesto:** añadir columnas sin quitar ninguna.
```sql
fecha_fichero as fecha, year(fecha_fichero) as anio,
fecha_fichero = max(fecha_fichero) over () as es_ultimo,
coalesce(c.nombre, a.ccaa) as ccaa
```
  Opcional: `otorgada_w_hab` con la población de la comunidad (potencia concedida por habitante).
- **Páginas:** conservar `fecha_fichero, cod_ccaa, comunidad, nudos, otorgada_mw, en_tramitacion_mw`; la página puede pasar a `WHERE es_ultimo` (quita las dos subconsultas `max(fecha_fichero)`), sin urgencia.
- **Ficha:** desaparece la trampa «tomar el último»; pasa a decir `es_ultimo = true` por defecto y `territorio.nombre = ccaa`, `tiempo.columna = fecha`.
- **Esfuerzo/riesgo:** bajo; columnas nuevas, nada roto.

### almacenamiento_diario
- **Modelo:** transform/models/marts/almacenamiento_diario.sql · **Páginas:** energia-clima/almacenamiento (4 traducciones) · **Prioridad:** 3
- **Problemas:** mezcla energía (MWh, se suma) y picos (MW, no se suman) en una fila, y el último día puede estar incompleto. No son errores: están bien nombradas con su unidad.
- **Cambio propuesto:** solo añadir `es_parcial` (último día de la serie) para que el chat no lo compare con días completos; no convertir unidades (la página ya divide entre 1000).
```sql
fecha = max(fecha) over () as es_parcial
```
- **Páginas:** conservar `fecha, bombeo_*_mwh, bombeo_*_pico_mw`.
- **Ficha:** la nota del último día incompleto se convierte en `tiempo.parcial` declarativo.
- **Esfuerzo/riesgo:** bajo; una columna.

### almacenamiento_mensual
- **Modelo:** transform/models/marts/almacenamiento_mensual.sql · **Páginas:** energia-clima/almacenamiento (4 traducciones) · **Prioridad:** 2
- **Problemas:** `rendimiento_bombeo` es proporción 0-1 (convención: `_pct` en 0-100; la ficha lo salva con `escala: 100`); último mes incompleto sin marcar; falta `anio` y `fecha`.
- **Cambio propuesto:** añadir al lado, sin quitar `rendimiento_bombeo`.
```sql
100 * bombeo_turbinado_gwh / nullif(bombeo_consumido_gwh, 0) as rendimiento_bombeo_pct,
year(mes) as anio, mes as fecha,
mes = max(mes) over () as es_parcial
```
- **Páginas:** conservar `mes, bombeo_*_gwh, baterias_*_gwh`; la página calcula `rendimiento` anual ella misma (suma/suma, correcto), no usa la columna 0-1.
- **Ficha:** desaparece `escala: 100` en `rendimiento_bombeo` (pasa a `rendimiento_bombeo_pct`, unidad %); el parcial pasa a `es_parcial`.
- **Esfuerzo/riesgo:** bajo; columnas nuevas.

### almacenamiento_potencia
- **Modelo:** transform/models/marts/almacenamiento_potencia.sql · **Páginas:** energia-clima/almacenamiento (4 traducciones) · **Prioridad:** 2
- **Problemas:** dos tipos (`bombeo_puro`, `baterias_hibridadas`) en formato largo con una sola unidad (MW), correcto pero cuesta sumarlo bien: es una foto mensual (no se suma entre meses); `comunidad` en vez de `ccaa`; sin `anio`/`fecha`; sin nada por habitante.
- **Cambio propuesto:** mantener formato largo (una unidad, MW) y añadir:
```sql
mes as fecha, year(mes) as anio, c.nombre as ccaa,
mes = max(mes) over () as es_ultimo,
case tipo when 'bombeo_puro' then 'Bombeo puro' else 'Baterías hibridadas' end as tipo_nombre,
1e6 * mw / nullif(p.poblacion, 0) as w_hab   -- población: ref('territorios') poblacion_ultima
```
- **Páginas:** conservar `mes, tipo, cod_ccaa, comunidad, mw`; no hace falta cambiar ninguna.
- **Ficha:** `es_ultimo` sustituye a la advertencia «no se suma entre meses»; `territorio.nombre = ccaa`; medida `w_hab` (W por habitante).
- **Esfuerzo/riesgo:** bajo.

### calor_espana_diario
- **Modelo:** transform/models/marts/calor_espana_diario.sql · **Páginas:** energia-clima/calor (4 traducciones) · **Prioridad:** —
- **Problemas:** ninguno real; tabla nacional por día con `fecha` + `anio`, grados con unidad clara; los recuentos por día no se suman y la nota basta.
- **Cambio propuesto:** no tocarla.
- **Páginas:** conservar `fecha, anomalia_tmax_media, n_provincias_por_encima, ...` (usa `SELECT *`).
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** nulo.

### calor_normal_diaria
- **Modelo:** transform/models/marts/calor_normal_diaria.sql · **Páginas:** energia-clima/calor (4 traducciones), solo para dibujar la banda p10/p90 · **Prioridad:** 3
- **Problemas:** auxiliar (ficha `usar: false`), el territorio solo tiene `cod_prov`; no es duplicada: la usa la gráfica y no se puede derivar de `calor_provincia_diario`.
- **Cambio propuesto:** dejarla (no borrar); añadir `provincia` desde `territorios_provincias` para que el código no vaya solo. Nada más.
```sql
join {{ ref('territorios_provincias') }} tp using (cod_prov)  -- tp.nombre as provincia
```
- **Páginas:** conservar `cod_prov, dia_anio, tmax_media, tmax_p10, tmax_p90`.
- **Ficha:** sigue `usar: false` (auxiliar de gráfica); sin excepción nueva.
- **Esfuerzo/riesgo:** bajo; cosmético.

### calor_records
- **Modelo:** transform/models/marts/calor_records.sql · **Páginas:** energia-clima/calor (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo los 20 mejores días por provincia; hay que filtrar `posicion = 1` para el récord absoluto (trampa de la ficha).
- **Cambio propuesto:** añadir un booleano; no cambiar el filtro `qualify <= 20` (la página lo usa).
```sql
posicion = 1 as es_record_absoluto
```
- **Páginas:** conservar `cod_prov, provincia, estacion, fecha, tmax, anomalia_tmax, posicion`.
- **Ficha:** la nota «filtrar posicion = 1» pasa a ser una dimensión con valor claro (`es_record_absoluto`).
- **Esfuerzo/riesgo:** bajo; mejora menor.

### ccaa_cuentas_capitulos
- **Modelo:** transform/models/marts/ccaa_cuentas_capitulos.sql (staging stg_hacienda_ccaa_capitulos) · **Páginas:** territorios/[ccaa]/index (4 traducciones) · **Prioridad:** 1
- **Problemas:** euros corrientes sin versión por habitante ni real (la página repite el join con población y `deflactor`); solo `cod_ccaa`, sin nombre; sin filas de total (hay que sumar capítulos y filtrar `tipo`).
- **Cambio propuesto:** añadir `ccaa`, población y las columnas por habitante y reales; mantener `ejecutado`, `presupuesto_*` en euros corrientes.
```sql
t.nombre as ccaa, p.poblacion,
s.ejecutado / p.poblacion as ejecutado_eur_hab,
s.ejecutado * d.factor as ejecutado_eur_real,
s.ejecutado * d.factor / p.poblacion as ejecutado_eur_hab_real,
s.presupuesto_definitivo * d.factor / p.poblacion as presupuesto_definitivo_eur_hab_real
-- join: territorios_ccaa t, poblacion_territorios (asof), deflactor
```
- **Páginas:** conservar `anio, cod_ccaa, tipo, capitulo, capitulo_nombre, presupuesto_definitivo, ejecutado`; la página `capitulos` puede pasar a `ejecutado_eur_hab_real` (hoy: `c.ejecutado / p.poblacion * coalesce(f.factor, 1)`).
- **Ficha:** desaparecen «sin nombre de comunidad» y «no hay versión por habitante ni real»; la medida principal pasa a `ejecutado_eur_hab_real`.
- **Esfuerzo/riesgo:** bajo-medio; modelo con joins nuevos, columnas aditivas. Aviso: el factor del año en curso (media parcial) cambia al cerrar el año; no es problema aquí (liquidación termina en 2024).

### ccaa_cuentas_resumen
- **Modelo:** transform/models/marts/ccaa_cuentas_resumen.sql · **Páginas:** territorios/index, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 1
- **Problemas:** euros corrientes sin habitante ni real; sin nombre; `deficit_no_financiero` es solo `saldo_no_financiero` con el signo cambiado (fuente de confusión del chat).
- **Cambio propuesto:** añadir `ccaa`, `poblacion` y por habitante real; no quitar `deficit_no_financiero` hasta que nadie lo use (ninguna página lo usa; podrá retirarse después).
```sql
t.nombre as ccaa, p.poblacion,
gastos_no_financieros / p.poblacion * d.factor as gastos_nf_eur_hab_real,
ingresos_no_financieros / p.poblacion * d.factor as ingresos_nf_eur_hab_real,
saldo_no_financiero / p.poblacion * d.factor as saldo_nf_eur_hab_real,
gastos_totales / p.poblacion * d.factor as gastos_totales_eur_hab_real
```
- **Páginas:** conservar `anio, cod_ccaa, ingresos_*, gastos_*, saldo_no_financiero, gastos_totales`; las consultas `cuentas`, `gasto_ranking` y `comparativa` (hoy repiten join de población y deflactor) pueden pasar a las columnas nuevas, y así se evita el truco `cod_ccaa <= '17'` si se decide una vista sin Ceuta/Melilla.
- **Ficha:** desaparecen «sin nombre» y «sin versión por habitante»; medida principal `gastos_nf_eur_hab_real`; el aviso del signo se mantiene.
- **Esfuerzo/riesgo:** bajo-medio; reaprovecha el patrón de arriba. Comprobar que `poblacion_territorios` cubre 18 y 19 (Ceuta y Melilla).

### ccaa_deuda
- **Modelo:** transform/models/marts/ccaa_deuda.sql (staging stg_bde_series) · **Páginas:** index, territorios/index, territorios/[ccaa]/index (12 traducciones); mención en src/lib/chat/herramientas.js solo como ejemplo de texto · **Prioridad:** 1
- **Problemas:** `deuda_eur` corriente sin habitante ni real (stock trimestral: la página lo calcula con población del año); `ccaa` viene como la publica el BdE (hoy coincide con `territorios`, pero sin garantía); `deflactor` no llega antes de 2002, así que 1994-2001 no tendría real.
- **Cambio propuesto:** añadir
```sql
p.poblacion,
deuda_eur / p.poblacion as deuda_eur_hab,
deuda_eur * d.factor as deuda_eur_real,
deuda_eur * d.factor / p.poblacion as deuda_eur_hab_real,
t.nombre as ccaa_nombre   -- de territorios_ccaa, por si el BdE cambia un nombre
-- población por asof (anio <= anio, padrón desde 1996); factor del año de la fecha
```
  Para tener real desde 1996 hay que alargar `mother.deflactor` con el IPCA (decisión 2); si no, `deuda_eur_hab_real` queda nulo hasta 2001.
- **Páginas:** conservar `fecha, anio, trimestre, cod_ccaa, ccaa, deuda_eur, deuda_pct_pib`; la KPI `deuda_ultima` y `deuda_hab_serie` pueden pasar a `deuda_eur_hab_real`, sin urgencia.
- **Ficha:** la medida principal sigue siendo `deuda_pct_pib`, pero se añade `deuda_eur_hab_real`; desaparece «sin habitante ni real».
- **Esfuerzo/riesgo:** bajo; aditivo. El factor del trimestre usa el año natural; el año en curso es provisional.

### ccaa_gasto_politicas
- **Modelo:** transform/models/marts/ccaa_gasto_politicas.sql (staging stg_hacienda_ccaa_funcional) · **Páginas:** territorios/[ccaa]/index (4 traducciones) · **Prioridad:** 1
- **Problemas:** `obligaciones` en euros corrientes sin habitante ni real (la página lo hace con `deflactor` + población y lo promedia ponderado); solo `cod_ccaa`, sin nombre; sin filas de total (sumar políticas).
- **Cambio propuesto:** añadir `ccaa`, `poblacion` y las columnas real/habitante; `obligaciones` queda tal cual.
```sql
t.nombre as ccaa, p.poblacion,
g.obligaciones / p.poblacion as obligaciones_eur_hab,
g.obligaciones * d.factor / p.poblacion as obligaciones_eur_hab_real,
g.obligaciones_brutas * d.factor / p.poblacion as obligaciones_brutas_eur_hab_real
```
- **Páginas:** conservar `anio, cod_ccaa, cod_area, area_nombre, cod_politica, politica_nombre, obligaciones`; la consulta `politicas` puede usar `obligaciones_eur_hab_real` (la media de las 17 sigue siendo suma/suma de `obligaciones` y `poblacion`, ya disponibles en la tabla).
- **Ficha:** desaparecen «sin nombre de comunidad» y «para comparar hay que dividir por población»; medida principal `obligaciones_eur_hab_real`.
- **Esfuerzo/riesgo:** bajo-medio; las políticas hijas suman a las áreas, no hay filas de total que se dupliquen.

### ccaa_saldo
- **Modelo:** transform/models/marts/ccaa_saldo.sql (staging stg_bde_series, be13a) · **Páginas:** territorios/[ccaa]/index (4 traducciones) · **Prioridad:** 1
- **Problemas:** `saldo_eur` y `pib_implicito_eur` corrientes sin habitante ni real; el PIB es implícito (deducido de la deuda del 4.º trimestre, no el oficial); sin Ceuta ni Melilla.
- **Cambio propuesto:** añadir columnas por habitante y reales; dejar claro en la columna que el PIB es implícito (ya lo dice el nombre).
```sql
p.poblacion,
a.saldo_eur / p.poblacion as saldo_eur_hab,
a.saldo_eur * d.factor / p.poblacion as saldo_eur_hab_real
```
  Nombre: usar `territorios_ccaa` en lugar del `ccaa` del BdE.
- **Páginas:** conservar `anio, cod_ccaa, saldo_eur, saldo_pct_pib`; la página divide `saldo_pct_pib / 100` y también usa `saldo_pct_pib` (el %); ninguna cambia.
- **Ficha:** se añade medida `saldo_eur_hab_real`; el signo (negativo = déficit) se mantiene en la nota.
- **Esfuerzo/riesgo:** bajo; aditivo.

### centrales
- **Modelo:** transform/models/marts/centrales.sql (staging stg_gem_centrales) · **Páginas:** energia-clima/centrales (4 traducciones) · **Prioridad:** 2
- **Problemas:** una fila por central y estado; hay que filtrar `estado_grupo = 'En operación'` o se mezclan canceladas y en tramitación (excepción `defecto` en la ficha); `potencia_mw` mezcla estados que no se suman; `municipio` solo por nombre (sin `cod_mun`, GEM no lo da).
- **Cambio propuesto:** añadir booleano y potencia segura de sumar.
```sql
u.estado_grupo = 'En operación' as en_operacion,
case when u.estado_grupo = 'En operación' then round(sum(u.potencia_mw), 1) end as potencia_operacion_mw
```
- **Páginas:** conservar `id, nombre, tecnologia, color, estado_grupo, potencia_mw, lat, lon, ccaa, provincia, ...`; la página puede seguir con su filtro.
- **Ficha:** `defecto: En operación` en `estado_grupo` se convierte en medida principal `potencia_operacion_mw` (no necesita filtro); sigue disponible `potencia_mw` por estado.
- **Esfuerzo/riesgo:** bajo; columnas nuevas. Sin tocar la ingestión.

### centrales_ccaa
- **Modelo:** transform/models/marts/centrales_ccaa.sql · **Páginas:** energia-clima/centrales (4 traducciones) · **Prioridad:** 1
- **Problemas:** potencia por comunidad solo en MW absolutos (comparar Castilla y León con La Rioja sin ajustar por población engaña, principio rector); `estado_grupo` con `defecto: En operación`; la suma de comunidades no cuadra con `centrales_resumen` (centrales sin comunidad se descartan con `cod_ccaa is not null`).
- **Cambio propuesto:** añadir población y vatios por habitante, y la potencia en operación sin filtro.
```sql
t.poblacion_ultima as poblacion,
1e6 * sum(u.potencia_mw) / t.poblacion_ultima as potencia_w_hab,
sum(u.potencia_mw) filter (where u.estado_grupo = 'En operación') as potencia_operacion_mw,
1e6 * sum(u.potencia_mw) filter (where u.estado_grupo = 'En operación') / t.poblacion_ultima as potencia_operacion_w_hab
-- join ref('territorios') t on t.nivel = 'ccaa' and t.cod = u.cod_ccaa
```
  (Ojo: se agrega por tecnología y estado; para que `potencia_w_hab` sea por fila hay que dividir en el `select` final, no sumar la columna.)
- **Páginas:** conservar `cod_ccaa, ccaa, tecnologia, estado_grupo, orden_estado, potencia_mw, n_*`; la gráfica `por_ccaa` (hoy en GW absolutos) debería pasar a `potencia_operacion_w_hab` para cumplir el principio por habitante; los GW totales quedan en el tooltip.
- **Ficha:** medida principal `potencia_operacion_w_hab`; desaparece el `defecto` en `estado_grupo` para la pregunta habitual.
- **Esfuerzo/riesgo:** medio; el cambio de la gráfica obliga a tocar la página y sus 4 traducciones (hash i18n); la tabla es aditiva.

### centrales_resumen
- **Modelo:** transform/models/marts/centrales_resumen.sql · **Páginas:** energia-clima/centrales (4 traducciones) · **Prioridad:** 3
- **Problemas:** total nacional por tecnología y estado, sin nivel/cod/nombre de España ni suma segura (misma trampa del estado); es casi `centrales_ccaa` sin comunidad.
- **Cambio propuesto:** mantenerla (da el total real, incluidas centrales sin comunidad, y el color de las tecnologías que usa la página); añadir
```sql
'pais' as nivel, '00' as cod, 'España' as nombre,
sum(u.potencia_mw) filter (where u.estado_grupo = 'En operación') as potencia_operacion_mw
```
  No fusionar con `centrales_ccaa` ahora (obligaría a reescribir KPIs y gráficas); queda como posible paso posterior.
- **Páginas:** conservar `tecnologia, color, orden_tecnologia, renovable, estado_grupo, potencia_mw`.
- **Ficha:** `defecto` del estado sustituido por `potencia_operacion_mw`; `territorio` con `nivel/cod/nombre`.
- **Esfuerzo/riesgo:** bajo; cosmético.

### construccion_afiliados
- **Modelo:** transform/models/marts/construccion_afiliados.sql · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** —
- **Problemas:** ninguno de fondo. Ya cumple las convenciones (`nivel`, `cod`, `nombre`, `fecha`, `anio`, `afiliados_constr_1000hab`, España como `pais`/`00`); la ficha solo avisa de no sumar niveles (inherente) y del cambio de CNAE.
- **Cambio propuesto:** no tocarla.
- **Páginas:** conservar todas las columnas.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** nulo.

### construccion_ccaa
- **Modelo:** transform/models/marts/construccion_ccaa.sql · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** 3
- **Problemas:** mezcla España (`cod = '00'`) y comunidades sin columna `nivel` (convención para tablas multinivel); el VAB en total (`vab_constr_meur`) solo en corrientes; `vab_constr_hab_real` ya cumple el principio.
- **Cambio propuesto:** añadir
```sql
case when b.cod = '00' then 'pais' else 'ccaa' end as nivel,
b.vab_constr_meur * d.factor as vab_constr_meur_real
```
- **Páginas:** conservar `cod, nombre, anio, pct_vab_construccion, vab_constr_hab_real, puesto, ...`.
- **Ficha:** `territorio.nivel = 'nivel'`; la excepción de España por `cod = '00'` pasa a `nivel = 'pais'`.
- **Esfuerzo/riesgo:** bajo.

### construccion_costes
- **Modelo:** transform/models/marts/construccion_costes.sql · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** 3
- **Problemas:** `pais` guarda el código ISO y `pais_nombre` el nombre (convención: `cod_pais` + `pais`); el coste real solo existe para España porque `ingestion/construccion.py` solo baja el IPCA de `geo=ES`; la serie de costes de España es idéntica a la de precios (dato de la fuente).
- **Cambio propuesto:** añadir `b.pais as cod_pais` y dejar `pais` hasta que ninguna página lo use (retirada posterior, con `pais_nombre` renombrado a `pais`). Para dar el coste real de todos los países habría que ingerir el IPCA de todos (`prc_hicp_aind` para cada país): datos que hoy no existen; solo se propone si el dueño lo quiere.
- **Páginas:** conservar `anio, pais, pais_nombre, es_referencia, coste_indice_2021, coste_real_indice_2021, var_coste_anual_pct`.
- **Ficha:** `territorio.codigo = cod_pais`; sin excepciones nuevas.
- **Esfuerzo/riesgo:** bajo para `cod_pais`; medio si se amplía la ingestión del IPCA.

### construccion_empleo
- **Modelo:** transform/models/marts/construccion_empleo.sql · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** 3
- **Problemas:** mezcla España y comunidades sin `nivel`; cifras en miles (convención: una columna, una unidad; está en el nombre `_miles`, vale); `periodo` en texto `2026T1` además de `fecha`.
- **Cambio propuesto:** solo añadir `nivel`.
```sql
case when cod = '00' then 'pais' else 'ccaa' end as nivel
```
- **Páginas:** conservar `cod, nombre, anio, trimestre, periodo, fecha, ocupados_*, pct_ocupados_constr, ocupados_constr_1000hab, tasa_paro_constr`.
- **Ficha:** `territorio.nivel`, `espana` por `nivel = 'pais'`.
- **Esfuerzo/riesgo:** bajo.

### construccion_grandes_constructoras
- **Modelo:** transform/models/marts/construccion_grandes_constructoras.sql (seed construccion_constructoras) · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** 3
- **Problemas:** el tiempo va en `edicion` (no `anio`); importes en millones de dólares (no hay deflactor ni cambio a euros: dato que no existe); solo ACS y Acciona tienen ingresos.
- **Cambio propuesto:** añadir `cast(edicion as integer) as anio`; no convertir a euros (faltaría un tipo de cambio por año y una fuente que no está ingerida). Son 7 filas: mantener la tabla.
- **Páginas:** conservar todas las columnas.
- **Ficha:** `tiempo.columna = anio`; la nota «importes en dólares» se queda.
- **Esfuerzo/riesgo:** bajo.

### construccion_permisos
- **Modelo:** transform/models/marts/construccion_permisos.sql · **Páginas:** economia/construccion (4 traducciones, 8 consultas) · **Prioridad:** 2
- **Problemas:** tres fuentes en una tabla (`ambito` = `UE`, `CCAA`, `ES_LARGA`); `cod` mezcla códigos INE y ISO; España aparece dos veces con la misma serie (la fila `'00'` de CCAA desde 2000 es el mismo dato que `ES_LARGA`, según el comentario del propio modelo) y una tercera vez en `UE` con otra fuente; hay que acordarse del `defecto: CCAA`.
- **Cambio propuesto:** en dos pasos. 1) Ahora, aditivo: añadir `nivel` (`pais`, `ccaa`, `pais_ue`), `cod_pais` y `pais` (solo filas UE, y España) para que cada columna tenga un solo significado. 2) Después, dividir: `construccion_permisos` (INE: `nivel = pais/ccaa`, 1992-2025, España una sola vez con la serie larga del BdE antes de 2000 y los visados del Ministerio desde 2000) y `construccion_permisos_ue` (Eurostat, `cod_pais` + `pais`). Las consultas `ES_LARGA` pasarían a `cod = '00' AND ambito = 'CCAA'` y las `UE` a la tabla nueva.
```sql
-- paso 2: unir 1992-1999 de ES_LARGA a la rama CCAA con cod '00'
select 'pais' as nivel, '00' as cod, 'España' as nombre, anio, ... from es_larga where anio < 2000
union all select nivel, cod, ... from ccaa
```
- **Páginas:** hoy filtran por `ambito`; conservar `ambito, cod, nombre, anio, viviendas_nueva(_1000hab), viviendas_reforma_1000hab, m2_*_hab, poblacion`. El paso 2 obliga a reescribir las 8 consultas del ES y las de las 4 copias.
- **Ficha:** al dividir desaparece el `defecto: CCAA` en `ambito` y la nota de las tres fuentes.
- **Esfuerzo/riesgo:** paso 1 bajo; paso 2 medio-alto (páginas y traducciones, y verificar que la serie larga y los visados coinciden desde 2000).

### construccion_produccion
- **Modelo:** transform/models/marts/construccion_produccion.sql · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** 3
- **Problemas:** `pais` es el código ISO y `pais_nombre` el nombre (igual que `construccion_costes`); índices (no euros, no se suman); el salto de España en 2025 ya está explicado en la columna `nota`. Sin problemas de unidad.
- **Cambio propuesto:** añadir `cod_pais` (copia de `pais`); no tocar índices ni `nota`.
- **Páginas:** conservar `anio, pais, pais_nombre, es_referencia, rama, rama_nombre, indice_2021, indice_2007, var_anual_pct, nota`.
- **Ficha:** `territorio.codigo = cod_pais`.
- **Esfuerzo/riesgo:** bajo.

### crimen_balance
- **Modelo:** transform/models/marts/crimen_balance.sql (macro con_uniprovinciales) · **Páginas:** index, sociedad/criminalidad, sociedad/index, territorios/municipios, territorios/[ccaa]/index (20 traducciones) · **Prioridad:** 1
- **Problemas:** la ficha está mal: marca `tasa_1000` e `infracciones` con `unidad: %` y `escala: 100` (nada es una proporción 0-1: `tasa_1000` es por 1.000 habitantes e `infracciones` es un recuento), lo que puede hacer que el chat multiplique por 100; `territorio` viene en mayúsculas («BALEARS (ILLES)», «RIOJA (LA)», «CIUDAD AUTÓNOMA DE CEUTA») frente al nombre de `territorios`.
- **Cambio propuesto:** (1) corregir la ficha: `tasa_1000` unidad «por cada 1.000 habitantes», `infracciones` unidad «infracciones», sin `escala`. (2) Añadir `nombre` normalizado, y una columna con la convención de tasa.
```sql
coalesce(t.nombre, n.territorio) as nombre,   -- left join ref('territorios') t on t.nivel = n.nivel and t.cod = n.cod
tasa_1000 as infracciones_por_1000_hab
```
  Los 1.349 registros ccaa/provincia de 2024 casan con `territorios`; los municipios siguen con el nombre del Balance (no hay nivel municipio en `territorios`).
- **Páginas:** conservar `anio, nivel, cod, territorio, categoria, infracciones, poblacion, tasa_1000` (varias lo usan como `b.territorio AS municipio`); pasar a `nombre` solo si luego se quiere unificar.
- **Ficha:** desaparecen la `escala: 100`/unidad «%» erróneas y la nota «nombres en mayúsculas y a veces sin tildes»; `territorio.nombre = nombre`.
- **Esfuerzo/riesgo:** bajo; el arreglo importante es de la ficha, no de la tabla.

### crimen_condenados
- **Modelo:** transform/models/marts/crimen_condenados.sql · **Páginas:** sociedad/criminalidad (4 traducciones) · **Prioridad:** 2
- **Problemas:** `cod_ccaa` con `'00'` = España, mezclado con comunidades sin `nivel` ni nombre (la ficha no puede dar el nombre; hay que traducir el código).
- **Cambio propuesto:** añadir `nivel`, `cod`, `nombre` desde `territorios` (España incluida), manteniendo `cod_ccaa`.
```sql
case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
n.cod_ccaa as cod,
coalesce(t.nombre, 'España') as nombre   -- left join ref('territorios') t
```
  Las tasas siguen siendo por 1.000 adultos (nada que convertir); mantener la advertencia de no promediar tasas entre nacionalidades.
- **Páginas:** conservar `anio, cod_ccaa, sexo, nacionalidad, condenados, poblacion_18, tasa_1000` (la página filtra `cod_ccaa = '00'`).
- **Ficha:** `territorio.nivel/codigo/nombre`; desaparece «sin columna de nombre».
- **Esfuerzo/riesgo:** bajo.

### crimen_condenas_delito
- **Modelo:** transform/models/marts/crimen_condenas_delito.sql · **Páginas:** sociedad/criminalidad (4 traducciones) · **Prioridad:** 1
- **Problemas:** la columna `delito` mezcla el total (`Delitos`), grupos (`Contra la libertad`) y delitos concretos que están dentro de ellos, así que sumar filas cuenta varias veces; hay dos clasificaciones con nombres distintos según el año; y solo recuentos, sin tasa por habitante (principio rector).
- **Cambio propuesto:** semilla `crimen_delitos_jerarquia` (delito, grupo, `nivel_delito`: 0 total, 1 grupo, 2 delito) y tasa por 100.000 habitantes con población de España.
```sql
j.nivel_delito, j.grupo,
100000.0 * total / p.poblacion as total_por_100k_hab,
100000.0 * espanola / pe.poblacion_es as espanola_por_100k_hab   -- si hay población por nacionalidad; si no, solo total
-- p = poblacion_territorios nivel 'pais' sexo 'Total'
```
  La población por nacionalidad ya está en `raw.ine_poblacion_nacionalidad` (la usa `crimen_condenados`), así que se puede calcular también española y extranjera.
- **Páginas:** conservar `anio, delito, total, espanola, extranjera, ue, resto_europa, africa, america, asia`; la página filtra por nombres de delito concretos y usa `extranjera / total`.
- **Ficha:** se declara `nivel_delito` (sumar solo dentro de un nivel) y desaparece la advertencia «sumar todas las filas cuenta varias veces»; se añade medida `total_por_100k_hab`.
- **Esfuerzo/riesgo:** medio; la jerarquía se escribe a mano (unos 60 nombres, dos clasificaciones) y hay que revisar que no queden delitos sin clasificar.

### crimen_serie_larga
- **Modelo:** transform/models/marts/crimen_serie_larga.sql · **Páginas:** sociedad/criminalidad, sociedad/index (8 traducciones) · **Prioridad:** 1
- **Problemas:** misma ficha errónea que `crimen_balance` (`tasa_1000` e `infracciones` con unidad `%` y `escala: 100`); sin nombre de territorio (solo `cod` y `nivel`; comunidad y provincia comparten códigos); `tipologia` en mayúsculas con jerarquía `nivel_tipologia`.
- **Cambio propuesto:** corregir la ficha como en `crimen_balance` y añadir el nombre.
```sql
coalesce(t.nombre, case when b.cod = '00' then 'España' end) as nombre
-- left join ref('territorios') t on t.nivel = b.nivel and t.cod = b.cod
```
- **Páginas:** conservar `anio, nivel, cod, codigo_tipologia, tipologia, nivel_tipologia, infracciones, tasa_1000` (filtran por `tipologia = 'TOTAL INFRACCIONES PENALES'` y `codigo_tipologia`).
- **Ficha:** desaparecen `escala`/unidad «%» erróneas y «sin nombre de territorio»; `territorio.nombre = nombre`.
- **Esfuerzo/riesgo:** bajo.

### crimen_ultimo_periodo
- **Modelo:** transform/models/marts/crimen_ultimo_periodo.sql · **Páginas:** sociedad/criminalidad (4 traducciones) · **Prioridad:** 1
- **Problemas:** ficha errónea (`infracciones` e `infracciones_anio_anterior` con `%` y `escala: 100`); no tiene tasa por habitante ni población, así que el chat solo compara recuentos; periodo parcial (enero-junio) fácil de confundir con un año completo; `territorio` en mayúsculas.
- **Cambio propuesto:** corregir la ficha y añadir población, tasa y nombre.
```sql
p.poblacion,
1000.0 * infracciones / nullif(p.poblacion, 0) as tasa_1000,
1000.0 * infracciones_anio_anterior / nullif(p.poblacion, 0) as tasa_1000_anio_anterior,
100.0 * (infracciones / nullif(infracciones_anio_anterior, 0) - 1) as variacion_pct,
true as es_parcial,
coalesce(t.nombre, territorio) as nombre
-- población como en crimen_balance (último padrón <= año)
```
- **Páginas:** conservar `anio, periodo, nivel, cod, territorio, categoria, infracciones, infracciones_anio_anterior` (la página calcula `variacion` por su cuenta).
- **Ficha:** desaparece la `escala` errónea y «sin tasa por habitante»; `tiempo.parcial = true` queda declarado por `es_parcial`.
- **Esfuerzo/riesgo:** bajo; reutiliza el CTE `poblacion` de `crimen_balance`.
