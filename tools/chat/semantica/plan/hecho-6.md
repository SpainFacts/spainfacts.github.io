# Hecho, lote 6

Base de pruebas: `data/limpieza-6.duckdb`. `probar-paginas.mjs --tabla <t>` da 0 errores en todas las páginas de mis tablas; los únicos errores que salen en `pages/territorios/[ccaa]/index.md` (`deuda_hab_serie`, `empleo_salario`, `empresas_aut`) son de otros lotes (tablas de otros lotes aún sin reconstruir en mi base). `validar.mjs --db data/limpieza-6.duckdb --tablas <las 30>`: 264 fichas, 0 errores. El aviso `tcu_por_familia: 0 filas` es de los datos (ningún partido llega a 300 observaciones con solo tres provincias rastreadas), no del cambio.

## Borradas

- `totalAno`, `totalAnoProvincia`, `totalAnoSexo`, `totalAnoSexoEdad`, `unemployment`: borrados sus `sources/mother/*.sql` y los modelos `poblacion_anual`, `poblacion_piramide` y `unemployment` (nadie más los usaba) y sus entradas de `schema.yml`. Ficha de `unemployment` quitada de `lote-8.json`; en `preguntas-desarrollo.json` (d06) `mother.unemployment` fuera de `tablas_oro`.

## Cambios por tabla

- **sanidad_listas_espera**: añadido `nombre` (join con `territorios`). Páginas: sin cambios (siguen uniendo con `territorios` para `ruta`). Ficha actualizada.
- **sanidad_recursos**: `geo` (código Eurostat) sustituido por `cod_pais` ISO2 (`EU27_2020` la media UE) vía seed `paises_iso`; añadido `nivel` (`pais`/`agregado`); `situacion` pasa a texto legible (`ejerciendo`/`activo`/`total`/`mixta`); quitada `por_100k` (duplicaba `por_1000`). Modelo `metricas_sociedad` adaptado (`cod_pais = 'ES'`). Páginas: `sociedad/salud.md` (5 idiomas) `geo`->`cod_pais`. Ficha y `sql_oro` de `preguntas-validacion3.json` actualizados.
- **sanidad_recursos_ccaa**: añadido `nombre`. Se dejan `por_100k` y `por_1000` porque `mapas_personas` (otro modelo) lee `por_100k`. Páginas sin cambios.
- **transparencia_internacional**: `cod_pais` pasa de ISO3 (con `EUU`/`OED` inventados) a ISO2 (`ES`, `EU27_2020`, `OECD`); `valor`, `valor_min` y `valor_max` de WJP y V-Dem pasan de 0-1 a 0-100 (se sustituye, no se añade columna); `unidad` unificada a "puntos 0-100". Páginas `comparacion-internacional.md` y `index.md` (5 idiomas): códigos de país, tarjetas, formatos de ejes, tablas, "centésimas" -> puntos, y texto de metodología traducido (es/en/ca/gl/eu). No he añadido `puntuacion_100_mejor` (la inversión de V-Dem la deja el sentido; ver dudas).
- **transparencia_liquidaciones**, **transparencia_pmp**, **transparencia_tcu**: añadidos `provincia` y `ccaa` (nombres) y la medida `incumple_pct` / `supera_30_pct` (100/0, NULL si no aplica). pmp: la columna publicada `fecha` (primer día del trimestre) sustituye a `fecha_trimestre`; páginas adaptadas. tcu: `anio` (entero) sustituye a `ejercicio`; páginas adaptadas. Los booleanos se conservan (las páginas cuentan con ellos).
- **transparencia_pie**: añadidos `importe_retenido_eur_real`, `_eur_hab`, `_eur_hab_real`, `anio_base`, `retenido_pct`, `provincia`, `ccaa`; `campania_completa` se publica como `es_parcial` (en el mart se mantiene porque lo lee `mapas_territorio`). `sources/mother/transparencia_pie.sql` actualizado. Página: `pie_importe_real` eliminada y `pie_lista` lee `importe_retenido_eur_real`; `pie_por_familia` usa `NOT es_parcial`.
- **transparencia_pie_mensual**: publicado con `fecha` (DATE, sustituye a `periodo`), `anio`, `municipio`, `provincia`, `importe_eur_real`, `importe_eur_hab`, `importe_eur_hab_real`, `anio_base` (el mart conserva `periodo` por `metricas_vivienda_cuentas`). Página: quitados los joins con `deflactor` en los cuatro bloques y `pie_importe_real`; `periodo`->`fecha`. `sql_oro` de las preguntas actualizado.
- **transparencia_publicidad_activa**: añadidos `ccaa`, `provincia`, `municipio` (nombres INE) junto a sus códigos. Página: la provincia de los ayuntamientos canarios sale de la columna (ya no el `CASE`).
- **vivienda_esfuerzo**: añadidos `euros_m2_real`, `precio_90m2_real`, `salario_anual_real`, `alquiler_mes_mediana_real`, `anio_base` (se conservan los corrientes, como `vivienda_precio_tasado`). Página `esfuerzo.md` (5 idiomas): variaciones de precio y salario y sparkline del salario en reales; texto "euros de cada año" -> "euros constantes de {anio_base}" traducido.
- **vivienda_mercado_anual**: `importe_hipotecas` (corrientes, sin uso) sustituido por `importe_hipotecas_real` y `importe_hipotecas_eur_hab_real`. `meses` ya cumple la regla del año parcial, no he añadido `es_parcial`. Páginas sin cambios.
- **vivienda_publica_internacional**: `valor` y `serie` sustituidos por `pct_parque_total` (OCDE) y `pct_viviendas_principales` (MIVAU/Eurostat); `cod_pais` ISO2 (`EU27_2020`, `OECD`). Se mantiene una tabla con dos columnas (como propone el plan) en vez de dos tablas. Páginas `vivienda-publica.md` (5 idiomas) adaptadas con alias `AS valor` para no tocar gráficas. `sql_oro` actualizado.

## No hecho y por qué

- `sanidad_listas_especialidad` (prioridad 3): exigiría añadir tres columnas constantes.
- `turismo_ccaa_mensual`, `turismo_mensual` (P3): las notas de las fichas ya dicen que los vacíos son NULL y los ceros de 2020 reales; sin cambios de datos.
- `vivienda_alquiler_municipios`, `trazabilidad_fuentes` (P3), y las de «—» (`territorios`, `vivienda_alquiler`, `vivienda_ipv`, `vivienda_mercado_mensual`, `vivienda_obra_nueva`, `vivienda_precio_tasado`, `vivienda_resumen_territorios`): sin cambios. Los cambios solo de ficha de `vivienda_alquiler` y `vivienda_ipv` (filtro fijo a `defecto`/`total`) quedan sin hacer.
- No he tocado `inventario.json` (sigue listando las 5 tablas borradas en `sin_uso`) ni el comentario de `catalogo.mjs`.

## Para el coordinador

- Al reconstruir con dbt hay que incluir las vistas de staging (en mi copia `transparencia_internacional` falló con "Catalog SpainFacts does not exist" hasta reconstruir `stg_transparencia_internacional+`).
- En mi base, `mapas_personas`, `mapas_territorio` y `metricas_vivienda_cuentas` fallan por cambios de otros lotes (`empresas_autonomos_anual`, `nivel` en salarios, `poblacion`); no por mis cambios. Revisar al final.
- Modelos de otros lotes que leen mis marts: `mapas_territorio` (`transparencia_pie.campania_completa`, que se mantiene en el mart), `metricas_vivienda_cuentas` (`transparencia_pie_mensual.periodo`, que se mantiene), `mapas_personas` (`sanidad_recursos_ccaa.por_100k`, que se mantiene).
- Decisión dudosa: no he añadido `puntuacion_100_mejor` en `transparencia_internacional`; el chat no puede mezclar indicadores V-Dem (más es peor) con los demás salvo leyendo `sentido`. Si se quiere, es una columna más.
- Ingestión: ninguna necesaria.
