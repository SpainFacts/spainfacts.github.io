# Plan de limpieza, lote 6 (30 tablas)

Notas comunes a todo el lote:
- Todo cambio es **aditivo**: columnas nuevas al lado de las viejas. Si la tabla publicada es un `SELECT` con lista de columnas en `sources/mother/<tabla>.sql` (pie_mensual, liquidaciones, pmp, tcu...), hay que añadir las columnas nuevas también ahí, no solo en el modelo dbt.
- Para nombres de territorio: `left join {{ ref('territorios') }}` por `nivel`/`cod` (como hace `turismo_ccaa_mensual`). Para euros reales: `left join {{ ref('deflactor') }} d on d.anio = ...` y `valor * d.factor` (como `sanidad_gasto` o `vivienda_alquiler`). Para por habitante: `{{ ref('poblacion_territorios') }}` (nivel, cod, sexo = 'Total'), con el año más cercano fuera de rango (patrón de `vivienda_mercado_anual`).
- Códigos de país: `transparencia_internacional`, `vivienda_publica_internacional` y `sanidad_recursos` usan ISO alfa-3 (`ESP`, `EUU`, `OED`) o códigos de Eurostat (`EL`, `UE`), no ISO alfa-2 como pide CONVENCIONES. Propongo **un solo seed `paises_iso`** (iso3, iso2, nombre; con `EUU`->`EU27_2020` y `OED`->`OECD`) compartido por las tres tablas y por cualquier otro lote con países. Hay que coordinarlo con los otros lotes (p. ej. `internacional_comparativa` también usa `'ESP'`).
- Nombre de columnas de porcentaje: `pct_espera_larga`, `pct_nueva`... usan prefijo `pct_` en vez del sufijo `_pct` de CONVENCIONES. Es cosmético: **no lo toco** salvo en columnas nuevas.

---

### sanidad_listas_especialidad
- **Modelo:** transform/models/marts/sanidad_listas_especialidad.sql · **Páginas:** pages/sociedad/salud.md (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo total nacional pero sin `nivel`/`cod` (la ficha dice territorio nulo); `pacientes` es nulo en `tipo='consultas'` y la unidad de `pacientes` cambia con el tipo; `tipo` tiene defecto `quirurgica`.
- **Cambio propuesto:** añadir `'pais' as nivel, '00' as cod, 'España' as nombre` para que cruce con `sanidad_listas_espera` igual que el resto. `tipo` se queda (es una dimensión legítima con unidades distintas); no la parto en dos tablas porque la página la filtra por `tipo`.
  ```sql
  'pais' as nivel, '00' as cod, 'España' as nombre,
  ```
- **Páginas:** usan `fecha, tipo, especialidad, tasa_1000, pct_espera_larga, dias_medio`; se conservan tal cual. Ninguna necesita migrar.
- **Ficha:** `territorio: null` pasa a nivel/cod/nombre/espana; el resto (defecto de `tipo`) se queda.
- **Esfuerzo/riesgo:** bajo, tres columnas constantes.

### sanidad_listas_espera
- **Modelo:** transform/models/marts/sanidad_listas_espera.sql · **Páginas:** pages/sociedad/salud.md, pages/territorios/[ccaa]/index.md (8 traducciones) · **Prioridad:** 2
- **Problemas:** `cod` sin nombre (la ficha obliga a unir con `territorios`; las dos páginas ya lo hacen con `JOIN territorios ON cod`); `tipo` y `corte` (junio/diciembre) como dimensiones con defecto.
- **Cambio propuesto:** añadir `nombre` desde `territorios` (España = `00` -> `pais`). `tipo` y `corte` son dimensiones reales (junio y diciembre no se comparan entre sí), así que se quedan.
  ```sql
  left join {{ ref('territorios') }} t on t.cod = r.cod and t.nivel = r.nivel  -- r = unión pais/ccaa
  ... t.nombre as nombre
  ```
- **Páginas:** conservan `nivel, cod, fecha, anio, corte, tipo, tasa_1000, dias_medio, pct_espera_larga, pacientes`. Las dos páginas pueden dejar de unir con `territorios` (opcional, no urgente).
- **Ficha:** desaparece el "sin nombre de territorio: unir con territorios" y `nombre: null` pasa a `nombre`.
- **Esfuerzo/riesgo:** bajo, un join por clave única.

### sanidad_recursos
- **Modelo:** transform/models/marts/sanidad_recursos.sql · **Páginas:** pages/sociedad/salud.md (4 traducciones) · **Prioridad:** 2
- **Problemas:** `geo` es código Eurostat (`EL`=Grecia, `UE`), no ISO; `situacion` (PRACT/PACT/total/mixta) aparece en la ficha con `defecto: PRACT`, pero el modelo ya elige una sola fila por (año, país, recurso) con `qualify` (PRACT antes que PACT), así que filtrar por `PRACT` **elimina países que solo informan PACT**; la media UE mezcla `pais` y `geo` ad hoc; `por_100k` y `por_1000` duplicados.
- **Cambio propuesto:** añadir `cod_pais` ISO-2 (EL->GR, UE->EU27_2020) y `nivel` (`pais` / `agregado`), y `situacion_txt` legible. La ficha deja de poner defecto en `situacion` (es informativa).
  ```sql
  p.iso2 as cod_pais,
  case when geo = 'UE' then 'agregado' else 'pais' end as nivel,
  case situacion when 'PRACT' then 'ejerciendo' when 'PACT' then 'activo' when 'mixta' then 'mixta' else situacion end as situacion_txt
  ```
- **Páginas:** conservan `geo, pais, recurso, anio, por_1000, numero, n_paises` (filtran por `geo IN ('ES','UE')`). No hace falta migrarlas.
- **Ficha:** desaparece el `defecto: PRACT` y la nota "no sumar situaciones" (una fila por país/año/recurso); territorio pasa a `cod_pais`+`pais`.
- **Esfuerzo/riesgo:** bajo-medio, depende del seed `paises_iso`.

### sanidad_recursos_ccaa
- **Modelo:** transform/models/marts/sanidad_recursos_ccaa.sql · **Páginas:** pages/sociedad/salud.md, pages/territorios/[ccaa]/index.md (8 traducciones) · **Prioridad:** 2
- **Problemas:** `cod` sin nombre (la ficha manda unir con `territorios`); `nuts2` es un segundo código alternativo; `recurso` mezcla médicos y camas (magnitudes distintas pero misma unidad por 1.000 hab, es una dimensión válida).
- **Cambio propuesto:** añadir `nombre` desde `territorios` y mantener `nuts2`. `recurso` se queda.
  ```sql
  left join {{ ref('territorios') }} t on t.cod = b.cod and t.nivel = b.nivel
  ... t.nombre as nombre
  ```
- **Páginas:** conservan `anio, nivel, cod, recurso, por_1000, numero`. Las dos páginas ya unen con `territorios`, siguen valiendo.
- **Ficha:** `nombre: null` pasa a `nombre`; desaparece la nota de unir por `cod`.
- **Esfuerzo/riesgo:** bajo.

### territorios
- **Modelo:** transform/models/marts/territorios.sql · **Páginas:** 35 páginas (140 traducciones) y `src/lib/chat/decision.js` · **Prioridad:** — (dejar como está)
- **Problemas:** ninguno de datos. Es la dimensión de referencia (nivel, cod, cod_ccaa, cod_ccaa_hacienda, nombre, slug, ruta, poblacion_ultima). La ficha ya dice `usar: false`.
- **Cambio propuesto:** no tocarla. Solo cuando llegue la fase de municipios del plan de territorios se le añadirán las filas de nivel `municipio`; no es parte de esta limpieza.
- **Páginas:** todas dependen de ella; cualquier cambio de columnas rompe 140 copias.
- **Ficha:** sin cambios (no usable por diseño).
- **Esfuerzo/riesgo:** ninguno.

### totalAno
- **Modelo:** transform/models/marts/poblacion_anual.sql (vía sources/mother/totalAno.sql) · **Páginas:** ninguna (0 traducciones) · **Prioridad:** 2
- **Problemas:** importación de la primera versión con columnas `Year`/`Total` en mayúscula y año como texto; duplica `mother.poblacion_territorios` (nivel `pais`, sexo `Total`). Sin ficha, el catálogo ya la excluye a mano (`tools/chat/catalogo.mjs`).
- **Cambio propuesto:** **borrar** `sources/mother/totalAno.sql`. Comprobado: ni `pages/` (ES y traducciones), `src/`, `ingestion/`, `orchestration/` ni `tools/` la usan (solo un comentario en `src/lib/chat/herramientas.js` y `catalogo.mjs`). Los modelos `poblacion_anual` y `poblacion_piramide` solo existen para estas cuatro; si las cuatro se borran, el modelo `poblacion_anual` puede borrarse también (sigue declarado en `schema.yml`; `poblacion_piramide` también). Los restos en `.claude/worktrees/peaceful-ptolemy-...` son de un worktree antiguo, ignorarlos.
- **Páginas:** ninguna. Reemplazo: `mother.poblacion_territorios WHERE nivel='pais' AND sexo='Total'`.
- **Ficha:** no tiene; desaparece de `inventario.json` y del cálculo de excluidas de `catalogo.mjs`.
- **Esfuerzo/riesgo:** bajo; solo borrar ficheros y quitar de `schema.yml`. Antes, ejecutar `grep` final en pages/ (hecho hoy: 0 coincidencias).

### totalAnoProvincia
- **Modelo:** transform/models/marts/poblacion_anual.sql (vía sources/mother/totalAnoProvincia.sql) · **Páginas:** ninguna · **Prioridad:** 2
- **Problemas:** columnas `statecode`, `Provincias`, `Población`, `Year` (nombres con tilde y mayúsculas, año texto); duplica `poblacion_territorios` nivel `provincia`.
- **Cambio propuesto:** **borrar** `sources/mother/totalAnoProvincia.sql`. Reemplazo: `mother.poblacion_territorios WHERE nivel='provincia' AND sexo='Total'` + `territorios` para el nombre.
- **Páginas:** ninguna.
- **Ficha:** sin ficha; sale del inventario.
- **Esfuerzo/riesgo:** bajo, igual que `totalAno`.

### totalAnoSexo
- **Modelo:** transform/models/marts/poblacion_anual.sql (vía sources/mother/totalAnoSexo.sql) · **Páginas:** ninguna · **Prioridad:** 2
- **Problemas:** `Year`, `Total`, `Sexo` en mayúscula, año texto; duplica `poblacion_territorios` (nivel `pais`, sexos Hombres/Mujeres).
- **Cambio propuesto:** **borrar** `sources/mother/totalAnoSexo.sql`.
- **Páginas:** ninguna.
- **Ficha:** sin ficha; sale del inventario.
- **Esfuerzo/riesgo:** bajo.

### totalAnoSexoEdad
- **Modelo:** transform/models/marts/poblacion_piramide.sql (vía sources/mother/totalAnoSexoEdad.sql) · **Páginas:** ninguna (el comentario del modelo menciona `pages/demografia/estructura-edades`, pero esa página ya no la consulta) · **Prioridad:** 2
- **Problemas:** `Sexo, Anio, RangoEdad, Orden_Grupo, Total`; `RangoEdad` con valores `'0.0-4.0'` (decimales) en la tabla publicada; año texto; sin ficha.
- **Cambio propuesto:** **borrar** `sources/mother/totalAnoSexoEdad.sql`. Es la única pirámide por grupos quinquenales: confirmar con el dueño que la página de estructura de edades obtiene sus pirámides de otra tabla (comprobado: ninguna página nombra `totalAnoSexoEdad`). Si algún día se quiere pirámide en el chat, crear una tabla limpia (`anio`, `sexo`, `rango_edad`, `orden`, `poblacion`) con otro nombre.
- **Páginas:** ninguna.
- **Ficha:** sin ficha; sale del inventario.
- **Esfuerzo/riesgo:** bajo.

### transparencia_internacional
- **Modelo:** transform/models/marts/transparencia_internacional.sql · **Páginas:** pages/transparencia/comparacion-internacional.md, pages/transparencia/index.md (8 traducciones) · **Prioridad:** 1
- **Problemas:** `valor` mezcla escalas y sentidos en una columna (CPI 0-100 más es mejor, WGI 0-100, WJP 0-1 más es mejor, V-Dem 0-1 **más es peor**); sin una medida comparable el chat no puede rankear ni mezclar indicadores; `cod_pais` es ISO alfa-3 con códigos inventados `EUU`/`OED`.
- **Cambio propuesto:** añadir una columna normalizada y el ISO-2, sin tocar `valor`:
  ```sql
  case indicador_id
      when 'cpi' then valor when like 'wgi_%' then valor
      when like 'wjp_%' then 100 * valor
      when like 'vdem_%' then 100 * (1 - valor)   -- sentido invertido: más es mejor
  end as puntuacion_100_mejor,
  p.iso2 as cod_iso2     -- seed paises_iso; EUU -> EU27_2020, OED -> OECD
  ```
  (`puesto_ue`, `puesto_ocde` y `valor_min/max` no cambian.)
- **Páginas:** usan `valor`, `cod_pais IN ('ESP','EUU','OED')`, `puesto_ue`, `sentido`, `unidad`; hay que conservarlos. Las gráficas V-Dem de la página seguirían en escala 0-1 salvo que el dueño quiera pasarlas a `puntuacion_100_mejor` (cambia el significado visual, no lo propongo).
- **Ficha:** desaparece la nota de escalas y sentidos (medida principal pasa a `puntuacion_100_mejor`, unidad "puntos 0-100, más es mejor"); el `defecto: cpi` de `indicador_id` se queda; territorio pasa a `cod_iso2`.
- **Esfuerzo/riesgo:** medio, el cálculo es una línea, pero hay que validar el sentido V-Dem y consensuar el seed de países.

### transparencia_liquidaciones
- **Modelo:** transform/models/marts/transparencia_liquidaciones.sql · **Páginas:** pages/transparencia/cuentas-municipales.md (4 traducciones) · **Prioridad:** 2
- **Problemas:** el porcentaje de incumplimiento exige contar `incumple = true` **solo con `aplica_indicador = true`** (hay 323 filas forales por año con `incumple = false` que falsean la media); `cod_prov`/`cod_ccaa` sin nombre.
- **Cambio propuesto:** añadir una medida numérica que ya excluye lo no evaluable, más nombres de provincia/comunidad:
  ```sql
  case when aplica_indicador then (case when incumple then 100 else 0 end) end as incumple_pct,  -- NULL si no aplica
  tp.nombre as provincia, tc.nombre as ccaa
  ```
  Así `avg(incumple_pct)` es directamente el % de ayuntamientos, sin filtro.
- **Páginas:** conservan `incumple`, `aplica_indicador`, `remitida`, `anio`, `tramo_*`, `familia_en_plazo`, `poblacion`; siguen filtrando como hoy. No hace falta migrarlas.
- **Ficha:** desaparece el filtro fijo `aplica_indicador=true` y la nota "la respuesta se obtiene contando filas booleanas": medida principal `incumple_pct`.
- **Esfuerzo/riesgo:** bajo, una columna derivada y dos joins.

### transparencia_pie
- **Modelo:** transform/models/marts/transparencia_pie.sql · **Páginas:** pages/transparencia/cuentas-municipales.md (4 traducciones) · **Prioridad:** 1
- **Problemas:** `importe_retenido_eur` es nominal (sin real) y sin por habitante; `anio` es el ejercicio de referencia (no el año de pago), y el ejercicio en curso es parcial; incumple el principio rector; el chat necesita contar `retenido=true` entre `aplica_indicador`.
- **Cambio propuesto:** dentro del modelo, deflactar mes a mes con `transparencia_pie_mensual` (la misma lógica que hoy se repite en la página, `pie_importe_real`) y dividir por la población del propio ayuntamiento (`poblacion` ya está en la fila):
  ```sql
  imp.importe_real as importe_retenido_eur_real,            -- sum(importe_eur * d.factor) por mes de pago (year(periodo))
  importe_retenido_eur / nullif(poblacion, 0) as importe_retenido_eur_hab,
  importe_real / nullif(poblacion, 0) as importe_retenido_eur_hab_real,
  case when aplica_indicador then (case when retenido then 100 else 0 end) end as retenido_pct,
  not campania_completa as es_parcial
  ```
  `coalesce(d.factor, 1)` para el año en curso, igual que la página.
- **Páginas:** usan `importe_retenido_eur`, `sigue_retenido`, `retenido`, `seccion`, `anio`; se conservan. `pie_importe_real` de la página puede pasar a leer `importe_retenido_eur_real` (y se borra el join con `pie_mensual`), pero no es obligatorio.
- **Ficha:** desaparece "importe nominal sin ajustar", el filtro `aplica_indicador` y la nota de booleano; medida principal `importe_retenido_eur_hab_real` (y `retenido_pct` para el %).
- **Esfuerzo/riesgo:** medio, el deflactado mensual se agrega por (ayuntamiento, sección, ejercicio) y hay que cuadrar con lo que muestra la página hoy.

### transparencia_pie_mensual
- **Modelo:** transform/models/marts/transparencia_pie_mensual.sql (y `sources/mother/transparencia_pie_mensual.sql`, que publica solo 7 columnas) · **Páginas:** pages/transparencia/cuentas-municipales.md (4 traducciones) · **Prioridad:** 1
- **Problemas:** `importe_eur` nominal, sin por habitante; el publicado no lleva nombre de municipio ni población (la ficha avisa "hay que cruzar con otra tabla"); sin `anio`/`fecha` estándar (se llama `periodo`, TIMESTAMP).
- **Cambio propuesto:** el modelo dbt ya calcula más columnas (`nombre_pdf`, `importe_mes_eur`, `importe_compartido`) que el `SELECT` de `sources/mother` no publica. Añadir en el modelo y publicar:
  ```sql
  importe_eur * d.factor as importe_eur_real,        -- d.anio = year(periodo), coalesce(d.factor, 1) en el año en curso
  importe_eur / nullif(pob.poblacion, 0) as importe_eur_hab,
  importe_eur * d.factor / nullif(pob.poblacion, 0) as importe_eur_hab_real,
  m.nombre as municipio, cod_ccaa, year(periodo) as anio, periodo as fecha
  ```
  (población y nombre del municipio desde `poblacion_municipios`/ayuntamientos).
- **Páginas:** usan `periodo, seccion, ejercicio_referencia, cod_mun, cod_prov, por_dependientes, importe_eur`; se conservan. Los tres bloques que hoy hacen `sum(importe_eur * coalesce(d.factor,1))` pueden pasar a `sum(importe_eur_real)`, lo que además quita el join con `deflactor` de tres consultas.
- **Ficha:** desaparece "sin nombre de municipio, cruzar con otra tabla" y "euros sin por habitante ni reales"; medida principal `importe_eur_hab_real`.
- **Esfuerzo/riesgo:** medio, hay que publicar más columnas y verificar que la población cruza para todos los ayuntamientos (Ceuta/Melilla y municipios fusionados).

### transparencia_pmp
- **Modelo:** transform/models/marts/transparencia_pmp.sql · **Páginas:** pages/transparencia/cuentas-municipales.md (4 traducciones) · **Prioridad:** 2
- **Problemas:** `supera_30` booleano que solo vale entre `aplica_indicador=true` (7.858 de 8.130 filas por trimestre); `periodo` es texto `2026T2` y el tiempo real está en `fecha_trimestre`; `cod_prov`/`cod_ccaa` sin nombre.
- **Cambio propuesto:**
  ```sql
  case when aplica_indicador then (case when supera_30 then 100 else 0 end) end as supera_30_pct,
  fecha_trimestre as fecha,                       -- DATE estándar
  tp.nombre as provincia, tc.nombre as ccaa
  ```
- **Páginas:** conservan `periodo`, `fecha_trimestre`, `pmp_dias`, `supera_30`, `reporta`, `aplica_indicador`, `tramo_*`, `familia_en_plazo`. No hace falta migrar.
- **Ficha:** desaparece el filtro fijo `aplica_indicador=true` y la nota de booleano; tiempo pasa de `periodo` a `fecha`.
- **Esfuerzo/riesgo:** bajo.

### transparencia_publicidad_activa
- **Modelo:** transform/models/marts/transparencia_publicidad_activa.sql · **Páginas:** pages/transparencia/publicidad-activa.md (4 traducciones) · **Prioridad:** 2
- **Problemas:** mezcla tres evaluaciones distintas (ITCanarias, ICIO/MESTA y entidades del Consejo) en una sola columna `puntuacion` normalizada a 100 pero **no comparables entre sí**; para tener la nota actual hay que filtrar `es_ultima=true` y `estado='evaluada'`; tipos de entidad con 40+ valores (`Ayuntamientos` y `Ayuntamiento`, `Fundaciones (C.A.)`, ...); códigos `cod_ccaa/cod_prov/cod_mun` sin nombre (`entidad` es solo el nombre de la entidad).
- **Cambio propuesto:** añadir `nivel` (`pais`/`ccaa`/`provincia`/`municipio`, `cod` y `nombre` desde `territorios` para la administración matriz, `NULL` si es un ente dependiente) y `puntuacion_pct` (= `puntuacion`, para fijar la unidad). **No fusiono tablas**; solo propongo que el chat y la ficha traten `indice` como dimensión obligatoria (no mezclar índices). Opcional: separar `ITCanarias` en su propia tabla si crecen otros índices.
  ```sql
  case when cod_mun is not null then 'municipio' when cod_prov is not null then 'provincia'
       when cod_ccaa is not null then 'ccaa' else 'pais' end as nivel
  ```
- **Páginas:** conservan `evaluador, indice, tipo_administracion, tipo_entidad, anio, estado, puntuacion, familia, gobernante, es_ultima, url_fuente`. No hay que migrar nada.
- **Ficha:** desaparece el filtro fijo `es_ultima=true`? **No**: sigue siendo necesario (serie histórica); lo que sí desaparece es "no usable por territorio" (nivel+cod+nombre) y el aviso de escalas originales.
- **Esfuerzo/riesgo:** medio, el nivel se deriva sin ambigüedad pero conviene revisar entes dependientes sin código.

### transparencia_tcu
- **Modelo:** transform/models/marts/transparencia_tcu.sql (y `sources/mother/transparencia_tcu.sql`) · **Páginas:** pages/transparencia/cuentas-municipales.md (4 traducciones; hace `SELECT *`) · **Prioridad:** 2
- **Problemas:** el tiempo está en `ejercicio` y no en `anio`; `incumple` booleano solo válido con `aplica_indicador=true` (p. ej. `cuenta_general` 2025 `no_vencido` tiene `aplica=false`); `obligacion` mezcla tres obligaciones con rangos de ejercicio distintos (`cuenta_general` 2012-2025, `contratos` 2021-2025, `control_interno` 2020-2024); solo cubre La Rioja, Cádiz y A Coruña (238 ayuntamientos).
- **Cambio propuesto:**
  ```sql
  cast(ejercicio as integer) as anio,
  case when aplica_indicador then (case when incumple then 100 else 0 end) end as incumple_pct,
  tp.nombre as provincia, tc.nombre as ccaa
  ```
  No borro filas ni separo la tabla por obligación: la ficha ya lo trata como dimensión con ejemplos.
- **Páginas:** hace `SELECT *`, así que añadir columnas es seguro; conserva `ejercicio`, `obligacion`, `estado`, `dias_retraso`, `incumple`, `aplica_indicador`, `fecha_*`.
- **Ficha:** desaparece el filtro fijo `aplica_indicador`, la nota de booleano y "tiempo en columna no estándar" (`anio`).
- **Esfuerzo/riesgo:** bajo.

### trazabilidad_fuentes
- **Modelo:** transform/models/marts/trazabilidad_fuentes.sql · **Páginas:** pages/fuentes/index.md, pages/index.md (8 traducciones) · **Prioridad:** 3
- **Problemas:** es un catálogo de metadatos de 144 fuentes (no responde preguntas de datos; ficha `usar: false`); la columna `estado_pipeline` es un literal fijo `'Sincronizado / Activo'` para todas las filas (no refleja el estado real).
- **Cambio propuesto:** no tocar la tabla ni mover nada. Opcional y cosmético: quitar el literal falso y mostrar la fecha de última ingesta real (hay que ver si existe); si no existe, dejar la columna y no mostrarla en la página.
- **Páginas:** `fuente_id, organismo, nombre_dataset, cod_oficial, frecuencia, formato_ingesta, tipo_licencia, url_oficial, metodologia, estado_pipeline`; se conservan.
- **Ficha:** sin cambios (no usable por diseño).
- **Esfuerzo/riesgo:** bajo; el único riesgo es mostrar un estado inventado.

### turismo_ccaa_mensual
- **Modelo:** transform/models/marts/turismo_ccaa_mensual.sql · **Páginas:** pages/territorios/[ccaa]/index.md (4 traducciones) · **Prioridad:** 3
- **Problemas:** ya tiene `cod_ccaa`+`comunidad`, euros reales y por 1.000 hab. La ficha dice que fuera de seis comunidades "valen 0": **es falso**, en los datos son `NULL` (332 de 332 filas con turistas nulos en las 13 comunidades sin dato, 0 ceros reales salvo abril y mayo de 2020, que son ceros verdaderos por la pandemia). Falta `nivel` (`'00'` España conviven con comunidades) y gasto por habitante.
- **Cambio propuesto:**
  ```sql
  case when p.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
  1e6 * p.gasto_real_meur / po.poblacion as gasto_real_eur_hab
  ```
- **Páginas:** usan `cod_ccaa, anio, mes, pernoct_*, turistas, turistas_1000hab, gasto_real_meur`; se conservan (calculan `turistas_por_hab`/`gasto_real_por_hab` en la propia consulta; pasan a la columna nueva si se quiere).
- **Ficha:** se corrige la nota "valen 0, no son datos reales" (son nulos); `espana` pasa a `nivel='pais'`.
- **Esfuerzo/riesgo:** bajo.

### turismo_mensual
- **Modelo:** transform/models/marts/turismo_mensual.sql · **Páginas:** pages/economia/turismo.md (4 traducciones) · **Prioridad:** 3
- **Problemas:** ya está en reales y por 1.000 hab; la ficha dice "los 0 corresponden a meses sin dato aún publicado", pero en la tabla hay 201 meses con `turistas` NULL y solo 2 ceros (abril y mayo de 2020, verdaderos). Falta el gasto mensual por habitante (solo existe `gasto_real_por_hab_12m`).
- **Cambio propuesto:** añadir `1e6 * gasto_real_meur / poblacion as gasto_real_eur_hab` en el modelo. Nada más; las `_12m` son acumulados móviles y se quedan.
- **Páginas:** usan `mes, anio, turistas, turistas_12m, turistas_por_hab_12m, gasto_*`; la página incluso cuenta los meses con `turistas = 0` de 2020 como meses a cero reales, luego **no se deben convertir a NULL**.
- **Ficha:** corregir la nota de ceros (la ficha ahora engaña al chat, que ignoraría los ceros reales de 2020).
- **Esfuerzo/riesgo:** bajo.

### unemployment
- **Modelo:** transform/models/marts/unemployment.sql (`stg_ine_paro`, tabla INE 65219) · **Páginas:** ninguna (solo la cita `tools/chat/evaluacion/preguntas-desarrollo.json`, pregunta d06, como tabla "de oro" alternativa) · **Prioridad:** 2
- **Problemas:** formato de la primera versión: `date, value, serie, cod_serie`, con el sexo y la edad dentro del texto de `serie` (39 series, nombres con dos órdenes distintos, hay que filtrar con `LIKE`); solo nacional y duplica `mercado_paro_trimestral.tasa_paro` (98 trimestres desde 2002).
- **Cambio propuesto:** **borrar** `sources/mother/unemployment.sql` (el modelo dbt `unemployment` se puede borrar también; `stg_ine_paro` sigue usándolo `metricas_base`). Pérdida real: el cruce sexo x grupo de edad quinquenal (`mercado_paro_grupos` da sexo y edad **por separado** y con 5 grupos). Si el dueño quiere conservar ese cruce, convertirla en `mercado_paro_sexo_edad` (`fecha, anio, trimestre, sexo, grupo_edad, tasa_paro`) parseando `serie`, en vez de borrarla. Mi propuesta es borrar; actualizar d06 quitando `mother.unemployment` de `tablas_oro`.
- **Páginas:** ninguna.
- **Ficha:** sale del lote (su ficha explicaba el `LIKE` y la serie por defecto).
- **Esfuerzo/riesgo:** bajo si se borra; medio si se reconvierte.

### vivienda_alquiler
- **Modelo:** transform/models/marts/vivienda_alquiler.sql · **Páginas:** pages/territorios/[ccaa]/index.md, [provincia].md, pages/vivienda/alquiler.md, pages/vivienda/index.md (16 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** ya tiene euros reales, `nivel/cod/nombre` y por 1.000 hab (`alquiladas_1000`). Dos filas por territorio y año (`tipologia` Colectiva/Unifamiliar, 14 años en España, 243 en CCAA, 681 en provincias cada una), y la ficha las filtra con `tipologia='Colectiva'`.
- **Cambio propuesto:** no tocar. `tipologia` es una dimensión legítima con valor por defecto; no vale la pena crear una tabla por tipología porque las páginas filtran por ella. Si molesta, solo mover el filtro de la ficha al campo `defecto`.
- **Páginas:** todas las columnas actuales; ninguna cambia.
- **Ficha:** el filtro fijo `tipologia=Colectiva` pasa a `defecto` de la dimensión (un cambio solo de ficha).
- **Esfuerzo/riesgo:** ninguno (solo ficha).

### vivienda_alquiler_municipios
- **Modelo:** transform/models/marts/vivienda_alquiler_municipios.sql · **Páginas:** pages/territorios/[ccaa]/[provincia].md, pages/vivienda/alquiler.md (8 traducciones) · **Prioridad:** 3
- **Problemas:** tiene `cod_mun`+`municipio` pero `cod_prov` y `cod_ccaa` sin nombre; ya está en reales y por 1.000 hab. Sin `nivel`. Sin `tipologia` (solo Colectiva, el modelo la filtra).
- **Cambio propuesto:** añadir `provincia`, `ccaa` desde `territorios` (las páginas ya unen con `territorios` por `cod_prov`).
  ```sql
  tp.nombre as provincia, tc.nombre as ccaa
  ```
  Nota en la ficha: tabla solo de pisos (Colectiva), no de unifamiliares.
- **Páginas:** conservan `cod_mun, municipio, cod_prov, anio, alquiler_mes_mediana_real, superficie_mediana, alquiladas_1000, variacion_real_5a`.
- **Ficha:** desaparece la falta de nombre de provincia/comunidad; el resto igual.
- **Esfuerzo/riesgo:** bajo.

### vivienda_esfuerzo
- **Modelo:** transform/models/marts/vivienda_esfuerzo.sql · **Páginas:** pages/vivienda/esfuerzo.md, alquiler.md, index.md, pages/territorios/[ccaa]/index.md (16 traducciones) · **Prioridad:** 1
- **Problemas:** `euros_m2`, `precio_90m2`, `salario_anual` y `alquiler_mes_mediana` son **nominales** y la página los compara entre décadas (`var_precio` y `var_salario` entre el primer y el último año, gráficas de euros); los cocientes `anios_salario` y `pct_alquiler` sí valen (mismo año numerador y denominador), pero las cifras en euros inducen a conclusiones de inflación.
- **Cambio propuesto:** añadir versiones reales con el factor anual (cada uno ya viene en media anual; el salario además ya tiene `salario_real` en `economia_salarios_ccaa`):
  ```sql
  left join {{ ref('deflactor') }} d on d.anio = s.anio
  p.euros_m2 * d.factor as euros_m2_real,
  90 * p.euros_m2 * d.factor as precio_90m2_real,
  s.salario_anual * d.factor as salario_anual_real,
  a.alquiler_mes_mediana * d.factor as alquiler_mes_mediana_real
  ```
- **Páginas:** conservan `anios_salario, pct_alquiler, precio_90m2, salario_anual, alquiler_mes_mediana, euros_m2`. **Migrar a las columnas reales** las tarjetas de `var_precio`/`var_salario` y cualquier gráfica de euros que compare años (es lo que cumple el principio rector). `anios_salario` y `pct_alquiler` no cambian.
- **Ficha:** desaparece "importes nominales"; medidas pasan a `*_real` y `anios_salario` sigue como principal.
- **Esfuerzo/riesgo:** bajo-medio, el cálculo es trivial pero hay que cambiar el texto de la página que dice "creció un X %" para que sea real.

### vivienda_ipv
- **Modelo:** transform/models/marts/vivienda_ipv.sql · **Páginas:** pages/vivienda/precios.md (4 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** ninguno de fondo: índice base 2015=100 con `indice` y `indice_real`, `interanual_*`, `nivel/cod/nombre`. Tres tipos (General 1.520 filas, Nueva y Segunda mano 1.368 cada una) y la ficha usa `tipo='General'` como total.
- **Cambio propuesto:** no tocar. `tipo` es una dimensión con total `General`, que es exactamente lo que CONVENCIONES permite (`Total` o equivalente legible).
- **Páginas:** todas las columnas actuales.
- **Ficha:** el filtro fijo `tipo=General` pasa a `total: General` en la dimensión (solo ficha).
- **Esfuerzo/riesgo:** ninguno.

### vivienda_mercado_anual
- **Modelo:** transform/models/marts/vivienda_mercado_anual.sql · **Páginas:** pages/vivienda/compraventas.md, construccion.md, index.md (12 traducciones) · **Prioridad:** 2
- **Problemas:** `importe_hipotecas` en euros nominales (se suma entre años) y **sin por habitante**; el CTE ya calcula `importe_hipotecas_real` pero no lo publica; el año en curso es parcial (`meses`, ya está) y los totales no se comparan con años completos.
- **Cambio propuesto:** publicar lo que ya se calcula y añadir por habitante:
  ```sql
  importe_hipotecas_real,
  importe_hipotecas_real / nullif(poblacion, 0) as importe_hipotecas_eur_hab_real,
  meses < 12 as es_parcial
  ```
  (`importe_hipotecas_real` es la suma de los meses ya deflactados; no usar el factor anual.)
- **Páginas:** ninguna usa `importe_hipotecas` (comprobado); se conservan `compraventas`, `compraventas_1000`, `hipotecas_1000`, `importe_medio_real`, `pct_*`, `meses`.
- **Ficha:** desaparece la nota "importe en euros, no millones" como trampa y se añade `importe_hipotecas_eur_hab_real` como medida; la nota del año parcial se queda pero apoyada en `es_parcial`.
- **Esfuerzo/riesgo:** bajo.

### vivienda_mercado_mensual
- **Modelo:** transform/models/marts/vivienda_mercado_mensual.sql · **Páginas:** pages/territorios/[ccaa]/index.md, [provincia].md, pages/vivienda/compraventas.md, index.md (16 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** ya tiene `importe_*_real`, `_12m_1000`, `nivel/cod/nombre` y `fecha`+`anio`. Las `_12m` son acumulados móviles (la ficha ya lo avisa y es inherente); el importe va en euros, no millones, que es la convención.
- **Cambio propuesto:** no tocar.
- **Páginas:** todas las columnas actuales.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** ninguno.

### vivienda_obra_nueva
- **Modelo:** transform/models/marts/vivienda_obra_nueva.sql · **Páginas:** pages/territorios/[ccaa]/[provincia].md, pages/vivienda/construccion.md (8 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** ninguno de datos: `iniciadas`, `terminadas`, `iniciadas_1000`, `terminadas_1000`, `nivel/cod/nombre`. Solo vivienda libre (no protegida), que va en la ficha como nota.
- **Cambio propuesto:** no tocar.
- **Páginas:** todas las columnas actuales.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** ninguno.

### vivienda_precio_tasado
- **Modelo:** transform/models/marts/vivienda_precio_tasado.sql · **Páginas:** pages/territorios/[ccaa]/index.md, [provincia].md, pages/vivienda/index.md, precios.md (16 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** ninguno: `euros_m2` y `euros_m2_real`, `precio_90m2` y `precio_90m2_real`, `interanual_*`, `nivel/cod/nombre`, `fecha`+`anio`+`trimestre`. Solo vivienda libre (nota).
- **Cambio propuesto:** no tocar. Es el modelo de referencia para "euros reales" en vivienda (deflactor trimestral).
- **Páginas:** todas las columnas actuales.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** ninguno.

### vivienda_publica_internacional
- **Modelo:** transform/models/marts/vivienda_publica_internacional.sql · **Páginas:** pages/vivienda/vivienda-publica.md (4 traducciones) · **Prioridad:** 2
- **Problemas:** la columna `valor` es siempre un % pero de **dos definiciones distintas** (OCDE: % del parque total, 58 filas; UE: % de viviendas principales, 29 filas), separadas solo por `serie` con defecto `ocde_pct_parque` y filtro fijo `es_ultimo=true`; `cod_pais` ISO-3 con `OED` inventado; `viviendas_sociales` mezcla número de viviendas con el %.
- **Cambio propuesto:** dos columnas con una unidad y una definición cada una, sin quitar `valor`:
  ```sql
  case when serie = 'ocde_pct_parque' then valor end as pct_parque_total,
  case when serie = 'ue_pct_hogares'  then valor end as pct_viviendas_principales,
  p.iso2 as cod_iso2        -- OED -> OECD (seed paises_iso)
  ```
  Alternativa si el dueño lo prefiere: dos tablas (`vivienda_publica_ocde`, `vivienda_publica_ue`), pero implica tocar la página; no la recomiendo.
- **Páginas:** conservan `serie, cod_pais, pais, anio, valor, viviendas_sociales, es_agregado, es_espana, destacado, es_ultimo, fuente`; ninguna tiene que migrar.
- **Ficha:** desaparece el filtro fijo `es_ultimo=true` **solo si** se sigue sin quererlo en la ficha (se mantiene como defecto); desaparece la nota "no mezclarlas" (cada definición en su columna) y el `defecto` de `serie`.
- **Esfuerzo/riesgo:** bajo-medio, depende del seed `paises_iso`.

### vivienda_resumen_territorios
- **Modelo:** transform/models/marts/vivienda_resumen_territorios.sql · **Páginas:** pages/territorios/[ccaa]/index.md, [provincia].md, pages/vivienda/alquiler.md, compraventas.md, index.md, precios.md (24 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** es una "foto" derivada que reúne la última cifra de precio, alquiler, mercado, obra y esfuerzo (72 filas, cada indicador con su fecha: `precio_periodo`, `alquiler_anio`, `mercado_fecha`, `obra_anio`, `esfuerzo_anio`). Choca con "sin tablas duplicadas o auxiliares", pero seis páginas (24 copias) dependen de ella para dibujar los mapas y rankings en una sola consulta; todo está ya en reales o por 1.000 hab.
- **Cambio propuesto:** no tocar. Cuando el modelo de `vivienda_esfuerzo` tenga las columnas `_real` (ver arriba), no hará falta añadirlas aquí (solo `anios_salario`, `pct_alquiler`, que ya están).
- **Páginas:** todas las columnas actuales (24 copias).
- **Ficha:** sin cambios; la ficha ya avisa de que es solo foto del último dato y remite a las tablas con serie.
- **Esfuerzo/riesgo:** ninguno.
