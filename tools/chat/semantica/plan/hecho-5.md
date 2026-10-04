# Hecho: lote 5 (30 tablas)

Base de datos de pruebas: `data/limpieza-5.duckdb`. Resultado: `validar.mjs` 0 errores en las 29 tablas con ficha; `probar-paginas.mjs` sin errores en ninguna consulta que toque mis tablas (los errores que quedan en las páginas son de tablas de otros lotes cuyo `sources/mother` ya cambió pero cuyo modelo no está en mi copia de la base: `local_deuda_municipio`, `sanidad_recursos`, `movilidad_flotas_*`, `movilidad_marcas_*`, `empleo_*`, etc.).

Nota técnica: en `data/limpieza-5.duckdb` las vistas `staging.stg_*` venían apuntando al catálogo `SpainFacts` (MotherDuck) y hacían fallar todo lo que dependía de ellas; las reconstruí con `dbt run --select path:models/staging`.

## Hechas con cambios

### movilidad_parque_municipio (P1)
- Añadidas: `municipio`, `cod_prov`, `poblacion` (último padrón), `turismos_por_1000_hab`, `enchufables_pct`, `sin_distintivo_pct`, `mas_de_15_anios_pct` (0-100). Se mantienen los conteos (`turismos`, `bev`, `phev`, `hev`, `distintivo_*`, `sin_distintivo`, `mas_de_15_anios`) porque son cifras, no cuotas.
- Páginas: `movilidad/parque` (+ en, ca, gl, eu): sin `JOIN poblacion_municipios` ni divisiones a mano; columnas `*_pct` con formato `0.0"%"`.

### movilidad_parque_provincia (P1)
- Añadidas: `ccaa`, `poblacion` (se repite por fila, no se suma), `vehiculos_por_1000_hab` (aditiva dentro de una provincia).
- Páginas: `movilidad/parque` (+4): el ranking y el mapa/tabla de provincias ordenan y enseñan turismos por 1.000 hab. (antes por turismos absolutos).

### movilidad_recarga_evolucion (P3, hecha por ser barata)
- `tramo_potencia` con la misma mayúscula inicial que `movilidad_recarga_sitios`; añadidas `anio` y `tramo_orden`.
- Mart `metricas_energia.sql` (de otro lote): una sola línea editada (`tramo_potencia like 'rápida%'...` pasa a `tramo_orden <= 2`), porque la comparación de texto se rompía.

### movilidad_recarga_sitios (P2)
- Añadidas: `municipio`, `provincia`, `cod_ccaa`, `ccaa`. No hecho: `operador_grupo` (opcional, requiere seed).
- Página: `movilidad/recarga` (+4): el mapa deja de hacer `SELECT *` y lista las columnas que usa (para no mandar al navegador las nuevas).

### movilidad_transporte_modos (P1)
- Todos los modos tienen `clave` (25, antes 14; las claves ya usadas no cambian); añadidas: `clave_padre` (jerarquía validada: la suma de los hijos es el padre; `total` = urbano + interurbano + especial y discrecional; el avión y el barco SÍ están en el total, al contrario de lo que decía el plan), `es_hoja`, `anio`, `poblacion` (España, padrón del año acotado), `viajeros_por_1000_hab`. No hay `en_total` (sería verdadero en todas las filas). 1997 sin población (el padrón no existe).
- Páginas: `movilidad/index` y `movilidad/transporte-publico` (+8): usan `viajeros_por_1000_hab` en las series mensuales y quitan los `JOIN` con población. Los cálculos anuales y los de las tarjetas siguen con `poblacion_territorios` (no hay columna equivalente anual).

### municipios_cuentas (P1)
- Mart y `sources/mother`: añadidas `municipio`, `cod_prov`, `provincia`, `gasto_hab_real`, `ingreso_hab_real`, `gastos_total_real`, `ingresos_total_real`, `saldo_no_financiero_real`, `anio_base` (deflactor del año de cada fila). Capítulos y áreas siguen en euros corrientes (decisión del plan).
- El mart también lleva `saldo_hab_real` (no publicada aquí, sí en la serie).

### municipios_cuentas_serie (P1)
- Añadidas: `municipio`, `cod_prov`, `provincia`, `tramo_poblacion`, `tramo_orden` (mismo criterio que `municipios_cuentas_medias`), `gasto_hab_real`, `ingreso_hab_real`, `saldo_hab_real`, `gastos_total_real`, `ingresos_total_real`, `anio_base`.

### municipios_politicas (P1)
- Añadidas: `municipio`, `poblacion`, `importe_real`, `importe_hab_real`, `anio_base`. NO ampliado a tres ejercicios (decisión pendiente del dueño: triplicaría el peso a ~2,5 MB).
- Páginas de las tres: `territorios/municipios` (+4): `cuentas_serie` y `politicas_mun` usan las columnas `_real` y `tramo_*` (sin CASE repetido ni `JOIN deflactor` en `politicas_mun`). Siguen con el CTE `defl` las consultas `areas` y `personal_ayto` y el cálculo de `gasto_hab_tramo_real`: las medianas vienen de `municipios_cuentas_medias` (otro lote, en euros corrientes) y los capítulos/áreas no tienen `_hab_real`. También corregido el doble prefijo «Distrito Distrito 01» (ver renta_distritos).

### observatorios (P3: borrar)
- Borrados: `sources/mother/observatorios.sql`, `transform/models/marts/observatorios.sql`, su entrada en `schema.yml` y su ficha. `stg_observatorios` se conserva (lo usa `observatorios_detalle`). Ninguna página ni pregunta del banco la usaba.

### observatorios_detalle (P3, hecha por ser barata)
- `comunidad` renombrada a `ccaa` (sustituida, no duplicada) y añadida `provincia`. Página `varios/observatorios` (+4): `coalesce(ccaa, '') AS comunidad`. La ficha es `usar: false`, no cambia.

### poblacion_territorios (P2)
- Añadida `nombre` (de `territorios_ccaa`/`territorios_provincias`, sin ciclo con `territorios`); `sources/mother` enumera columnas y la incluye. Ninguna página cambia. Ficha: `territorio.nombre = nombre`.

### primario_paises_largo (P2: se mantiene como tabla pública enriquecida)
- Añadidas: `cod_pais` (ISO, GR), `valor_hab`, `unidad_hab`, `valor_real`, `valor_hab_real` (solo M EUR) y `anio_base`, con el IPCA de cada país (`deflactor_paises`), no con el IPC de España. `poblacion_miles` ahora sale de `poblacion_paises`.
- `geo` (código Eurostat, EL) se queda en el mart porque `primario_ranking_ue` (otro lote) lo usa, pero la tabla publicada lo excluye (`SELECT * EXCLUDE (geo)`). La ficha pasa a `usar: true`.
- Página `economia/sector-primario` (+4): la consulta del vino usa `cod_pais`.

### primario_pesca (P2)
- `geo` sustituido por `cod_pais`; `kg_hab` sustituido por `valor_hab` + `unidad_hab`; añadidas `valor_hab_real`; `valor_real` ahora con el IPCA de cada país (antes IPC de España en todos); `paises_sin_dato` lleva códigos ISO.
- Página: `cod_pais = 'ES'` y `valor_hab AS kg_hab` (4 idiomas).

### renta_distritos (P3: solo el error visible)
- Página `territorios/municipios` (+4): quitado el `'Distrito ' ||` que duplicaba el prefijo. No se añade `municipio` (P3 con columna nueva).

### renta_ecv_ccaa (P2)
- Añadida `nombre` (de `territorios`). Páginas sin cambios.

### renta_ue (P2)
- `geo` sustituido por `cod_pais` (GR; EU27_2020 para la UE); añadidas `unidad` (por indicador) y `es_agregado`. Ficha corregida (`es_ue` es verdadero solo para los 27 países). Página `sociedad/desigualdad` (+4): `geo = ...` pasa a `cod_pais = ...`.

### salud_causas_muerte (P2)
- `es_capitulo` sustituida por `tipo_causa` (total | capitulo | causa); añadida `nombre`. `sources/mother` filtra por `tipo_causa`. Página `sociedad/salud` (+4): `tipo_causa = 'capitulo'`.

### salud_esperanza_vida (P2)
- Añadidas `nombre` y `fuente` (Eurostat para España, INE para el resto). Páginas sin cambios.

### salud_mortalidad_semanal (P1)
- `semana` (último día) sustituida por `fecha` (lunes); `exceso` (0-1) sustituido por `exceso_pct` (0-100); añadidas `nombre`, `poblacion` (padrón del año acotado al rango; nula en 1997), `defunciones_por_100k_hab`, `media_2015_2019_por_100k_hab`, `exceso_hab_pct`. Se mantienen `defunciones` y `media_2015_2019` (cifras brutas).
- Página `sociedad/salud` (+4): el gráfico anual usa `exceso_hab_pct`, el semanal usa las tasas por 100.000 habitantes; textos visibles traducidos en los cuatro idiomas (títulos y la nota, que ahora dice que ya corrige el crecimiento de población pero no el envejecimiento). Banco de preguntas (`preguntas-validacion3.json`): `sql_oro` actualizado a `fecha`/`exceso_pct`.

### sanidad_gasto (P2)
- `geo` sustituido por `cod_pais` (GR, EU27_2020); añadida `es_agregado`; `eur_hab_real` ahora para todos los países (IPCA de cada país, antes solo España con IPC) y añadida `millones_eur_real`. Páginas `sociedad/salud` (+4): `cod_pais`.
- Mart `metricas_sociedad.sql` (de otro lote): una línea editada (`where geo = 'ES'` pasa a `where cod_pais = 'ES'`).

### sanidad_gasto_ccaa (P2)
- Añadida `nombre` (`Total comunidades autónomas` para el `00`). La ficha ya no dice que `00` es España. Páginas `sociedad/salud` (+4): quitada la división `pct_pib / 100` (la columna ya es 0-100) y formato `0.0"%"`.

## Sin cambios (a propósito)
- `pensiones_afiliados_regimen`, `pensiones_anual`, `pensiones_territorio` (plan: «—»). Siguen pasando sus páginas.
- Prioridad 3 que añadían columnas, no hechas: `primario_aceite` (cod_pais, es_agregado), `primario_aceite_precios` (cod_pais, anio), `primario_ccaa_cultivos` (cod_ccaa, es_agregado), `primario_mundo` (cod_pais, es_agregado), `primario_serie_espana` (cobertura_completa), `renta_ecv_edad` (es_agrupacion). En `renta_ecv_edad` solo se corrigió la nota de la ficha (los grupos con `orden` 1-5 no se solapan; «Menos de 18» y «De 18 a 64» sí). En `primario_aceite` solo se cambió la fuente de la población (ver abajo).

## Avisos para el coordinador
1. **Colisión de nombre en la ingestión**: `ingestion/eurostat.py` crea `eurostat_poblacion_paises` con columna `poblacion` (demo_gind), pero el pipeline `primario` ya cargaba una tabla con el mismo nombre y columna `valor` (nama_10_pe, miles). Con `write_disposition="replace"` el que corra último pisa al otro y rompe los modelos que leen `valor`. Yo he pasado `primario_paises_largo` y `primario_aceite` a `poblacion_paises`, pero **siguen leyendo `valor` `primario_ranking_ue` y `primario_valor_produccion`** (otro lote): en mi base `primario_valor_produccion` queda con 0 filas y `primario_ranking_ue` sin cuota de población. Hay que renombrar una de las dos tablas raw o moverlas a esos dos modelos.
2. Errores aguas abajo que NO son míos (modelos de otros lotes a medio cambiar): `metricas_energia` (columna `anio` en `alm_anual`), `metricas_economia`/`metricas_sociedad` (`cod_pais` en `sanidad_recursos`), `mapas_personas`, `mapas_territorio` (`cod`), `metricas_vivienda_cuentas` (`cuentas_balance_anual.poblacion`).
3. `inventario.json` aún lista `observatorios`; se regenera con `inventario.mjs`.
4. Páginas editadas con texto visible nuevo (hay que actualizar `i18n_origen`): `sociedad/salud.md` (5 idiomas). Mapas y tablas de `movilidad/parque.md` también cambian de columnas, sin texto nuevo salvo el título de columna «Por 1.000 hab.» que ya existía en las traducciones.
5. `sources/mother/municipios_cuentas*.sql` y `municipios_politicas.sql` enumeran columnas: ya incluyen las nuevas (revisar el peso del parquet tras el build: se añaden unas 8 columnas y `provincia`/`municipio` con codificación por diccionario).
6. `movilidad_transporte_modos.poblacion` y las tasas mensuales de 1997 son nulas (INE no publica padrón 1997); lo mismo en `salud_mortalidad_semanal` para 1997.
