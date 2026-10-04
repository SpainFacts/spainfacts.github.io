# Lote 3: lo hecho

Base: `data/limpieza-3.duckdb`. `dbt build` de las 28 tablas y de lo que cuelga de ellas: 0 errores propios (ver «Dependencias» para los 3 `metricas_*` que fallan por tablas de otros lotes). `probar-paginas` 0 errores en todas las páginas de mi lote (castellano y en/ca/gl/eu); solo fallan consultas `deuda_*` de `territorios/[ccaa]` por tablas de otro lote. `validar.mjs` 0 errores en las 32 fichas del lote.

Nota de entorno: la copia de la base traía 31 vistas `stg_*` que apuntaban al catálogo `SpainFacts` y fallaban; las reconstruí con `dbt run --select stg_...` (solo en `limpieza-3.duckdb`).

## Tablas

### empleo_salarios_ccaa (P2)
- Cambio: `cod_ccaa` sustituido por `nivel` + `cod` + `nombre`; añadida `brecha_publico_pct` (0-100). Sin euros reales: es una sola edición (2022).
- Páginas: `cuentas-publicas/empleo-publico` (quita el join con territorios y el cálculo `público/privado - 1`, la columna usa `fmt='0"%"'`), `territorios/[ccaa]/index` (`cod_ccaa` -> `nivel = 'ccaa' AND cod`). Las 4 traducciones de ambas.
- Otros modelos: `mapas_territorio` (usa `cod`, `nivel = 'ccaa'` y `brecha_publico_pct`).

### empleo_salarios_deciles (P1)
- Cambio: `decil` queda INTEGER 1-10 (vacío en la media, que ya no es «0»); `decil_nombre` (D1..D10, `Total`); `salario_mensual_real` + `anio_euros`; `anio` INTEGER. Se conserva `salario_mensual` (corrientes).
- Páginas: `empleo-publico` (5 consultas: deciles, brecha real sin join, serie real sin cálculo de IPC a mano), `economia/salarios` (consulta `deciles` sin join con `deflactor`). Más traducciones.
- Otros modelos: `metricas_vivienda_cuentas` (`decil = 0` -> `decil_nombre = 'Total'`, edición mínima en un modelo de otro lote).

### empleo_territorio (P3)
- Añadido `nombre`. Sin `anio` (no hace falta, `fecha` basta). Páginas sin cambios.

### empresas_autonomos (P2) -> partida en dos
- `empresas_autonomos` queda solo trimestral (sin `trimestre = 0`) con `nivel`, `nombre`; nueva `empresas_autonomos_anual` (media anual; modelo, `sources/mother`, schema y ficha). 
- Páginas: `economia/empresas` (3 consultas) y `territorios/[ccaa]/index` (1) + traducciones.
- Otros modelos: `mapas_personas` (usa la anual) y `metricas_economia` (quita `trimestre > 0`).

### empresas_concursos, empresas_dirce_sector, empresas_dirce_tamano, empresas_id_ccaa, empresas_sociedades_anual, empresas_sociedades_mensual (P3)
- Añadidos `nivel` + `nombre` (el código `cod` se queda). `empresas_dirce_sector`: `por_1000hab` renombrada a `por_1000_hab` (página `economia/empresas` + traducciones). `empresas_sociedades_mensual`: añadido `capital_real_12m_hab` (principio rector). Páginas sin más cambios.
- No hecho (P3, añaden columnas): `por_1000_hab` en `empresas_dirce_tamano`, `es_total_sector` en `empresas_id_ccaa`.

### empresas_dirce_territorio (P3)
- Añadido `nombre`; `crecimiento` -> `crecimiento_pct` (página `economia/empresas` + traducciones). `empresas_1000hab` se queda porque la usan `mapas_personas` y `metricas_economia` (modelos de otros lotes) y una pregunta de evaluación; renombrarla a `por_1000_hab` queda pendiente para el coordinador. No hecho: `otras_formas` (queda explicado en la ficha).

### empresas_tamano_ue (P3)
- `geo` -> `cod_pais` (ISO2, con el seed `paises_iso`; `pais` en castellano, p. ej. «Unión Europea (27)» en vez de «UE-27»); `vab_meur` sustituida por `vab_meur_real` + `vab_eur_hab_real` (IPCA de `deflactor_paises` y `poblacion_paises`) + `anio_euros`.
- Páginas: `economia/empresas` (filtros por `cod_pais` en vez de nombres de país), + traducciones.

### energia_emisiones_gei (P1)
- `año` -> `anio`; añadido `t_co2eq_hab` (población `poblacion_paises` ES, Eurostat); `porcentaje_total` -> `cuota_pct`.
- Página `energia-clima/index`: la gráfica en Mt se queda y se añade debajo la misma por habitante (título y eje traducidos a en/ca/gl/eu). Las dos cifras visibles.

### energia_mix_electrico (P2), energia_resumen_anual_mix (P2)
- `año` -> `anio`; añadido `generacion_kwh_hab` (y `demanda_kwh_hab` en el resumen); `porcentaje_total` -> `cuota_pct` en el mix.
- Páginas `energia-clima/index` y `mix-electrico` (todas las lenguas). No se cambió ninguna gráfica a kWh/hab (opcional).

### energia_potencia_instalada (P2)
- `año` -> `anio`, `porcentaje_total` -> `cuota_pct`. Sin por habitante (decisión del dueño: potencia en totales). `metricas_energia` actualizada (`anio`).

### gobierno_indultos_mensual (P2)
- Filtra desde 1977-07-01 (fuera la fila del 1200); `mes` -> `fecha`; añadida `es_parcial`. Página `indultos` sin cambios (solo lee `anio` e `indultos`).

### gobierno_presupuestos (P3)
- `ejercicio` -> `anio`, `en_curso` -> `es_parcial`. Página `transparencia/presupuestos` (primera consulta, con alias para no tocar el resto) + traducciones.

### industria_ccaa_ramas (P3)
- `ccaa` ahora con el nombre de `territorios`. Páginas sin cambios.

### industria_exportaciones_ue (P2)
- Quitadas `exportacion_es_eur` y `exportacion_ue_eur` (euros sin uso); añadidas `exportacion_es_real_eur_hab` y `destino_nombre` (el total en `exportacion_es_real_meur` se conserva: las dos cifras). Página `economia/industria`: la consulta y la tabla de exportaciones muestran las dos columnas (título nuevo traducido en las 5 lenguas).

### industria_ipi (P2) -> partida y borrada
- Sustituida por `industria_ipi_paises` (Eurostat, `cod_pais` ISO2 + `pais`) e `industria_ipi_ine` (INE: destino económico por territorio y divisiones, con `tipo_rama`, `nivel`, `nombre`). Borrados su `sources/mother/industria_ipi.sql`, su modelo y su ficha; creados los de las dos nuevas (sources, schema_industria.yml, fichas). Ninguna pregunta de evaluación la citaba.
- Página `economia/industria`: `ipi_anual` e `ipi_res` leen `industria_ipi_paises` (`cod_pais`). `industria_ipi_ine` no la lee ninguna página (antes tampoco usaba esas filas).

### industria_ipi_mensual (P3)
- `cod_ccaa` -> `nivel` + `cod` + `nombre` (de territorios); `mes` -> `fecha`; añadida `anio`; `es_subdestino` no añadida (explicado en la ficha). Página `economia/industria`: `ipi_mes`, `ipi_destinos` (+ traducciones).

### industria_ramas_ue (P3)
- Sin cambios (añadir `cifra_negocios_es_real_eur_hab` era P3 y añade columna).

### inmigracion_flujos (P3)
- `trimestre` -> `fecha`; añadidas `anio` y `es_parcial`. Ninguna página la usa.

### inmigracion_nacionalizaciones (P2)
- Añadidos `nivel`, `nombre`, `es_grupo`. Página `sociedad/inmigracion`: `nac_origen` usa `NOT es_grupo` en vez de 4 `NOT LIKE` (+ traducciones). Dependientes (`mapas_personas`, `metricas_sociedad`) sin tocar.

### inmigracion_poblacion (P1)
- `pct_extranjeros` (fracción) sustituida por `extranjeros_pct` (0-100); añadido `nombre`. Páginas `sociedad/inmigracion` (serie, mapa y tooltip con formato `0.0"%"`) y `metricas_sociedad` (quita el `100 *`). Pregunta de evaluación `preguntas-desarrollo` actualizada.

### inmigracion_saldos (P3)
- Añadido `nombre`. Sin más cambios.

### Sin tocar (—)
`gobierno_decretos_ley` (ficha sigue `usar: false`, no se cambió a true), `gobierno_presidencias_resumen`, `gobiernos_presidentes` (ya figura como referencia en CONVENCIONES.md).

## Evaluación
Actualizados `sql_oro` en `preguntas-desarrollo.json`, `preguntas-validacion2/3/4.json` (año -> anio, cuota_pct, extranjeros_pct, ejercicio -> anio, fecha, cod).

## Dependencias y avisos para el coordinador
- `metricas_vivienda_cuentas` (usa `cuentas_balance_anual.poblacion`), `metricas_sociedad` (usa `sanidad_recursos.cod_pais`) y `metricas_energia` (usa `almacenamiento_potencia.fecha`) fallan en mi base por tablas de otros lotes, no por mis cambios (`metricas_energia`: ya llevo su referencia a `anio` de potencia instalada).
- `tools/chat/semantica/inventario.json` no se ha regenerado.
- Pendiente de decisión: renombrar `empresas_dirce_territorio.empresas_1000hab` (`mapas_personas`, `metricas_economia`).
- Ediciones mínimas en modelos de otros lotes: `mapas_territorio`, `mapas_personas`, `metricas_economia`, `metricas_energia`, `metricas_sociedad`, `metricas_vivienda_cuentas`.
