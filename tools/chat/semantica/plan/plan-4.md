# Plan de limpieza, lote 4 (30 tablas)

Resumen: prioridad 1 = 4 tablas, prioridad 2 = 8, prioridad 3 = 9, sin cambios (—) = 9. Se propone retirar de `mother.*` 1 tabla (`ipc`, sin borrar su modelo dbt). Ninguna propuesta quita ni renombra columnas que usen páginas.

Observaciones transversales:
- Población y deflactor ya existen para todo lo que haga falta en España: `mother.poblacion_territorios` (nivel pais/ccaa/provincia, `sexo='Total'`), `mother.poblacion_municipios` y `mother.deflactor` (`factor`, base 2025, desde 2002). La población de países extranjeros sí está: es el indicador `poblacion` de `internacional_comparativa` (18 países, 1990-2025).
- En las tablas de este lote los «unidades mezcladas» que marca el inventario son falsos positivos casi siempre (cada columna ya tiene una sola unidad); se resuelven con la ficha, no con cambios de modelo.
- Hallazgo (bug latente en páginas): `pages/territorios/[ccaa]/index.md` y `[provincia].md` hacen `LEFT JOIN mother.mercado_paro_territorios e ON e.nivel = 'pais'`, pero esa fila no existe, así que `tasa_paro_espana` sale siempre vacía. Se arregla en el modelo (ver `mercado_paro_territorios`), sin tocar las páginas.
- Todas las páginas con SQL repetido tienen traducciones (`en`, `ca`, `gl`, `eu`): cualquier cambio de SQL en una página exige propagarlo con `tools/i18n` y que pasen las pruebas. Por eso las columnas nuevas se añaden y las páginas solo se migran cuando compensa.

---

### internacional_comparativa
- **Modelo:** transform/models/marts/internacional_comparativa.sql · **Páginas:** ninguna directa (la usa el componente `Comparativa.svelte` y el chat) (0 traducciones) · **Prioridad:** 3
- **Problemas:** formato largo con unidad distinta por indicador (ya hay `unidad` en cada fila); `cod_pais` es ISO alfa-3 (`ESP`, `EUU`, `OED`) y la convención pide alfa-2 / `EU27_2020`; sin columna `anio_ultimo` ni marca de último año.
- **Cambio propuesto:** no partir la tabla (el catálogo de 38 indicadores es la gracia). Añadir `cod_iso2` (`ES`, `FR`..., `EU27_2020` para la UE, `OECD` para la OCDE), `es_ultimo` BOOLEAN (último año con dato de ese país e indicador) y `unidad_tipo` (`pct`, `por_hab`, `indice`, `personas`, `usd_ppa`) para que el chat sepa cuándo dos indicadores son comparables.
```sql
select ..., case cod_pais when 'EUU' then 'EU27_2020' when 'OED' then 'OECD'
       else <tabla alfa3->alfa2 en un CTE> end as cod_iso2,
       anio = max(anio) over (partition by indicador_id, cod_pais) as es_ultimo
```
- **Páginas:** `Comparativa.svelte` usa `cod_pais`, `pais`, `valor`, `anio`, `indicador_id`, `sentido`, `es_agregado`, `es_referencia`: se conservan. Ninguna página tiene que migrar.
- **Ficha:** desaparece la excepción de «cada país tiene un último año distinto» (se filtra `es_ultimo`); sigue el filtro obligatorio de `indicador_id`.
- **Esfuerzo/riesgo:** bajo; solo columnas nuevas en un único modelo.

### internacional_ultimo
- **Modelo:** transform/models/marts/internacional_ultimo.sql · **Páginas:** 20 páginas de tema (cuentas-publicas, demografia, economia, energia-clima, movilidad, sociedad, vivienda) vía `Comparativa` (80 traducciones) · **Prioridad:** 3
- **Problemas:** el año se llama `anio_ultimo` en vez de `anio` (el componente ya lo traduce con `f.anio ?? f.anio_ultimo`); `cod_pais` alfa-3; falta `unidad` ya presente pero sin tipo.
- **Cambio propuesto:** añadir `anio` (= `anio_ultimo`) y `cod_iso2` heredado de la comparativa; nada más. Es derivada pura de `internacional_comparativa`: si el owner prefiere menos tablas, se podría retirar y dejar `es_ultimo` en la comparativa, pero las 80 páginas traducidas la leen con `SELECT *`, así que no compensa.
```sql
select u.*, u.anio as anio_ultimo, ...   -- antes: u.anio as anio_ultimo
```
- **Páginas:** conservar `indicador_id`, `cod_pais`, `pais`, `valor`, `anio_ultimo`, `valor_espana_mismo_anio`, `es_agregado`, `es_referencia`, `sentido`, `unidad`, `fuente`. Ninguna migra.
- **Ficha:** desaparece «tiempo en columna no estándar»; sigue «filtrar un indicador_id».
- **Esfuerzo/riesgo:** bajo; columnas nuevas, `SELECT *` de las páginas no se rompe.

### ipc
- **Modelo:** transform/models/marts/ipc.sql · **Páginas:** ninguna (en las páginas `FROM ipc` son CTE locales, no `mother.ipc`); solo la usa el modelo `mercado_ipc_grupos` vía `ref('ipc')`; el banco de evaluación del chat la cita en `tablas_oro` de d08 (0 traducciones) · **Prioridad:** 2
- **Problemas:** 56 series del INE (índices y tasas anual/mensual/acumulada) en una columna `value` con la unidad dentro del texto de `serie`; duplicada por `mercado_ipc_grupos` y `mercado_ipc_ccaa`, que son mejores.
- **Cambio propuesto:** BORRAR de `mother.*`: eliminar `sources/mother/ipc.sql` y pasar el modelo a `{{ config(materialized='ephemeral') }}` (o convertirlo en `stg_ine_ipc_series`) para que `mercado_ipc_grupos` siga funcionando. Comprobado: ni `ingestion/`, ni `orchestration/` (solo un README antiguo que habla de `main.ipc`), ni `tools/` la leen. Quitar `mother.ipc` de `tablas_oro` de d08 en `tools/chat/evaluacion/preguntas-desarrollo.json` (el `sql_oro` ya usa `mercado_ipc_mensual`).
- **Páginas:** ninguna que migrar.
- **Ficha:** se elimina la ficha entera (y su entrada en el inventario).
- **Esfuerzo/riesgo:** bajo; único riesgo, olvidar que el modelo debe seguir existiendo como dependencia.

### local_deuda_municipio
- **Modelo:** transform/models/marts/local_deuda_municipio.sql · **Páginas:** `territorios/municipios.md`, `territorios/[ccaa]/[provincia].md` (8 traducciones) · **Prioridad:** 1
- **Problemas:** solo `deuda_eur` nominal; ambas páginas calculan a mano `deuda_eur / poblacion * factor` (pegando la población con el límite del padrón y el deflactor anual), duplicando lógica en 8 sitios; el chat no la tiene.
- **Cambio propuesto:** añadir `cod_prov`, `poblacion`, `deuda_eur_real`, `deuda_eur_hab`, `deuda_eur_hab_real` en el modelo con la misma lógica que las páginas (población del año acotada al rango del padrón; factor del año natural; nulo antes de 2002 porque el deflactor empieza ahí).
```sql
left join pob p on p.cod_mun = d.cod_mun
  and p.anio = greatest(least(d.anio, r.fin), r.ini)         -- poblacion_municipios, sexo='Total'
left join {{ ref('deflactor') }} f on f.anio = d.anio
select ..., p.poblacion,
  d.deuda_eur * f.factor as deuda_eur_real,
  d.deuda_eur / p.poblacion as deuda_eur_hab,
  d.deuda_eur * f.factor / p.poblacion as deuda_eur_hab_real
```
- **Páginas:** conservar `fecha`, `anio`, `trimestre`, `cod_mun`, `municipio`, `deuda_eur`. Las dos páginas pueden pasar a leer `deuda_eur_hab_real` directamente (quitan el `rango`, el cruce de población y el de deflactor); recomendable pero no urgente.
- **Ficha:** desaparece la nota «no hay versión por habitante, dividir por la población».
- **Esfuerzo/riesgo:** bajo; solo 13 ciudades y 1.651 filas. Ojo: los nulos de `deuda_eur_real` antes de 2002 deben seguir tratándose como en la página (hoy la página hace `JOIN` interno y los descarta).

### local_deuda_provincia
- **Modelo:** transform/models/marts/local_deuda_provincia.sql · **Páginas:** `territorios/[ccaa]/[provincia].md` (4 traducciones) · **Prioridad:** 1
- **Problemas:** solo `cod_prov` sin nombre; importes nominales (4 columnas); la página calcula a mano los 4 por habitante reales.
- **Cambio propuesto:** añadir `provincia`, `cod_ccaa`, `poblacion` y, para cada una de las 4 columnas de deuda, la versión `_real` y `_hab_real` (total, ayuntamientos, diputaciones, resto), más `pct_ayuntamientos`. Nombre y comunidad de `territorios_provincias`; población de `poblacion_territorios` (provincia, 31 de diciembre → padrón del año, con tope en el último).
```sql
join {{ ref('territorios_provincias') }} t using (cod_prov)
left join pob p on p.cod = d.cod_prov and p.anio = least(d.anio, (select max(anio) from pob))
left join {{ ref('deflactor') }} f on f.anio = d.anio
select ..., t.nombre as provincia, t.cod_ccaa, p.poblacion,
  deuda_eur * f.factor / p.poblacion as deuda_eur_hab_real,
  deuda_ayuntamientos_eur * f.factor / p.poblacion as deuda_ayuntamientos_eur_hab_real, ...
```
- **Páginas:** conservar `anio`, `fecha`, `trimestre`, `cod_prov`, `deuda_eur`, `deuda_ayuntamientos_eur`, `deuda_diputaciones_eur`, `deuda_resto_eell_eur`. La página de provincia puede pasar a `deuda_*_hab_real` y borrar el cruce con población y deflactor.
- **Ficha:** desaparecen «solo hay código de provincia» y «conviene dividir por su población».
- **Esfuerzo/riesgo:** bajo; 936 filas. Hay que replicar `coalesce(f.factor, 1)` solo si se quiere conservar el comportamiento de la página; en el modelo basta el factor (2008+ siempre existe).

### mapas_indicadores
- **Modelo:** transform/models/marts/mapas_indicadores.sql (une `mapas_personas` y `mapas_territorio`) · **Páginas:** `varios/mapas.md` (4 traducciones) · **Prioridad:** —
- **Problemas:** 151.206 filas y 257 indicadores con unidad y sentido propios (ya tiene `unidad` y `sentido` en cada fila); repite datos de las tablas temáticas; es la tabla que alimenta el explorador de mapas.
- **Cambio propuesto:** no tocarla (es una tabla de presentación; cambiarla rompe el explorador y sus 4 copias). Marcarla como auxiliar: campo `auxiliar: true` en la ficha para que `catalogo.mjs` la excluya del chat (el chat ya debe preferir la tabla del tema). Decisión del owner: si se quiere cumplir al pie de la letra «sin tablas auxiliares en mother», se movería a un esquema aparte (`web.*`), con cambio de `sources/mother/mapas_indicadores.sql` a `sources/web/` y de la página y sus 4 copias; no lo recomiendo ahora.
- **Páginas:** sin cambios.
- **Ficha:** se mantiene como auxiliar y se oculta; no se corrige nada dentro.
- **Esfuerzo/riesgo:** bajo si solo se marca; alto si se mueve de esquema.

### medios_contratos_ejemplos
- **Modelo:** transform/models/marts/medios_contratos_ejemplos.sql · **Páginas:** `medios/dinero-publico.md` (4 traducciones) · **Prioridad:** 3
- **Problemas:** territorio solo con código (`cod_ccaa`, `cod_municipio`); `importe_eur_real` ya existe; el top 50 por año es una muestra, no sirve para totales (está en la ficha y es inherente).
- **Cambio propuesto:** añadir `ccaa` (de `territorios`, nivel ccaa) y `municipio` (de `poblacion_municipios`, nombre del código más reciente) para que el chat no tenga que cruzar. El importe por habitante no aplica (contrato individual).
```sql
left join {{ ref('territorios') }} t on t.nivel = 'ccaa' and t.cod = b.cod_ccaa   -- as ccaa
left join (select cod_mun, any_value(municipio) municipio from {{ ref('poblacion_municipios') }} group by 1) m
  on m.cod_mun = b.cod_municipio
```
- **Páginas:** conservar `anio`, `rango`, `objeto`, `organo`, `nivel`, `adjudicatario`, `grupo`, `importe_eur_nominal`, `importe_eur_real`, `url`, `fecha_adjudicacion`; ninguna migra.
- **Ficha:** desaparece «territorio solo con código».
- **Esfuerzo/riesgo:** bajo; dos joins a tablas pequeñas.

### medios_publicidad_age_medios
- **Modelo:** transform/models/marts/medios_publicidad_age_medios.sql · **Páginas:** `medios/dinero-publico.md` (4 traducciones) · **Prioridad:** —
- **Problemas:** ninguno de fondo: ya trae `importe_eur_nominal`, `importe_eur_real`, `eur_hab_real` y `pct`. El filtro por `ambito` es real (dos definiciones del informe que no se suman).
- **Cambio propuesto:** dejarla. Partirla en dos tablas por ámbito sería factible, pero la página usa ambos ámbitos y el resultado sería peor; basta con `defecto: ambito = 'institucional'` en la ficha.
- **Páginas:** sin cambios.
- **Ficha:** la excepción de filtro se queda, expresada como `defecto` y con la explicación del ámbito.
- **Esfuerzo/riesgo:** bajo (solo ficha).

### medios_publicidad_grupos
- **Modelo:** transform/models/marts/medios_publicidad_grupos.sql · **Páginas:** `medios/dinero-publico.md` (4 traducciones) · **Prioridad:** —
- **Problemas:** ninguno de fondo: ya tiene `importe_eur_real`, `eur_hab_real`, `eur_1000hab_real`, `pct`, `puesto`, `es_plataforma`, `es_publico`. El filtro por `tipo` es inherente (informes distintos, `puesto` por tipo). Dato único de 2025, así que nominal = real.
- **Cambio propuesto:** dejarla. Es el único caso donde la tabla tiene dos columnas por habitante equivalentes (`eur_hab_real` y `eur_1000hab_real`): se podría quitar `eur_1000hab_real` cuando ninguna página la use (lo comprobaré con grep al ejecutar; hoy no he verificado si la página la lee).
- **Páginas:** conservar `anio`, `tipo`, `grupo`, `importe_eur_nominal`, `importe_eur_real`, `eur_hab_real`, `pct`, `puesto`, `es_plataforma`, `es_publico`.
- **Ficha:** se mantiene el `defecto: tipo`.
- **Esfuerzo/riesgo:** bajo (solo ficha).

### medios_receptores
- **Modelo:** transform/models/marts/medios_receptores.sql · **Páginas:** `medios/buscador.md` (4 traducciones) · **Prioridad:** 2
- **Problemas:** 154.000 filas con `duplicado_probable`: cualquier `sum(importe_eur_real)` sin filtrarlo cuenta dos veces los contratos de publicidad ya presentes en la fuente territorial (la página lo excluye siempre; el chat no lo sabe); `cod_ccaa` sin nombre de comunidad (sí hay `gobierno`); importes negativos (correcciones, 1.613) legítimos; `anio` sale como DOUBLE.
- **Cambio propuesto:** añadir `importe_eur_real_suma` y `importe_eur_nominal_suma` (igual al importe, o NULL si `duplicado_probable`), de modo que `sum(importe_eur_real_suma)` sea siempre correcto sin filtro, y `ccaa` (nombre). No tocar la base heterogénea (`base`) que ya está documentada. Valorar cast de `anio` a INTEGER si la publicación no lo normaliza.
```sql
case when not duplicado_probable then importe_eur_real end as importe_eur_real_suma,
case when not duplicado_probable then importe_eur_nominal end as importe_eur_nominal_suma,
t.nombre as ccaa     -- left join territorios nivel 'ccaa'
```
- **Páginas:** conservar todas las actuales (`medio_id`, `via`, `anio`, `administracion`, `gobierno`, `importe_eur_real`, `duplicado_probable`, `url`...). `buscador.md` podría usar `_suma` y quitar sus `AND NOT duplicado_probable` (7 consultas), aunque no es necesario.
- **Ficha:** la excepción de filtro `NOT duplicado_probable` pasa a «sumar `importe_eur_real_suma`»; sigue la nota de bases no homogéneas.
- **Esfuerzo/riesgo:** bajo; dos columnas calculadas. Cuidado con el cupo de MotherDuck: añade dos columnas DOUBLE a 154.000 filas (poco).

### medios_receptores_resumen
- **Modelo:** transform/models/marts/medios_receptores_resumen.sql · **Páginas:** `medios/buscador.md` (4 traducciones) · **Prioridad:** 2
- **Problemas:** 13 columnas de total del medio (`total_*`, `estado_*`, `territorial_*`, `contratos_*`, `subvenciones_*`, `n_*_total`, `rango_*`) repetidas en cada fila de medio-año-vía: trampa clásica de doble suma (la propia ficha avisa).
- **Cambio propuesto:** crear una tabla nueva de una fila por medio (`medios_receptores_totales`) con todo lo repetido (CTE `rangos` que ya existe en el modelo) y dejar en el resumen solo `medio_id`, `medio`, `anio`, `via`, `importe_*`, `n_*`. Fase 1: añadir la tabla nueva y mantener las columnas viejas; fase 2 (cuando el buscador lea la tabla nueva): quitar las repetidas del resumen. Decisión del owner: crear tabla nueva (mother pasa a 1 tabla más) o dejar como está y solo documentar. Mi recomendación: crearla, y marcar la repetición como pendiente de retirar.
```sql
-- medios_receptores_totales.sql: select * from rangos   (una fila por medio)
-- resumen: select a.medio_id, a.anio, a.via, a.importe_eur_nominal, a.importe_eur_real, a.n_pagos, ...
```
- **Páginas:** hoy `buscador.md` usa los totales del medio del resumen; deben pasar a la tabla nueva para retirar las columnas repetidas (4 traducciones más el SQL en castellano).
- **Ficha:** desaparece «las columnas total_* repiten el total: no sumarlas» (tras la fase 2).
- **Esfuerzo/riesgo:** medio; modelo nuevo y migración del buscador, pero el modelo ya calcula los totales en un CTE aparte.

### medios_subvenciones_beneficiarios
- **Modelo:** transform/models/marts/medios_subvenciones_beneficiarios.sql · **Páginas:** `medios/dinero-publico.md` (4 traducciones) · **Prioridad:** 2
- **Problemas:** una fila por NIF y año con `total_*`, `n_convocatorias`, `administraciones`, `rango`... repetidos en cada año (doble suma si se agrega); administraciones concedentes como texto largo en mayúsculas.
- **Cambio propuesto:** mismo patrón que el resumen de receptores: tabla `medios_subvenciones_totales` (una fila por NIF, el CTE `totales` actual con `rango` y `forma_juridica`) y dejar el detalle anual en la tabla actual. Fase 1: añadir, sin quitar; fase 2: retirar los campos repetidos cuando la página lea la tabla nueva. Añadir además `es_parcial` BOOLEAN para 2026 (hoy solo en la ficha).
- **Páginas:** conservar `nif`, `nombre`, `anio`, `importe_eur_real`, `total_eur_real`, `rango`, `forma_juridica`...; el ranking de beneficiarios debe pasar a la tabla de totales.
- **Ficha:** desaparece «total_* y rango se repiten: no sumarlos».
- **Esfuerzo/riesgo:** medio; igual que el resumen. Si el owner decide no crear tablas nuevas, dejar solo con la advertencia de la ficha (prioridad 3).

### mercado_energia_carburantes
- **Modelo:** transform/models/marts/mercado_energia_carburantes.sql · **Páginas:** `economia/ipc.md` (4 traducciones) · **Prioridad:** 3
- **Problemas:** el tiempo se llama `semana` (convención: `fecha` + `anio`); `geo` + `territorio` ('ES'/'EU' frente a convención `cod_pais`/`pais`); ya trae euros reales (`eur_litro_real`, base `anio_euros`), sin problema de fondo.
- **Cambio propuesto:** añadir `fecha` (= `semana`), `anio`, `cod_pais` (`ES`, `EU27_2020`) y `pais`. Resto igual.
```sql
select w.fecha as semana, w.fecha as fecha, cast(year(w.fecha) as integer) as anio,
  case w.geo when 'ES' then 'ES' else 'EU27_2020' end as cod_pais, ...
```
- **Páginas:** conservar `semana`, `geo`, `territorio`, `producto`, `eur_litro`, `eur_litro_real`, `anio_euros`; ninguna migra.
- **Ficha:** desaparece «tiempo en columna no estándar».
- **Esfuerzo/riesgo:** bajo.

### mercado_energia_hogares
- **Modelo:** transform/models/marts/mercado_energia_hogares.sql · **Páginas:** `economia/ipc.md` (4 traducciones) · **Prioridad:** 3
- **Problemas:** el tiempo es `semestre_inicio` + etiqueta `semestre` (convención: `fecha` + `anio`); precios ya reales (`eur_kwh_real`). `geo` ya es `EU27_2020`/ISO2 y `pais` está en castellano: cumple.
- **Cambio propuesto:** añadir `fecha` (= `semestre_inicio`) y `anio`.
- **Páginas:** conservar `semestre_inicio`, `semestre`, `energia`, `geo`, `pais`, `eur_kwh`, `eur_kwh_real`, `anio_euros`.
- **Ficha:** desaparece «tiempo en columna no estándar».
- **Esfuerzo/riesgo:** bajo.

### mercado_energia_ipc
- **Modelo:** transform/models/marts/mercado_energia_ipc.sql · **Páginas:** `economia/ipc.md` (4 traducciones) · **Prioridad:** —
- **Problemas:** solo la trampa de la ficha (tasas no se suman); `mes` DATE primer día de mes sirve como `fecha`; las unidades por columna son claras (`indice`, `var_anual` en %, `indice_2019`, `ponderacion` por mil, `contribucion_aprox` en puntos).
- **Cambio propuesto:** no tocarla. Decisión transversal del owner: declarar en CONVENCIONES que `mes`, `trimestre` y `semana` (DATE de inicio del periodo) valen como `fecha` y que `var_*` es % aunque no lleve `_pct`.
- **Páginas:** sin cambios.
- **Ficha:** se mantiene, añadiendo `unidad_columna` para `var_anual` (%) y `ponderacion` (por mil).
- **Esfuerzo/riesgo:** bajo (solo ficha y convención).

### mercado_ipc_ccaa
- **Modelo:** transform/models/marts/mercado_ipc_ccaa.sql · **Páginas:** `economia/ipc.md`, `territorios/[ccaa]/index.md` (8 traducciones) · **Prioridad:** 2
- **Problemas:** solo `cod_ccaa` sin nombre (la página lo cruza con `territorios`); `cod_ccaa='00'` es el total nacional pero no se llama «España»; `anio` ya existe.
- **Cambio propuesto:** añadir `ccaa` (nombre de `territorios`, uniendo nivel `ccaa` y nivel `pais` para el `00`) y `es_nacional` BOOLEAN. No añadir euros: es una tasa.
```sql
left join {{ ref('territorios') }} t on t.cod = n.cod_ccaa and t.nivel in ('ccaa', 'pais')
select ..., t.nombre as ccaa, n.cod_ccaa = '00' as es_nacional
```
- **Páginas:** conservar `mes`, `anio`, `cod_ccaa`, `var_anual`, `var_mensual`, `subida_desde_2019`; las dos páginas pueden dejar su `JOIN mother.territorios` pero no hace falta.
- **Ficha:** desaparece «sin nombre de comunidad: solo código INE».
- **Esfuerzo/riesgo:** bajo.

### mercado_ipc_grupos
- **Modelo:** transform/models/marts/mercado_ipc_grupos.sql · **Páginas:** `economia/ipc.md` (4 traducciones) · **Prioridad:** —
- **Problemas:** ninguno; tiene `grupo`, `grupo_corto`, `es_general` y las unidades están claras; las advertencias de la ficha (tasas no se suman) son de contenido.
- **Cambio propuesto:** no tocar. Depende de `ref('ipc')`: si `ipc` pasa a ephemeral, este modelo sigue igual.
- **Páginas:** sin cambios.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** bajo.

### mercado_paro_grupos
- **Modelo:** transform/models/marts/mercado_paro_grupos.sql · **Páginas:** `economia/paro.md` (4 traducciones) · **Prioridad:** —
- **Problemas:** formato largo (`dimension`, `grupo`, `orden`, `tasa_paro`) con una sola unidad (%), por lo que no mezcla unidades; sin fila de total (está en `mercado_paro_trimestral`); `trimestre` DATE sin `anio`.
- **Cambio propuesto:** dejar como está: la tasa de paro de varias dimensiones no se suma, y el formato largo es el natural. Opcional: añadir `anio`. No justifica trabajo.
- **Páginas:** sin cambios.
- **Ficha:** se mantiene la advertencia de que los grupos de dimensiones distintas no se suman.
- **Esfuerzo/riesgo:** bajo.

### mercado_paro_registrado
- **Modelo:** transform/models/marts/mercado_paro_registrado.sql · **Páginas:** `economia/paro.md`, `territorios/[ccaa]/index.md`, `territorios/[ccaa]/[provincia].md` (12 traducciones) · **Prioridad:** 2
- **Problemas:** `cod` sin nombre (hay que filtrar siempre `nivel`); `paro_registrado` en personas pero la comparación entre territorios debe hacerse con `por_100_16_64` (que ya existe y es la versión por habitante); sin `anio`.
- **Cambio propuesto:** añadir `territorio` (nombre) y `anio`; opcionalmente `paro_registrado_por_1000_hab_16_64` si el owner prefiere la unidad estándar, pero `por_100_16_64` ya cumple el principio y las páginas lo usan: no duplicar.
```sql
left join {{ ref('territorios') }} t on t.nivel = n.nivel and t.cod = n.cod
select ..., t.nombre as territorio, cast(year(mes) as integer) as anio
```
- **Páginas:** conservar `mes`, `nivel`, `cod`, `paro_registrado`, `por_100_16_64`, `variacion_anual_pct`, `paro_menor25`, `paro_hombres`, `paro_mujeres`, `poblacion_16_64`. Ninguna migra.
- **Ficha:** desaparece «sin columna de nombre»; se documenta que para comparar territorios se usa `por_100_16_64`.
- **Esfuerzo/riesgo:** bajo; una unión a `territorios`, 17.000 filas.

### mercado_paro_territorios
- **Modelo:** transform/models/marts/mercado_paro_territorios.sql · **Páginas:** `economia/paro.md`, `territorios/[ccaa]/index.md`, `territorios/[ccaa]/[provincia].md` (12 traducciones) · **Prioridad:** 2
- **Problemas:** `cod` sin nombre; no tiene fila de España aunque las dos páginas de territorio la piden (`e.nivel = 'pais'`): hoy `tasa_paro_espana` y `tasa_paro_menor25_espana` salen siempre vacíos; las columnas dependen del nivel (provincia no tiene `tasa_paro_menor25`, ccaa no tiene `tasa_empleo`), con NULL silenciosos.
- **Cambio propuesto:** añadir `territorio` (nombre) y la fila `nivel='pais'`, `cod='00'` calculada con la misma lógica sobre `'Total Nacional'` (paro total, menor25, extranjeros, hogares, empleo, actividad, mujeres). Con eso se arregla el bug de las páginas sin tocarlas. Documentar en la ficha qué columnas existen por nivel.
```sql
pais as (  -- mismas agregaciones que ccaa/provincia pero list_contains(partes, 'Total Nacional')
    select 'pais' as nivel, '00' as cod, trimestre, ... from ccaa_raw ... union provincia_raw ...
),
todo as (select * from ccaa union all select * from provincia union all select * from pais)
```
- **Páginas:** conservar `nivel`, `cod`, `trimestre`, `tasa_paro`, `tasa_paro_menor25`, `pct_hogares_todos_parados`, `tasa_empleo`, `tasa_actividad`, `media_4t_*`, `tasa_paro_dif_anual`. Las páginas no cambian; empezarán a mostrar España.
- **Ficha:** desaparecen «sin columna de nombre» y «no incluye fila de España»; se mantiene que las provincias pequeñas son ruidosas (usar `media_4t_*`).
- **Esfuerzo/riesgo:** medio; hay que reproducir las agregaciones de ccaa y provincia sobre el total nacional, comprobar que `mercado_paro_trimestral` coincide con las nuevas filas y vigilar que las páginas que hacen `LEFT JOIN` por `trimestre` no dupliquen filas.

### mercado_paro_trimestral
- **Modelo:** transform/models/marts/mercado_paro_trimestral.sql · **Páginas:** `economia/paro.md` (4 traducciones) · **Prioridad:** —
- **Problemas:** ninguno de fondo: solo España, `trimestre` DATE + `anio` + `trim` + `periodo` (etiqueta). Personas (`parados`, `asalariados`) son stocks. Está bien.
- **Cambio propuesto:** no tocar. Tras añadir la fila `pais` en `mercado_paro_territorios` habrá dos fuentes de la misma tasa nacional; la convención pide «nunca la misma España dos veces por venir de dos fuentes». Se resuelve por construcción si la fila `pais` de `territorios` se calcula del mismo origen EPA (verificar igualdad), y la ficha dirá que `mercado_paro_trimestral` es la serie nacional completa.
- **Páginas:** sin cambios.
- **Ficha:** sin cambios, solo una referencia cruzada.
- **Esfuerzo/riesgo:** bajo.

### metricas
- **Modelo:** transform/models/marts/metricas.sql (une 5 submodelos) · **Páginas:** `index.md`, `economia/index.md`, `energia-clima/records.md`, `transparencia/index.md`, `cuentas-publicas/empleo-publico.md`, `varios/indicadores/index.md`, `varios/indicadores/[metrica_id].md` (28 traducciones) · **Prioridad:** —
- **Problemas:** ~190 indicadores con unidades distintas en una columna `valor`; duplica las tablas temáticas; pero es la base de KPIs de portada y de las fichas de indicador.
- **Cambio propuesto:** no tocar ni borrar (7 páginas más 28 traducciones). Marcarla `auxiliar: true` en la ficha para que el chat no la use (ya tiene `unidad` por fila). Misma decisión que `mapas_indicadores`: mover a un esquema `web.*` solo si el owner quiere cumplir «sin auxiliares»; no recomendado ahora.
- **Páginas:** sin cambios.
- **Ficha:** se mantiene como auxiliar/oculta.
- **Esfuerzo/riesgo:** bajo si solo se marca; alto si se mueve de esquema.

### movilidad_flotas_municipios
- **Modelo:** transform/models/marts/movilidad_flotas_municipios.sql · **Páginas:** `movilidad/flotas-e-impuestos.md` (4 traducciones) · **Prioridad:** 3
- **Problemas:** `cuota_flota_espana` es proporción 0-1 (la página la multiplica por 100); `flota_por_habitante` es razón con valores hasta 99 (conviene `por_1000_hab`); `ahorro_estimado` y `ahorro_por_coche` son euros constantes de 2026 por construcción (tarifa de IVTM de 2026 aplicada a todos los años), no hace falta deflactarlos pero hay que decirlo.
- **Cambio propuesto:** añadir `cuota_flota_espana_pct` (0-100) y `flota_por_1000_hab`; dejar las viejas hasta migrar la página. En la ficha, `unidad_columna` de `ahorro_*` = «€ de 2026, estimación con la tarifa vigente».
```sql
100 * f.flota / n.flota_espana as cuota_flota_espana_pct,
1000 * f.flota / nullif(p.poblacion, 0) as flota_por_1000_hab
```
- **Páginas:** conservar `anio`, `municipio`, `provincia`, `poblacion`, `flota`, `flota_por_habitante`, `cuota_flota_espana`, `ivtm_turismo*`, `capital`, `ahorro_*`; la página puede pasar a `cuota_flota_espana_pct` y quitar sus `* 100` (resumen + gráficos).
- **Ficha:** desaparece «proporción 0-1 en vez de %».
- **Esfuerzo/riesgo:** bajo; la migración de la página es opcional y mecánica.

### movilidad_marcas_mensual
- **Modelo:** transform/models/marts/movilidad_marcas_mensual.sql · **Páginas:** `movilidad/camiones-y-autobuses.md` (4 traducciones) · **Prioridad:** 3
- **Problemas:** códigos sin etiqueta (`grupo` = `turismo`/`camion`, `energia` = `bev`, `canal` = `renting`) frente a `movilidad_matriculaciones_mensual`, que sí trae `grupo_etiqueta`, `energia_etiqueta`, `canal_etiqueta`; falta `anio`; no hay fila de total (inherente, solo nuevos).
- **Cambio propuesto:** unir con las semillas `movilidad_grupos`, `movilidad_energias`, `movilidad_canales` (como el modelo hermano) y añadir `grupo_etiqueta`, `energia_etiqueta`, `canal_etiqueta` y `anio`.
```sql
left join {{ ref('movilidad_grupos') }} g on g.grupo = m.grupo   -- g.etiqueta as grupo_etiqueta
left join {{ ref('movilidad_energias') }} e on e.energia = m.energia
left join {{ ref('movilidad_canales') }} c on c.canal = m.canal
```
- **Páginas:** conservar `mes`, `grupo`, `energia`, `canal`, `marca`, `grupo_empresarial`, `matriculaciones`; ninguna migra.
- **Ficha:** se queda el `defecto: grupo` (no mezclar tipos de vehículo), pero desaparece la necesidad de explicar códigos.
- **Esfuerzo/riesgo:** bajo; tabla agregada pequeña, joins a semillas de pocas filas.

### movilidad_matriculaciones_mensual
- **Modelo:** transform/models/marts/movilidad_matriculaciones_mensual.sql · **Páginas:** `index.md`, `movilidad/camiones-y-autobuses.md`, `coche-electrico.md`, `flotas-e-impuestos.md`, `index.md`, `marcas-y-modelos.md`, `parque.md` (28 traducciones) · **Prioridad:** —
- **Problemas:** el filtro `nuevo_usado = 'N'` y la ausencia de fila de total son reales (dimensión que no se mezcla) y todas las páginas ya lo gestionan; ya trae etiquetas, orden y color; falta `anio` pero `mes` sirve.
- **Cambio propuesto:** no tocar. Partirla en nuevos/usados rompería 7 páginas y 28 copias por un beneficio pequeño. Documentar `defecto: nuevo_usado = 'N'` en la ficha.
- **Páginas:** sin cambios.
- **Ficha:** se queda como `defecto` explícito (con cuándo usar `U`).
- **Esfuerzo/riesgo:** bajo (solo ficha).

### movilidad_matriculaciones_municipio
- **Modelo:** transform/models/marts/movilidad_matriculaciones_municipio.sql · **Páginas:** ninguna; no la usa ningún componente, banco de evaluación ni script (existe `sources/mother/movilidad_matriculaciones_municipio.sql`) (0 traducciones) · **Prioridad:** 1
- **Problemas:** sin nombre de municipio (solo `cod_mun`), sin provincia ni comunidad, sin población: no se puede ordenar «por habitante» ni preguntar por un pueblo por su nombre; las flotas inflan algunos municipios (para eso existe `particulares`). Sin ninguna página que la use, dejarla así es el peor caso para el chat. No la propongo borrar: tiene datos únicos (matriculaciones por energía para todos los municipios) y se solapa solo parcialmente con `movilidad_flotas_municipios`.
- **Cambio propuesto:** añadir `municipio`, `cod_prov`, `provincia`, `cod_ccaa`, `poblacion` (padrón del año acotado al último), `turismos_por_1000_hab`, `particulares_por_1000_hab` y `bev_pct`/`phev_pct`/`hev_pct` (0-100). Los municipios que no están en el padrón (nulos de población) conservan fila.
```sql
left join pob p on p.cod_mun = m.cod_mun and p.anio = least(m.anio, (select max(anio) from pob))
select ..., p.municipio, p.cod_prov, p.cod_ccaa, p.poblacion,
  1000.0 * turismos / nullif(p.poblacion, 0) as turismos_por_1000_hab,
  1000.0 * particulares / nullif(p.poblacion, 0) as particulares_por_1000_hab,
  100.0 * bev / nullif(turismos, 0) as bev_pct
```
- **Páginas:** ninguna usa la tabla; nada que conservar ni migrar.
- **Ficha:** desaparecen «sin nombre de municipio, solo código INE» y «dividir por población». Pasa a recomendarse `particulares_por_1000_hab` para ranking de pueblos.
- **Esfuerzo/riesgo:** bajo; municipio-año es una tabla de unas 40.000 filas; vigilar el cupo de MotherDuck (columnas nuevas pequeñas).

### movilidad_matriculaciones_provincia
- **Modelo:** transform/models/marts/movilidad_matriculaciones_provincia.sql · **Páginas:** `index.md`, `movilidad/coche-electrico.md` (8 traducciones) · **Prioridad:** 1
- **Problemas:** sin población ni versión por habitante (la ficha manda dividir); sin nombre de comunidad (solo `cod_ccaa`); filtros `nuevo_usado='N'` y de `canal` (flotas inflan Madrid, Barcelona, Baleares) inevitables pero fuera del chat; un ranking por total de matriculaciones favorece a las provincias grandes, justo lo que el principio de la web prohíbe.
- **Cambio propuesto:** añadir `poblacion` (provincia, año de `mes`, acotado al último padrón), `ccaa` (nombre), `matriculaciones_por_1000_hab` (aditiva: sumar sobre filas da el valor correcto) y `es_flota` BOOLEAN derivado de `canal` (`renting`, `alquiler`, `empresa` frente a `particular`) para que «sin flotas» sea una condición simple.
```sql
join {{ ref('poblacion_territorios') }} p on p.nivel = 'provincia' and p.cod = m.cod_prov
  and p.sexo = 'Total' and p.anio = least(year(m.mes), (select max(anio) from {{ ref('poblacion_territorios') }}))
select ..., p.poblacion, 1000.0 * sum(m.matriculaciones) / nullif(p.poblacion, 0) as matriculaciones_por_1000_hab
```
Advertencia: `poblacion` se repite en cada fila (mes x energía x canal): no sumarla, ponerlo en la ficha. Alternativa más limpia: no incluir `poblacion` y solo `matriculaciones_por_1000_hab`; recomiendo esta alternativa para evitar la trampa.
- **Páginas:** conservar `mes`, `cod_prov`, `cod_ccaa`, `provincia`, `energia`, `nuevo_usado`, `canal`, `matriculaciones`. `index.md` y `coche-electrico.md` usan cuotas (%), no totales, así que no necesitan migrar; el mapa de matriculaciones por provincia, si se añade, debe usar la columna nueva.
- **Ficha:** desaparece «sin per cápita: dividir por población»; sigue el `defecto: nuevo_usado = 'N'` y la nota de flotas.
- **Esfuerzo/riesgo:** medio; ~50.000 filas mes x provincia x energía x canal con un join de población por año; hay que comprobar que la suma por provincia-año sea la misma que antes.

### movilidad_modelos_mensual
- **Modelo:** transform/models/marts/movilidad_modelos_mensual.sql · **Páginas:** `movilidad/marcas-y-modelos.md` (4 traducciones) · **Prioridad:** 3
- **Problemas:** mismos códigos sin etiqueta que `movilidad_marcas_mensual`; el mismo coche con nombres distintos (`LEON` y `LEON SP`); solo 36 meses; sin `anio`.
- **Cambio propuesto:** añadir `grupo_etiqueta`, `energia_etiqueta`, `canal_etiqueta` y `anio` (como en marcas). La normalización de modelo (`modelo_base`) queda fuera: no hay reglas fiables y sería inventar; documentarlo en la ficha.
- **Páginas:** conservar `mes`, `grupo`, `energia`, `canal`, `marca`, `grupo_empresarial`, `modelo`, `matriculaciones`.
- **Ficha:** se elimina la explicación de códigos; se mantiene el aviso de variantes de nombre.
- **Esfuerzo/riesgo:** bajo.

### movilidad_parque_evolucion
- **Modelo:** transform/models/marts/movilidad_parque_evolucion.sql · **Páginas:** ninguna; la usa el banco de evaluación del chat (pregunta con `sql_oro` sobre ella) (0 traducciones) · **Prioridad:** 2
- **Problemas:** parque (stock) de España sin versión por habitante (`vehiculos` totales, sin comparar con la población); `mes` sin `anio`; sin total (hay que filtrar `grupo`); solo 17 cortes mensuales. Sin página, no la propongo borrar porque el chat la usa y el parque nacional por energía no está en otro sitio (`movilidad_parque_modelos` es solo el último mes).
- **Cambio propuesto:** añadir `vehiculos_por_1000_hab` (aditiva) con la población de España del año de `mes`, y `anio`.
```sql
join (select anio, poblacion from {{ ref('poblacion_territorios') }}
      where nivel = 'pais' and cod = '00' and sexo = 'Total') p
  on p.anio = least(year(p.mes), (select max(anio) from ...))
select ..., 1000.0 * sum(p.vehiculos) / any_value(pob.poblacion) as vehiculos_por_1000_hab
```
- **Páginas:** ninguna.
- **Ficha:** desaparece la nota de usar siempre `grupo = 'turismo'` para «coches» solo parcialmente (sigue siendo útil filtrar por grupo); se añade la columna por habitante como la recomendada.
- **Esfuerzo/riesgo:** bajo; unas decenas de filas.

### movilidad_parque_modelos
- **Modelo:** transform/models/marts/movilidad_parque_modelos.sql · **Páginas:** `movilidad/parque.md` (4 traducciones) · **Prioridad:** 3
- **Problemas:** filas `(modelo sin especificar)` que no son un modelo real y obligan a filtrar; códigos sin etiqueta; solo último mes y modelos con 100 o más unidades.
- **Cambio propuesto:** añadir `es_modelo_real` BOOLEAN (false para `(modelo sin especificar)`) y las etiquetas `grupo_etiqueta`, `energia_etiqueta`. No quitar las filas: la página puede estar mostrándolas.
```sql
modelo <> '(modelo sin especificar)' as es_modelo_real
```
- **Páginas:** conservar `mes`, `grupo`, `energia`, `marca`, `modelo`, `vehiculos`; quizá `parque.md` ya filtra las sin especificar, a comprobar al ejecutar.
- **Ficha:** la excepción pasa de «hay filas que no son un modelo» a `defecto: es_modelo_real`.
- **Esfuerzo/riesgo:** bajo.
