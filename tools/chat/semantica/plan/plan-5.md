# Plan de limpieza, lote 5 (30 tablas)

Notas comunes (valen para todas las tablas):

- La tabla publicada es `sources/mother/<tabla>.sql` encima del mart dbt. Las columnas nuevas se añaden en el mart (y en el `SELECT` de `sources/mother` cuando enumera columnas: `municipios_cuentas`, `municipios_cuentas_serie`, `municipios_politicas`, `salud_causas_muerte`). Cada cambio toca además `schema_*.yml` (descripción de la columna) y la ficha en `lote-*.json`.
- Recetas ya resueltas en el repo: euros reales = `left join {{ ref('deflactor') }} d on d.anio = x.anio` y `x * d.factor` + `d.anio_base` (ver `sanidad_gasto_ccaa.sql`, `renta_distritos.sql`); nombre de territorio = `left join {{ ref('territorios') }} t on t.nivel = x.nivel and t.cod = x.cod` (ver `pensiones_territorio.sql`); por habitante con población = `ref('poblacion_territorios')` con el año acotado al rango disponible (`greatest(least(anio, max), min)`, ver `pensiones_territorio.sql`); nombre de municipio = último padrón de `ref('poblacion_municipios')` (CTE `municipios` de `municipios_cuentas.sql`).
- En el parquet publicado todos los numéricos salen como DOUBLE (también `anio`), así que la convención `anio INTEGER` no se puede cumplir tabla a tabla; las páginas ya hacen `CAST(anio AS INTEGER)`. Fuera de este plan.
- Peso: probado con `municipios_cuentas` y `municipios_cuentas_serie`: añadir `municipio` (dictionary encoding de parquet) cuesta unos 80-100 KB (3-4 %) sobre 2,3 MB. No justifica seguir quitando el nombre.
- Riesgo común de añadir `nombre`/`municipio`: páginas con `SELECT *` + `JOIN mother.territorios` recibirían dos columnas `nombre`. Antes de subir, buscar `SELECT \*` junto a un join con `territorios` en las páginas (y sus copias en `en|ca|gl|eu`) de cada tabla.

### movilidad_parque_municipio
- **Modelo:** transform/models/marts/movilidad_parque_municipio.sql · **Páginas:** movilidad/parque (4 traducciones) · **Prioridad:** 1 (parque de turismos sin nombre ni cifra por habitante)
- **Problemas:** solo `cod_mun` (sin nombre); no hay `turismos` por habitante (la página lo calcula uniendo con `poblacion_municipios`); cuotas como proporciones 0-1 calculadas en la página; solo municipios de 10.000 hab. o más (la DGT anonimiza el resto), no se puede arreglar.
- **Cambio propuesto:** añadir `municipio`, `cod_prov`, `poblacion` (padrón más reciente), `turismos_por_1000_hab`, `bev_por_1000_hab`, `enchufables_pct`, `sin_distintivo_pct`, `mas_15_anios_pct` (0-100). Sin tocar las existentes.
  ```sql
  join (select cod_mun, municipio, cod_prov, poblacion from {{ ref('poblacion_municipios') }}
        where sexo = 'Total' qualify anio = max(anio) over ()) m using (cod_mun)
  -- 1000.0 * turismos / m.poblacion as turismos_por_1000_hab
  -- 100.0 * (bev + coalesce(phev, 0)) / turismos as enchufables_pct
  ```
- **Páginas:** conservar `cod_mun, turismos, bev, phev, sin_distintivo, mas_de_15_anios`. `parque.md` puede dejar el `JOIN poblacion_municipios` y usar `turismos_por_1000_hab` y los `_pct` (la columna `poblacion` ya viene en la tabla).
- **Ficha:** desaparecen «sin nombre» y «no hay cifra por habitante». Queda «solo el último mes y municipios de 10.000 hab. o más».
- **Esfuerzo/riesgo:** bajo; 780 filas, solo columnas nuevas.

### movilidad_parque_provincia
- **Modelo:** transform/models/marts/movilidad_parque_provincia.sql · **Páginas:** movilidad/camiones-y-autobuses, movilidad/index, movilidad/parque (12 traducciones) · **Prioridad:** 1 (parque sin cifra por habitante; el chat no puede responder «coches por habitante»)
- **Problemas:** sin población ni tasa por habitante (cada página trae `poblacion` de `poblacion_territorios` y divide); `cod_ccaa` sin nombre de comunidad; sin fila total (hay que sumar categorías y filtrar `grupo = 'turismo'`); `mes` único (último mes cargado).
- **Cambio propuesto:** añadir `ccaa` (nombre), `poblacion` (provincia, padrón más reciente) y `vehiculos_por_1000_hab` = `1000 * vehiculos / poblacion`, que es aditiva dentro de una provincia (sumar filas de una provincia da su tasa total). Ojo: `poblacion` se repite en cada fila, no se suma; la ficha debe decir que para España es `sum(vehiculos) / población de España`.
  ```sql
  join {{ ref('territorios') }} t on t.nivel = 'provincia' and t.cod = p.cod_prov   -- ya existe join a territorios_provincias
  -- t.poblacion_ultima as poblacion
  -- 1000.0 * sum(p.vehiculos) / t.poblacion_ultima as vehiculos_por_1000_hab
  ```
  (`territorios.poblacion_ultima` ya trae la última población oficial por provincia.)
- **Páginas:** conservar `mes, cod_prov, provincia, cod_ccaa, grupo, energia, distintivo, antiguedad, vehiculos`. `parque.md` (tabla de provincias) pasaría a `sum(vehiculos_por_1000_hab) FILTER (grupo = 'turismo')` para el ranking por habitante en vez de solo `turismos` totales (hoy ordena por turismos absolutos, que premia a las provincias grandes).
- **Ficha:** desaparece «por habitante hay que dividir por población» (queda el aviso de no sumar `poblacion`). El defecto `grupo = turismo` para coches se mantiene (es una dimensión real).
- **Esfuerzo/riesgo:** bajo; el riesgo es que alguien sume `poblacion`, por eso va con aviso en la ficha.

### movilidad_recarga_evolucion
- **Modelo:** transform/models/marts/movilidad_recarga_evolucion.sql · **Páginas:** ninguna (0 traducciones); la leen los marts `mapas_territorio.sql` (l.708) y `metricas_energia.sql` (l.304) y una pregunta de `tools/chat/evaluacion/preguntas-validacion4.json` · **Prioridad:** 3 (cosmético)
- **Problemas:** `tramo_potencia` en minúsculas y distinto de `movilidad_recarga_sitios.tramo` (`lenta (<22 kW)` frente a `Lenta (<22 kW)`); sin orden de tramo; solo 8 filas (2 días) y sin `anio`.
- **Cambio propuesto:** NO borrar (la usan dos marts y el banco de preguntas). Poner el mismo texto de tramo que `movilidad_recarga_sitios` (`initcap` en la primera letra) y añadir `tramo_orden` y `anio`. Los marts que la leen no filtran por texto de tramo (comprobar al aplicar).
  ```sql
  case tramo_potencia when 'ultrarrápida (≥150 kW)' then 1 when 'rápida (50-149 kW)' then 2
       when 'semirrápida (22-49 kW)' then 3 else 4 end as tramo_orden
  ```
- **Páginas:** ninguna que conservar. Decisión del dueño: si prefiere no publicarla, se puede quitar de `sources/mother` y dejarla solo como mart interno (los dos marts siguen funcionando); el coste es perder la serie diaria en el chat.
- **Ficha:** desaparece la ambigüedad de nombres de tramo entre tablas.
- **Esfuerzo/riesgo:** bajo; hay que revisar que `metricas_energia.sql` no compare el texto del tramo.

### movilidad_recarga_sitios
- **Modelo:** transform/models/marts/movilidad_recarga_sitios.sql · **Páginas:** movilidad/recarga (4 traducciones) · **Prioridad:** 2 (mejora clara)
- **Problemas:** `cod_mun` y `cod_prov` sin nombre (4 sitios sin ninguno); operadores con razón social completa (156 valores: «IBERDROLA CLIENTES S.A.U», «ENDESA X WAY, S.L.»); sin cifra por habitante (es un punto de recarga, la tasa se calcula al agregar).
- **Cambio propuesto:** añadir `municipio`, `provincia`, `cod_ccaa`, `ccaa` uniendo con `poblacion_municipios` (último padrón) y `territorios`. Opcional (más trabajo): `operador_grupo` con un seed pequeño (Iberdrola, Endesa X Way, Repsol, Tesla...). La tasa por habitante ya existe en `movilidad_recarga_provincia` (`puntos_por_100k_hab`), no hace falta repetirla aquí.
  ```sql
  left join (select cod_mun, municipio from {{ ref('poblacion_municipios') }} where sexo='Total'
             qualify anio = max(anio) over ()) m on m.cod_mun = s.cod_mun
  ```
- **Páginas:** conservar `sitio_id, sitio, operador, latitud, longitud, puntos, potencia_max_kw, tramo, tramo_orden`; `recarga.md` usa `SELECT *` en el mapa (las columnas nuevas viajan al navegador, 12.000 filas: vigilar el peso o limitar la lista de columnas del mapa).
- **Ficha:** desaparece «sin nombre de municipio»; la nota de razones sociales se resuelve con `operador_grupo` si se hace.
- **Esfuerzo/riesgo:** bajo (nombres) / medio (grupo de operador con seed).

### movilidad_transporte_modos
- **Modelo:** transform/models/marts/movilidad_transporte_modos.sql · **Páginas:** movilidad/index, movilidad/transporte-publico (8 traducciones) · **Prioridad:** 1 (viajeros sin cifra por habitante y con modos solapados que el chat suma)
- **Problemas:** hay 25 `modo` y 11 sin `clave` (Transporte especial, escolar, laboral, discrecional, aéreo peninsular/interinsular, autobús interurbano media/larga distancia/cercanías) que la página descarta con `clave IS NOT NULL`; los modos se solapan (urbano contiene metro y autobús urbano, ferrocarril contiene cercanías/media/larga, alta velocidad es parte de larga distancia) y el total no incluye avión ni marítimo; sin cifra por habitante (`index.md` calcula `1000 * viajeros / población` uniendo por año).
- **Cambio propuesto:** añadir `clave_padre` (modo que lo contiene, `NULL` para `total` y para los de primer nivel), `en_total` BOOLEAN (cuenta dentro de «Total de viajeros»), `anio`, `poblacion` (España, padrón del año acotado al rango) y `viajeros_por_1000_hab`. Dar `clave` también a los 11 modos que no la tienen (así `clave IS NOT NULL` deja de ser una trampa). La jerarquía hay que comprobarla contra los datos (suma de hijos = padre) antes de fijarla.
  ```sql
  case clave when 'metro' then 'urbano' when 'autobus_urbano' then 'urbano'
             when 'cercanias' then 'ferrocarril' when 'media_distancia' then 'ferrocarril'
             when 'larga_distancia' then 'ferrocarril' when 'alta_velocidad' then 'larga_distancia'
             when 'larga_distancia_convencional' then 'larga_distancia'
             when 'urbano' then 'total' when 'interurbano' then 'total' end as clave_padre
  ```
- **Páginas:** conservar `mes, modo, clave, viajeros`. `index.md` (`transporte_serie`) pasa a `viajeros_por_1000_hab` y se quita el `JOIN pob`; `transporte-publico.md` puede seguir con `clave IS NOT NULL` (inocuo si todos tienen clave).
- **Ficha:** desaparecen la advertencia de solapamiento (queda `clave_padre`/`en_total`), «no sumar todos los modos» y la ausencia de por habitante.
- **Esfuerzo/riesgo:** medio; la jerarquía exige validar sumas y cuidado con las claves nuevas (no cambiar las ya usadas por páginas).

### municipios_cuentas
- **Modelo:** transform/models/marts/municipios_cuentas.sql (más `sources/mother/municipios_cuentas.sql`, que recorta columnas) · **Páginas:** territorios/municipios (4 traducciones) · **Prioridad:** 1 (euros corrientes sin deflactar; la página deflacta a mano)
- **Problemas:** importes y `gasto_hab`/`ingreso_hab` en euros corrientes (la página multiplica por `mother.deflactor.factor` en cada consulta); sin `municipio` (el mart lo tiene, el `SELECT` publicado lo quita); `tiene_datos = false` deja filas con importes NULL; 2025 provisional con 5.900 de 8.100 municipios.
- **Cambio propuesto:** en `sources/mother/municipios_cuentas.sql` añadir `municipio`, `cod_prov`, `gasto_hab_real`, `ingreso_hab_real`, `anio_base` y, para totales, `gastos_total_real`, `ingresos_total_real` y `saldo_no_financiero_real` (BIGINT redondeados como los demás). Capítulos y áreas se quedan en corrientes (por capítulo la página ya usa la tabla de medianas), salvo que se quiera `_real` también ahí: no lo propongo, son 30 columnas.
  ```sql
  left join {{ ref('deflactor') }} d on d.anio = b.anio
  -- round(gasto_hab * d.factor)::INTEGER as gasto_hab_real, d.anio_base
  ```
  Alternativa a decidir: mantener el recorte de columnas y que `gasto_hab_real`/`ingreso_hab_real` sean las únicas nuevas más `municipio`.
- **Páginas:** conservar `cod_mun, anio, provisional, poblacion, tiene_datos, gastos_c1, gastos_total, gasto_area_*, ingresos_*, saldo_no_financiero, gasto_hab, ingreso_hab`. `municipios.md` (`areas`, `capitulo1`) puede sustituir `x * (SELECT factor FROM defl)` por las columnas `_real` y quitar el CTE `defl` (hoy repetido 3 veces por página y por idioma).
- **Ficha:** desaparece «importes en euros corrientes (sin deflactar)» y «sin nombre». Quedan `tiene_datos`, `provisional` y que 2025 es parcial (la marca `provisional` ya cumple la convención).
- **Esfuerzo/riesgo:** medio; son pocas columnas, pero las páginas usan el factor del último año definitivo (`defl` por año) mientras la columna usa el factor del año de cada fila: ojo con los dos en la misma gráfica (hoy `defl` lleva todo al mismo año base, que es lo que hace `anio_base`).

### municipios_cuentas_serie
- **Modelo:** transform/models/marts/municipios_cuentas.sql (el publicado es `sources/mother/municipios_cuentas_serie.sql`) · **Páginas:** territorios/municipios (4 traducciones) · **Prioridad:** 1 (misma razón que `municipios_cuentas`)
- **Problemas:** euros corrientes; sin nombre; 130.000 filas con `tiene_datos = false` en torno al 13 % de los años definitivos y al 27 % de 2025; la página reconstruye `_real` con el deflactor y el tramo de población con un `CASE` repetido.
- **Cambio propuesto:** igual que `municipios_cuentas`: `municipio`, `cod_prov`, `gasto_hab_real`, `ingreso_hab_real`, `saldo_hab_real`, `gastos_total_real`, `ingresos_total_real`, `anio_base`; y `tramo_poblacion` (texto igual al `CASE` de la página, ya usado en `municipios_cuentas_medias.tramo_poblacion`) para que cada página no lo recalcule.
  ```sql
  case when poblacion < 1000 then 1 when poblacion < 5000 then 2 ... else 7 end as tramo_orden
  ```
  (usar el mismo criterio que `municipios_cuentas_medias`, no inventar otros tramos).
- **Páginas:** conservar `cod_mun, anio, provisional, tiene_datos, poblacion, gasto_hab, ingreso_hab, gastos_total, ingresos_total, saldo_no_financiero`; `cuentas_serie` y `politicas_mun` de `municipios.md` ganan columnas ya hechas y pierden el `JOIN mother.deflactor`.
- **Ficha:** desaparecen «euros corrientes» y «sin nombre». Se mantiene `tiene_datos` (la fila existe para saber que el municipio no rindió cuentas).
- **Esfuerzo/riesgo:** medio; el tramo hay que alinearlo con `municipios_cuentas_medias` (tabla que no es de este lote).

### municipios_politicas
- **Modelo:** transform/models/marts/municipios_politicas.sql (el publicado filtra al último año) · **Páginas:** territorios/municipios (4 traducciones) · **Prioridad:** 1 (importes en euros corrientes)
- **Problemas:** `importe` e `importe_hab` corrientes; sin `municipio` ni `poblacion` (la página une con `municipios_cuentas_serie` para el tramo y la población); solo un año (2024), áreas y políticas como dos niveles de la misma clasificación; algún importe negativo es un ajuste.
- **Cambio propuesto:** añadir `municipio`, `poblacion`, `importe_real`, `importe_hab_real`, `anio_base` (deflactor del año del importe).
  ```sql
  left join {{ ref('deflactor') }} d on d.anio = p.anio
  -- p.importe * d.factor as importe_real
  -- round(p.importe * d.factor / nullif(c.poblacion, 0), 2) as importe_hab_real
  ```
  Decisión: ampliar el recorte de `sources/mother` a los tres últimos ejercicios definitivos que el mart ya calcula (88.669 filas son las del último año; con tres años serían unas 3 veces más, ~2,5 MB). Sin esa ampliación no hay serie de políticas, pero cada tabla pesa lo mismo que hoy.
- **Páginas:** conservar `cod_mun, anio, cod_area, area_nombre, cod_politica, politica_nombre, importe, importe_hab`; `politicas_mun` pasa a `importe_hab_real` y pierde el CTE `defl` y la unión con `municipios_cuentas_serie` salvo para el tramo.
- **Ficha:** desaparece «euros corrientes»; queda «sumar políticas da el gasto total» y el aviso de ajustes negativos.
- **Esfuerzo/riesgo:** bajo (columnas) / medio si se amplía a tres años (peso y ficha).

### observatorios
- **Modelo:** transform/models/marts/observatorios.sql · **Páginas:** ninguna (0 traducciones, 0 componentes) · **Prioridad:** 3 (cosmético: borrar)
- **Problemas:** duplicada por `observatorios_detalle` (mismo censo con nivel, ubicación, estado y partido); columnas en inglés (`name, creation_year, is_active, scope`) y un ámbito sin normalizar. Comprobado: ninguna página, componente, `tools/` (salvo la ficha), `orchestration/` ni `ingestion/` lee `mother.observatorios`; solo la declara `schema.yml`. La ingestión `ingestion/observatorios.py` alimenta `stg_observatorios`, que SÍ usa `observatorios_detalle`: no se toca.
- **Cambio propuesto:** borrar la tabla publicada y el mart. Pasos: eliminar `sources/mother/observatorios.sql`, `transform/models/marts/observatorios.sql`, su entrada en `transform/models/marts/schema.yml` (líneas ~78-82, test `not_null` de `name`) y su ficha en `lote-*.json`. Conservar `stg_observatorios`.
- **Páginas:** ninguna.
- **Ficha:** desaparece la ficha entera (y su excepción de «duplicada»).
- **Esfuerzo/riesgo:** bajo; solo hay que confirmar que ninguna copia traducida ni la web de MCP la nombran (la búsqueda no encontró nada).

### observatorios_detalle
- **Modelo:** transform/models/marts/observatorios_detalle.sql · **Páginas:** varios/observatorios (4 traducciones); la leen además los marts `mapas_territorio.sql` y `metricas_vivienda_cuentas.sql` · **Prioridad:** 3 (cosmético)
- **Problemas:** `cod_prov` sin nombre de provincia; la comunidad se llama `comunidad` (la convención dice `ccaa`); `color_partido` es presentación dentro de los datos; 259 de 520 con estado «Sin información». Es una lista (sin cifras), contable solo por filas.
- **Cambio propuesto:** añadir `provincia` (join a `territorios` nivel `provincia`) y `ccaa` como copia de `comunidad` (sin quitar `comunidad`). No se toca nada más: no es tabla de cifras y los 520 registros ya tienen cada atributo con su método (`metodo_ubicacion`, `metodo_partido`).
  ```sql
  left join (select cod, nombre from {{ ref('territorios') }} where nivel = 'provincia') pr on pr.cod = c.cod_prov
  -- pr.nombre as provincia, nc.nombre as ccaa
  ```
- **Páginas:** conservar `nombre, nivel, cod_ccaa, comunidad, cod_prov, cod_mun, municipio, anio_creacion, estado, tipo, partido, gobernante, color_partido, cambio_en_el_anio`.
- **Ficha:** desaparece la ausencia de nombre de provincia; la nota «sin cifras» se queda (es la verdad).
- **Esfuerzo/riesgo:** bajo; solo añade dos columnas.

### pensiones_afiliados_regimen
- **Modelo:** transform/models/marts/pensiones_afiliados_regimen.sql · **Páginas:** cuentas-publicas/pensiones (4 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** el año en curso promedia solo los meses publicados, pero ya lo marca la columna `meses` (cumple la convención); `Total` y regímenes conviven con valor `Total` legible; `por_1000_hab` ya está.
- **Cambio propuesto:** ninguno. Opcional: `es_parcial` (`meses < 12`) para no depender de saber que hay que filtrar `meses = 12`, pero la convención acepta `meses`.
- **Páginas:** `anio, regimen, meses, pct_del_total` (todas se conservan).
- **Ficha:** sin cambios (el aviso de `meses` se queda).
- **Esfuerzo/riesgo:** nulo.

### pensiones_anual
- **Modelo:** transform/models/marts/pensiones_anual.sql · **Páginas:** cuentas-publicas/pensiones (4 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** solo España; el año en curso suma 9 meses (columna `meses`, vale); gastos en % del PIB con huecos en los últimos años (dato de Eurostat, no arreglable aquí). Ya están `pension_media_real` (euros de `anio_euros`), `pensiones_por_1000_hab` y `poblacion`. Repite la fila `pais` de `pensiones_territorio` pero añade salario, tasa de sustitución y gasto/PIB (derivados de otras fuentes), así que no es un duplicado.
- **Cambio propuesto:** ninguno. Decisión menor: la columna se llama `anio_euros` mientras otras tablas usan `anio_base`; añadir `anio_base` como copia sería lo único coherente, pero no merece tocarla.
- **Páginas:** la página hace `SELECT *`; no se puede quitar nada.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** nulo.

### pensiones_territorio
- **Modelo:** transform/models/marts/pensiones_territorio.sql · **Páginas:** cuentas-publicas/pensiones, territorios/[ccaa]/index, territorios/[ccaa]/[provincia] (12 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** el mismo `cod` significa cosas distintas según `nivel` (hay que filtrar por nivel; la convención lo permite porque lleva `nivel` + `cod` + `nombre`); las comunidades uniprovinciales aparecen también como provincia con las mismas cifras (documentado en el SQL); afiliados solo desde 2021; 2026 con 9 meses (`meses`).
- **Cambio propuesto:** ninguno. Es la tabla que sigue la convención (nombre, nivel, euros reales con deflactor, por 1.000 hab y por 100 mayores). Sirve de modelo para las demás.
- **Páginas:** todas las columnas se conservan.
- **Ficha:** sin cambios; se mantiene el aviso de nivel/`cod` y de provincia 28.
- **Esfuerzo/riesgo:** nulo.

### poblacion_territorios
- **Modelo:** transform/models/marts/poblacion_territorios.sql · **Páginas:** 15 páginas (empleo-publico, index, medios, movilidad, territorios, varios/observatorios...) (60 traducciones) · **Prioridad:** 2 (mejora clara; es la tabla base del principio por habitante)
- **Problemas:** sin `nombre` (hay que unir con `territorios`); el mismo `cod` por nivel; `sexo` en 3 valores, de modo que olvidar `sexo = 'Total'` triplica la población (los 60 usos lo filtran a mano).
- **Cambio propuesto:** añadir `nombre` (de `territorios`). No cambiar `sexo`: partir la tabla rompe 60 páginas; la ficha ya lleva el defecto `sexo = 'Total'`.
  ```sql
  left join {{ ref('territorios') }} t on t.nivel = a.nivel and t.cod = a.cod   -- a.* de agregados
  -- t.nombre
  ```
  Cuidado: `territorios.sql` lee `poblacion_territorios` (para `poblacion_ultima`); añadir el join aquí crea un ciclo. Hay que sacar el nombre de `territorios_ccaa` y `territorios_provincias` (los seeds/stages que ya usa `territorios`), no de `territorios`.
- **Páginas:** conservar `anio, nivel, cod, sexo, poblacion, n_municipios`; ninguna cambia.
- **Ficha:** desaparece «no tiene columna de nombre». Se mantienen `defecto sexo = 'Total'` y la nota del `cod` por nivel.
- **Esfuerzo/riesgo:** medio; el ciclo con `territorios` obliga a usar los modelos de ccaa y provincias directamente.

### primario_aceite
- **Modelo:** transform/models/marts/primario_aceite.sql · **Páginas:** economia/sector-primario (4 traducciones) · **Prioridad:** 3 (cosmético)
- **Problemas:** `grupo` mezcla países y agregados («Resto de la UE», «Mundo (COI)»); `campania` texto `2024/25` y `anio` es el de inicio de campaña (no hay `fecha`); sin código de país. Ya tiene `kg_hab` y cuotas.
- **Cambio propuesto:** añadir `cod_pais` (ES, IT, GR, PT; `EU27_2020` para la UE restante y `MUNDO` para el COI) y `es_agregado` BOOLEAN (true para «Resto de la UE» y «Mundo (COI)»). La página sigue con `grupo <> 'Mundo (COI)'`.
  ```sql
  case grupo when 'España' then 'ES' when 'Italia' then 'IT' when 'Grecia' then 'GR' when 'Portugal' then 'PT'
             when 'Mundo (COI)' then 'MUNDO' else 'UE_RESTO' end as cod_pais,
  grupo in ('Resto de la UE', 'Mundo (COI)') as es_agregado
  ```
- **Páginas:** conservar `campania, anio, grupo, produccion_miles_t, cuota_ue_pct, cuota_mundo_pct, kg_hab, estimado`.
- **Ficha:** desaparece «Resto de la UE y Mundo no son países» (queda `es_agregado`). El aviso de estimación (`estimado`) se queda.
- **Esfuerzo/riesgo:** bajo.

### primario_aceite_precios
- **Modelo:** transform/models/marts/primario_aceite_precios.sql · **Páginas:** economia/sector-primario (4 traducciones) · **Prioridad:** 3 (cosmético)
- **Problemas:** `geo` en código Eurostat (`EL` para Grecia en lugar de `GR`); sin `anio`; las tres `categoria` no se mezclan (Virgen extra es el defecto de la ficha); `eur_kg_real` usa el IPC mensual de España con base el último mes (`mes_base`) también para Italia y Grecia (así «euros de hoy» leídos en España).
- **Cambio propuesto:** añadir `cod_pais` (ISO: GR para EL) y `anio`; conservar `geo` y `eur_kg_real`. No cambio el deflactor: el mensual es más preciso que el anual para una serie de precios mensuales y ya está documentado. Dejar el defecto `categoria = 'Virgen extra'` (es una dimensión real, no un hueco).
  ```sql
  case s.geo when 'EL' then 'GR' else s.geo end as cod_pais, year(s.mes) as anio
  ```
- **Páginas:** conservar `geo, pais, categoria, mes, eur_kg, eur_kg_real, mes_base`.
- **Ficha:** desaparece nada importante; la ficha ya explica el defecto de categoría. Se puede anotar que en Italia y Grecia el real usa el IPC de España.
- **Esfuerzo/riesgo:** bajo.

### primario_ccaa_cultivos
- **Modelo:** transform/models/marts/primario_ccaa_cultivos.sql · **Páginas:** economia/sector-primario (4 traducciones) · **Prioridad:** 3 (cosmético)
- **Problemas:** el código de comunidad se llama `cod` + `ccaa` (la convención de un solo nivel pide `cod_ccaa` + `ccaa`); `Cereales` incluye `Cebada`, `Maíz en grano` y `Arroz` (hay que no sumarlos); ceros donde no se cultiva (Eurostat los da como 0, no son huecos). Ya tiene `kg_hab` y `ha_1000hab`.
- **Cambio propuesto:** añadir `cod_ccaa` (copia de `cod`) y `es_agregado` BOOLEAN (`producto_id = 'C0000'`) para que el chat no sume cereales con sus partes.
  ```sql
  d.cod as cod_ccaa, d.crops = 'C0000' as es_agregado
  ```
- **Páginas:** conservar `cod, ccaa, producto_id, producto, anio, produccion_miles_t, superficie_miles_ha, cuota_espana_pct, kg_hab, ha_1000hab, poblacion`.
- **Ficha:** desaparece el aviso de «Cereales incluye ...» (queda `es_agregado`).
- **Esfuerzo/riesgo:** bajo.

### primario_mundo
- **Modelo:** seed transform/seeds/primario_mundo.csv (la publica `sources/mother/primario_mundo.sql`) · **Páginas:** economia/sector-primario (4 traducciones) · **Prioridad:** 3 (cosmético)
- **Problemas:** 23 filas de valores fijos de COI y OIV con unidades distintas por indicador (cada fila lleva `unidad`, que cumple la convención de formato largo); `cod` mezcla ISO y `MUNDO`; solo salen los 3-5 primeros países (no hay ranking completo); sin cifra por habitante.
- **Cambio propuesto:** añadir `cod_pais` (copia de `cod`) y `es_agregado` BOOLEAN (`cod = 'MUNDO'`) en el CSV o en un `select` del modelo del seed. El por habitante no se puede hacer: no existe población de países fuera de la UE (Turquía, Túnez, Argentina...) en las fuentes; haría falta ingestar `Eurostat/UN` nuevas.
- **Páginas:** conservar `indicador, periodo, anio, cod, pais, valor, unidad, puesto_mundo`.
- **Ficha:** desaparece el aviso «`Mundo` no es un país» (queda `es_agregado`); sigue «filtrar por indicador».
- **Esfuerzo/riesgo:** bajo (seed pequeño); el cambio de CSV sin tocar las columnas existentes no rompe nada.

### primario_paises_largo
- **Modelo:** transform/models/marts/primario_paises_largo.sql · **Páginas:** economia/sector-primario (4 traducciones, solo el cálculo del precio del vino exportado) · **Prioridad:** 2 (mejora clara)
- **Problemas:** tabla base en formato largo (producto × país × año) que mezcla unidades distintas en `valor` (cada fila lleva `unidad`, vale); `geo` con códigos Eurostat (`EL`) sin `cod_pais`; trae `poblacion_miles` pero no la tasa por habitante ni el euro real, que sí calculan sus derivadas (`primario_serie_espana`, `primario_pesca`) solo para España o pesca; el chat solo puede comparar países producto a producto si conoce `producto_id` (hay 70).
- **Cambio propuesto:** no borrarla (es la única que da todos los países y años; la página del vino la necesita y las derivadas dependen de ella, aunque la ficha pida usar las derivadas). Enriquecerla igual que `primario_serie_espana`: `cod_pais`, `valor_hab`, `unidad_hab`, `valor_real` y `valor_hab_real` (solo `M EUR`), `anio_base`.
  ```sql
  case unidad when 'miles de t' then 'kg por habitante' when 'M EUR' then 'euros por habitante' ... end as unidad_hab,
  case when unidad = 'M EUR' then valor * d.factor end as valor_real
  ```
  Decisión del dueño: (a) mantenerla como tabla pública enriquecida (recomendado) o (b) dejarla solo como mart interno y crear una `primario_vino_precio` pequeña para la página (más trabajo y menos poder de comparación). El real de valores de otros países usa el IPC de España (igual que `primario_pesca`): no hay IPC por país (haría falta ingestar HICP de Eurostat para un deflactor correcto).
- **Páginas:** `sector-primario` usa `producto_id, geo, pais, anio, valor` (la consulta del vino); se conservan.
- **Ficha:** desaparece «mezcla unidades en una columna: no sirve sin filtrar por producto» para las cifras por habitante (queda `unidad`); y «usar las derivadas» deja de ser obligatorio.
- **Esfuerzo/riesgo:** medio; son 48.000 filas y la tabla es grande en cifras, pero las columnas nuevas son derivadas de las mismas.

### primario_pesca
- **Modelo:** transform/models/marts/primario_pesca.sql · **Páginas:** economia/sector-primario (4 traducciones) · **Prioridad:** 2 (mejora clara)
- **Problemas:** `medida` en formato largo con 5 unidades en `valor` (cada fila lleva `unidad`); `kg_hab` solo para capturas y acuicultura en volumen; `valor_real` solo para `acuicultura_eur` y sin su tasa por habitante; la flota (arqueo y buques) sin tasa; el defecto `medida` es obligatorio; Irlanda y Portugal no publican capturas recientes (la cuota se infla, ya trae `cuota_min_pct`).
- **Cambio propuesto:** añadir `valor_hab`, `unidad_hab` y `valor_hab_real` con la misma lógica de `primario_serie_espana` (kg por habitante, euros reales por habitante, GT por 1.000 hab., buques por 100.000 hab.), `cod_pais` (GR por EL). Se queda `kg_hab` para no romper la página (se puede retirar cuando ninguna página lo use).
  ```sql
  case when r.unidad = 'M EUR' then r.valor * d.factor * 1000 / r.poblacion_miles end as valor_hab_real,
  case when r.unidad = 'buques' then r.valor / r.poblacion_miles * 100 else r.valor * 1000 / r.poblacion_miles end as valor_hab
  ```
- **Páginas:** conservar `medida, geo, pais, anio, valor, cuota_pct, cuota_min_pct, kg_hab`. `sector-primario.md` (pesca_hab) puede pasar a `valor_hab`/`valor_hab_real` para acuicultura en euros; hoy compara kg por habitante, que ya cumple.
- **Ficha:** desaparece «`kg_hab` solo en capturas y acuicultura_t» y «`valor_real` solo en acuicultura_eur» (todo con tasa por habitante). Se mantienen el filtro por `medida` (defecto) y el aviso de Irlanda/Portugal.
- **Esfuerzo/riesgo:** bajo; el modelo ya tiene las piezas.

### primario_serie_espana
- **Modelo:** transform/models/marts/primario_serie_espana.sql · **Páginas:** economia/sector-primario (4 traducciones) · **Prioridad:** 3 (cosmético)
- **Problemas:** ya cumple casi todo (`valor_hab`, `unidad_hab`, `valor_real`, `valor_hab_real`, `anio_base`); la página filtra `n_paises = 27` para evitar años con pocos países (cuotas infladas), y el año en curso está incompleto en algunos cereales; las unidades por producto (hay que filtrar por `producto_id`).
- **Cambio propuesto:** añadir `cobertura_completa` BOOLEAN (`n_paises = max(n_paises)` por producto) para sustituir el `n_paises = 27` fijo de las páginas (que no sirve en ovino o caprino) y marcar los años con pocos países; dejar `n_paises`.
  ```sql
  r.n_paises = max(r.n_paises) over (partition by r.producto_id) as cobertura_completa
  ```
- **Páginas:** conservar `anio, producto_id, cuota_pct, valor_hab, n_paises, valor_espana...`; las consultas de `serie_citricos`, `serie_porcino`, `huerta_serie` pueden pasar de `n_paises = 27` a `cobertura_completa`.
- **Ficha:** desaparece el aviso sobre años incompletos (queda `cobertura_completa`).
- **Esfuerzo/riesgo:** bajo.

### renta_distritos
- **Modelo:** transform/models/marts/renta_distritos.sql · **Páginas:** territorios/municipios (4 traducciones) · **Prioridad:** 3 (cosmético)
- **Problemas:** solo `cod_mun` (sin `municipio`); `distrito` es `Distrito 01`, `Distrito 02` y la página lo prefija otra vez (`'Distrito ' || distrito` da «Distrito Distrito 01»; hallazgo a corregir en `municipios.md` línea 455); ya está en euros reales y con `anio_base`; no hay `cod_prov`.
- **Cambio propuesto:** añadir `municipio` (último padrón, como `municipios_cuentas`) y `poblacion_municipio` no hace falta. No tocar el resto.
  ```sql
  left join (select cod_mun, municipio from {{ ref('poblacion_municipios') }} where sexo='Total'
             qualify anio = max(anio) over ()) m using (cod_mun)
  ```
- **Páginas:** conservar `cod_mun, cod_distrito, distrito, anio, renta_persona_real, renta_hogar_real`. Corregir la página quitando el `'Distrito ' ||` duplicado (error visible, afecta también a las 4 traducciones).
- **Ficha:** desaparece «no hay nombre de municipio: unir con renta_municipios». Se mantiene «los distritos se llaman Distrito 01...».
- **Esfuerzo/riesgo:** bajo.

### renta_ecv_ccaa
- **Modelo:** transform/models/marts/renta_ecv_ccaa.sql · **Páginas:** sociedad/desigualdad, sociedad/index, territorios/[ccaa]/index (12 traducciones) · **Prioridad:** 2 (mejora clara)
- **Problemas:** `cod` sin `nombre`; `nivel` `pais`/`ccaa` bien; `anio` (año de encuesta) y `anio_renta` (anio - 1): dos años en la fila; ya trae reales (`renta_persona_real`, `renta_uc_real`, `renta_hogar_real`) y `anio_base`; la muestra pequeña en comunidades chicas hace saltar las cifras.
- **Cambio propuesto:** añadir `nombre` (de `ine_ccaa_nombres`, que el modelo ya une: `n.nombre` según `nivel`; para `00` poner `España`) y `slug`/`ruta` no hace falta. No tocar `anio`/`anio_renta`.
  ```sql
  case when n.cod_ccaa = '00' then 'España' else n.nombre end as nombre
  ```
- **Páginas:** conservar todas las columnas; las páginas que hacen `JOIN mother.territorios` por `cod` siguen valiendo. `desigualdad.md` puede quitar el join solo cuando necesite nombre y ruta a la vez (la `ruta` sigue en `territorios`).
- **Ficha:** desaparece «sin columna de nombre».
- **Esfuerzo/riesgo:** bajo; confirmar que la tabla `ine_ccaa_nombres` trae el nombre normalizado igual que `territorios`.

### renta_ecv_edad
- **Modelo:** transform/models/marts/renta_ecv_edad.sql · **Páginas:** sociedad/desigualdad (4 traducciones) · **Prioridad:** 3 (cosmético)
- **Problemas:** solo España; los grupos de edad se solapan (`Menores de 16 años` está dentro de `Menos de 18 años` según la ficha; `De 18 a 64 años` agrupa otros); hay un `orden` en lugar de un campo que distinga totales; ya está en euros reales.
- **Cambio propuesto:** añadir `es_agrupacion` BOOLEAN para los grupos que contienen a otros, y `nivel` = `pais`, `cod` = `00`, `nombre` = `España` si se quiere homogeneidad con `renta_ecv_ccaa` (opcional). Hay que confirmar que `Menos de 18` y `18 a 64` realmente salen en la serie (los `CASE` de `orden` solo cubren Total, Menores de 16, 16-29, 30-44, 45-64 y 65 y más: la ficha menciona otros grupos que quizá no estén en la tabla).
  ```sql
  edad in ('Total') as es_total
  ```
- **Páginas:** conservar `anio, edad, orden, arope, tasa_pobreza, carencia_severa, renta_uc_real` (la página filtra `orden BETWEEN 1 AND 5`).
- **Ficha:** desaparece o se corrige el aviso de solapamiento según lo que se compruebe en los datos.
- **Esfuerzo/riesgo:** bajo.

### renta_ue
- **Modelo:** transform/models/marts/renta_ue.sql · **Páginas:** sociedad/desigualdad (4 traducciones) · **Prioridad:** 2 (mejora clara)
- **Problemas:** `valor` mezcla tres unidades (`arope` en %, `gini` 0-100, `s80_s20` en veces) y la tabla no lo dice por fila (la ficha sí); `geo` en código Eurostat (`EL`, `EU27_2020`) sin `cod_pais` ISO; `es_ue` es `false` para el agregado `UE-27` y `true` para los 27 países (la ficha dice lo contrario: error de la ficha); hay que filtrar siempre por `indicador`.
- **Cambio propuesto:** añadir `unidad` por fila (`%`, `índice 0-100`, `veces`), `cod_pais` (GR para EL; `EU27_2020` se queda para la UE) y `es_agregado` BOOLEAN (`geo = 'EU27_2020'`). No separar en tres tablas: las páginas hacen `FILTER (indicador = ...)` y se romperían.
  ```sql
  case r.indicador when 'arope' then '%' when 'gini' then 'índice 0-100' else 'veces' end as unidad,
  r.geo = 'EU27_2020' as es_agregado
  ```
- **Páginas:** conservar `indicador, geo, pais, anio, valor, es_ue`. Ninguna cambia.
- **Ficha:** desaparece la nota de unidades por indicador (queda `unidad` por fila) y se corrige el error de `es_ue` (es true solo para los 27 países); el defecto de filtrar por `indicador` se mantiene.
- **Esfuerzo/riesgo:** bajo.

### salud_causas_muerte
- **Modelo:** transform/models/marts/salud_causas_muerte.sql (el publicado filtra causas y provincias en `sources/mother/salud_causas_muerte.sql`) · **Páginas:** sociedad/salud (4 traducciones) · **Prioridad:** 2 (mejora clara)
- **Problemas:** sin `nombre` de territorio (el `cod` por nivel); capítulos de la CIE-10 (`es_capitulo = true`, p. ej. «Tumores») mezclados con causas concretas (`false`, p. ej. «Suicidio...») y el total `Todas las causas` (`codigo_causa = '001-102'`) como un capítulo más; la tasa es bruta (sin ajustar por edad: una provincia envejecida tiene más muertes por habitante sin que su salud sea peor). El `sources/mother` publica solo 15 causas concretas elegidas a mano y las provincias desde 2010.
- **Cambio propuesto:** añadir `nombre` y `tipo_causa` (`total` | `capitulo` | `causa`) que separa el total de los capítulos y de las causas. La tasa ya es por 100.000 hab. (`tasa_100k`). Ajustar por edad NO se puede con estos datos: haría falta la población por edad y las defunciones por edad (la tabla 9936 del INE no las desglosa), es decir, ingestar datos nuevos; mientras tanto la ficha avisa de que es bruta.
  ```sql
  case when t.codigo_causa = '001-102' then 'total' when t.es_capitulo then 'capitulo' else 'causa' end as tipo_causa
  ```
- **Páginas:** conservar `anio, nivel, cod, sexo, codigo_causa, causa, es_capitulo, defunciones, tasa_100k`. Las consultas con `es_capitulo AND codigo_causa <> '001-102'` pasan a `tipo_causa = 'capitulo'`.
- **Ficha:** desaparecen «sin nombre de territorio» y «no sumar capítulos y causas ni excluir Todas las causas a mano» (queda `tipo_causa`). Se mantiene «tasa bruta sin ajustar por edad» y el recorte de causas publicadas.
- **Esfuerzo/riesgo:** bajo (columnas) y medio si se quisiera la tasa ajustada (datos nuevos).

### salud_esperanza_vida
- **Modelo:** transform/models/marts/salud_esperanza_vida.sql · **Páginas:** index, sociedad/index, sociedad/salud (12 traducciones) · **Prioridad:** 2 (mejora clara)
- **Problemas:** sin `nombre` (el `cod '13'` es Madrid como comunidad y Ciudad Real como provincia: el error ya está en la ficha como trampa); la fuente de España (Eurostat, redondeada a un decimal) difiere de la de comunidades y provincias (INE); `sexo` usa `Ambos sexos` mientras `poblacion_territorios` y `salud_causas_muerte` usan `Total`.
- **Cambio propuesto:** añadir `nombre` y `fuente` (`Eurostat`/`INE`). No cambiar `sexo` (renombrar rompe 12 páginas): la convención admite `Ambos sexos`. Opcional: `sexo_total` BOOLEAN no hace falta.
  ```sql
  left join {{ ref('territorios') }} t on t.nivel = x.nivel and t.cod = x.cod   -- y 'Eurostat' / 'INE' as fuente
  ```
- **Páginas:** conservar `anio, nivel, cod, sexo, anios`; ninguna cambia.
- **Ficha:** desaparece «sin nombre de territorio»; se mantiene el aviso de `nivel` y la diferencia de fuente (ahora con columna `fuente`).
- **Esfuerzo/riesgo:** bajo.

### salud_mortalidad_semanal
- **Modelo:** transform/models/marts/salud_mortalidad_semanal.sql · **Páginas:** sociedad/salud (4 traducciones) · **Prioridad:** 1 (afecta al principio por habitante: las muertes crudas crecen con la población y el envejecimiento)
- **Problemas:** `exceso` es una proporción 0-1 (1,57 = 157 %) y la convención pide `_pct` en 0-100; defunciones semanales brutas sin tasa por habitante (comparar 2015-2019 con hoy sin corregir por población, que ha crecido; el propio SQL lo reconoce); `semana` es el último día de la semana (la convención pide `fecha` con el primer día); sin `nombre`; el `cod` por nivel (`13` es Madrid).
- **Cambio propuesto:** añadir `fecha` (`semana - 6 días`, DATE), `nombre`, `poblacion` (padrón del año, acotado al rango como en `pensiones_territorio`), `defunciones_por_100k_hab`, `media_2015_2019_por_100k_hab` (referencia también por habitante: media de la tasa en 2015-2019) y `exceso_pct` (0-100) y `exceso_hab_pct` (el exceso respecto a la tasa de referencia por habitante). Dejar `exceso` y `media_2015_2019` para no romper `exceso_anual` y `semanal`.
  ```sql
  100000.0 * c.defunciones / p.poblacion as defunciones_por_100k_hab,
  100 * (c.defunciones / nullif(r.media_2015_2019, 0) - 1) as exceso_pct,
  100 * ((c.defunciones / p.poblacion) / nullif(r.media_tasa_2015_2019, 0) - 1) as exceso_hab_pct
  ```
  Aviso: el exceso por habitante sigue sin ajustar por edad (no hay defunciones semanales por edad en este corte: la fuente 35177 las trae por grupos de edad, pero el modelo solo toma «Todas las edades»); eso sería una segunda fase con datos ya ingestados.
- **Páginas:** conservar `semana, anio, semana_anio, nivel, cod, defunciones, media_2015_2019, exceso`. `exceso_anual` y `semanal` de `salud.md` pasarían a `exceso_hab_pct` y a una serie por 100.000 hab. para el gráfico principal («Muertes de cada año frente a la media de 2015-2019»).
- **Ficha:** desaparece «`exceso` es una proporción, no un porcentaje» (queda `exceso_pct`); la limitación de no ajustar por edad se mantiene.
- **Esfuerzo/riesgo:** medio; hay que fijar bien el rango de población para 2026 (acotar al último padrón) y decidir qué cifra enseña la página (la del exceso con o sin corrección de población).

### sanidad_gasto
- **Modelo:** transform/models/marts/sanidad_gasto.sql · **Páginas:** sociedad/salud (4 traducciones) · **Prioridad:** 2 (mejora clara)
- **Problemas:** `eur_hab_real` solo para España (22 filas de 2.047): el deflactor es el IPC de España y no hay HICP por país en las fuentes; para comparar países hay que usar `pct_pib` o `pps_hab`; `geo` es `UE` para el agregado mientras `renta_ue` y `primario_*` usan `EU27_2020` y `EL` en lugar de `GR`; `financiacion` mezcla total y partes; `millones_eur` en corrientes sin real.
- **Cambio propuesto:** añadir `cod_pais` (ISO, `EU27_2020` para la UE, `GR` para EL) y `es_agregado`; añadir `millones_eur_real` solo para España (`millones_eur * d.factor`) para completar la regla. NO deflactar a otros países con el IPC español (falsearía la comparación); dejar documentado que para comparar países se usa `pps_hab` (ya está por habitante y en paridad de poder de compra) y `pct_pib`. Un real para cada país exigiría ingestar el HICP de Eurostat (`prc_hicp_aind`).
  ```sql
  case b.geo when 'EL' then 'GR' else b.geo end as cod_pais, b.geo = 'EU27_2020' as es_agregado
  ```
- **Páginas:** conservar `anio, geo, pais, financiacion, pct_pib, eur_hab, pps_hab, millones_eur, eur_hab_real, anio_base`. Ninguna cambia.
- **Ficha:** desaparece «`UE-27` aparece con geo `UE`» (queda `cod_pais`/`es_agregado`). Se mantienen el defecto `financiacion = 'Total'` y «`eur_hab_real` solo España».
- **Esfuerzo/riesgo:** bajo; solo columnas nuevas; el real de otros países queda pendiente de datos nuevos.

### sanidad_gasto_ccaa
- **Modelo:** transform/models/marts/sanidad_gasto_ccaa.sql · **Páginas:** sociedad/salud, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 2 (mejora clara)
- **Problemas:** `cod` sin nombre; `nivel = 'total_ccaa'` con `cod = '00'` es el conjunto de las comunidades (no España) y rompe la convención de `nivel` (choca con el `00` de `pais` en otras tablas); Ceuta y Melilla no aparecen (las gestiona el INGESA); 2023 y 2024 son provisionales (columna `provisional`, vale); `pct_pib` 0-100 y la página lo divide entre 100 por el formato.
- **Cambio propuesto:** añadir `nombre` (`Total comunidades autónomas` para el `00`) y `pct_pib_ratio` no hace falta. Dejar `nivel = 'total_ccaa'` (las páginas dependen de él); documentarlo en la ficha como no equivalente a `pais`. Ya trae `eur_hab_real`, `anio_base`; añadir también `gasto_meur_real` (no existe el gasto total en la fuente: sería `eur_hab × población`; no se propone).
  ```sql
  case when b.cod = '00' then 'Total comunidades autónomas' else t.nombre end as nombre
  ```
- **Páginas:** conservar `anio, nivel, cod, provisional, eur_hab, eur_hab_real, pct_pib, anio_base`.
- **Ficha:** desaparece «sin nombre de territorio»; se mantiene la advertencia de que `00` (`total_ccaa`) no es España.
- **Esfuerzo/riesgo:** bajo.
