# Hecho del lote 4 (30 tablas)

Base de pruebas: `data/limpieza-4.duckdb`. Todo lo siguiente está reconstruido con dbt (tests de las tablas tocadas: 37 PASS), las fichas validan (`validar.mjs`: 0 errores) y `probar-paginas.mjs` no da errores en ninguna consulta que lea tablas de este lote. Los errores que aún salen en esas páginas son de tablas de otros lotes cuyos modelos no están en esta copia de la base (ver «Para el coordinador»).

Páginas = castellano más sus copias `en`, `ca`, `gl`, `eu` (mismo SQL). No se ha tocado `i18n_origen`.

## Tablas con cambios

### local_deuda_municipio (prioridad 1)
- Modelo: añade `cod_prov`, `provincia`, `poblacion`, `deuda_eur_real`, `deuda_eur_hab`, `deuda_eur_hab_real`, `anio_base`. `deuda_eur` se queda (dos cifras: total y por habitante). Población del padrón del año acotada al rango del padrón por municipio (1997 no tiene padrón: queda NULL, igual que antes la página lo descartaba).
- Páginas: `territorios/municipios.md` (`deuda_ayto` ya no cruza padrón ni deflactor; gráfico a `deuda_eur_hab_real`) y `territorios/[ccaa]/[provincia].md` (`deuda_ciudades`). Texto: quitada la frase «el más cercano fuera de los últimos 10 años» (municipios) y «empieza en 2002, primer año con IPC anual» (provincia), que ya no son ciertas (deflactor desde 1996); traducido en los 4 idiomas por quitar, no por añadir.
- Ficha actualizada (principal `deuda_eur_hab_real`, sin la nota «no hay versión por habitante»).

### local_deuda_provincia (prioridad 1)
- Modelo: añade `provincia`, `cod_ccaa`, `deuda_eur_real`, las 4 columnas `_hab_real` (total, ayuntamientos, diputaciones, resto), `pct_ayuntamientos`, `anio_base`. No lleva `poblacion` (se repetiría en cada fila sin necesidad).
- Página `[provincia].md`: bloques `deuda_local`, `deuda_local_hab`, `deuda_local_tipo`, `deuda_ciudades` y KPI/gráficos pasan a las columnas del modelo (se quitan los cruces con población y deflactor).
- Ficha actualizada.

### movilidad_matriculaciones_municipio (prioridad 1)
- Añade `municipio`, `provincia`, `ccaa`, `cod_prov`, `cod_ccaa`, `poblacion`, `turismos_por_1000_hab`, `particulares_por_1000_hab`, `bev_pct`, `phev_pct`, `hev_pct`. Municipios que no están en el padrón conservan fila (nombre y población vacíos). Sin página que la use.
- Ficha: principal `particulares_por_1000_hab`; desaparece «sin nombre de municipio».

### movilidad_matriculaciones_provincia (prioridad 1)
- Añade `ccaa`, `es_flota` (renting, alquiler y empresa; `servicio_publico` no cuenta como flota), `matriculaciones_por_1000_hab` (aditiva). No lleva `poblacion` (alternativa recomendada por el plan, evita la trampa de sumarla). Las páginas (`index.md`, `coche-electrico.md`) usan cuotas y no cambian.
- Ficha actualizada.

### ipc (borrada)
- Eliminado `sources/mother/ipc.sql`; el modelo pasa a `ephemeral` (sigue alimentando `mercado_ipc_grupos`, que se reconstruye bien). Quitada su entrada de `schema.yml`, su ficha en `lote-5.json` y su referencia en `tablas_oro` de d08 (`preguntas-desarrollo.json`). Ninguna página la usaba.

### medios_receptores (partida)
- Se parte en `medios_receptores` (sin los 13.718 pagos duplicados: `sum(importe_eur_real)` ya es siempre correcto, sin columna `duplicado_probable`) y `medios_receptores_duplicados` (esas filas, solo para saber cuánto se deja fuera). Esto sustituye al `_suma` que proponía el plan (el dueño no quiere columnas duplicadas). El modelo original pasa a `medios_receptores_base.sql` (ephemeral, con todo el SQL anterior).
- Añade `ccaa` y `municipio` (nombres).
- `buscador.md`: quitados los 7 filtros `NOT duplicado_probable`; el bloque `duplicados` lee la tabla nueva.
- Nuevos `sources/mother/medios_receptores_duplicados.sql`; ficha nueva (usar: false).

### medios_receptores_resumen (partida) y medios_receptores_totales (nueva)
- `medios_receptores_totales`: una fila por medio con todo lo que antes se repetía (totales, por vía, n_*, años, rangos). `medios_receptores_resumen` queda en `medio_id`, `medio`, `anio`, `via`, `importe_*`, `n_pagos`, `n_administraciones`, `n_gobiernos` (la fase 2 del plan, hecha ya).
- `buscador.md`: `lista_medios`, `sel`, `relacionados`, `ranking`, `publicos` leen los totales (se quitan los `DISTINCT`); `sel_anual` sigue en el resumen.
- Nuevo `sources/mother/medios_receptores_totales.sql`; ficha nueva.

### medios_subvenciones_beneficiarios (partida) y medios_subvenciones_totales (nueva)
- `medios_subvenciones_totales`: una fila por NIF (nombre, forma jurídica, total_*, rango, concedentes...). `medios_subvenciones_beneficiarios` queda con `nif`, `nombre`, `anio`, `es_parcial`, `importe_*`, `n_concesiones`.
- `dinero-publico.md`: `sub_beneficiarios` lee la tabla de totales (sin `anio = ultimo_anio`).
- Nuevo `sources/mother/medios_subvenciones_totales.sql`; ficha nueva.

### medios_contratos_ejemplos
- Añade `ccaa` y `municipio` (nombres). Sin cambios en páginas.

### medios_publicidad_grupos
- Quitada `eur_1000hab_real` (era la misma cifra que `eur_hab_real` x1000). `dinero-publico.md`: los dos gráficos de grupos pasan a `eur_hab_real` (formato `0.00`) y los textos «€ por 1.000 habitantes» pasan a «€ por habitante» en los 5 idiomas (4 textos por idioma, traducidos). Ficha sin la medida.

### mercado_paro_territorios
- Añade `territorio` y la fila `nivel='pais'`, `cod='00'` (misma lógica EPA sobre «Total Nacional», con empleo y actividad nacionales). Comprobado: coincide con `mercado_paro_trimestral` en paro, paro juvenil, empleo y hogares todos parados, en los 98 trimestres. Arregla sin tocar las páginas el bug de `tasa_paro_espana` vacía en `[ccaa]/index.md` y `[provincia].md`.
- `mapas_personas` ignora la fila nueva (se une con `territorios` de ccaa/provincia).

### mercado_paro_registrado
- Añade `territorio` y `anio`. Páginas sin cambios.

### mercado_ipc_ccaa
- Añade `ccaa` (con «España» para `00`) y `es_nacional`. Las páginas siguen cruzando `territorios` porque necesitan `ruta`.

### mercado_energia_carburantes y mercado_energia_hogares
- Se sustituyen: `semana`/`semestre_inicio` -> `fecha` (+ `anio`), `geo`/`territorio` -> `cod_pais` (ISO2, `EU27_2020` para la media UE) + `pais`. En hogares `geo` pasa a `cod_pais`.
- `economia/ipc.md` (5 idiomas): bloques `carb*` y `hogares*` y atributos `x=` actualizados. `metricas_economia.sql` (usa ambas tablas) adaptado. `preguntas-prueba.json` p05 y `preguntas-validacion3.json` w03 (`sql_oro`) adaptadas.
- No se ha cambiado `anio_euros` -> `anio_base`, ni se ha pasado el deflactor de hogares/carburantes a `deflactor_paises` (siguen deflactándose con el IPC español): no estaba en el plan y toca textos.

### internacional_comparativa y internacional_ultimo
- `cod_pais` pasa de ISO3 del Banco Mundial a ISO alfa-2 con el seed `paises_iso` (`EU27_2020`, `OECD`). En `internacional_ultimo`, `anio_ultimo` -> `anio`.
- Código que cambia con esto: `Comparativa.svelte` (valores por defecto y comparaciones), claves `pais.XX` de `src/lib/i18n.js` (5 idiomas), `src/lib/paisesReferencia.js`, `schema_internacional.yml`, ficha. La única página con SQL sobre esos códigos (`vivienda-publica.md`) ya la había reescrito otro lote.
- No se han añadido `es_ultimo` ni `unidad_tipo` (el plan los daba como opcionales y `internacional_ultimo` ya cubre el «último año»).

### movilidad_flotas_municipios
- `cuota_flota_espana` (0-1) -> `cuota_flota_espana_pct` (0-100). `flotas-e-impuestos.md` (5 idiomas): quitados los `* 100`, columna de tabla en `num1`, eje del gráfico `0"%"`.
- No convertida `flota_por_habitante` a `por_1000_hab`: el récord de la página se lee «99 coches por habitante» y pasar a por 1.000 obligaba a reescribir el texto en 5 idiomas; la ficha lo documenta como razón. `ahorro_*` documentados como euros de 2026 por construcción.

### movilidad_marcas_mensual y movilidad_modelos_mensual
- Añaden `anio`, `grupo_etiqueta`, `energia_etiqueta`, `canal_etiqueta` (seeds `movilidad_grupos/energias/canales`). `camiones-y-autobuses.md` (5 idiomas): el `CASE` de etiquetas a mano pasa a `m.grupo_etiqueta`.

### movilidad_parque_evolucion
- Añade `anio`, `grupo_etiqueta`, `vehiculos_por_1000_hab` (aditiva, padrón de España). Sin página.

### movilidad_parque_modelos
- Añade `es_modelo_real`, `grupo_etiqueta`, `energia_etiqueta`. `parque.md` (5 idiomas): `modelo <> '(modelo sin especificar)'` -> `es_modelo_real`. La ficha lleva `defecto: true` en `es_modelo_real`.

## Tablas sin cambio de modelo (solo ficha, o ni eso)
- `mapas_indicadores` y `metricas`: auxiliares, ya `usar: false`; sin cambios.
- `medios_publicidad_age_medios`: ya tenía `defecto: ambito = institucional`; sin cambios.
- `mercado_energia_ipc`, `mercado_ipc_grupos`, `mercado_paro_grupos`, `movilidad_matriculaciones_mensual`: sin cambios (solo se comprobó que siguen construyéndose).
- `mercado_paro_trimestral`: ficha con la referencia cruzada a `mercado_paro_territorios`.

## Para el coordinador
- Falta regenerar `tools/chat/semantica/inventario.json` (`node tools/chat/semantica/inventario.mjs`): aún trae `ipc` y no conoce las 3 tablas nuevas.
- Tablas nuevas que necesitan despliegue/`sources`: `medios_receptores_totales`, `medios_receptores_duplicados`, `medios_subvenciones_totales` (cada una con su `sources/mother/*.sql`). `medios_receptores_base` e `ipc` son `ephemeral`: en MotherDuck queda la tabla `main.ipc` vieja, que ya nadie lee (se puede borrar a mano).
- `medios_receptores` y `medios_receptores_resumen` cambian de forma (menos filas, menos columnas): el deploy con `--changed` tiene que reconstruir también `medios_receptores_resumen` y `medios_subvenciones_beneficiarios`.
- `mapas_territorio.sql` (`local_deuda_provincia`, `movilidad_matriculaciones_provincia`) y `metricas_economia.sql` (`mercado_paro_registrado`, carburantes, hogares) dependen de modelos que he cambiado; las columnas que leen siguen existiendo salvo las renombradas de carburantes/hogares, ya adaptadas. No pude reconstruir `mapas_personas`/`mapas_territorio` en mi copia: `mapas_personas` falla porque `empresas_autonomos_anual` no está en mi base (otro lote); no tiene que ver con estos cambios.
- Errores que siguen saliendo en `probar-paginas` con mi base, todos de tablas de otros lotes (columnas nuevas en sus páginas, modelos no reconstruidos en mi copia): `municipios_cuentas_serie`, `municipios_politicas`, `elecciones_municipios`, `ccaa_deuda` (`deuda_eur_hab_real`), `empleo_territorio`, `empresas_autonomos_anual`, `movilidad_parque_provincia` y `_municipio`, `vivienda_publica_internacional`, `embalses`, y varias de `cuentas-publicas` y `tamano_ue`/`alumno`/`san_rec`.
- `tools/pruebas/estatico.mjs` da 20 enlaces rotos solo porque no hay build; `tools/i18n/comprobar.mjs`: 87 correctas por idioma.
- `semantica/CONVENCIONES.md` sigue sin declarar que `mes`/`trimestre`/`semana` (DATE de inicio) valen como `fecha` (decisión transversal del plan); en este lote hay varias tablas mensuales que conservan `mes` y solo añaden `anio`.
- Decisión dudosa: `es_flota` no incluye `servicio_publico`; si el dueño quiere que «sin flotas» sea exactamente `canal = 'particular'` como en las páginas, basta cambiar una línea del modelo.
