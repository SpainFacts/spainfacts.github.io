# Lote 2: lo hecho

Base de pruebas: `data/limpieza-2.duckdb`. Modelos reconstruidos con `dbt build` (24 modelos y sus 43 pruebas, todo en verde). Las 120 páginas (castellano y copias en/ca/gl/eu) que usan alguna de las 25 tablas pasan `probar-paginas.mjs` sin errores en las consultas de este lote; los 105 errores que quedan son consultas de tablas de otros lotes cuyos modelos no están en esta copia (`municipios_cuentas_serie`, `municipios_politicas`, `empresas_autonomos_anual`, deuda local, `empleo_salarios_*`). `validar.mjs` para las 30 tablas del lote: 0 errores.

Regla aplicada: una columna mal formada se sustituye (se quita la vieja). Año en letras de las páginas: «desde 2002» pasa a «desde 1996» en `gastos` e `ingresos` (el deflactor ahora empieza en 1996).

## Tablas con cambios

### cuentas_balance_anual (prioridad 1)
- Quita: `año`, `poblacion_m`. Añade: `anio`, `poblacion` (habitantes), `anio_base`, `ingresos_eur_hab_real`, `gastos_eur_hab_real`, `saldo_eur_hab_real`, `deuda_eur_hab_real`. Se quedan los `_mrd`, `saldo_deficit_pib`, `deuda_pib`.
- Páginas (x5 idiomas): `cuentas-publicas/index`, `gastos`. Se eliminan los cálculos con el deflactor; `ingresos` ya no lee esta tabla.
- Modelo dependiente: `metricas_vivienda_cuentas` (lee las columnas nuevas).

### cuentas_gastos (1)
- Quita: `año`, `gasto_por_habitante_eur` (corriente). Añade: `anio`, `anio_base`, `gasto_eur_hab_real`. Se queda `millones_euros` (total corriente), `porcentaje_pib`, `porcentaje_gasto_total`.
- Páginas (x5): `cuentas-publicas/gastos`, `index`.

### cuentas_ingresos (1)
- Quita: `año`. Añade: `anio`, `anio_base`, `ingreso_eur_hab_real`.
- Páginas (x5): `cuentas-publicas/ingresos`, `index`.

### cuentas_subsectores (1)
- Quita: `año`. Añade: `anio`, `anio_base`, `gasto_eur_hab_real`, `ingreso_eur_hab_real`, `saldo_eur_hab_real`.
- Páginas (x5): `cuentas-publicas/index`.

### demografia_anual, demografia_envejecimiento, demografia_hogares, demografia_piramide (2)
- Añaden `nombre` (join a `territorios`; sin duplicar filas; el parquet de la pirámide no crece, 2,3 MB).
- Páginas: ninguna cambia. Siguen necesitando el join a `territorios` por `ruta` (enlace a la ficha), así que no hay nada que simplificar.

### economia_pib_trimestral (3)
- Renombra `anio_euros` a `anio_base` (sin columna nueva). No se añade `fecha` (`trimestre` ya es DATE).
- Páginas (x5): `economia/pib`, `index`, `comercio-exterior` (sustitución del nombre).

### educacion_gasto_alumno (2)
- Quita: `nivel_geo`. Renombra `nivel` a `nivel_educativo`. Añade `cod_pais` (`ES`/`EU27_2020`) y `pais`.
- `eur_real` pasa a existir también para la UE: usa `deflactor_paises` (IPCA) en ambos, así España y UE son comparables (España cambia ligeramente respecto al IPC del INE, p. ej. ESO 2015: 7.414 en vez de 7.421).
- Páginas (x5): `sociedad/educacion`.

### educacion_indicadores (2)
- Añade `nombre` (España, comunidades y «Unión Europea»), `indicador_nombre` y `unidad` (`%`). Se mantiene `nivel = 'ue'` (se queda por los filtros de las páginas).
- Páginas (x5): `sociedad/educacion` (la consulta `neet_ccaa` deja el join a `territorios`).

### elecciones_participacion, elecciones_familias (2)
- Añaden `nombre` y `eleccion` (etiqueta legible, p. ej. «Congreso, noviembre de 2019»); familias añade además `tipo_nombre` y `fecha` (se toman de participacion).
- Páginas (x5): `territorios/[ccaa]/index` y `[provincia]` (`elec_familias` usa `f.fecha`, sin join a participación).

### elecciones_municipios (2)
- Añade `fecha`, `tipo_nombre`, `eleccion`, `municipio`, `cod_prov`, `provincia`, `cod_ccaa`, `ccaa`. Idem en `sources/mother/elecciones_municipios.sql` (que enumera columnas): parquet 2,45 MB. Sin filas duplicadas.
- Páginas (x5): `territorios/municipios` (`elec_mun` usa `e.fecha`, sin join a participación).
- `elecciones_municipios_congreso` (otro lote) queda redundante pero sigue funcionando sin cambios.

### electrificacion_sectores (2)
- Quita: `cuota_electricidad` (0-1), `es_rama_industrial`. Añade `cuota_electricidad_pct`, `cuota_gas_pct`, `cuota_petroleo_pct`, `cuota_renovables_pct`, `cuota_calor_carbon_pct` (0-100) y `tipo_sector` (`total`, `sector`, `rama_industria`, `rama_transporte`).
- Modelo dependiente: `metricas_energia` (ya usa `cuota_electricidad_pct`).

### electrificacion_hogares (2)
- Quita: `cuota` (0-1). Añade `cuota_pct` (0-100) y `es_total_uso`.

### electrificacion_calefaccion_provincia (2)
- Quita: `cuota_*` (0-1), `cod_prov`, `provincia`. Añade `nivel` (`pais`/`provincia`), `cod`, `nombre`, `ccaa` (el `cod_ccaa` se queda), `anio` (2021) y `cuota_electricidad_pct`, `cuota_gas_pct`, `cuota_petroleo_pct`.
- Páginas (x5): `energia-clima/electrificacion` (las tres tablas): formatos pasan a `'0"%"'`, sin multiplicar por 100 ni dividir entre 0,01; el cálculo manual de cuotas por fuente desaparece.
- Modelo dependiente: `mapas_territorio` (usa `nivel`/`cod`).
- Pruebas de `schema_electrificacion.yml` ajustadas.

### embalses_semanal, embalses_estado_actual (3)
- Renombra `clave` a `cod` (España pasa de `ES` a `00`). Sin columna nueva. `sources/mother/embalses_semanal.sql` ajustado; prueba de `schema.yml` ajustada.
- Páginas (x5): `energia-clima/embalses` (mapa de demarcaciones).

### empleo_coste (1)
- Quita: `eur_por_habitante` (corriente). Añade `eur_hab_real`, `millones_eur_real`, `anio_base`.
- Páginas (x5): `cuentas-publicas/empleo-publico` (se eliminan el IPC reconstruido a mano y el join al deflactor; la tarjeta «Cuestan al año, por habitante» pasa a euros constantes y lo dice, traducido).
- Modelo dependiente: `metricas_vivienda_cuentas`.

### empleo_efectivos (2)
- Añade `anio`, `provincia`, `ccaa` («Extranjero» si no hay provincia).
- Páginas (x5): `empleo-publico` (la serie «por 1.000 habitantes» usa `empleo_territorio`, sin cálculo a mano de población).

### empleo_epa_ccaa (1)
- Quita: `trimestre`, `cod_ccaa`, `cuota_publico`. Añade `nivel`, `cod`, `nombre`, `fecha`, `anio`, `cuota_publico_pct` (0-100), `publicos_por_1000_hab`.
- Páginas (x5): `empleo-publico` (gráfico de cuota por comunidad).
- Modelo dependiente: `mapas_territorio` (`cp_epa`).

### empleo_gasto_personal_territorio (1)
- Quita: `gasto_personal_ccaa_hab`, `gasto_personal_ayuntamientos_hab` (corrientes). Añade `nombre`, `anio_base`, `gasto_personal_ccaa_eur_hab_real`, `gasto_personal_ayuntamientos_eur_hab_real`. Un año sin deflactor da NULL (fase 0: desaparece el `coalesce(factor, 1)`). Se quedan los totales corrientes `gasto_personal_*`.
- Páginas (x5): `empleo-publico` (con «euros de {anio_base}» en el título, traducido), `territorios/[ccaa]/index`, `[provincia]`.
- Modelo dependiente: `mapas_territorio`.

## Sin cambios (— o prioridad 3 que añadía columnas)
- `deflactor`, `diputados_inmuebles_resumen`, `electricidad_records`, `electricidad_records_historia`, `electricidad_ultimas_24h`: según el plan.
- `elecciones_partidos` (3): solo añadía `eleccion` y `cod_pais`/`nombre`; sin cambios.
- `electricidad_diaria` (3): solo añadía `anio`, `sistema_nombre`, `es_parcial`; sin cambios. Su `completo` lo usa `electricidad_extremos_diarios`.

## Otros ficheros tocados
- Fichas: `lote-2.json` y `lote-3.json` (25 tablas; quitadas las excepciones `escala`, nombre `null`, «euros corrientes» y «sin nombre»).
- Evaluación: `preguntas-desarrollo.json` (d17), `preguntas-prueba.json` (p11: la respuesta de oro pasa a euros constantes, +14 €/hab, de 285 a 299), `preguntas-validacion4.json` (v4-30, v4-38: `sql_oro` y cifra real nueva de 7.414 €).
- `schema_cuentas.yml`, `schema_empleo.yml`, `schema_elecciones.yml`, `schema_educacion.yml`, `schema_electrificacion.yml`, `schema.yml`.

## Para el coordinador
- No pude reconstruir `metricas_vivienda_cuentas`, `metricas_energia`, `mapas_territorio`, `mapas_personas` ni `metricas_sociedad` enteros: fallan por cambios de otros lotes (`decil_nombre`, `nivel` en `empleo_salarios_*`, `extranjeros_pct`, `almacenamiento_*`, `empresas_autonomos_anual`). Mis cambios en ellos son pequeños y las columnas que leen existen (comprobado con consultas); conviene reconstruirlos al final.
- `deflactor` y las vistas de `staging` de la copia de producción referencian el catálogo `SpainFacts`: en `limpieza-2.duckdb` hubo que recrear las vistas con `dbt run --select path:models/staging`.
- Las 4 tablas partidas / borradas: ninguna en este lote.
