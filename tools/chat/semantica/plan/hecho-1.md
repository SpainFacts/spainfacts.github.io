# Hecho, lote 1 (30 tablas)

Base de datos de trabajo: `data/limpieza-1.duckdb`. Todas las páginas que usan tablas del lote dan **0 errores** con `probar-paginas.mjs` (castellano y traducciones; los únicos errores que salen en las páginas compartidas son consultas de tablas de otros lotes cuyo modelo aún no está en mi base: `empleo_salario`, `empresas_aut`, `embalses`, y en `municipios.md` las de cuentas municipales y elecciones). `validar.mjs` sobre las 30 tablas: 0 errores. `tools/i18n/sql-propagado.mjs`: 0 traducciones sin propagar.

Páginas tocadas (cada una en castellano y en `en|ca|gl|eu`): `energia-clima/almacenamiento`, `territorios/index`, `territorios/[ccaa]/index`, `economia/construccion`, `sociedad/criminalidad`. No se ha tocado `i18n_origen`.

## Tablas con cambios

- **alcaldes_familias_territorio**: añadido `nombre` (de `territorios`, España incluida: la fila `nivel = pais` es el total nacional). Sin páginas. Ficha: `territorio.nombre = nombre`.
- **alcaldes_resumen_familias**: BORRADA (modelo, `sources/mother`, entrada en `schema_alcaldes.yml`, ficha). Pregunta d38 de `preguntas-desarrollo.json` reescrita sobre `alcaldes_familias_territorio` (`nivel='pais'`, `n`).
- **almacenamiento_acceso**: `fecha_fichero` -> `fecha` (+`anio`), `comunidad` -> `ccaa`, añadido `es_ultimo`. Página: sin las subconsultas `max(fecha_fichero)` (usa `es_ultimo`).
- **almacenamiento_mensual**: `mes` -> `fecha` (+`anio`), `rendimiento_bombeo` (0-1) sustituida por `rendimiento_bombeo_pct` (0-100), añadido `es_parcial`. Página: `fecha AS mes` en las consultas; `anio` ya viene de la tabla. Ficha sin `escala`.
- **almacenamiento_potencia**: `mes` -> `fecha` (+`anio`), `comunidad` -> `ccaa`, añadido `es_ultimo`. Página: `WHERE es_ultimo`. Banco del chat (v4-19, v14) actualizado. Sin `w_hab` (decisión de totales no aplicaba; no hay página que lo pida).
- **ccaa_cuentas_capitulos**: añadidos `ccaa`, `ejecutado_eur_hab_real`, `anio_base`. Página `[ccaa]`: `capitulos` deja de unir población y deflactor.
- **ccaa_cuentas_resumen**: añadidos `ccaa`, `{gastos,ingresos}_{totales,nf}_eur_hab_real`, `saldo_eur_hab_real`, `saldo_nf_eur_hab_real`, `anio_base`; QUITADA `deficit_no_financiero` (nadie la usaba; era el saldo con el signo cambiado). Páginas `[ccaa]` (`cuentas`, `gasto_ranking`) y `territorios/index` (`comparativa`) usan las columnas nuevas; fuera los cálculos a mano y el `coalesce(factor, 1)`.
- **ccaa_deuda**: `ccaa` pasa a ser el nombre de `territorios_ccaa`; añadidos `deuda_eur_hab_real` y `anio_base`. Páginas `[ccaa]` (`deuda_ultima`, `deuda_hab_serie`) y `territorios/index`. La serie real por habitante empieza en 1996 (antes 2002): actualizado el texto de la nota en los 5 idiomas.
- **ccaa_gasto_politicas**: añadidos `ccaa`, `poblacion`, `obligaciones_eur_hab_real`, `anio_base`. Página `[ccaa]` (`politicas`: la media de las 17 sale de `hab_real * poblacion`).
- **ccaa_saldo**: `ccaa` de `territorios_ccaa`; añadidos `saldo_eur_hab_real`, `anio_base`. Páginas sin cambios (no usan por habitante).
- **construccion_permisos**: PARTIDA. Ahora solo visados: `nivel` (`pais`/`ccaa`), `cod`, `nombre`; España una sola vez (1992-1999 Banco de España, desde 2000 Ministerio, con m² del BdE); quitadas `ambito`, `m2_residencial_hab`, `m2_no_residencial_hab`. Ficha reescrita.
- **construccion_permisos_ue** (NUEVA): permisos de Eurostat con `cod_pais` (ISO, Grecia = GR) y `pais`, vía `paises_iso`. Con su `sources/mother`, `schema_construccion.yml` y ficha. Consultas `visados`, `visados_ccaa`, `permisos_ue`, `permisos_res` de `construccion.md` reescritas.
- **construccion_costes** y **construccion_produccion**: `pais` (código Eurostat) -> `cod_pais` (ISO) y `pais_nombre` -> `pais` (vía `paises_iso`). Consultas de la página y fichas ajustadas; eval v4 de producción actualizada.
- **construccion_grandes_constructoras**: `edicion` -> `anio`. En la página la consulta mantiene el alias `edicion` para el texto y la tabla.
- **crimen_balance**, **crimen_serie_larga**: `territorio` -> `nombre` normalizado (el de `territorios`; municipios con el nombre del Balance); en serie_larga se añade `nombre`. Página: `b.nombre AS municipio`.
- **crimen_ultimo_periodo**: `territorio` -> `nombre`; añadidos `poblacion`, `tasa_1000` (del periodo) y `variacion_pct` (la página ya no la calcula). Eval v4 ajustada.
- **crimen_condenados**: `cod_ccaa` sustituido por `nivel` (`pais`/`ccaa`), `cod`, `nombre`. Página: `WHERE nivel = 'pais'`. También `mapas_personas.sql` (leía `cod_ccaa`) y eval v3.
- **crimen_condenas_delito**: nueva seed `crimen_delitos_jerarquia` (61 delitos, 4 niveles, comprobado que cada nivel suma exactamente al padre en todos los años) y columnas `nivel_delito`, `delito_padre`, `total_por_100k_hab`, `espanola_por_100k_hab`, `extranjera_por_100k_hab`. Sin cambios de página.
- Fichas de las 5 tablas de crimen y de las tablas anteriores actualizadas (`escala`, `nombre: null`, notas de trampa retiradas).
- Otros ficheros tocados por dependencia: `metricas_energia.sql` (columnas renombradas de almacenamiento), `schema_*.yml`, `sources/mother/construccion_permisos_ue.sql`, bancos `preguntas-validacion2/3/4.json` y `preguntas-desarrollo.json`.

## Sin cambios (a propósito)

- **alcaldes_historia, calor_espana_diario, construccion_afiliados**: sin cambios (plan: nulo).
- **centrales, centrales_ccaa, centrales_resumen**: sin cambios. La decisión del dueño es potencia por comunidad **en totales**, así que `centrales_ccaa` no lleva W/hab; `en_operacion`/`potencia_operacion_mw` serían duplicados de `estado_grupo`/`potencia_mw` y se mantiene el `defecto` de la ficha.
- **almacenamiento_diario, calor_normal_diaria, calor_records, construccion_ccaa, construccion_empleo**: prioridad 3 cuya única mejora era añadir una columna (`es_parcial`, `provincia`, `es_record_absoluto`, `nivel`, `vab_constr_meur_real`).
- **`tasa_1000`** de las tablas de crimen y **`*_1000hab`** de construcción conservan el nombre (ya dicen su unidad); renombrarlas a `_por_1000_hab` obligaba a tocar unas 30 consultas y gráficas en 5 idiomas.

## Para el coordinador

- **Fase 0**: en `pages/territorios/[ccaa]/index.md` siguen los `coalesce(f.factor, 1)` de `empleo_gasto_serie` y `empleo_gasto` (tablas de empleo público, de otro lote); los de mis tablas ya están fuera.
- `mapas_territorio.sql` sigue calculando a mano el gasto/saldo/deuda por habitante con `ccaa_cuentas_resumen`, `ccaa_deuda`, `ccaa_saldo`; funciona, pero podría leer ya `*_eur_hab_real`.
- `metricas_energia.sql` en mi base falla por una edición de otro lote (`cast(anio as integer) as anio` en el CTE `potencia`); mis cambios en ese fichero (CTE `alm_*`) están bien.
- La causa de que `dbt build` no funcionara de entrada en las copias: las vistas `staging.stg_*` apuntan al catálogo `SpainFacts`; hay que reconstruirlas con `--select stg_...` antes de los marts que las leen.
- La seed nueva `crimen_delitos_jerarquia` hay que cargarla con `dbt seed` en producción antes del build.
