# Plan de limpieza, lote 2 (30 tablas)

Receta común (no se repite en cada tabla):

- **Euros reales**: `left join {{ ref('deflactor') }} d on d.anio = <anio>` y `valor * d.factor as <col>_real`, más `d.anio_base`. Ejemplos ya hechos: `educacion_gasto_alumno`, `economia_salarios_ccaa`, `construccion_deflactor`.
- **Por habitante**: Eurostat con `eurostat_poblacion` (miles, `valor * 1000`) como en `cuentas_gastos`; territorios con `ref('poblacion_territorios')` (`sexo = 'Total'`) como en `empleo_territorio`.
- **Nombre de territorio**: `left join {{ ref('territorios') }} t on t.nivel = x.nivel and t.cod = x.cod` y `t.nombre`.
- **Regla de oro**: solo se añaden columnas. Las páginas (y sus copias en `pages/en|ca|gl|eu`) siguen funcionando sin tocarse; migrarlas a las columnas nuevas es opcional y se hace después, y solo cuando ninguna use la vieja se retira la vieja y su excepción de la ficha.
- Las traducciones repiten el SQL: migrar una página implica migrar sus copias, con `tools/i18n/estado.mjs`.

---

### cuentas_balance_anual
- **Modelo:** transform/models/marts/cuentas_balance_anual.sql · **Páginas:** cuentas-publicas/index, gastos, ingresos (12 traducciones) · **Prioridad:** 1
- **Problemas:** importes en `_mrd` corrientes (miles de millones) sin euros reales ni por habitante; columna de tiempo `"año"` con eñe (todas las páginas hacen `CAST(b.año AS INTEGER)`); solo `poblacion_m` en millones.
- **Cambio propuesto:** añadir `anio` INTEGER, `poblacion` (habitantes, enteros), `anio_base` y las versiones reales y por habitante de los flujos y la deuda.
```sql
cast(m.anio as integer) as anio, p.poblacion_m * 1e6 as poblacion, d.anio_base,
m.ingresos_mio * d.factor as ingresos_meur_real,  m.gastos_mio * d.factor as gastos_meur_real,
m.saldo_mio * d.factor as saldo_meur_real,  de.deuda_mio * d.factor as deuda_meur_real,
m.ingresos_mio * 1e6 * d.factor / (p.poblacion_m*1e6) as ingresos_eur_hab_real,   -- ídem gastos, saldo, deuda
left join {{ ref('deflactor') }} d on d.anio = m.anio
```
- **Páginas:** conservar `año`, `ingresos_totales_mrd`, `gastos_totales_mrd`, `saldo_deficit_mrd/pib`, `deuda_publica_mrd/pib`, `poblacion_m`. `cuentas-publicas/index` calcula hoy `ingresos_hab_real` y `gastos_hab_real` con un join al deflactor; debería pasar a `ingresos_eur_hab_real` / `gastos_eur_hab_real` (y la de `gastos.md` que lee `poblacion_m`).
- **Ficha:** desaparecen "euros corrientes, no reales", la ausencia de por habitante y la columna de tiempo `año` (tiempo pasa a `anio`).
- **Esfuerzo/riesgo:** bajo, solo se añaden columnas; hay que vigilar que el factor del 2025 (último año completo) sea 1 y el de años sin deflactor (antes de 2002 según un comentario de las páginas) quede NULL en lugar de romper.

### cuentas_gastos
- **Modelo:** transform/models/marts/cuentas_gastos.sql · **Páginas:** cuentas-publicas/gastos, index (8 traducciones) · **Prioridad:** 1
- **Problemas:** `gasto_por_habitante_eur` es corriente (el real lo calculan las páginas con el deflactor); `"año"` con eñe; sin `anio_base`; nombres no estándar (`millones_euros`, `porcentaje_pib`).
- **Cambio propuesto:** añadir `anio`, `gasto_eur_hab` (copia estándar), `gasto_eur_hab_real`, `millones_euros_real` y `anio_base`; `porcentaje_pib`/`porcentaje_gasto_total` se quedan (ya son 0-100, se les puede añadir alias `_pct` más adelante).
```sql
cast(a.anio as integer) as anio, d.anio_base,
a.millones_euros * d.factor as millones_euros_real,
round(a.millones_euros * 1e6 * d.factor / h.habitantes, 0) as gasto_eur_hab_real
```
- **Páginas:** conservar `año`, `funcion_cofog`, `categoria_macro`, `millones_euros`, `porcentaje_pib`, `porcentaje_gasto_total`, `gasto_por_habitante_eur`. `gastos.md` (serie_gastos_macro, por habitante a precios constantes) pasaría a leer `gasto_eur_hab_real` sin join al deflactor.
- **Ficha:** desaparece la excepción de "euros corrientes, no reales" (se declara `gasto_eur_hab_real` como medida principal) y la columna de tiempo `año`.
- **Esfuerzo/riesgo:** bajo; solo añade columnas a un modelo ya con población y PIB. Ojo con el reparto de GF0107 (se mantiene tal cual).

### cuentas_ingresos
- **Modelo:** transform/models/marts/cuentas_ingresos.sql · **Páginas:** cuentas-publicas/index, ingresos (8 traducciones) · **Prioridad:** 1
- **Problemas:** solo `millones_euros` corrientes; ni por habitante ni reales (incumple el principio rector); `"año"` con eñe.
- **Cambio propuesto:** traer población (como en `cuentas_gastos`) y deflactor y añadir `anio`, `millones_euros_real`, `ingreso_eur_hab`, `ingreso_eur_hab_real`, `anio_base`.
```sql
poblacion as (select cast(periodo as integer) as anio, valor*1000.0 as habitantes
              from {{ source('raw_eurostat_extra','eurostat_poblacion') }} where valor is not null)
c.millones_euros * 1e6 / h.habitantes as ingreso_eur_hab,
c.millones_euros * 1e6 * d.factor / h.habitantes as ingreso_eur_hab_real
```
- **Páginas:** conservar `año`, `categoria`, `tipo_ingreso`, `millones_euros`, `porcentaje_pib`, `porcentaje_ingreso_total`. `ingresos.md` e `index` deberían pasar a `ingreso_eur_hab_real` (hoy muestran totales o hacen el cálculo a mano).
- **Ficha:** desaparecen "importes en euros corrientes, sin cifra por habitante" y `año`.
- **Esfuerzo/riesgo:** bajo; mismo patrón que `cuentas_gastos`. Hay que decidir si los residuos ("Otros...", "No tributarios y Fondos UE") siguen mezclados con las figuras (sí, no se cambia).

### cuentas_subsectores
- **Modelo:** transform/models/marts/cuentas_subsectores.sql · **Páginas:** cuentas-publicas/index (4 traducciones) · **Prioridad:** 1
- **Problemas:** `gasto_mrd`/`ingreso_mrd`/`saldo_deficit_mrd` corrientes sin por habitante ni reales; `"año"`; `peso_gasto_pct` suma más de 100 % (cuentas no consolidadas).
- **Cambio propuesto:** añadir `anio`, `gasto_eur_hab_real`, `ingreso_eur_hab_real`, `saldo_eur_hab_real`, `anio_base` con población de Eurostat y deflactor; dejar claro en la ficha que no se suman subsectores (para el total, `cuentas_balance_anual`).
```sql
b.te * 1e6 * d.factor / h.habitantes as gasto_eur_hab_real,
b.tr * 1e6 * d.factor / h.habitantes as ingreso_eur_hab_real
```
- **Páginas:** conservar `año`, `subsector`, `cod_sector`, `gasto_mrd`, `ingreso_mrd`, `saldo_deficit_mrd`, `peso_gasto_pct`. `index.md` (reparto por subsector) puede pasar a `gasto_eur_hab_real`.
- **Ficha:** desaparece "euros corrientes" y `año`; la advertencia de solapamiento se queda (es del dato, no del modelo).
- **Esfuerzo/riesgo:** bajo.

### deflactor
- **Modelo:** transform/models/marts/deflactor.sql · **Páginas:** 10 páginas de cuentas-publicas, economía, territorios y transparencia (40 traducciones) · **Prioridad:** —
- **Problemas:** la ficha lo marca `usar: false` ("auxiliar"); es correcto, es una de las dos tablas de referencia permitidas (`territorios`, `deflactor`). Año en curso con `meses` < 12 (2026 con 8 meses).
- **Cambio propuesto:** no tocarla ni borrarla: la usan 10 páginas, 7 marts y las tablas nuevas de este plan. Opcional: `meses < 12 as es_parcial` para cumplir la convención de año incompleto; no hace falta.
- **Páginas:** conservar `anio`, `ipc_medio`, `meses`, `anio_base`, `factor`.
- **Ficha:** ninguna; sigue `usar: false` a propósito, y el chat debe consumir las columnas `_real` de cada tabla, no el deflactor.
- **Esfuerzo/riesgo:** ninguno.

### demografia_anual
- **Modelo:** transform/models/marts/demografia_anual.sql · **Páginas:** demografia/index, evolucion-poblacion, natalidad, territorios/[ccaa] y [provincia] (20 traducciones) · **Prioridad:** 2
- **Problemas:** territorio solo con `cod` (los de comunidad y provincia se solapan y el chat tiene que unir con `territorios`); ficha con "nombre: null". `crecimiento_1000` etc. ya están por habitante, bien.
- **Cambio propuesto:** añadir `nombre` desde `territorios` (y `anio` ya es estándar).
```sql
t.nombre
left join {{ ref('territorios') }} t on t.nivel = b.nivel and t.cod = b.cod
```
- **Páginas:** conservar todas las columnas actuales (`nivel`, `cod`, `anio`, `nacimientos`, `*_1000`, `fecundidad*`, `saldo_exterior*`...). Ninguna necesita cambiar; las que hacen `JOIN mother.territorios` pueden dejar el join (opcional).
- **Ficha:** desaparece "sin columna de nombre" (territorio.nombre = "nombre") y la trampa del solape de códigos.
- **Esfuerzo/riesgo:** bajo; un join por (nivel, cod) que no multiplica filas.

### demografia_envejecimiento
- **Modelo:** transform/models/marts/demografia_envejecimiento.sql · **Páginas:** demografia (5 subpáginas), territorios/[ccaa] y [provincia] (28 traducciones) · **Prioridad:** 2
- **Problemas:** igual que la anterior: sin nombre de territorio; códigos solapados entre ccaa y provincia.
- **Cambio propuesto:** añadir `nombre` con el mismo join a `territorios` (`r.nivel`, `r.cod`).
- **Páginas:** conservar todo (`poblacion`, `pct_65`, `pct_80`, `edad_media`, `dependencia`, `pct_nacidos_extranjero`...); las demás tablas demográficas (`demografia_anual` y la pirámide) ya la usan como fuente de población.
- **Ficha:** desaparece la excepción de nombre; queda la nota de que "población a 1 de enero" es la del año `anio`.
- **Esfuerzo/riesgo:** bajo.

### demografia_hogares
- **Modelo:** transform/models/marts/demografia_hogares.sql · **Páginas:** demografia/hogares (4 traducciones) · **Prioridad:** 2
- **Problemas:** sin nombre de territorio; `hogares` es un recuento sin versión por habitante (solo `tamano_medio`, que ya normaliza).
- **Cambio propuesto:** añadir `nombre` (join a `territorios`). No añadir hogares por 1.000 habitantes: `tamano_medio` ya cumple el principio.
- **Páginas:** conservar `anio`, `nivel`, `cod`, `hogares`, `tamano_medio`, `unipersonales`, `pct_*` y `clave`; la página divide `pct_*/100` por el formato, ninguna cambia.
- **Ficha:** desaparece la excepción de nombre; la serie desde 2021 (datos a 1 de enero) se queda como nota.
- **Esfuerzo/riesgo:** bajo.

### demografia_piramide
- **Modelo:** transform/models/marts/demografia_piramide.sql · **Páginas:** estructura-edades, poblacion-sexo, territorios/[ccaa] y [provincia] (16 traducciones) · **Prioridad:** 2
- **Problemas:** sin nombre de territorio; no hay fila de total (hay que sumar grupos y sexos o usar `demografia_envejecimiento`); `grupo` no ordena (se usa `edad_desde`).
- **Cambio propuesto:** añadir `nombre` (join a `territorios`, ~140k filas; el parquet pesa 2,4 MB, el diccionario del nombre añade poco). No añadir filas de total: es sumable y ya existe la otra tabla.
- **Páginas:** conservar `anio`, `nivel`, `cod`, `sexo`, `edad_desde`, `grupo`, `poblacion`, `pct`, `nacidos_extranjero`, `pct_nacidos_extranjero`; ninguna debe cambiar.
- **Ficha:** desaparece "sin nombre de territorio"; se quedan la nota del orden por `edad_desde` y la de que no hay total.
- **Esfuerzo/riesgo:** bajo; comprobar el tamaño del parquet tras añadir la cadena.

### diputados_inmuebles_resumen
- **Modelo:** transform/models/marts/diputados_inmuebles_resumen.sql · **Páginas:** varios/diputados-caseros (4 traducciones) · **Prioridad:** —
- **Problemas:** una fila por definición de "casero" con los totales repetidos (`t.*`); las definiciones se solapan; sin territorio ni año (el ejercicio de rentas va en `ejercicio_rentas`). No son problemas del modelo, son del dato.
- **Cambio propuesto:** no tocarla: ya es una tabla de resumen con `definicion_id` + `definicion` legibles, `pct` en 0-100 y sin euros que deflactar. Quizá en el futuro `anio = ejercicio_rentas` si se cruza con otras tablas, no ahora.
- **Páginas:** conservar `definicion_id`, `definicion`, `n_cumplen`, `pct`, `n_validos`, `n_diputados`.
- **Ficha:** se mantiene la advertencia de solapamiento y la de elegir definición.
- **Esfuerzo/riesgo:** ninguno.

### economia_pib_trimestral
- **Modelo:** transform/models/marts/economia_pib_trimestral.sql · **Páginas:** economia/pib, index, comercio-exterior (12 traducciones) · **Prioridad:** 3
- **Problemas:** ya trae `real_meur` y `por_habitante_real`. Cosmético: `anio_euros` en vez de `anio_base`; la fecha se llama `trimestre`; `por_habitante_real` es anualizado y eso solo está en la nota.
- **Cambio propuesto:** añadir `fecha` (= `trimestre`) y `anio_base` (= `anio_euros`); opcional `por_habitante_real_anual` como alias explícito de `por_habitante_real`. No renombrar.
```sql
make_date(b.anio, 3*b.trim-2, 1) as fecha, (select anio from completo) as anio_base
```
- **Páginas:** conservar `trimestre`, `anio`, `trim`, `componente`, `nombre`, `nominal_meur`, `real_meur`, `anio_euros`, `interanual`, `pct_pib`, `por_habitante_real`.
- **Ficha:** casi nada; la unidad "€ de 2025 por habitante al año" y la nota de anualización se mantienen.
- **Esfuerzo/riesgo:** bajo; solo alias.

### educacion_gasto_alumno
- **Modelo:** transform/models/marts/educacion_gasto_alumno.sql · **Páginas:** sociedad/educacion (4 traducciones) · **Prioridad:** 2
- **Problemas:** `nivel` significa nivel educativo (choca con la convención, donde `nivel` es el territorial) y el territorio está en `nivel_geo`; `eur_real` solo para España (la UE no tiene deflactor); niveles que se solapan; sin `cod_pais`.
- **Cambio propuesto:** añadir `nivel_educativo` (= `nivel`), `cod_pais` (`ES` / `EU27_2020`) y `pais` (`España` / `Unión Europea`). Para el real de la UE hace falta el IPC armonizado de la UE-27 (Eurostat `prc_hicp_aind`), que no está en la ingesta: sin él se queda en NULL y se compara con `pps`.
```sql
g.nivel as nivel_educativo, case g.geo when 'ES' then 'ES' else 'EU27_2020' end as cod_pais,
case g.geo when 'ES' then 'España' else 'Unión Europea' end as pais
```
- **Páginas:** conservar `anio`, `nivel_geo`, `isced11`, `nivel`, `eur`, `eur_real`, `pps`, `pct_pib_hab`, `anio_base`; las páginas leen `nivel_geo = 'pais'`.
- **Ficha:** desaparece la confusión de `nivel`/`nivel_geo`; la excepción "euros reales solo para España" sigue salvo que se ingiera el IPC de la UE.
- **Esfuerzo/riesgo:** bajo (columnas) y medio si se quiere el real de la UE (nueva fuente).

### educacion_indicadores
- **Modelo:** transform/models/marts/educacion_indicadores.sql · **Páginas:** sociedad/educacion, sociedad/index, territorios/[ccaa] (12 traducciones) · **Prioridad:** 2
- **Problemas:** solo código en `cod` (00, 01-19 y `UE`) sin nombre; `nivel = 'ue'` rompe el catálogo de niveles; formato largo con seis indicadores sin `unidad` ni descripción, y la ficha exige elegir uno (`defecto: abandono`).
- **Cambio propuesto:** añadir `nombre` (de `territorios`; `España`, `Unión Europea`), `unidad` (`%` en todos), `indicador_nombre` y `poblacion_ref` (por ejemplo "Abandono temprano, 18-24 años").
```sql
case f.indicador when 'abandono' then 'Abandono temprano de la educación (18-24 años)' ... end as indicador_nombre,
'%' as unidad,
coalesce(t.nombre, case when f.geo = 'EU27_2020' then 'Unión Europea' end) as nombre
```
- **Páginas:** conservar `anio`, `nivel`, `cod`, `indicador`, `valor`; los filtros `nivel IN ('pais','ue')` siguen valiendo.
- **Ficha:** desaparece "sin nombres de comunidad"; el `defecto: abandono` se mantiene (no se pueden mezclar indicadores) pero la ficha ya sabe describirlos desde `indicador_nombre`.
- **Esfuerzo/riesgo:** bajo.

### elecciones_familias
- **Modelo:** transform/models/marts/elecciones_familias.sql · **Páginas:** sociedad/elecciones, territorios/municipios, [ccaa], [provincia] (16 traducciones) · **Prioridad:** 2
- **Problemas:** sin nombre de territorio; `tipo` solo como código ('02', '04', '07') y `defecto: 02`; 2019 aparece dos veces (abril y noviembre) distinguido solo por `proceso`; falta `fecha`.
- **Cambio propuesto:** añadir `nombre`, `tipo_nombre` y `fecha` (ya salen de `elecciones_participacion`, que se une por `proceso, nivel, cod`) y `eleccion`, una etiqueta legible ("Congreso, abril de 2019").
```sql
t.nombre, p.tipo_nombre, p.fecha,
p.tipo_nombre || ' ' || strftime(p.fecha, '%Y-%m') as eleccion   -- distingue las dos de 2019
```
- **Páginas:** conservar `proceso`, `tipo`, `anio`, `nivel`, `cod`, `familia`, `siglas_familia`, `color`, `bloque`, `votos`, `pct`, `escanos`, `pct_escanos`. Ninguna cambia.
- **Ficha:** desaparecen "solo código" y la necesidad de explicar los códigos de tipo; el filtro por tipo/proceso sigue siendo obligatorio (`defecto: Congreso`).
- **Esfuerzo/riesgo:** bajo; el `totales` ya hace el mismo join por proceso.

### elecciones_municipios
- **Modelo:** transform/models/marts/elecciones_municipios.sql · **Páginas:** territorios/municipios (4 traducciones) · **Prioridad:** 2
- **Problemas:** solo `cod_mun`, sin `municipio`, `cod_prov` ni `provincia` (hoy hay que ir a `elecciones_municipios_congreso`, que solo trae Congreso); `tipo` en código con `defecto: 02`; 197k filas, 3,5 MB.
- **Cambio propuesto:** añadir `municipio`, `cod_prov`, `provincia`, `cod_ccaa`, `ccaa`, `tipo_nombre` y `fecha` desde `ref('poblacion_municipios')` y `ref('elecciones_participacion')`/`procesos`. Con esto `elecciones_municipios_congreso` queda como candidata a borrado (decidirlo en el lote que la contenga). Medir el parquet: debería subir poco con diccionario.
```sql
left join (select distinct cod_mun, municipio, cod_prov, cod_ccaa from {{ ref('poblacion_municipios') }}) m using (cod_mun)
```
- **Páginas:** conservar `proceso`, `tipo`, `anio`, `cod_mun`, `participacion`, `ganador_*`, `pct_*`, `nep`, `censo`, `votantes`, `concejales`. `municipios.md` ya une los nombres por su cuenta; puede simplificarse.
- **Ficha:** desaparece "no tiene nombre de municipio"; se mantiene `defecto: 02` y el aviso de 2019.
- **Esfuerzo/riesgo:** medio; el join por municipio no debe duplicar filas (nombres que cambian de año, fusiones) y hay que vigilar el tamaño de un parquet que las fichas cargan en el navegador.

### elecciones_participacion
- **Modelo:** transform/models/marts/elecciones_participacion.sql · **Páginas:** sociedad/elecciones, sociedad/index, territorios/municipios, [ccaa], [provincia] (20 traducciones) · **Prioridad:** 2
- **Problemas:** sin nombre de territorio; 2019 con dos generales sin etiqueta legible; la ficha pone `tiempo.columna = fecha` pero la tabla también tiene `anio`.
- **Cambio propuesto:** añadir `nombre` y `eleccion` (etiqueta con año y mes). Es la tabla de la que cuelgan las demás (`elecciones_familias`, `elecciones_partidos`), así que se hace primero.
```sql
t.nombre, pr.tipo_nombre || ' ' || strftime(pr.fecha, '%Y-%m') as eleccion
left join {{ ref('territorios') }} t on t.nivel = t_.nivel and t.cod = t_.cod   -- t_ = la fila agregada
```
- **Páginas:** conservar todo lo actual (`proceso`, `tipo`, `tipo_nombre`, `anio`, `fecha`, `nivel`, `cod`, `participacion`, `validos`, `ganador_*`, `nep_*`, `gallagher`).
- **Ficha:** desaparece "solo tiene código"; se queda el `defecto: Congreso` y la fijación de año/proceso.
- **Esfuerzo/riesgo:** bajo; el único cuidado es ordenar la dependencia (se construye antes que `familias` y `partidos`).

### elecciones_partidos
- **Modelo:** transform/models/marts/elecciones_partidos.sql · **Páginas:** sociedad/elecciones (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo la necesidad de fijar `tipo_nombre` y el proceso (2019 dos veces); ámbito solo nacional.
- **Cambio propuesto:** añadir `eleccion` (etiqueta legible, como en las otras dos) y `cod_pais`/`nombre` = `ES`/`España` para que el nivel nacional sea explícito; sin cambios de fondo.
- **Páginas:** conservar `proceso`, `tipo`, `tipo_nombre`, `anio`, `fecha`, `siglas`, `familia`, `bloque`, `votos`, `pct`, `escanos`, `pct_escanos`, `votos_por_escano`, `ventaja`.
- **Ficha:** el `defecto: Congreso` se queda (no se mezclan Congreso y Europeas); `tiempo` pasa de `fecha` a `eleccion` solo como ayuda.
- **Esfuerzo/riesgo:** bajo; cosmético.

### electricidad_diaria
- **Modelo:** transform/models/marts/electricidad_diaria.sql (y `sources/mother/electricidad_diaria.sql`, que recorta a los 3 últimos años) · **Páginas:** energia-clima/records, index (8 traducciones) · **Prioridad:** 3
- **Problemas:** el aviso "euros sin por habitante ni reales" es un falso positivo: el precio spot es €/MWh, no un gasto, no se divide. Reales: el último día incompleto (`completo = false`), `sistema` con tres valores sin España total (Ceuta y Melilla no están) y `defecto: peninsula`.
- **Cambio propuesto:** añadir `anio` (año del día), `sistema_nombre` (como en `electricidad_records`) y `es_parcial` (= `not completo`) para la convención del año incompleto. No añadir fila España: sumaría 3 de 5 sistemas y daría un total falso.
```sql
year(d.fecha) as anio, case d.sistema when 'peninsula' then 'Península' when 'baleares' then 'Baleares' when 'canarias' then 'Canarias' end as sistema_nombre,
not (d.n_intervalos >= 276) as es_parcial
```
- **Páginas:** conservar `fecha`, `sistema`, `pct_renovable`, `demanda_mwh`, `*_mwh`, `precio_spot_medio_eur_mwh`, `completo`; ninguna cambia.
- **Ficha:** desaparece la excepción del último día incompleto como "parcial: true" (queda el booleano `es_parcial`); `defecto: peninsula` se mantiene.
- **Esfuerzo/riesgo:** bajo; hay que repetir el alias en `sources/mother/electricidad_diaria.sql`.

### electricidad_records
- **Modelo:** transform/models/marts/electricidad_records.sql · **Páginas:** energia-clima/records (4 traducciones) · **Prioridad:** —
- **Problemas:** cada fila es un récord distinto con su propia `unidad` (MW, GWh, %, g CO2/kWh, t CO2/h, €/MWh): es formato largo y ya cumple la convención (`unidad` en cada fila). Defectos `Península` y `hora` necesarios.
- **Cambio propuesto:** dejar como está. Partirla en una tabla por unidad haría perder la lista de récords que pinta la página.
- **Páginas:** conservar todo (`codigo`, `categoria`, `sistema`, `sistema_nombre`, `periodo`, `valor`, `unidad`, `fecha`, `reciente`, `orden`...).
- **Ficha:** se mantienen "valor con unidad variable" y los defectos de sistema y periodo; son del dato.
- **Esfuerzo/riesgo:** ninguno.

### electricidad_records_historia
- **Modelo:** transform/models/marts/electricidad_records_historia.sql · **Páginas:** energia-clima/records (4 traducciones; la usa en tres consultas: evolución, últimos 30 días y recuento) · **Prioridad:** —
- **Problemas:** ninguna tabla duplicada: es el detalle de la anterior; la ficha la marca `usar: false`, correcto.
- **Cambio propuesto:** no borrar (la usa la página de récords con `NOT es_inicio_serie`) ni tocar. Mantenerla fuera del chat.
- **Páginas:** conservar `codigo`, `sistema`, `periodo`, `fecha`, `valor`, `unidad`, `ts_local`, `valor_anterior`, `ts_anterior`, `n_record`, `es_inicio_serie`, `orden`, `categoria`.
- **Ficha:** ninguna; se queda `usar: false`.
- **Esfuerzo/riesgo:** ninguno.

### electricidad_ultimas_24h
- **Modelo:** transform/models/marts/electricidad_5min.sql (la tabla mother se define en `sources/mother/electricidad_ultimas_24h.sql`, que filtra las últimas 24 h) · **Páginas:** energia-clima/directo (4 traducciones) + `src/lib/components/DirectoSistemaElectrico.svelte`, `src/lib/config/directo.js` y `workers/ree-directo` · **Prioridad:** —
- **Problemas:** es el contrato de datos del directo (el Worker publica el mismo esquema); la ficha ya la marca `usar: false`.
- **Cambio propuesto:** no tocar ni borrar: romperla rompe el directo. El comentario del modelo ya avisa "no renombrar sin avisar".
- **Páginas:** conservar `sistema`, `ts_utc`, `ts_local` y todas las columnas MW de `electricidad_5min`.
- **Ficha:** ninguna.
- **Esfuerzo/riesgo:** ninguno; cualquier cambio exige coordinar página, componente y Worker.

### electrificacion_calefaccion_provincia
- **Modelo:** transform/models/marts/electrificacion_calefaccion_provincia.sql · **Páginas:** energia-clima/electrificacion (4 traducciones) · **Prioridad:** 2
- **Problemas:** `cuota_*` en proporción 0-1 (la ficha tiene que declarar `escala: 100`); España como fila con `cod_prov = '00'` sin `nivel`; `cod_ccaa` sin nombre; sin año (es el censo 2021).
- **Cambio propuesto:** añadir `cuota_electricidad_pct`, `cuota_gas_pct`, `cuota_petroleo_pct` (0-100), `nivel` (`pais`/`provincia`), `ccaa` (nombre) y `anio = 2021`.
```sql
100.0 * max(viviendas) filter (where combustible = 'Electricidad') / nullif(max(viviendas) filter (where combustible = 'Total'), 0) as cuota_electricidad_pct,
case when b.cod_prov = '00' then 'pais' else 'provincia' end as nivel, 2021 as anio
```
- **Páginas:** conservar `cod_prov`, `provincia`, `cod_ccaa`, `viviendas`, `electricidad`, `gas_natural`, `petroleo`, `otros` y las `cuota_*` 0-1 (el mapa y el gráfico las formatean con `pct`). Migrarlas a `_pct` exige cambiar el formato, no solo el nombre, y repetirlo en las 4 traducciones: dejar para después.
- **Ficha:** al migrar las páginas desaparece `escala: 100`; hasta entonces la ficha usa las nuevas `_pct` y ya no hay excepción de escala para el chat.
- **Esfuerzo/riesgo:** bajo para el modelo, medio si luego se migran páginas y traducciones.

### electrificacion_hogares
- **Modelo:** transform/models/marts/electrificacion_hogares.sql · **Páginas:** energia-clima/electrificacion (4 traducciones) · **Prioridad:** 2
- **Problemas:** `cuota` en 0-1 (escala 100 en la ficha); el total exige fijar `uso = 'Todos los usos'`, si no se duplica; `cod_uso` y `uso` redundantes; es TJ de toda España, sin por habitante (no aplica: son cuotas y energía).
- **Cambio propuesto:** añadir `cuota_pct` (0-100) y `es_total_uso` BOOLEAN (= `uso = 'Todos los usos'`) para quitar la trampa de la suma. Dejar `tj`.
```sql
100.0 * cuota as cuota_pct, uso = 'Todos los usos' as es_total_uso
```
- **Páginas:** conservar `anio`, `cod_uso`, `uso`, `combustible`, `tj`, `cuota` (las consultas filtran por `cod_uso`).
- **Ficha:** desaparece la excepción de escala (tras migrar o al apoyarse la ficha en `cuota_pct`) y la trampa del total queda explícita con `es_total_uso`.
- **Esfuerzo/riesgo:** bajo.

### electrificacion_sectores
- **Modelo:** transform/models/marts/electrificacion_sectores.sql · **Páginas:** energia-clima/electrificacion (4 traducciones) · **Prioridad:** 2
- **Problemas:** `cuota_electricidad` en 0-1; sectores que se solapan (industria y sus ramas, transporte y carretera, y "Toda la economía"), con `es_rama_industrial` solo para parte; las páginas calculan a mano `gas_natural/total`.
- **Cambio propuesto:** añadir `cuota_electricidad_pct`, `cuota_gas_pct`, `cuota_petroleo_pct`, `cuota_renovables_pct`, y `tipo_sector` (`total`, `sector`, `rama`) para saber qué filas se pueden sumar.
```sql
100.0 * electricidad / nullif(total, 0) as cuota_electricidad_pct,
case when sector = 'FC_E' then 'total' when sector like 'FC_IND_%' and sector <> 'FC_IND_E' or sector like 'FC_TRA_%_E' and sector <> 'FC_TRA_E' then 'rama' else 'sector' end as tipo_sector
```
- **Páginas:** conservar `anio`, `cod_sector`, `sector`, `es_rama_industrial`, `total`, `electricidad`, `gas_natural`, `petroleo`, `renovables`, `calor`, `carbon`, `cuota_electricidad`.
- **Ficha:** desaparecen `escala: 100` y la advertencia de no sumar sectores (queda `tipo_sector`).
- **Esfuerzo/riesgo:** bajo; la lista de ramas de transporte debe quedar bien definida (carretera y ferrocarril).

### embalses_estado_actual
- **Modelo:** transform/models/marts/embalses_estado_actual.sql · **Páginas:** energia-clima/embalses, index (8 traducciones) · **Prioridad:** 3
- **Problemas:** el aviso "unidades mezcladas" es un falso positivo (hm³ y % están en columnas distintas, bien); niveles `cuenca`, `demarcacion` y `pais` que se solapan; usa `clave`/`nombre` en vez de `cod`/`nombre`, y España es `ES` en vez de `00`.
- **Cambio propuesto:** añadir `cod` (= `clave`, y `'00'` para el nivel país) para alinearla con la convención; no renombrar `clave` ni `id`. Es derivable de `embalses_semanal` pero aporta las comparativas ya calculadas: se queda.
```sql
case when u.nivel = 'pais' then '00' else u.clave end as cod
```
- **Páginas:** conservar `id`, `nivel`, `clave`, `nombre`, `fecha`, `pct_llenado`, `volumen_hm3`, `capacidad_hm3`, `dif_vs_*`, `pct_media_10_anios`; las páginas filtran por `nivel` y `clave`.
- **Ficha:** desaparecen "unidades mezcladas" (se retira del inventario) y la excepción del código `ES`; queda la nota de fijar `nivel` antes de sumar.
- **Esfuerzo/riesgo:** bajo.

### embalses_semanal
- **Modelo:** transform/models/marts/embalses_semanal.sql · **Páginas:** energia-clima/embalses, index (8 traducciones) · **Prioridad:** 3
- **Problemas:** misma convención de territorio (`clave`/`nombre`, `ES`); niveles solapados; `pct_llenado` puede pasar de 100 (sobrellenado).
- **Cambio propuesto:** añadir `cod` como en la anterior (y `fecha` ya es DATE con `anio` y `semana`). Sin más cambios.
- **Páginas:** conservar `fecha`, `anio`, `semana`, `nivel`, `clave`, `nombre`, `id`, `capacidad_hm3`, `volumen_hm3`, `n_embalses`, `pct_llenado`.
- **Ficha:** desaparece la excepción del código de país `ES`; la nota de sobrellenado y de fijar `nivel` se queda.
- **Esfuerzo/riesgo:** bajo.

### empleo_coste
- **Modelo:** transform/models/marts/empleo_coste.sql · **Páginas:** cuentas-publicas/empleo-publico (4 traducciones) · **Prioridad:** 1
- **Problemas:** `eur_por_habitante` corriente (la página calcula `eur_hab_real` con el deflactor en dos consultas, una de ellas reconstruyendo el IPC a mano); `millones_eur` sin real; falta `anio_base`.
- **Cambio propuesto:** añadir `eur_hab_real`, `millones_eur_real` y `anio_base`.
```sql
b.millones_eur * d.factor as millones_eur_real, b.millones_eur * 1e6 * d.factor / p.habitantes as eur_hab_real, d.anio_base
left join {{ ref('deflactor') }} d on d.anio = b.anio
```
- **Páginas:** conservar `anio`, `cod_sector`, `subsector`, `millones_eur`, `pct_pib`, `eur_por_habitante`. `coste` y `coste_por_hab` deben pasar a `eur_hab_real` y borrar el IPC a mano.
- **Ficha:** desaparece "euros corrientes (no deflactados)"; la medida principal pasa a `eur_hab_real`.
- **Esfuerzo/riesgo:** bajo; la migración de la página es simple pero hay que repetirla en las 4 traducciones.

### empleo_efectivos
- **Modelo:** transform/models/marts/empleo_efectivos.sql · **Páginas:** cuentas-publicas/empleo-publico, territorios/[ccaa] y [provincia] (12 traducciones) · **Prioridad:** 2
- **Problemas:** `cod_prov` y `cod_ccaa` sin nombre; los efectivos del extranjero quedan con NULL; no hay filas de total (hay que fijar una `fecha` o se duplica); la tasa por habitante vive en `empleo_territorio`.
- **Cambio propuesto:** añadir `provincia` y `ccaa` (nombres, y `'Extranjero'` si no hay provincia) y `anio` = `year(fecha)`. No añadir por habitante aquí: ya está en `empleo_territorio`.
```sql
coalesce(t.nombre, 'Extranjero') as provincia, coalesce(cc.nombre, 'Extranjero') as ccaa
left join {{ ref('territorios_provincias') }} t on t.cod_prov = c.cod_prov
```
- **Páginas:** conservar `fecha`, `administracion`, `sector`, `tipo_personal`, `cod_prov`, `cod_ccaa`, `sexo`, `efectivos`; las páginas siguen igual.
- **Ficha:** desaparece "códigos sin nombre"; queda "fijar una edición" y la remisión a `empleo_territorio` para la tasa.
- **Esfuerzo/riesgo:** bajo; los nombres añaden poco peso al ser una tabla agregada.

### empleo_epa_ccaa
- **Modelo:** transform/models/marts/empleo_epa_ccaa.sql · **Páginas:** cuentas-publicas/empleo-publico (4 traducciones) · **Prioridad:** 1
- **Problemas:** `cuota_publico` en 0-1; solo `cod_ccaa` (con `00` España mezclado con las comunidades, sin `nivel`); `publicos`, `privados` y `total` son personas sin tasa por habitante (la página calcula "por 1.000 habitantes" aparte); sin `fecha`/`anio`.
- **Cambio propuesto:** añadir `nivel`, `cod`, `nombre`, `fecha` (= `trimestre`), `anio`, `cuota_publico_pct` (0-100) y `publicos_por_1000_hab` con `poblacion_territorios`.
```sql
case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel, n.cod_ccaa as cod, t.nombre,
100.0 * cuota_publico as cuota_publico_pct,
1000.0 * publicos / p.poblacion as publicos_por_1000_hab
```
- **Páginas:** conservar `trimestre`, `cod_ccaa`, `publicos`, `privados`, `total`, `cuota_publico`; las series de "por 1.000 hab. según la EPA" deberían usar `publicos_por_1000_hab` en lugar de unir a mano con población.
- **Ficha:** desaparecen `escala: 100`, "sin nombres" y la trampa de sumar España con las comunidades (`nivel`).
- **Esfuerzo/riesgo:** medio; población anual contra dato trimestral (usar la del año, o la última disponible como en `empleo_territorio`).

### empleo_gasto_personal_territorio
- **Modelo:** transform/models/marts/empleo_gasto_personal_territorio.sql · **Páginas:** cuentas-publicas/empleo-publico, territorios/[ccaa] y [provincia] (12 traducciones) · **Prioridad:** 1
- **Problemas:** euros corrientes: `_hab` sin deflactar (las páginas multiplican por `d.factor` en varios sitios); `gasto_personal_*` en euros crudos; `cod` sin nombre y solapado entre ccaa y provincia.
- **Cambio propuesto:** añadir `nombre`, `anio_base`, `gasto_personal_ccaa_eur_hab_real`, `gasto_personal_ayuntamientos_eur_hab_real` y `gasto_personal_ccaa_meur_real`.
```sql
c.gasto_personal_ccaa / p.poblacion * d.factor as gasto_personal_ccaa_eur_hab_real,
a.gasto / nullif(a.pob, 0) * d.factor as gasto_personal_ayuntamientos_eur_hab_real, d.anio_base
```
- **Páginas:** conservar `anio`, `nivel`, `cod`, `gasto_personal_ccaa`, `gasto_personal_ccaa_hab`, `gasto_personal_ayuntamientos`, `gasto_personal_ayuntamientos_hab`, `ayuntamientos_con_datos`. `empleo-publico` y `[ccaa]` deben leer las `_real` y dejar el `coalesce(f.factor, 1)`.
- **Ficha:** desaparecen "euros corrientes (no deflactados)" y "solo código"; permanece la limitación foral (Álava y Navarra sin datos).
- **Esfuerzo/riesgo:** bajo para el modelo; la migración de [ccaa] es la más delicada: el `coalesce(factor, 1)` actual trata como 1 un año sin deflactor, y eso hay que decidirlo (mejor NULL).

---

## Resumen del lote

- Prioridad 1: 7 (cuentas_balance_anual, cuentas_gastos, cuentas_ingresos, cuentas_subsectores, empleo_coste, empleo_epa_ccaa, empleo_gasto_personal_territorio).
- Prioridad 2: 13 (demografia_anual, demografia_envejecimiento, demografia_hogares, demografia_piramide, educacion_gasto_alumno, educacion_indicadores, elecciones_familias, elecciones_municipios, elecciones_participacion, electrificacion_calefaccion_provincia, electrificacion_hogares, electrificacion_sectores, empleo_efectivos).
- Prioridad 3: 5 (economia_pib_trimestral, elecciones_partidos, electricidad_diaria, embalses_estado_actual, embalses_semanal).
- Sin cambios (—): 5 (deflactor, diputados_inmuebles_resumen, electricidad_records, electricidad_records_historia, electricidad_ultimas_24h).
- Borrar: 0 en este lote (`elecciones_municipios_congreso`, de otro lote, queda candidata si `elecciones_municipios` gana los nombres).
