# Plan de limpieza del modelo de datos (mother.*)

Plan por tabla de las 180 tablas publicadas que tienen algún problema o ninguna página usa (de 268). Lo escribieron seis agentes leyendo cada modelo dbt, el SQL de las páginas que la usan y los datos; nada se ha cambiado todavía. Cómo deben quedar las tablas: [CONVENCIONES.md](CONVENCIONES.md). Inventario de partida: `node tools/chat/semantica/inventario.mjs`.

**Decidido por el dueño (2026-10-03):** se hacen las fases 0 a 4. Las columnas mal formadas **se sustituyen** (no se añaden al lado) y se cambian a la vez las páginas que las usan y sus traducciones: la web está en desarrollo y se prefiere un modelo limpio. Decisiones 1, 2, 3, 5, 6 y 7: como se proponen (6 hecho: seed paises_iso, deflactor_paises, poblacion_paises y deflactor desde 1996). Decisión 4: potencia de centrales por comunidad en totales; emisiones, exportaciones y deuda local con las dos cifras (por habitante y total).

## Fases

| Fase | Qué | Tablas | Toca páginas | Necesita |
|---|---|---|---|---|
| 0 | Errores que ya se ven en la web (abajo) | 4 | no (salvo 1 línea) | — |
| 1 | Columnas por habitante, euros reales y nombres de territorio en las de prioridad 1 | 35 | no | extracción completa `[datos]` |
| 2 | Lo mismo en las de prioridad 2 (proporciones a `_pct`, unidades, totales, España) | 62 | no | `[datos]` |
| 3 | Pasar páginas a las columnas nuevas (gráficas absolutas a por habitante, nominal a real) | por grupos | sí, con traducciones | tu visto bueno por grupo |
| 4 | Borrar tablas y partir las que mezclan fuentes o periodos | 8 + ~4 | sí en las partidas | tu visto bueno |
| 5 | Cosmético (prioridad 3) | 53 | no | — |

Cada fase acaba con: `dbt build` de los modelos tocados, extracción, fichas semánticas actualizadas (`validar.mjs` a 0 errores), build y pruebas (i18n, estática, humo), y la batería del chat.

## Fase 0: errores que ya se ven en la web

- **`mercado_paro_territorios` no tiene fila de España**: las páginas de comunidad y provincia la piden (`e.nivel = 'pais'`) y la tasa de paro de España sale siempre vacía. Se arregla añadiendo la fila en el modelo, sin tocar páginas.
- **`[ccaa]` deflacta con `coalesce(f.factor, 1)`**: un año sin deflactor cuenta como si no hubiera inflación. Mejor vacío.
- **`pages/territorios/municipios.md` (línea ~455, y sus 4 traducciones)** antepone «Distrito » a un valor que ya lo lleva: sale «Distrito Distrito 01».
- **`gobierno_indultos_mensual` tiene una fila del año 1200** que se cuela en rankings y evoluciones: se filtra en el modelo.
- Ya corregido en las fichas del chat (sin tocar datos): tasas de criminalidad y recuentos que el chat multiplicaba por 100, ceros de turismo, `defecto: PRACT` de sanidad, `es_ue` de renta_ue.

## Decisiones que necesitan tu visto bueno

1. **Euros reales y por habitante dentro de cada tabla** (fase 1, 35 tablas): columnas `*_real`, `*_hab`, `*_hab_real` y `anio_base`, con `mother.deflactor` y `poblacion_territorios`. Hoy muchas páginas lo calculan a mano, cada una a su manera (empleo público reconstruye el IPC por su cuenta). Propuesta: un año sin deflactor da vacío (no «sin inflación»), y el nombre estándar es `anio_base` (hoy conviven `anio_base` y `anio_euros`).
2. **Alargar `mother.deflactor` hasta 1996** con el IPCA de Eurostat (hoy empieza en 2002; `construccion_deflactor` ya lo hace solo para construcción). Sin esto, la deuda autonómica (desde 1994) y otras series largas no tienen euros reales antes de 2002.
3. **Borrar 8 tablas que nadie usa**: `alcaldes_resumen_familias` (es `alcaldes_familias_territorio` con nivel país), `ipc` (la cubren `mercado_ipc_*`), `observatorios` (la sustituye `observatorios_detalle`), `totalAno`, `totalAnoProvincia`, `totalAnoSexo`, `totalAnoSexoEdad` (la primera versión; las sustituye `poblacion_territorios`) y `unemployment`. Con `unemployment` se pierde el cruce sexo × edad del paro; la alternativa es rehacerla limpia como `mercado_paro_sexo_edad`.
4. **Gráficas que hoy enseñan totales** y deberían enseñar por habitante (fase 3): potencia eléctrica por comunidad (GW a W por habitante), emisiones por sector, mix eléctrico, exportaciones, deuda local, matriculaciones; y tarjetas que comparan euros nominales entre décadas (esfuerzo de vivienda, PIE). Cada una toca la página y sus 4 traducciones.
5. **Partir tablas que mezclan fuentes o periodos** (fase 4, rompe consultas de páginas): `construccion_permisos` (UE / comunidades / serie larga de España, con España tres veces), `industria_ipi` (Eurostat / INE / INE por división), `empresas_autonomos` (trimestre 0 = media anual). La fase 2 solo les añade columnas para distinguirlas; partirlas es opcional.
6. **Países**: un seed común `paises_iso` (ISO3 → ISO2, `EUU` → `EU27_2020`) para las tablas internacionales, que hoy usan tres codificaciones. Y, si quieres euros reales de otros países, ingerir el IPCA por país de Eurostat (`prc_hicp_aind`), que hoy no se descarga.
7. **Tablas auxiliares que usan las páginas** (`metricas`, `mapas_indicadores`): quedarse en mother.* marcadas como auxiliares (el chat ya las ignora) en vez de moverlas a otro esquema, que obligaría a tocar todas las páginas que las leen.

## Recetas comunes (ya usadas en el repo)

- **Euros reales:** `left join {{ ref('deflactor') }} d on d.anio = x.anio` → `importe * d.factor as importe_real`, `d.anio_base` (ejemplos: `sanidad_gasto_ccaa`, `renta_distritos`, `construccion_ccaa`).
- **Por habitante:** `{{ ref('poblacion_territorios') }}` (`sexo = 'Total'`, año acotado al rango disponible) o `poblacion_municipios`; países UE en `raw_industria.eurostat_industria_poblacion`, extranjeros en `internacional_comparativa` (indicador `poblacion`).
- **Nombre de territorio:** `left join {{ ref('territorios') }} t on t.nivel = x.nivel and t.cod = x.cod` (ejemplo: `pensiones_territorio`). `poblacion_territorios` no puede usar `territorios` (ciclo): sale de `territorios_ccaa`/`territorios_provincias`.
- Si `sources/mother/<tabla>.sql` enumera columnas en vez de `SELECT *`, hay que añadir ahí las nuevas.
- En el parquet publicado los números salen como DOUBLE (también `anio`); las páginas ya hacen `CAST(anio AS INTEGER)`.

## Índice (180 tablas: 35 de prioridad 1, 62 de 2, 53 de 3, 30 sin cambios)

| Tabla | Prioridad | Esfuerzo | Problema |
|---|---|---|---|
| [ccaa_cuentas_capitulos](#ccaa_cuentas_capitulos) | 1 | bajo | euros corrientes sin versión por habitante ni real (la página repite el join con población y `deflactor`); solo `cod_ccaa`, sin nombre; sin  |
| [ccaa_cuentas_resumen](#ccaa_cuentas_resumen) | 1 | bajo | euros corrientes sin habitante ni real; sin nombre; `deficit_no_financiero` es solo `saldo_no_financiero` con el signo cambiado (fuente de c |
| [ccaa_deuda](#ccaa_deuda) | 1 | bajo | `deuda_eur` corriente sin habitante ni real (stock trimestral: la página lo calcula con población del año); `ccaa` viene como la publica el  |
| [ccaa_gasto_politicas](#ccaa_gasto_politicas) | 1 | bajo | `obligaciones` en euros corrientes sin habitante ni real (la página lo hace con `deflactor` + población y lo promedia ponderado); solo `cod_ |
| [ccaa_saldo](#ccaa_saldo) | 1 | bajo | `saldo_eur` y `pib_implicito_eur` corrientes sin habitante ni real; el PIB es implícito (deducido de la deuda del 4.º trimestre, no el ofici |
| [centrales_ccaa](#centrales_ccaa) | 1 | medio | potencia por comunidad solo en MW absolutos (comparar Castilla y León con La Rioja sin ajustar por población engaña, principio rector); `est |
| [crimen_balance](#crimen_balance) | 1 | bajo | la ficha está mal: marca `tasa_1000` e `infracciones` con `unidad: %` y `escala: 100` (nada es una proporción 0-1: `tasa_1000` es por 1.000  |
| [crimen_condenas_delito](#crimen_condenas_delito) | 1 | medio | la columna `delito` mezcla el total (`Delitos`), grupos (`Contra la libertad`) y delitos concretos que están dentro de ellos, así que sumar  |
| [crimen_serie_larga](#crimen_serie_larga) | 1 | bajo | misma ficha errónea que `crimen_balance` (`tasa_1000` e `infracciones` con unidad `%` y `escala: 100`); sin nombre de territorio (solo `cod` |
| [crimen_ultimo_periodo](#crimen_ultimo_periodo) | 1 | bajo | ficha errónea (`infracciones` e `infracciones_anio_anterior` con `%` y `escala: 100`); no tiene tasa por habitante ni población, así que el  |
| [cuentas_balance_anual](#cuentas_balance_anual) | 1 | bajo | importes en `_mrd` corrientes (miles de millones) sin euros reales ni por habitante; columna de tiempo `"año"` con eñe (todas las páginas ha |
| [cuentas_gastos](#cuentas_gastos) | 1 | bajo | `gasto_por_habitante_eur` es corriente (el real lo calculan las páginas con el deflactor); `"año"` con eñe; sin `anio_base`; nombres no está |
| [cuentas_ingresos](#cuentas_ingresos) | 1 | bajo | solo `millones_euros` corrientes; ni por habitante ni reales (incumple el principio rector); `"año"` con eñe. |
| [cuentas_subsectores](#cuentas_subsectores) | 1 | bajo | `gasto_mrd`/`ingreso_mrd`/`saldo_deficit_mrd` corrientes sin por habitante ni reales; `"año"`; `peso_gasto_pct` suma más de 100 % (cuentas n |
| [empleo_coste](#empleo_coste) | 1 | bajo | `eur_por_habitante` corriente (la página calcula `eur_hab_real` con el deflactor en dos consultas, una de ellas reconstruyendo el IPC a mano |
| [empleo_epa_ccaa](#empleo_epa_ccaa) | 1 | medio | `cuota_publico` en 0-1; solo `cod_ccaa` (con `00` España mezclado con las comunidades, sin `nivel`); `publicos`, `privados` y `total` son pe |
| [empleo_gasto_personal_territorio](#empleo_gasto_personal_territorio) | 1 | bajo | euros corrientes: `_hab` sin deflactar (las páginas multiplican por `d.factor` en varios sitios); `gasto_personal_*` en euros crudos; `cod`  |
| [empleo_salarios_deciles](#empleo_salarios_deciles) | 1 | bajo | `salario_mensual` en euros corrientes (el chat compara 2006 con 2024 sin deflactar; las páginas lo deflactan a mano con `mother.deflactor` e |
| [energia_emisiones_gei](#energia_emisiones_gei) | 1 | medio | solo cifras absolutas (Mt) sin por habitante, contra el principio rector; el año se llama `año` (con eñe, obliga a entrecomillar en SQL); si |
| [inmigracion_poblacion](#inmigracion_poblacion) | 1 | bajo | `pct_extranjeros` es una fracción 0-1 (la página la multiplica por 100 en `pob_espana`; en el mapa de comunidades se formatea como pct), con |
| [local_deuda_municipio](#local_deuda_municipio) | 1 | bajo | solo `deuda_eur` nominal; ambas páginas calculan a mano `deuda_eur / poblacion * factor` (pegando la población con el límite del padrón y el |
| [local_deuda_provincia](#local_deuda_provincia) | 1 | bajo | solo `cod_prov` sin nombre; importes nominales (4 columnas); la página calcula a mano los 4 por habitante reales. |
| [movilidad_matriculaciones_municipio](#movilidad_matriculaciones_municipio) | 1 | bajo | sin nombre de municipio (solo `cod_mun`), sin provincia ni comunidad, sin población: no se puede ordenar «por habitante» ni preguntar por un |
| [movilidad_matriculaciones_provincia](#movilidad_matriculaciones_provincia) | 1 | medio | sin población ni versión por habitante (la ficha manda dividir); sin nombre de comunidad (solo `cod_ccaa`); filtros `nuevo_usado='N'` y de ` |
| [movilidad_parque_municipio](#movilidad_parque_municipio) | 1 | bajo | solo `cod_mun` (sin nombre); no hay `turismos` por habitante (la página lo calcula uniendo con `poblacion_municipios`); cuotas como proporci |
| [movilidad_parque_provincia](#movilidad_parque_provincia) | 1 | bajo | sin población ni tasa por habitante (cada página trae `poblacion` de `poblacion_territorios` y divide); `cod_ccaa` sin nombre de comunidad;  |
| [movilidad_transporte_modos](#movilidad_transporte_modos) | 1 | medio | hay 25 `modo` y 11 sin `clave` (Transporte especial, escolar, laboral, discrecional, aéreo peninsular/interinsular, autobús interurbano medi |
| [municipios_cuentas](#municipios_cuentas) | 1 | medio | importes y `gasto_hab`/`ingreso_hab` en euros corrientes (la página multiplica por `mother.deflactor.factor` en cada consulta); sin `municip |
| [municipios_cuentas_serie](#municipios_cuentas_serie) | 1 | medio | euros corrientes; sin nombre; 130.000 filas con `tiene_datos = false` en torno al 13 % de los años definitivos y al 27 % de 2025; la página  |
| [municipios_politicas](#municipios_politicas) | 1 | bajo | `importe` e `importe_hab` corrientes; sin `municipio` ni `poblacion` (la página une con `municipios_cuentas_serie` para el tramo y la poblac |
| [salud_mortalidad_semanal](#salud_mortalidad_semanal) | 1 | medio | `exceso` es una proporción 0-1 (1,57 = 157 %) y la convención pide `_pct` en 0-100; defunciones semanales brutas sin tasa por habitante (com |
| [transparencia_internacional](#transparencia_internacional) | 1 | medio | `valor` mezcla escalas y sentidos en una columna (CPI 0-100 más es mejor, WGI 0-100, WJP 0-1 más es mejor, V-Dem 0-1 **más es peor**); sin u |
| [transparencia_pie](#transparencia_pie) | 1 | medio | `importe_retenido_eur` es nominal (sin real) y sin por habitante; `anio` es el ejercicio de referencia (no el año de pago), y el ejercicio e |
| [transparencia_pie_mensual](#transparencia_pie_mensual) | 1 | medio | `importe_eur` nominal, sin por habitante; el publicado no lleva nombre de municipio ni población (la ficha avisa "hay que cruzar con otra ta |
| [vivienda_esfuerzo](#vivienda_esfuerzo) | 1 | bajo | `euros_m2`, `precio_90m2`, `salario_anual` y `alquiler_mes_mediana` son **nominales** y la página los compara entre décadas (`var_precio` y  |
| [alcaldes_familias_territorio](#alcaldes_familias_territorio) | 2 | bajo | `cod` sin nombre de territorio (convención: nunca un código sin su nombre); la ficha tiene `territorio.nombre = null`. |
| [alcaldes_resumen_familias](#alcaldes_resumen_familias) | 2 (borrar) | bajo | duplicada: es `alcaldes_familias_territorio` filtrada a `nivel = 'pais'` con otros nombres de columna (`n_ayuntamientos`, `poblacion_goberna |
| [almacenamiento_acceso](#almacenamiento_acceso) | 2 | bajo | foto mensual completa (2 ficheros: sumarlos duplica); la página y el chat deben filtrar `fecha_fichero = max(...)`; tiempo en `fecha_fichero |
| [almacenamiento_mensual](#almacenamiento_mensual) | 2 | bajo | `rendimiento_bombeo` es proporción 0-1 (convención: `_pct` en 0-100; la ficha lo salva con `escala: 100`); último mes incompleto sin marcar; |
| [almacenamiento_potencia](#almacenamiento_potencia) | 2 | bajo | dos tipos (`bombeo_puro`, `baterias_hibridadas`) en formato largo con una sola unidad (MW), correcto pero cuesta sumarlo bien: es una foto m |
| [centrales](#centrales) | 2 | bajo | una fila por central y estado; hay que filtrar `estado_grupo = 'En operación'` o se mezclan canceladas y en tramitación (excepción `defecto` |
| [construccion_permisos](#construccion_permisos) | 2 | ? | tres fuentes en una tabla (`ambito` = `UE`, `CCAA`, `ES_LARGA`); `cod` mezcla códigos INE y ISO; España aparece dos veces con la misma serie |
| [crimen_condenados](#crimen_condenados) | 2 | bajo | `cod_ccaa` con `'00'` = España, mezclado con comunidades sin `nivel` ni nombre (la ficha no puede dar el nombre; hay que traducir el código) |
| [demografia_anual](#demografia_anual) | 2 | bajo | territorio solo con `cod` (los de comunidad y provincia se solapan y el chat tiene que unir con `territorios`); ficha con "nombre: null". `c |
| [demografia_envejecimiento](#demografia_envejecimiento) | 2 | bajo | igual que la anterior: sin nombre de territorio; códigos solapados entre ccaa y provincia. |
| [demografia_hogares](#demografia_hogares) | 2 | bajo | sin nombre de territorio; `hogares` es un recuento sin versión por habitante (solo `tamano_medio`, que ya normaliza). |
| [demografia_piramide](#demografia_piramide) | 2 | bajo | sin nombre de territorio; no hay fila de total (hay que sumar grupos y sexos o usar `demografia_envejecimiento`); `grupo` no ordena (se usa  |
| [educacion_gasto_alumno](#educacion_gasto_alumno) | 2 | bajo | `nivel` significa nivel educativo (choca con la convención, donde `nivel` es el territorial) y el territorio está en `nivel_geo`; `eur_real` |
| [educacion_indicadores](#educacion_indicadores) | 2 | bajo | solo código en `cod` (00, 01-19 y `UE`) sin nombre; `nivel = 'ue'` rompe el catálogo de niveles; formato largo con seis indicadores sin `uni |
| [elecciones_familias](#elecciones_familias) | 2 | bajo | sin nombre de territorio; `tipo` solo como código ('02', '04', '07') y `defecto: 02`; 2019 aparece dos veces (abril y noviembre) distinguido |
| [elecciones_municipios](#elecciones_municipios) | 2 | medio | solo `cod_mun`, sin `municipio`, `cod_prov` ni `provincia` (hoy hay que ir a `elecciones_municipios_congreso`, que solo trae Congreso); `tip |
| [elecciones_participacion](#elecciones_participacion) | 2 | bajo | sin nombre de territorio; 2019 con dos generales sin etiqueta legible; la ficha pone `tiempo.columna = fecha` pero la tabla también tiene `a |
| [electrificacion_calefaccion_provincia](#electrificacion_calefaccion_provincia) | 2 | bajo | `cuota_*` en proporción 0-1 (la ficha tiene que declarar `escala: 100`); España como fila con `cod_prov = '00'` sin `nivel`; `cod_ccaa` sin  |
| [electrificacion_hogares](#electrificacion_hogares) | 2 | bajo | `cuota` en 0-1 (escala 100 en la ficha); el total exige fijar `uso = 'Todos los usos'`, si no se duplica; `cod_uso` y `uso` redundantes; es  |
| [electrificacion_sectores](#electrificacion_sectores) | 2 | bajo | `cuota_electricidad` en 0-1; sectores que se solapan (industria y sus ramas, transporte y carretera, y "Toda la economía"), con `es_rama_ind |
| [empleo_efectivos](#empleo_efectivos) | 2 | bajo | `cod_prov` y `cod_ccaa` sin nombre; los efectivos del extranjero quedan con NULL; no hay filas de total (hay que fijar una `fecha` o se dupl |
| [empleo_salarios_ccaa](#empleo_salarios_ccaa) | 2 | bajo | solo `cod_ccaa` (con `00` = España mezclado con comunidades); salarios en euros corrientes de 2022 sin `anio_euros` ni versión real; la brec |
| [empresas_autonomos](#empresas_autonomos) | 2 | bajo | `trimestre = 0` (media anual) mezclado con los trimestres 1-4, y todas las páginas filtran `trimestre = 0`; solo `cod`; `anio`/`trimestre` D |
| [energia_mix_electrico](#energia_mix_electrico) | 2 | bajo | `año` con eñe; solo TWh absolutos, sin kWh por habitante; `porcentaje_total` en 0-100 pero la página mix-electrico lo divide por 100 para fo |
| [energia_potencia_instalada](#energia_potencia_instalada) | 2 | bajo | `año` con eñe; MW absolutos sin W por habitante; es un stock (no se suma entre años) y solo por nombre en notas; la dbt `metricas_energia` d |
| [energia_resumen_anual_mix](#energia_resumen_anual_mix) | 2 | bajo | `año` con eñe; TWh sin por habitante; solapa en fuente y años con `energia_mix_electrico` (el total y la cuota renovable salen de las mismas |
| [gobierno_indultos_mensual](#gobierno_indultos_mensual) | 2 | bajo | fila anómala del año 1200 (`mes = 1200-11-01`, 2 indultos, sin presidente) que contamina mínimos y rankings; sin filas de ceros en meses sin |
| [industria_exportaciones_ue](#industria_exportaciones_ue) | 2 | bajo | `exportacion_es_real_meur` es la medida principal pero absoluta (sin euros reales por habitante, contra el principio); `destino` con códigos |
| [industria_ipi](#industria_ipi) | 2 | bajo | tres series mezcladas por `fuente` (eurostat por país, ine por comunidad, ine_divisiones por división); España duplicada (`cod` `00` INE y ` |
| [inmigracion_nacionalizaciones](#inmigracion_nacionalizaciones) | 2 | bajo | solo `cod` (`00` = España junto a comunidades); `nacionalidad_previa` mezcla países, continentes («De Africa», «De América del Norte») y agr |
| [ipc](#ipc) | 2 (borrar) | bajo | 56 series del INE (índices y tasas anual/mensual/acumulada) en una columna `value` con la unidad dentro del texto de `serie`; duplicada por  |
| [medios_receptores](#medios_receptores) | 2 | bajo | 154.000 filas con `duplicado_probable`: cualquier `sum(importe_eur_real)` sin filtrarlo cuenta dos veces los contratos de publicidad ya pres |
| [medios_receptores_resumen](#medios_receptores_resumen) | 2 | medio | 13 columnas de total del medio (`total_*`, `estado_*`, `territorial_*`, `contratos_*`, `subvenciones_*`, `n_*_total`, `rango_*`) repetidas e |
| [medios_subvenciones_beneficiarios](#medios_subvenciones_beneficiarios) | 2 | medio | una fila por NIF y año con `total_*`, `n_convocatorias`, `administraciones`, `rango`... repetidos en cada año (doble suma si se agrega); adm |
| [mercado_ipc_ccaa](#mercado_ipc_ccaa) | 2 | bajo | solo `cod_ccaa` sin nombre (la página lo cruza con `territorios`); `cod_ccaa='00'` es el total nacional pero no se llama «España»; `anio` ya |
| [mercado_paro_registrado](#mercado_paro_registrado) | 2 | bajo | `cod` sin nombre (hay que filtrar siempre `nivel`); `paro_registrado` en personas pero la comparación entre territorios debe hacerse con `po |
| [mercado_paro_territorios](#mercado_paro_territorios) | 2 | medio | `cod` sin nombre; no tiene fila de España aunque las dos páginas de territorio la piden (`e.nivel = 'pais'`): hoy `tasa_paro_espana` y `tasa |
| [movilidad_parque_evolucion](#movilidad_parque_evolucion) | 2 | bajo | parque (stock) de España sin versión por habitante (`vehiculos` totales, sin comparar con la población); `mes` sin `anio`; sin total (hay qu |
| [movilidad_recarga_sitios](#movilidad_recarga_sitios) | 2 | bajo | `cod_mun` y `cod_prov` sin nombre (4 sitios sin ninguno); operadores con razón social completa (156 valores: «IBERDROLA CLIENTES S.A.U», «EN |
| [poblacion_territorios](#poblacion_territorios) | 2 | medio | sin `nombre` (hay que unir con `territorios`); el mismo `cod` por nivel; `sexo` en 3 valores, de modo que olvidar `sexo = 'Total'` triplica  |
| [primario_paises_largo](#primario_paises_largo) | 2 | medio | tabla base en formato largo (producto × país × año) que mezcla unidades distintas en `valor` (cada fila lleva `unidad`, vale); `geo` con cód |
| [primario_pesca](#primario_pesca) | 2 | bajo | `medida` en formato largo con 5 unidades en `valor` (cada fila lleva `unidad`); `kg_hab` solo para capturas y acuicultura en volumen; `valor |
| [renta_ecv_ccaa](#renta_ecv_ccaa) | 2 | bajo | `cod` sin `nombre`; `nivel` `pais`/`ccaa` bien; `anio` (año de encuesta) y `anio_renta` (anio - 1): dos años en la fila; ya trae reales (`re |
| [renta_ue](#renta_ue) | 2 | bajo | `valor` mezcla tres unidades (`arope` en %, `gini` 0-100, `s80_s20` en veces) y la tabla no lo dice por fila (la ficha sí); `geo` en código  |
| [salud_causas_muerte](#salud_causas_muerte) | 2 | bajo | sin `nombre` de territorio (el `cod` por nivel); capítulos de la CIE-10 (`es_capitulo = true`, p. ej. «Tumores») mezclados con causas concre |
| [salud_esperanza_vida](#salud_esperanza_vida) | 2 | bajo | sin `nombre` (el `cod '13'` es Madrid como comunidad y Ciudad Real como provincia: el error ya está en la ficha como trampa); la fuente de E |
| [sanidad_gasto](#sanidad_gasto) | 2 | bajo | `eur_hab_real` solo para España (22 filas de 2.047): el deflactor es el IPC de España y no hay HICP por país en las fuentes; para comparar p |
| [sanidad_gasto_ccaa](#sanidad_gasto_ccaa) | 2 | bajo | `cod` sin nombre; `nivel = 'total_ccaa'` con `cod = '00'` es el conjunto de las comunidades (no España) y rompe la convención de `nivel` (ch |
| [sanidad_listas_espera](#sanidad_listas_espera) | 2 | bajo | `cod` sin nombre (la ficha obliga a unir con `territorios`; las dos páginas ya lo hacen con `JOIN territorios ON cod`); `tipo` y `corte` (ju |
| [sanidad_recursos](#sanidad_recursos) | 2 | bajo | `geo` es código Eurostat (`EL`=Grecia, `UE`), no ISO; `situacion` (PRACT/PACT/total/mixta) aparece en la ficha con `defecto: PRACT`, pero el |
| [sanidad_recursos_ccaa](#sanidad_recursos_ccaa) | 2 | bajo | `cod` sin nombre (la ficha manda unir con `territorios`); `nuts2` es un segundo código alternativo; `recurso` mezcla médicos y camas (magnit |
| [totalAno](#totalano) | 2 (borrar) | bajo | importación de la primera versión con columnas `Year`/`Total` en mayúscula y año como texto; duplica `mother.poblacion_territorios` (nivel ` |
| [totalAnoProvincia](#totalanoprovincia) | 2 (borrar) | bajo | columnas `statecode`, `Provincias`, `Población`, `Year` (nombres con tilde y mayúsculas, año texto); duplica `poblacion_territorios` nivel ` |
| [totalAnoSexo](#totalanosexo) | 2 (borrar) | bajo | `Year`, `Total`, `Sexo` en mayúscula, año texto; duplica `poblacion_territorios` (nivel `pais`, sexos Hombres/Mujeres). |
| [totalAnoSexoEdad](#totalanosexoedad) | 2 (borrar) | bajo | `Sexo, Anio, RangoEdad, Orden_Grupo, Total`; `RangoEdad` con valores `'0.0-4.0'` (decimales) en la tabla publicada; año texto; sin ficha. |
| [transparencia_liquidaciones](#transparencia_liquidaciones) | 2 | bajo | el porcentaje de incumplimiento exige contar `incumple = true` **solo con `aplica_indicador = true`** (hay 323 filas forales por año con `in |
| [transparencia_pmp](#transparencia_pmp) | 2 | bajo | `supera_30` booleano que solo vale entre `aplica_indicador=true` (7.858 de 8.130 filas por trimestre); `periodo` es texto `2026T2` y el tiem |
| [transparencia_publicidad_activa](#transparencia_publicidad_activa) | 2 | medio | mezcla tres evaluaciones distintas (ITCanarias, ICIO/MESTA y entidades del Consejo) en una sola columna `puntuacion` normalizada a 100 pero  |
| [transparencia_tcu](#transparencia_tcu) | 2 | bajo | el tiempo está en `ejercicio` y no en `anio`; `incumple` booleano solo válido con `aplica_indicador=true` (p. ej. `cuenta_general` 2025 `no_ |
| [unemployment](#unemployment) | 2 (borrar) | bajo | formato de la primera versión: `date, value, serie, cod_serie`, con el sexo y la edad dentro del texto de `serie` (39 series, nombres con do |
| [vivienda_mercado_anual](#vivienda_mercado_anual) | 2 | bajo | `importe_hipotecas` en euros nominales (se suma entre años) y **sin por habitante**; el CTE ya calcula `importe_hipotecas_real` pero no lo p |
| [vivienda_publica_internacional](#vivienda_publica_internacional) | 2 | bajo | la columna `valor` es siempre un % pero de **dos definiciones distintas** (OCDE: % del parque total, 58 filas; UE: % de viviendas principale |
| [almacenamiento_diario](#almacenamiento_diario) | 3 | bajo | mezcla energía (MWh, se suma) y picos (MW, no se suman) en una fila, y el último día puede estar incompleto. No son errores: están bien nomb |
| [calor_normal_diaria](#calor_normal_diaria) | 3 | bajo | auxiliar (ficha `usar: false`), el territorio solo tiene `cod_prov`; no es duplicada: la usa la gráfica y no se puede derivar de `calor_prov |
| [calor_records](#calor_records) | 3 | bajo | solo los 20 mejores días por provincia; hay que filtrar `posicion = 1` para el récord absoluto (trampa de la ficha). |
| [centrales_resumen](#centrales_resumen) | 3 | bajo | total nacional por tecnología y estado, sin nivel/cod/nombre de España ni suma segura (misma trampa del estado); es casi `centrales_ccaa` si |
| [construccion_ccaa](#construccion_ccaa) | 3 | bajo | mezcla España (`cod = '00'`) y comunidades sin columna `nivel` (convención para tablas multinivel); el VAB en total (`vab_constr_meur`) solo |
| [construccion_costes](#construccion_costes) | 3 | bajo | `pais` guarda el código ISO y `pais_nombre` el nombre (convención: `cod_pais` + `pais`); el coste real solo existe para España porque `inges |
| [construccion_empleo](#construccion_empleo) | 3 | bajo | mezcla España y comunidades sin `nivel`; cifras en miles (convención: una columna, una unidad; está en el nombre `_miles`, vale); `periodo`  |
| [construccion_grandes_constructoras](#construccion_grandes_constructoras) | 3 | bajo | el tiempo va en `edicion` (no `anio`); importes en millones de dólares (no hay deflactor ni cambio a euros: dato que no existe); solo ACS y  |
| [construccion_produccion](#construccion_produccion) | 3 | bajo | `pais` es el código ISO y `pais_nombre` el nombre (igual que `construccion_costes`); índices (no euros, no se suman); el salto de España en  |
| [economia_pib_trimestral](#economia_pib_trimestral) | 3 | bajo | ya trae `real_meur` y `por_habitante_real`. Cosmético: `anio_euros` en vez de `anio_base`; la fecha se llama `trimestre`; `por_habitante_rea |
| [elecciones_partidos](#elecciones_partidos) | 3 | bajo | solo la necesidad de fijar `tipo_nombre` y el proceso (2019 dos veces); ámbito solo nacional. |
| [electricidad_diaria](#electricidad_diaria) | 3 | bajo | el aviso "euros sin por habitante ni reales" es un falso positivo: el precio spot es €/MWh, no un gasto, no se divide. Reales: el último día |
| [embalses_estado_actual](#embalses_estado_actual) | 3 | bajo | el aviso "unidades mezcladas" es un falso positivo (hm³ y % están en columnas distintas, bien); niveles `cuenca`, `demarcacion` y `pais` que |
| [embalses_semanal](#embalses_semanal) | 3 | bajo | misma convención de territorio (`clave`/`nombre`, `ES`); niveles solapados; `pct_llenado` puede pasar de 100 (sobrellenado). |
| [empleo_territorio](#empleo_territorio) | 3 | bajo | solo `cod` (provincia y comunidad comparten dígitos, hay que fijar `nivel`); `administracion = 'Total'` convive con sus partes (aceptado por |
| [empresas_concursos](#empresas_concursos) | 3 | bajo | solo `cod` (`00` junto a comunidades); la serie termina en 2020 (el INE no publica más), no se dice en la tabla. |
| [empresas_dirce_sector](#empresas_dirce_sector) | 3 | bajo | solo `cod`; sin fila total (se suman los 11 sectores; la convención lo admite). Ya trae `por_1000hab` y `pct`. |
| [empresas_dirce_tamano](#empresas_dirce_tamano) | 3 | bajo | solo `cod`; no tiene tasa por habitante (el sector hermano sí); sin fila total (se suman cinco tramos). |
| [empresas_dirce_territorio](#empresas_dirce_territorio) | 3 | bajo | ya tiene `nivel`+`cod`+`empresas_1000hab`, pero sin `nombre`; `personas_fisicas + sociedades` no suman `empresas` (faltan otras formas juríd |
| [empresas_id_ccaa](#empresas_id_ccaa) | 3 | bajo | solo `cod` (`00` = España mezclado con comunidades); `sector = 'Total'` suma Empresas+AAPP+Universidades+IPSFL, hay que filtrar siempre. Eur |
| [empresas_sociedades_anual](#empresas_sociedades_anual) | 3 | bajo | solo falta nombre; ya trae por 100.000 hab y euros reales con `anio_euros` (es el modelo de referencia). `capital_real` y `capital_nominal`  |
| [empresas_sociedades_mensual](#empresas_sociedades_mensual) | 3 | bajo | solo `cod` sin nombre; las columnas `_12m` son sumas móviles (no sumar) y nada en el nombre lo avisa. Real y por habitante ya están (`capita |
| [empresas_tamano_ue](#empresas_tamano_ue) | 3 | bajo | el código de país va en `geo` (convención: `cod_pais`) y el nombre en `pais`; `vab_meur` en euros corrientes sin real ni por habitante. Los  |
| [gobierno_presupuestos](#gobierno_presupuestos) | 3 | bajo | el tiempo se llama `ejercicio` (convención `anio`); el ejercicio en curso está abierto (`Prorrogado (en curso)`) y `dias_prorroga` crece has |
| [industria_ccaa_ramas](#industria_ccaa_ramas) | 3 | bajo | `ccaa` con formato INE («Madrid, Comunidad de», «Rioja, La»); mezcla ramas agregadas y finas (ya trae `es_agregado`); sin fila de España (co |
| [industria_ipi_mensual](#industria_ipi_mensual) | 3 | bajo | `cod_ccaa` con `00` = España (mejor `nivel`/`cod`); `nombre` con formato INE («Madrid, Comunidad de»); `mes` en lugar de `fecha` y sin `anio |
| [industria_ramas_ue](#industria_ramas_ue) | 3 | bajo | ya trae euros reales (`cifra_negocios_es_real_meur`, `anio_base`) y cuotas sobre UE; falta el equivalente por habitante (principio rector) y |
| [inmigracion_flujos](#inmigracion_flujos) | 3 | bajo | ninguna página ni componente la usa y solo cubre 18 nacionalidades principales (no suman el total) y 3,5 años (175 filas); último trimestre  |
| [inmigracion_saldos](#inmigracion_saldos) | 3 | bajo | solo `cod`; `nacionalidad` mezcla países, grupos continentales y Española/Extranjera/Total (ya hay `es_grupo`); a nivel comunidad solo exist |
| [internacional_comparativa](#internacional_comparativa) | 3 | bajo | formato largo con unidad distinta por indicador (ya hay `unidad` en cada fila); `cod_pais` es ISO alfa-3 (`ESP`, `EUU`, `OED`) y la convenci |
| [internacional_ultimo](#internacional_ultimo) | 3 | bajo | el año se llama `anio_ultimo` en vez de `anio` (el componente ya lo traduce con `f.anio ?? f.anio_ultimo`); `cod_pais` alfa-3; falta `unidad |
| [medios_contratos_ejemplos](#medios_contratos_ejemplos) | 3 | bajo | territorio solo con código (`cod_ccaa`, `cod_municipio`); `importe_eur_real` ya existe; el top 50 por año es una muestra, no sirve para tota |
| [mercado_energia_carburantes](#mercado_energia_carburantes) | 3 | bajo | el tiempo se llama `semana` (convención: `fecha` + `anio`); `geo` + `territorio` ('ES'/'EU' frente a convención `cod_pais`/`pais`); ya trae  |
| [mercado_energia_hogares](#mercado_energia_hogares) | 3 | bajo | el tiempo es `semestre_inicio` + etiqueta `semestre` (convención: `fecha` + `anio`); precios ya reales (`eur_kwh_real`). `geo` ya es `EU27_2 |
| [movilidad_flotas_municipios](#movilidad_flotas_municipios) | 3 | bajo | `cuota_flota_espana` es proporción 0-1 (la página la multiplica por 100); `flota_por_habitante` es razón con valores hasta 99 (conviene `por |
| [movilidad_marcas_mensual](#movilidad_marcas_mensual) | 3 | bajo | códigos sin etiqueta (`grupo` = `turismo`/`camion`, `energia` = `bev`, `canal` = `renting`) frente a `movilidad_matriculaciones_mensual`, qu |
| [movilidad_modelos_mensual](#movilidad_modelos_mensual) | 3 | bajo | mismos códigos sin etiqueta que `movilidad_marcas_mensual`; el mismo coche con nombres distintos (`LEON` y `LEON SP`); solo 36 meses; sin `a |
| [movilidad_parque_modelos](#movilidad_parque_modelos) | 3 | bajo | filas `(modelo sin especificar)` que no son un modelo real y obligan a filtrar; códigos sin etiqueta; solo último mes y modelos con 100 o má |
| [movilidad_recarga_evolucion](#movilidad_recarga_evolucion) | 3 | bajo | `tramo_potencia` en minúsculas y distinto de `movilidad_recarga_sitios.tramo` (`lenta (<22 kW)` frente a `Lenta (<22 kW)`); sin orden de tra |
| [observatorios](#observatorios) | 3 (borrar) | bajo | duplicada por `observatorios_detalle` (mismo censo con nivel, ubicación, estado y partido); columnas en inglés (`name, creation_year, is_act |
| [observatorios_detalle](#observatorios_detalle) | 3 | bajo | `cod_prov` sin nombre de provincia; la comunidad se llama `comunidad` (la convención dice `ccaa`); `color_partido` es presentación dentro de |
| [primario_aceite](#primario_aceite) | 3 | bajo | `grupo` mezcla países y agregados («Resto de la UE», «Mundo (COI)»); `campania` texto `2024/25` y `anio` es el de inicio de campaña (no hay  |
| [primario_aceite_precios](#primario_aceite_precios) | 3 | bajo | `geo` en código Eurostat (`EL` para Grecia en lugar de `GR`); sin `anio`; las tres `categoria` no se mezclan (Virgen extra es el defecto de  |
| [primario_ccaa_cultivos](#primario_ccaa_cultivos) | 3 | bajo | el código de comunidad se llama `cod` + `ccaa` (la convención de un solo nivel pide `cod_ccaa` + `ccaa`); `Cereales` incluye `Cebada`, `Maíz |
| [primario_mundo](#primario_mundo) | 3 | bajo | 23 filas de valores fijos de COI y OIV con unidades distintas por indicador (cada fila lleva `unidad`, que cumple la convención de formato l |
| [primario_serie_espana](#primario_serie_espana) | 3 | bajo | ya cumple casi todo (`valor_hab`, `unidad_hab`, `valor_real`, `valor_hab_real`, `anio_base`); la página filtra `n_paises = 27` para evitar a |
| [renta_distritos](#renta_distritos) | 3 | bajo | solo `cod_mun` (sin `municipio`); `distrito` es `Distrito 01`, `Distrito 02` y la página lo prefija otra vez (`'Distrito ' // distrito` da « |
| [renta_ecv_edad](#renta_ecv_edad) | 3 | bajo | solo España; los grupos de edad se solapan (`Menores de 16 años` está dentro de `Menos de 18 años` según la ficha; `De 18 a 64 años` agrupa  |
| [sanidad_listas_especialidad](#sanidad_listas_especialidad) | 3 | bajo | solo total nacional pero sin `nivel`/`cod` (la ficha dice territorio nulo); `pacientes` es nulo en `tipo='consultas'` y la unidad de `pacien |
| [trazabilidad_fuentes](#trazabilidad_fuentes) | 3 | bajo | es un catálogo de metadatos de 144 fuentes (no responde preguntas de datos; ficha `usar: false`); la columna `estado_pipeline` es un literal |
| [turismo_ccaa_mensual](#turismo_ccaa_mensual) | 3 | bajo | ya tiene `cod_ccaa`+`comunidad`, euros reales y por 1.000 hab. La ficha dice que fuera de seis comunidades "valen 0": **es falso**, en los d |
| [turismo_mensual](#turismo_mensual) | 3 | bajo | ya está en reales y por 1.000 hab; la ficha dice "los 0 corresponden a meses sin dato aún publicado", pero en la tabla hay 201 meses con `tu |
| [vivienda_alquiler_municipios](#vivienda_alquiler_municipios) | 3 | bajo | tiene `cod_mun`+`municipio` pero `cod_prov` y `cod_ccaa` sin nombre; ya está en reales y por 1.000 hab. Sin `nivel`. Sin `tipologia` (solo C |
| [alcaldes_historia](#alcaldes_historia) | — | ? | ninguno de datos; la ficha ya la marca `usar: false` (listado sin cifra) y es correcto. `es_actual` solapa con `alcaldes_actuales`, pero lo  |
| [calor_espana_diario](#calor_espana_diario) | — | ? | ninguno real; tabla nacional por día con `fecha` + `anio`, grados con unidad clara; los recuentos por día no se suman y la nota basta. |
| [construccion_afiliados](#construccion_afiliados) | — | ? | ninguno de fondo. Ya cumple las convenciones (`nivel`, `cod`, `nombre`, `fecha`, `anio`, `afiliados_constr_1000hab`, España como `pais`/`00` |
| [deflactor](#deflactor) | — | ? | la ficha lo marca `usar: false` ("auxiliar"); es correcto, es una de las dos tablas de referencia permitidas (`territorios`, `deflactor`). A |
| [diputados_inmuebles_resumen](#diputados_inmuebles_resumen) | — | ? | una fila por definición de "casero" con los totales repetidos (`t.*`); las definiciones se solapan; sin territorio ni año (el ejercicio de r |
| [electricidad_records](#electricidad_records) | — | ? | cada fila es un récord distinto con su propia `unidad` (MW, GWh, %, g CO2/kWh, t CO2/h, €/MWh): es formato largo y ya cumple la convención ( |
| [electricidad_records_historia](#electricidad_records_historia) | — | ? | ninguna tabla duplicada: es el detalle de la anterior; la ficha la marca `usar: false`, correcto. |
| [electricidad_ultimas_24h](#electricidad_ultimas_24h) | — | ? | es el contrato de datos del directo (el Worker publica el mismo esquema); la ficha ya la marca `usar: false`. |
| [gobierno_decretos_ley](#gobierno_decretos_ley) | — | bajo | ninguno de datos: es una lista de decretos uno por uno (fecha, presidente, familia, estado, enlace) que la página enseña tal cual y de la qu |
| [gobierno_presidencias_resumen](#gobierno_presidencias_resumen) | — | bajo | diez filas, 7 presidentes y 3 partidos en la misma columna `grupo` distinguidas por `nivel`: no sumar niveles (ya lo cumple `nivel`); sin pe |
| [gobiernos_presidentes](#gobiernos_presidentes) | — | bajo | ninguno. Es una tabla de referencia (presidentes estatales y autonómicos con fechas y familia política) de la que cuelgan al menos 12 modelo |
| [mapas_indicadores](#mapas_indicadores) | — | bajo | 151.206 filas y 257 indicadores con unidad y sentido propios (ya tiene `unidad` y `sentido` en cada fila); repite datos de las tablas temáti |
| [medios_publicidad_age_medios](#medios_publicidad_age_medios) | — | bajo | ninguno de fondo: ya trae `importe_eur_nominal`, `importe_eur_real`, `eur_hab_real` y `pct`. El filtro por `ambito` es real (dos definicione |
| [medios_publicidad_grupos](#medios_publicidad_grupos) | — | bajo | ninguno de fondo: ya tiene `importe_eur_real`, `eur_hab_real`, `eur_1000hab_real`, `pct`, `puesto`, `es_plataforma`, `es_publico`. El filtro |
| [mercado_energia_ipc](#mercado_energia_ipc) | — | bajo | solo la trampa de la ficha (tasas no se suman); `mes` DATE primer día de mes sirve como `fecha`; las unidades por columna son claras (`indic |
| [mercado_ipc_grupos](#mercado_ipc_grupos) | — | bajo | ninguno; tiene `grupo`, `grupo_corto`, `es_general` y las unidades están claras; las advertencias de la ficha (tasas no se suman) son de con |
| [mercado_paro_grupos](#mercado_paro_grupos) | — | bajo | formato largo (`dimension`, `grupo`, `orden`, `tasa_paro`) con una sola unidad (%), por lo que no mezcla unidades; sin fila de total (está e |
| [mercado_paro_trimestral](#mercado_paro_trimestral) | — | bajo | ninguno de fondo: solo España, `trimestre` DATE + `anio` + `trim` + `periodo` (etiqueta). Personas (`parados`, `asalariados`) son stocks. Es |
| [metricas](#metricas) | — | bajo | ~190 indicadores con unidades distintas en una columna `valor`; duplica las tablas temáticas; pero es la base de KPIs de portada y de las fi |
| [movilidad_matriculaciones_mensual](#movilidad_matriculaciones_mensual) | — | bajo | el filtro `nuevo_usado = 'N'` y la ausencia de fila de total son reales (dimensión que no se mezcla) y todas las páginas ya lo gestionan; ya |
| [pensiones_afiliados_regimen](#pensiones_afiliados_regimen) | — | ? | el año en curso promedia solo los meses publicados, pero ya lo marca la columna `meses` (cumple la convención); `Total` y regímenes conviven |
| [pensiones_anual](#pensiones_anual) | — | ? | solo España; el año en curso suma 9 meses (columna `meses`, vale); gastos en % del PIB con huecos en los últimos años (dato de Eurostat, no  |
| [pensiones_territorio](#pensiones_territorio) | — | ? | el mismo `cod` significa cosas distintas según `nivel` (hay que filtrar por nivel; la convención lo permite porque lleva `nivel` + `cod` + ` |
| [territorios](#territorios) | — | ? | ninguno de datos. Es la dimensión de referencia (nivel, cod, cod_ccaa, cod_ccaa_hacienda, nombre, slug, ruta, poblacion_ultima). La ficha ya |
| [vivienda_alquiler](#vivienda_alquiler) | — | ? | ya tiene euros reales, `nivel/cod/nombre` y por 1.000 hab (`alquiladas_1000`). Dos filas por territorio y año (`tipologia` Colectiva/Unifami |
| [vivienda_ipv](#vivienda_ipv) | — | ? | ninguno de fondo: índice base 2015=100 con `indice` y `indice_real`, `interanual_*`, `nivel/cod/nombre`. Tres tipos (General 1.520 filas, Nu |
| [vivienda_mercado_mensual](#vivienda_mercado_mensual) | — | ? | ya tiene `importe_*_real`, `_12m_1000`, `nivel/cod/nombre` y `fecha`+`anio`. Las `_12m` son acumulados móviles (la ficha ya lo avisa y es in |
| [vivienda_obra_nueva](#vivienda_obra_nueva) | — | ? | ninguno de datos: `iniciadas`, `terminadas`, `iniciadas_1000`, `terminadas_1000`, `nivel/cod/nombre`. Solo vivienda libre (no protegida), qu |
| [vivienda_precio_tasado](#vivienda_precio_tasado) | — | ? | ninguno: `euros_m2` y `euros_m2_real`, `precio_90m2` y `precio_90m2_real`, `interanual_*`, `nivel/cod/nombre`, `fecha`+`anio`+`trimestre`. S |
| [vivienda_resumen_territorios](#vivienda_resumen_territorios) | — | ? | es una "foto" derivada que reúne la última cifra de precio, alquiler, mercado, obra y esfuerzo (72 filas, cada indicador con su fecha: `prec |

## Prioridad 1: por habitante, euros reales o rompe el chat (35)

### ccaa_cuentas_capitulos
- **Modelo:** transform/models/marts/ccaa_cuentas_capitulos.sql (staging stg_hacienda_ccaa_capitulos) · **Páginas:** territorios/[ccaa]/index (4 traducciones) · **Prioridad:** 1
- **Problemas:** euros corrientes sin versión por habitante ni real (la página repite el join con población y `deflactor`); solo `cod_ccaa`, sin nombre; sin filas de total (hay que sumar capítulos y filtrar `tipo`).
- **Cambio propuesto:** añadir `ccaa`, población y las columnas por habitante y reales; mantener `ejecutado`, `presupuesto_*` en euros corrientes.
```sql
t.nombre as ccaa, p.poblacion,
s.ejecutado / p.poblacion as ejecutado_eur_hab,
s.ejecutado * d.factor as ejecutado_eur_real,
s.ejecutado * d.factor / p.poblacion as ejecutado_eur_hab_real,
s.presupuesto_definitivo * d.factor / p.poblacion as presupuesto_definitivo_eur_hab_real
-- join: territorios_ccaa t, poblacion_territorios (asof), deflactor
```
- **Páginas:** conservar `anio, cod_ccaa, tipo, capitulo, capitulo_nombre, presupuesto_definitivo, ejecutado`; la página `capitulos` puede pasar a `ejecutado_eur_hab_real` (hoy: `c.ejecutado / p.poblacion * coalesce(f.factor, 1)`).
- **Ficha:** desaparecen «sin nombre de comunidad» y «no hay versión por habitante ni real»; la medida principal pasa a `ejecutado_eur_hab_real`.
- **Esfuerzo/riesgo:** bajo-medio; modelo con joins nuevos, columnas aditivas. Aviso: el factor del año en curso (media parcial) cambia al cerrar el año; no es problema aquí (liquidación termina en 2024).

### ccaa_cuentas_resumen
- **Modelo:** transform/models/marts/ccaa_cuentas_resumen.sql · **Páginas:** territorios/index, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 1
- **Problemas:** euros corrientes sin habitante ni real; sin nombre; `deficit_no_financiero` es solo `saldo_no_financiero` con el signo cambiado (fuente de confusión del chat).
- **Cambio propuesto:** añadir `ccaa`, `poblacion` y por habitante real; no quitar `deficit_no_financiero` hasta que nadie lo use (ninguna página lo usa; podrá retirarse después).
```sql
t.nombre as ccaa, p.poblacion,
gastos_no_financieros / p.poblacion * d.factor as gastos_nf_eur_hab_real,
ingresos_no_financieros / p.poblacion * d.factor as ingresos_nf_eur_hab_real,
saldo_no_financiero / p.poblacion * d.factor as saldo_nf_eur_hab_real,
gastos_totales / p.poblacion * d.factor as gastos_totales_eur_hab_real
```
- **Páginas:** conservar `anio, cod_ccaa, ingresos_*, gastos_*, saldo_no_financiero, gastos_totales`; las consultas `cuentas`, `gasto_ranking` y `comparativa` (hoy repiten join de población y deflactor) pueden pasar a las columnas nuevas, y así se evita el truco `cod_ccaa <= '17'` si se decide una vista sin Ceuta/Melilla.
- **Ficha:** desaparecen «sin nombre» y «sin versión por habitante»; medida principal `gastos_nf_eur_hab_real`; el aviso del signo se mantiene.
- **Esfuerzo/riesgo:** bajo-medio; reaprovecha el patrón de arriba. Comprobar que `poblacion_territorios` cubre 18 y 19 (Ceuta y Melilla).

### ccaa_deuda
- **Modelo:** transform/models/marts/ccaa_deuda.sql (staging stg_bde_series) · **Páginas:** index, territorios/index, territorios/[ccaa]/index (12 traducciones); mención en src/lib/chat/herramientas.js solo como ejemplo de texto · **Prioridad:** 1
- **Problemas:** `deuda_eur` corriente sin habitante ni real (stock trimestral: la página lo calcula con población del año); `ccaa` viene como la publica el BdE (hoy coincide con `territorios`, pero sin garantía); `deflactor` no llega antes de 2002, así que 1994-2001 no tendría real.
- **Cambio propuesto:** añadir
```sql
p.poblacion,
deuda_eur / p.poblacion as deuda_eur_hab,
deuda_eur * d.factor as deuda_eur_real,
deuda_eur * d.factor / p.poblacion as deuda_eur_hab_real,
t.nombre as ccaa_nombre   -- de territorios_ccaa, por si el BdE cambia un nombre
-- población por asof (anio <= anio, padrón desde 1996); factor del año de la fecha
```
  Para tener real desde 1996 hay que alargar `mother.deflactor` con el IPCA (decisión 2); si no, `deuda_eur_hab_real` queda nulo hasta 2001.
- **Páginas:** conservar `fecha, anio, trimestre, cod_ccaa, ccaa, deuda_eur, deuda_pct_pib`; la KPI `deuda_ultima` y `deuda_hab_serie` pueden pasar a `deuda_eur_hab_real`, sin urgencia.
- **Ficha:** la medida principal sigue siendo `deuda_pct_pib`, pero se añade `deuda_eur_hab_real`; desaparece «sin habitante ni real».
- **Esfuerzo/riesgo:** bajo; aditivo. El factor del trimestre usa el año natural; el año en curso es provisional.

### ccaa_gasto_politicas
- **Modelo:** transform/models/marts/ccaa_gasto_politicas.sql (staging stg_hacienda_ccaa_funcional) · **Páginas:** territorios/[ccaa]/index (4 traducciones) · **Prioridad:** 1
- **Problemas:** `obligaciones` en euros corrientes sin habitante ni real (la página lo hace con `deflactor` + población y lo promedia ponderado); solo `cod_ccaa`, sin nombre; sin filas de total (sumar políticas).
- **Cambio propuesto:** añadir `ccaa`, `poblacion` y las columnas real/habitante; `obligaciones` queda tal cual.
```sql
t.nombre as ccaa, p.poblacion,
g.obligaciones / p.poblacion as obligaciones_eur_hab,
g.obligaciones * d.factor / p.poblacion as obligaciones_eur_hab_real,
g.obligaciones_brutas * d.factor / p.poblacion as obligaciones_brutas_eur_hab_real
```
- **Páginas:** conservar `anio, cod_ccaa, cod_area, area_nombre, cod_politica, politica_nombre, obligaciones`; la consulta `politicas` puede usar `obligaciones_eur_hab_real` (la media de las 17 sigue siendo suma/suma de `obligaciones` y `poblacion`, ya disponibles en la tabla).
- **Ficha:** desaparecen «sin nombre de comunidad» y «para comparar hay que dividir por población»; medida principal `obligaciones_eur_hab_real`.
- **Esfuerzo/riesgo:** bajo-medio; las políticas hijas suman a las áreas, no hay filas de total que se dupliquen.

### ccaa_saldo
- **Modelo:** transform/models/marts/ccaa_saldo.sql (staging stg_bde_series, be13a) · **Páginas:** territorios/[ccaa]/index (4 traducciones) · **Prioridad:** 1
- **Problemas:** `saldo_eur` y `pib_implicito_eur` corrientes sin habitante ni real; el PIB es implícito (deducido de la deuda del 4.º trimestre, no el oficial); sin Ceuta ni Melilla.
- **Cambio propuesto:** añadir columnas por habitante y reales; dejar claro en la columna que el PIB es implícito (ya lo dice el nombre).
```sql
p.poblacion,
a.saldo_eur / p.poblacion as saldo_eur_hab,
a.saldo_eur * d.factor / p.poblacion as saldo_eur_hab_real
```
  Nombre: usar `territorios_ccaa` en lugar del `ccaa` del BdE.
- **Páginas:** conservar `anio, cod_ccaa, saldo_eur, saldo_pct_pib`; la página divide `saldo_pct_pib / 100` y también usa `saldo_pct_pib` (el %); ninguna cambia.
- **Ficha:** se añade medida `saldo_eur_hab_real`; el signo (negativo = déficit) se mantiene en la nota.
- **Esfuerzo/riesgo:** bajo; aditivo.

### centrales_ccaa
- **Modelo:** transform/models/marts/centrales_ccaa.sql · **Páginas:** energia-clima/centrales (4 traducciones) · **Prioridad:** 1
- **Problemas:** potencia por comunidad solo en MW absolutos (comparar Castilla y León con La Rioja sin ajustar por población engaña, principio rector); `estado_grupo` con `defecto: En operación`; la suma de comunidades no cuadra con `centrales_resumen` (centrales sin comunidad se descartan con `cod_ccaa is not null`).
- **Cambio propuesto:** añadir población y vatios por habitante, y la potencia en operación sin filtro.
```sql
t.poblacion_ultima as poblacion,
1e6 * sum(u.potencia_mw) / t.poblacion_ultima as potencia_w_hab,
sum(u.potencia_mw) filter (where u.estado_grupo = 'En operación') as potencia_operacion_mw,
1e6 * sum(u.potencia_mw) filter (where u.estado_grupo = 'En operación') / t.poblacion_ultima as potencia_operacion_w_hab
-- join ref('territorios') t on t.nivel = 'ccaa' and t.cod = u.cod_ccaa
```
  (Ojo: se agrega por tecnología y estado; para que `potencia_w_hab` sea por fila hay que dividir en el `select` final, no sumar la columna.)
- **Páginas:** conservar `cod_ccaa, ccaa, tecnologia, estado_grupo, orden_estado, potencia_mw, n_*`; la gráfica `por_ccaa` (hoy en GW absolutos) debería pasar a `potencia_operacion_w_hab` para cumplir el principio por habitante; los GW totales quedan en el tooltip.
- **Ficha:** medida principal `potencia_operacion_w_hab`; desaparece el `defecto` en `estado_grupo` para la pregunta habitual.
- **Esfuerzo/riesgo:** medio; el cambio de la gráfica obliga a tocar la página y sus 4 traducciones (hash i18n); la tabla es aditiva.

### crimen_balance
- **Modelo:** transform/models/marts/crimen_balance.sql (macro con_uniprovinciales) · **Páginas:** index, sociedad/criminalidad, sociedad/index, territorios/municipios, territorios/[ccaa]/index (20 traducciones) · **Prioridad:** 1
- **Problemas:** la ficha está mal: marca `tasa_1000` e `infracciones` con `unidad: %` y `escala: 100` (nada es una proporción 0-1: `tasa_1000` es por 1.000 habitantes e `infracciones` es un recuento), lo que puede hacer que el chat multiplique por 100; `territorio` viene en mayúsculas («BALEARS (ILLES)», «RIOJA (LA)», «CIUDAD AUTÓNOMA DE CEUTA») frente al nombre de `territorios`.
- **Cambio propuesto:** (1) corregir la ficha: `tasa_1000` unidad «por cada 1.000 habitantes», `infracciones` unidad «infracciones», sin `escala`. (2) Añadir `nombre` normalizado, y una columna con la convención de tasa.
```sql
coalesce(t.nombre, n.territorio) as nombre,   -- left join ref('territorios') t on t.nivel = n.nivel and t.cod = n.cod
tasa_1000 as infracciones_por_1000_hab
```
  Los 1.349 registros ccaa/provincia de 2024 casan con `territorios`; los municipios siguen con el nombre del Balance (no hay nivel municipio en `territorios`).
- **Páginas:** conservar `anio, nivel, cod, territorio, categoria, infracciones, poblacion, tasa_1000` (varias lo usan como `b.territorio AS municipio`); pasar a `nombre` solo si luego se quiere unificar.
- **Ficha:** desaparecen la `escala: 100`/unidad «%» erróneas y la nota «nombres en mayúsculas y a veces sin tildes»; `territorio.nombre = nombre`.
- **Esfuerzo/riesgo:** bajo; el arreglo importante es de la ficha, no de la tabla.

### crimen_condenas_delito
- **Modelo:** transform/models/marts/crimen_condenas_delito.sql · **Páginas:** sociedad/criminalidad (4 traducciones) · **Prioridad:** 1
- **Problemas:** la columna `delito` mezcla el total (`Delitos`), grupos (`Contra la libertad`) y delitos concretos que están dentro de ellos, así que sumar filas cuenta varias veces; hay dos clasificaciones con nombres distintos según el año; y solo recuentos, sin tasa por habitante (principio rector).
- **Cambio propuesto:** semilla `crimen_delitos_jerarquia` (delito, grupo, `nivel_delito`: 0 total, 1 grupo, 2 delito) y tasa por 100.000 habitantes con población de España.
```sql
j.nivel_delito, j.grupo,
100000.0 * total / p.poblacion as total_por_100k_hab,
100000.0 * espanola / pe.poblacion_es as espanola_por_100k_hab   -- si hay población por nacionalidad; si no, solo total
-- p = poblacion_territorios nivel 'pais' sexo 'Total'
```
  La población por nacionalidad ya está en `raw.ine_poblacion_nacionalidad` (la usa `crimen_condenados`), así que se puede calcular también española y extranjera.
- **Páginas:** conservar `anio, delito, total, espanola, extranjera, ue, resto_europa, africa, america, asia`; la página filtra por nombres de delito concretos y usa `extranjera / total`.
- **Ficha:** se declara `nivel_delito` (sumar solo dentro de un nivel) y desaparece la advertencia «sumar todas las filas cuenta varias veces»; se añade medida `total_por_100k_hab`.
- **Esfuerzo/riesgo:** medio; la jerarquía se escribe a mano (unos 60 nombres, dos clasificaciones) y hay que revisar que no queden delitos sin clasificar.

### crimen_serie_larga
- **Modelo:** transform/models/marts/crimen_serie_larga.sql · **Páginas:** sociedad/criminalidad, sociedad/index (8 traducciones) · **Prioridad:** 1
- **Problemas:** misma ficha errónea que `crimen_balance` (`tasa_1000` e `infracciones` con unidad `%` y `escala: 100`); sin nombre de territorio (solo `cod` y `nivel`; comunidad y provincia comparten códigos); `tipologia` en mayúsculas con jerarquía `nivel_tipologia`.
- **Cambio propuesto:** corregir la ficha como en `crimen_balance` y añadir el nombre.
```sql
coalesce(t.nombre, case when b.cod = '00' then 'España' end) as nombre
-- left join ref('territorios') t on t.nivel = b.nivel and t.cod = b.cod
```
- **Páginas:** conservar `anio, nivel, cod, codigo_tipologia, tipologia, nivel_tipologia, infracciones, tasa_1000` (filtran por `tipologia = 'TOTAL INFRACCIONES PENALES'` y `codigo_tipologia`).
- **Ficha:** desaparecen `escala`/unidad «%» erróneas y «sin nombre de territorio»; `territorio.nombre = nombre`.
- **Esfuerzo/riesgo:** bajo.

### crimen_ultimo_periodo
- **Modelo:** transform/models/marts/crimen_ultimo_periodo.sql · **Páginas:** sociedad/criminalidad (4 traducciones) · **Prioridad:** 1
- **Problemas:** ficha errónea (`infracciones` e `infracciones_anio_anterior` con `%` y `escala: 100`); no tiene tasa por habitante ni población, así que el chat solo compara recuentos; periodo parcial (enero-junio) fácil de confundir con un año completo; `territorio` en mayúsculas.
- **Cambio propuesto:** corregir la ficha y añadir población, tasa y nombre.
```sql
p.poblacion,
1000.0 * infracciones / nullif(p.poblacion, 0) as tasa_1000,
1000.0 * infracciones_anio_anterior / nullif(p.poblacion, 0) as tasa_1000_anio_anterior,
100.0 * (infracciones / nullif(infracciones_anio_anterior, 0) - 1) as variacion_pct,
true as es_parcial,
coalesce(t.nombre, territorio) as nombre
-- población como en crimen_balance (último padrón <= año)
```
- **Páginas:** conservar `anio, periodo, nivel, cod, territorio, categoria, infracciones, infracciones_anio_anterior` (la página calcula `variacion` por su cuenta).
- **Ficha:** desaparece la `escala` errónea y «sin tasa por habitante»; `tiempo.parcial = true` queda declarado por `es_parcial`.
- **Esfuerzo/riesgo:** bajo; reutiliza el CTE `poblacion` de `crimen_balance`.

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

### empleo_salarios_deciles
- **Modelo:** transform/models/marts/empleo_salarios_deciles.sql · **Páginas:** cuentas-publicas/empleo-publico, economia/salarios (8 traducciones) · **Prioridad:** 1
- **Problemas:** `salario_mensual` en euros corrientes (el chat compara 2006 con 2024 sin deflactar; las páginas lo deflactan a mano con `mother.deflactor` en 3 sitios); `decil = 0` es la media mezclada con los deciles 1-10; `anio` y `decil` son DOUBLE.
- **Cambio propuesto:** añadir `salario_mensual_real`, `anio_euros`, `decil_nombre` (`Media`, `D1`...`D10`) y `es_media` BOOLEAN. No hay por habitante (es salario medio).
```sql
valor * d.factor as salario_mensual_real, d.anio_base as anio_euros,
case decil when 0 then 'Media' else 'D' || cast(decil as integer) end as decil_nombre, decil = 0 as es_media
-- join deflactor d on d.anio = cast(anio as integer)
```
- **Páginas:** conservar `jornada`, `decil`, `sector`, `salario_mensual`, `anio`. empleo-publico (`brecha`, `serie_*`) y salarios.md pueden sustituir su `JOIN deflactor` por `salario_mensual_real` (opcional, ×8 traducciones cada una).
- **Ficha:** `decil` deja de tener la excepción «0 es la media» (dimensión `decil_nombre` con total `Media`); medida principal pasa a `salario_mensual_real` (campo `real` de la medida actual).
- **Esfuerzo/riesgo:** bajo, columnas nuevas sobre una tabla pequeña; riesgo nulo mientras no se retire `decil`.

### energia_emisiones_gei
- **Modelo:** transform/models/marts/energia_emisiones_gei.sql (staging `stg_energia_emisiones_gei`) · **Páginas:** energia-clima/index (4 traducciones) · **Prioridad:** 1
- **Problemas:** solo cifras absolutas (Mt) sin por habitante, contra el principio rector; el año se llama `año` (con eñe, obliga a entrecomillar en SQL); sin fila total (se suma). Sirve de origen para ingestion/emisiones.py.
- **Cambio propuesto:** añadir `anio` INTEGER, `t_co2eq_hab` y `total_t_co2eq_hab` por sector con la población ya calculada en `clima_emisiones_anual` (Eurostat demo_gind, desde 1990; `poblacion_territorios` solo llega a 1996).
```sql
s.anio as "año", s.anio as anio,
round(s.mt_co2eq * 1e6 / c.poblacion, 3) as t_co2eq_hab
-- left join {{ ref('clima_emisiones_anual') }} c on c.anio = s.anio
```
- **Páginas:** conservar `año`, `sector`, `millones_toneladas_co2eq`, `porcentaje_total`. La gráfica por sector de energia-clima/index debería pasar a `t_co2eq_hab` (por habitante) con el total en el tooltip; las 4 traducciones copian el SQL.
- **Ficha:** desaparece «datos absolutos, no por habitante»; la medida principal pasa a `t_co2eq_hab`, y el tiempo a `anio` (se pierde la columna `año` como excepción).
- **Esfuerzo/riesgo:** medio, cambia el mensaje de una gráfica y 4 páginas; el mart es trivial.

### inmigracion_poblacion
- **Modelo:** transform/models/marts/inmigracion_poblacion.sql · **Páginas:** sociedad/inmigracion (4 traducciones) · **Prioridad:** 1
- **Problemas:** `pct_extranjeros` es una fracción 0-1 (la página la multiplica por 100 en `pob_espana`; en el mapa de comunidades se formatea como pct), contra «porcentajes 0-100 con sufijo `_pct`»: el chat da 0,12 en vez de 12 %; solo `cod`; las zonas de origen no suman el total.
- **Cambio propuesto:** añadir `pct_extranjeros_pct` (0-100), `nombre`, y `pct_otros_origen` o dejar la advertencia. No quitar `pct_extranjeros` hasta que las páginas migren. Ya trae `poblacion`, así que cada zona se puede dar `_pct`.
```sql
100.0 * extranjeros / poblacion as pct_extranjeros_pct, t.nombre
```
- **Páginas:** conservar `anio`, `nivel`, `cod`, `poblacion`, `extranjeros`, `pct_extranjeros`, `ue`, `resto_europa`, `africa`, `america_norte`, `centroamerica_caribe`, `sudamerica`, `asia`. Migrar `pob_espana` (`100 * pct_extranjeros AS valor`) y `ccaa` a la columna nueva (4 traducciones).
- **Ficha:** desaparece «pct_extranjeros viene como fracción»; medida principal `pct_extranjeros_pct`. Retirada de la columna vieja cuando ninguna página la use (la usa también `nacionalizaciones` por `extranjeros`, esa se queda).
- **Esfuerzo/riesgo:** bajo.

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

## Prioridad 2: mejora clara (62)

### alcaldes_familias_territorio
- **Modelo:** transform/models/marts/alcaldes_familias_territorio.sql · **Páginas:** ninguna (solo chat y banco de pruebas) · **Prioridad:** 2
- **Problemas:** `cod` sin nombre de territorio (convención: nunca un código sin su nombre); la ficha tiene `territorio.nombre = null`.
- **Cambio propuesto:** añadir `nombre` desde `territorios` (España = `'España'`). Sin tocar `clave`, `n`, `poblacion`.
```sql
left join {{ ref('territorios') }} t on t.nivel = agregado.nivel and t.cod = agregado.cod
-- select ... coalesce(t.nombre, 'España') as nombre
```
  Además absorbe a `alcaldes_resumen_familias` (su fila `nivel = 'pais'` es lo mismo).
- **Páginas:** ninguna la usa; nada que conservar salvo `familia`, `n`, `pct_*`, `clave` (los usa el banco `tools/chat/evaluacion`).
- **Ficha:** `territorio.nombre` pasa de null a `nombre`.
- **Esfuerzo/riesgo:** bajo; un join, ninguna página afectada.

### alcaldes_resumen_familias
- **Modelo:** transform/models/marts/alcaldes_resumen_familias.sql · **Páginas:** ninguna (solo la pregunta `sql_oro` de tools/chat/evaluacion/preguntas-desarrollo.json, línea 1142-1146) · **Prioridad:** 2 (BORRAR)
- **Problemas:** duplicada: es `alcaldes_familias_territorio` filtrada a `nivel = 'pais'` con otros nombres de columna (`n_ayuntamientos`, `poblacion_gobernada`). Ninguna página, componente, ingestion/ ni orchestration/ la usa (solo `schema_alcaldes.yml`, `sources/mother/alcaldes_resumen_familias.sql` y la ficha).
- **Cambio propuesto:** borrar el modelo, su entrada en `schema_alcaldes.yml`, `sources/mother/alcaldes_resumen_familias.sql` y su ficha en `lote-1.json`. Reescribir la pregunta del banco: `SELECT familia, n, pct_poblacion FROM mother.alcaldes_familias_territorio WHERE nivel='pais' AND familia='PP'`.
- **Páginas:** ninguna.
- **Ficha:** desaparece la ficha entera; en la de `alcaldes_familias_territorio` hay que decir que también sirve para el total de España.
- **Esfuerzo/riesgo:** bajo; solo hay que actualizar el banco de pruebas del chat (verificar que sigue pasando).

### almacenamiento_acceso
- **Modelo:** transform/models/marts/almacenamiento_acceso.sql · **Páginas:** energia-clima/almacenamiento (4 traducciones) · **Prioridad:** 2
- **Problemas:** foto mensual completa (2 ficheros: sumarlos duplica); la página y el chat deben filtrar `fecha_fichero = max(...)`; tiempo en `fecha_fichero` (no `fecha`/`anio`); el nombre se llama `comunidad` (convención: `ccaa`).
- **Cambio propuesto:** añadir columnas sin quitar ninguna.
```sql
fecha_fichero as fecha, year(fecha_fichero) as anio,
fecha_fichero = max(fecha_fichero) over () as es_ultimo,
coalesce(c.nombre, a.ccaa) as ccaa
```
  Opcional: `otorgada_w_hab` con la población de la comunidad (potencia concedida por habitante).
- **Páginas:** conservar `fecha_fichero, cod_ccaa, comunidad, nudos, otorgada_mw, en_tramitacion_mw`; la página puede pasar a `WHERE es_ultimo` (quita las dos subconsultas `max(fecha_fichero)`), sin urgencia.
- **Ficha:** desaparece la trampa «tomar el último»; pasa a decir `es_ultimo = true` por defecto y `territorio.nombre = ccaa`, `tiempo.columna = fecha`.
- **Esfuerzo/riesgo:** bajo; columnas nuevas, nada roto.

### almacenamiento_mensual
- **Modelo:** transform/models/marts/almacenamiento_mensual.sql · **Páginas:** energia-clima/almacenamiento (4 traducciones) · **Prioridad:** 2
- **Problemas:** `rendimiento_bombeo` es proporción 0-1 (convención: `_pct` en 0-100; la ficha lo salva con `escala: 100`); último mes incompleto sin marcar; falta `anio` y `fecha`.
- **Cambio propuesto:** añadir al lado, sin quitar `rendimiento_bombeo`.
```sql
100 * bombeo_turbinado_gwh / nullif(bombeo_consumido_gwh, 0) as rendimiento_bombeo_pct,
year(mes) as anio, mes as fecha,
mes = max(mes) over () as es_parcial
```
- **Páginas:** conservar `mes, bombeo_*_gwh, baterias_*_gwh`; la página calcula `rendimiento` anual ella misma (suma/suma, correcto), no usa la columna 0-1.
- **Ficha:** desaparece `escala: 100` en `rendimiento_bombeo` (pasa a `rendimiento_bombeo_pct`, unidad %); el parcial pasa a `es_parcial`.
- **Esfuerzo/riesgo:** bajo; columnas nuevas.

### almacenamiento_potencia
- **Modelo:** transform/models/marts/almacenamiento_potencia.sql · **Páginas:** energia-clima/almacenamiento (4 traducciones) · **Prioridad:** 2
- **Problemas:** dos tipos (`bombeo_puro`, `baterias_hibridadas`) en formato largo con una sola unidad (MW), correcto pero cuesta sumarlo bien: es una foto mensual (no se suma entre meses); `comunidad` en vez de `ccaa`; sin `anio`/`fecha`; sin nada por habitante.
- **Cambio propuesto:** mantener formato largo (una unidad, MW) y añadir:
```sql
mes as fecha, year(mes) as anio, c.nombre as ccaa,
mes = max(mes) over () as es_ultimo,
case tipo when 'bombeo_puro' then 'Bombeo puro' else 'Baterías hibridadas' end as tipo_nombre,
1e6 * mw / nullif(p.poblacion, 0) as w_hab   -- población: ref('territorios') poblacion_ultima
```
- **Páginas:** conservar `mes, tipo, cod_ccaa, comunidad, mw`; no hace falta cambiar ninguna.
- **Ficha:** `es_ultimo` sustituye a la advertencia «no se suma entre meses»; `territorio.nombre = ccaa`; medida `w_hab` (W por habitante).
- **Esfuerzo/riesgo:** bajo.

### centrales
- **Modelo:** transform/models/marts/centrales.sql (staging stg_gem_centrales) · **Páginas:** energia-clima/centrales (4 traducciones) · **Prioridad:** 2
- **Problemas:** una fila por central y estado; hay que filtrar `estado_grupo = 'En operación'` o se mezclan canceladas y en tramitación (excepción `defecto` en la ficha); `potencia_mw` mezcla estados que no se suman; `municipio` solo por nombre (sin `cod_mun`, GEM no lo da).
- **Cambio propuesto:** añadir booleano y potencia segura de sumar.
```sql
u.estado_grupo = 'En operación' as en_operacion,
case when u.estado_grupo = 'En operación' then round(sum(u.potencia_mw), 1) end as potencia_operacion_mw
```
- **Páginas:** conservar `id, nombre, tecnologia, color, estado_grupo, potencia_mw, lat, lon, ccaa, provincia, ...`; la página puede seguir con su filtro.
- **Ficha:** `defecto: En operación` en `estado_grupo` se convierte en medida principal `potencia_operacion_mw` (no necesita filtro); sigue disponible `potencia_mw` por estado.
- **Esfuerzo/riesgo:** bajo; columnas nuevas. Sin tocar la ingestión.

### construccion_permisos
- **Modelo:** transform/models/marts/construccion_permisos.sql · **Páginas:** economia/construccion (4 traducciones, 8 consultas) · **Prioridad:** 2
- **Problemas:** tres fuentes en una tabla (`ambito` = `UE`, `CCAA`, `ES_LARGA`); `cod` mezcla códigos INE y ISO; España aparece dos veces con la misma serie (la fila `'00'` de CCAA desde 2000 es el mismo dato que `ES_LARGA`, según el comentario del propio modelo) y una tercera vez en `UE` con otra fuente; hay que acordarse del `defecto: CCAA`.
- **Cambio propuesto:** en dos pasos. 1) Ahora, aditivo: añadir `nivel` (`pais`, `ccaa`, `pais_ue`), `cod_pais` y `pais` (solo filas UE, y España) para que cada columna tenga un solo significado. 2) Después, dividir: `construccion_permisos` (INE: `nivel = pais/ccaa`, 1992-2025, España una sola vez con la serie larga del BdE antes de 2000 y los visados del Ministerio desde 2000) y `construccion_permisos_ue` (Eurostat, `cod_pais` + `pais`). Las consultas `ES_LARGA` pasarían a `cod = '00' AND ambito = 'CCAA'` y las `UE` a la tabla nueva.
```sql
-- paso 2: unir 1992-1999 de ES_LARGA a la rama CCAA con cod '00'
select 'pais' as nivel, '00' as cod, 'España' as nombre, anio, ... from es_larga where anio < 2000
union all select nivel, cod, ... from ccaa
```
- **Páginas:** hoy filtran por `ambito`; conservar `ambito, cod, nombre, anio, viviendas_nueva(_1000hab), viviendas_reforma_1000hab, m2_*_hab, poblacion`. El paso 2 obliga a reescribir las 8 consultas del ES y las de las 4 copias.
- **Ficha:** al dividir desaparece el `defecto: CCAA` en `ambito` y la nota de las tres fuentes.
- **Esfuerzo/riesgo:** paso 1 bajo; paso 2 medio-alto (páginas y traducciones, y verificar que la serie larga y los visados coinciden desde 2000).

### crimen_condenados
- **Modelo:** transform/models/marts/crimen_condenados.sql · **Páginas:** sociedad/criminalidad (4 traducciones) · **Prioridad:** 2
- **Problemas:** `cod_ccaa` con `'00'` = España, mezclado con comunidades sin `nivel` ni nombre (la ficha no puede dar el nombre; hay que traducir el código).
- **Cambio propuesto:** añadir `nivel`, `cod`, `nombre` desde `territorios` (España incluida), manteniendo `cod_ccaa`.
```sql
case when n.cod_ccaa = '00' then 'pais' else 'ccaa' end as nivel,
n.cod_ccaa as cod,
coalesce(t.nombre, 'España') as nombre   -- left join ref('territorios') t
```
  Las tasas siguen siendo por 1.000 adultos (nada que convertir); mantener la advertencia de no promediar tasas entre nacionalidades.
- **Páginas:** conservar `anio, cod_ccaa, sexo, nacionalidad, condenados, poblacion_18, tasa_1000` (la página filtra `cod_ccaa = '00'`).
- **Ficha:** `territorio.nivel/codigo/nombre`; desaparece «sin columna de nombre».
- **Esfuerzo/riesgo:** bajo.

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

### empleo_salarios_ccaa
- **Modelo:** transform/models/marts/empleo_salarios_ccaa.sql · **Páginas:** cuentas-publicas/empleo-publico, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 2
- **Problemas:** solo `cod_ccaa` (con `00` = España mezclado con comunidades); salarios en euros corrientes de 2022 sin `anio_euros` ni versión real; la brecha público/privado se calcula en la página; faltan Ceuta y Melilla (el INE no las publica en esta serie).
- **Cambio propuesto:** añadir `nivel`, `cod`, `nombre` (territorios), `salario_*_real` y `anio_euros`, y `brecha_publico_pct`. Por habitante no aplica (son medias por asalariado).
```sql
case when n.cod_ccaa='00' then 'pais' else 'ccaa' end as nivel, n.cod_ccaa as cod, t.nombre,
max(valor) filter (where control='Control de la empresa público') * d.factor as salario_publico_real,
100.0*(max(.. público ..)/max(.. privado ..)-1) as brecha_publico_pct, d.anio_base as anio_euros
```
- **Páginas:** conservar `cod_ccaa`, `salario_publico`, `salario_privado`. empleo-publico puede pasar a `nombre` y `brecha_publico_pct` (quita un join y un cálculo, ×8 traducciones, opcional).
- **Ficha:** desaparece la nota «solo código INE / 00 es España»; el territorio pasa a `nivel`/`cod`/`nombre`.
- **Esfuerzo/riesgo:** bajo, solo se añaden columnas a una tabla de 18 filas.

### empresas_autonomos
- **Modelo:** transform/models/marts/empresas_autonomos.sql · **Páginas:** economia/empresas, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 2
- **Problemas:** `trimestre = 0` (media anual) mezclado con los trimestres 1-4, y todas las páginas filtran `trimestre = 0`; solo `cod`; `anio`/`trimestre` DOUBLE; cifras en miles de personas junto a `pct_*`.
- **Cambio propuesto:** fase 1, añadir `nivel`, `nombre`, `tipo_periodo` (`Media anual`/`Trimestre`) y `es_media_anual` BOOLEAN. Fase 2 (cuando las páginas migren), partir en `empresas_autonomos` (trimestral) y `empresas_autonomos_anual` (media). El pct ya es relativo, no hace falta por habitante.
```sql
case when trimestre = 0 then 'Media anual' else 'Trimestre' end as tipo_periodo, trimestre = 0 as es_media_anual,
case when cod='00' then 'pais' else 'ccaa' end as nivel, t.nombre
```
- **Páginas:** conservar `cod`, `anio`, `trimestre`, `periodo`, `fecha`, `pct_*`, `cuenta_propia`. Para la fase 2 las 2 páginas (×8 con traducciones) cambian `FROM` a la tabla anual y quitan `trimestre = 0`.
- **Ficha:** tras la fase 2 desaparece el filtro `trimestre distinto 0`; tras la fase 1 pasa a dimensión `tipo_periodo` con `defecto`.
- **Esfuerzo/riesgo:** bajo la fase 1, medio la fase 2 (hay que tocar páginas y traducciones).

### energia_mix_electrico
- **Modelo:** transform/models/marts/energia_mix_electrico.sql (staging `stg_energia_generacion`) · **Páginas:** energia-clima/index, energia-clima/mix-electrico (8 traducciones) · **Prioridad:** 2
- **Problemas:** `año` con eñe; solo TWh absolutos, sin kWh por habitante; `porcentaje_total` en 0-100 pero la página mix-electrico lo divide por 100 para formatear (aceptable, solo es formato).
- **Cambio propuesto:** añadir `anio` y `generacion_kwh_hab` (población `poblacion_territorios` nivel `pais`, 2007-2025 cubierto); el porcentaje ya es la medida relativa.
```sql
g.anio as anio, round(sum(g.generacion_twh) * 1e9 / any_value(p.poblacion), 0) as generacion_kwh_hab
-- left join pob p on p.anio = g.anio
```
- **Páginas:** conservar `año`, `tecnologia`, `tipo_fuente`, `generacion_twh`, `porcentaje_total`. La gráfica de áreas de energia-clima/index podría pasar a kWh/hab (opcional).
- **Ficha:** desaparece la excepción `tiempo.columna = año`; medida nueva `generacion_kwh_hab`.
- **Esfuerzo/riesgo:** bajo, solo columnas nuevas.

### energia_potencia_instalada
- **Modelo:** transform/models/marts/energia_potencia_instalada.sql (staging `stg_energia_potencia`) · **Páginas:** energia-clima/index, energia-clima/mix-electrico (8 traducciones) · **Prioridad:** 2
- **Problemas:** `año` con eñe; MW absolutos sin W por habitante; es un stock (no se suma entre años) y solo por nombre en notas; la dbt `metricas_energia` depende de ella.
- **Cambio propuesto:** añadir `anio` y `potencia_w_hab` (MW x 1e6 / población). Mantener `fuente`. No tocar `metricas_energia`.
```sql
a.anio as anio, round(a.potencia_mw * 1e6 / p.poblacion, 1) as potencia_w_hab
```
- **Páginas:** conservar `año`, `tecnologia`, `tipo`, `potencia_mw`, `porcentaje_total`, `fuente`; las gráficas de solar y eólica del índice pueden pasar a W/hab (opcional).
- **Ficha:** desaparece la excepción `año`; medida nueva `potencia_w_hab`.
- **Esfuerzo/riesgo:** bajo.

### energia_resumen_anual_mix
- **Modelo:** transform/models/marts/energia_resumen_anual_mix.sql · **Páginas:** energia-clima/index (4 traducciones) · **Prioridad:** 2
- **Problemas:** `año` con eñe; TWh sin por habitante; solapa en fuente y años con `energia_mix_electrico` (el total y la cuota renovable salen de las mismas filas), pero la portada usa `SELECT *`, así que no se puede fusionar sin cambiar la página.
- **Cambio propuesto:** añadir `anio`, `generacion_kwh_hab` y `demanda_kwh_hab`. No borrar: las páginas leen `SELECT *` y las KPI dependen de las columnas actuales.
```sql
g.anio as anio, g.total_twh * 1e9 / p.poblacion as generacion_kwh_hab, d.demanda_twh * 1e9 / p.poblacion as demanda_kwh_hab
```
- **Páginas:** conservar todas (`SELECT *`, `cuota_renovable_pct`, `cuota_libre_emisiones_pct`, `año`).
- **Ficha:** desaparece la excepción `año`; medida nueva por habitante.
- **Esfuerzo/riesgo:** bajo.

### gobierno_indultos_mensual
- **Modelo:** transform/models/marts/gobierno_indultos_mensual.sql · **Páginas:** transparencia/indultos (4 traducciones) · **Prioridad:** 2
- **Problemas:** fila anómala del año 1200 (`mes = 1200-11-01`, 2 indultos, sin presidente) que contamina mínimos y rankings; sin filas de ceros en meses sin indulto; el último mes (julio 2026) puede estar incompleto sin marca; `mes` en lugar de `fecha` (convención).
- **Cambio propuesto:** filtrar `fecha_disposicion >= '1977-07-01'` en el mart, añadir `fecha` (= mes) y `es_parcial` BOOLEAN para el mes en curso. Rellenar meses sin indulto con 0 no es necesario si la ficha avisa; si se quiere, `generate_series` por mes.
```sql
where tipo = 'indulto' and fecha_disposicion >= date '1977-07-01'
... , m.mes as fecha, m.mes = date_trunc('month', current_date) as es_parcial
```
- **Páginas:** conservar `mes`, `anio`, `indultos`, `presidente`, `familia`. La página `indultos.md` calcula el pico con esta tabla; sin la fila de 1200 el resultado no cambia.
- **Ficha:** desaparece la nota «excluir anio >= 1977»; `tiempo.parcial` queda cubierto por `es_parcial`.
- **Esfuerzo/riesgo:** bajo, un filtro y dos columnas.

### industria_exportaciones_ue
- **Modelo:** transform/models/marts/industria_exportaciones_ue.sql · **Páginas:** economia/industria (4 traducciones) · **Prioridad:** 2
- **Problemas:** `exportacion_es_real_meur` es la medida principal pero absoluta (sin euros reales por habitante, contra el principio); `destino` con códigos crudos `WORLD` / `EXT_EU27_2020` (WORLD incluye el comercio intra-UE, trampa de 394.000 M€); `exportacion_es_eur`/`exportacion_ue_eur` en euros y no en millones; capítulos y partidas en la misma columna (`es_capitulo` ya los distingue).
- **Cambio propuesto:** añadir `exportacion_es_real_eur_hab` (con población de España), `destino_nombre` (`Mundo (incluye UE)` / `Fuera de la UE`) y `exportacion_es_meur`. No cambiar `destino`.
```sql
a.exportacion_es_eur / 1e6 as exportacion_es_meur,
a.exportacion_es_eur * d.factor / p.poblacion as exportacion_es_real_eur_hab,
case a.destino when 'WORLD' then 'Mundo (incluye UE)' else 'Fuera de la UE' end as destino_nombre
```
- **Páginas:** conservar todo lo que usa la página (`partida`, `cuota_pct`, `puesto`, `puesto_sin_nl_be`, `lider_nombre`, `veces_peso_poblacion`, `exportacion_es_real_meur`, `es_ultimo_anio`, `destino`). La tabla de exportaciones podría mostrar `exportacion_es_real_eur_hab` en vez del total.
- **Ficha:** `dimension destino` gana nombre legible (defecto sigue siendo `WORLD`); medida principal pasa a euros reales por habitante.
- **Esfuerzo/riesgo:** bajo, columnas nuevas; población ES de `poblacion_territorios` (nivel `pais`).

### industria_ipi
- **Modelo:** transform/models/marts/industria_ipi.sql · **Páginas:** economia/industria (4 traducciones) · **Prioridad:** 2
- **Problemas:** tres series mezcladas por `fuente` (eurostat por país, ine por comunidad, ine_divisiones por división); España duplicada (`cod` `00` INE y `ES` Eurostat) y códigos ISO e INE en la misma columna `cod`; el total es `B-D` en Eurostat y «Total industria» en INE; el chat necesita el `defecto: ine`. Es un índice: no se deflacta ni se divide por población (ya anotado en el modelo).
- **Cambio propuesto:** añadir `nivel` normalizado (`pais`/`ccaa`), `cod_pais` (ISO, `ES` para las dos Españas), `es_total` BOOLEAN y mantener `nombre` con el de `territorios` en INE. Fase 2 opcional: partir en `industria_ipi_paises` (Eurostat) e `industria_ipi_ine` (INE + divisiones) cuando la página lea de las nuevas.
```sql
rama in ('B-D','Total industria') as es_total,
case when fuente='eurostat' then e.pais when cod='00' then 'ES' end as cod_pais
```
- **Páginas:** la página filtra `fuente = 'eurostat' AND rama = 'B-D' AND cod IN ('ES',...)`; conservar `fuente`, `rama`, `cod`, `nombre`, `indice`, `anio`. Para fase 2 solo 2 consultas (×4 traducciones) cambian de `FROM`.
- **Ficha:** desaparece el `defecto: ine` si se parte; si no, se queda como dimensión `fuente`.
- **Esfuerzo/riesgo:** bajo la fase 1, medio la fase 2.

### inmigracion_nacionalizaciones
- **Modelo:** transform/models/marts/inmigracion_nacionalizaciones.sql · **Páginas:** sociedad/index, sociedad/inmigracion (8 traducciones) · **Prioridad:** 2
- **Problemas:** solo `cod` (`00` = España junto a comunidades); `nacionalidad_previa` mezcla países, continentes («De Africa», «De América del Norte») y agregados UE en la misma columna (la página los excluye con 4 `NOT LIKE`); `por_1000_extranjeros` solo existe para `Total`.
- **Cambio propuesto:** añadir `nivel`, `nombre` y `es_grupo` BOOLEAN (igual que `inmigracion_saldos`), con la misma lógica de nombres de agregado; la página puede sustituir sus filtros por `NOT es_grupo`.
```sql
nacionalidad_previa like 'De %' or nacionalidad_previa like 'País de%' or nacionalidad_previa like 'Resto%'
  or nacionalidad_previa like 'Otro país%' or nacionalidad_previa = 'Total' as es_grupo,
case when n.cod_ccaa='00' then 'pais' else 'ccaa' end as nivel, t.nombre
```
- **Páginas:** conservar `anio`, `cod`, `nacionalidad_previa`, `nacionalizaciones`, `por_1000_extranjeros`. `nac_origen` en sociedad/inmigracion pasa a `WHERE NOT es_grupo` (×8 traducciones, opcional); es dependencia dbt de `mapas_personas` y `metricas_sociedad`: no tocar.
- **Ficha:** desaparece «solo código» y «mezcla países y grupos»; dimensión con `es_grupo`.
- **Esfuerzo/riesgo:** bajo, lista de agregados cerrada y verificable con una consulta.

### ipc
- **Modelo:** transform/models/marts/ipc.sql · **Páginas:** ninguna (en las páginas `FROM ipc` son CTE locales, no `mother.ipc`); solo la usa el modelo `mercado_ipc_grupos` vía `ref('ipc')`; el banco de evaluación del chat la cita en `tablas_oro` de d08 (0 traducciones) · **Prioridad:** 2
- **Problemas:** 56 series del INE (índices y tasas anual/mensual/acumulada) en una columna `value` con la unidad dentro del texto de `serie`; duplicada por `mercado_ipc_grupos` y `mercado_ipc_ccaa`, que son mejores.
- **Cambio propuesto:** BORRAR de `mother.*`: eliminar `sources/mother/ipc.sql` y pasar el modelo a `{{ config(materialized='ephemeral') }}` (o convertirlo en `stg_ine_ipc_series`) para que `mercado_ipc_grupos` siga funcionando. Comprobado: ni `ingestion/`, ni `orchestration/` (solo un README antiguo que habla de `main.ipc`), ni `tools/` la leen. Quitar `mother.ipc` de `tablas_oro` de d08 en `tools/chat/evaluacion/preguntas-desarrollo.json` (el `sql_oro` ya usa `mercado_ipc_mensual`).
- **Páginas:** ninguna que migrar.
- **Ficha:** se elimina la ficha entera (y su entrada en el inventario).
- **Esfuerzo/riesgo:** bajo; único riesgo, olvidar que el modelo debe seguir existiendo como dependencia.

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

### unemployment
- **Modelo:** transform/models/marts/unemployment.sql (`stg_ine_paro`, tabla INE 65219) · **Páginas:** ninguna (solo la cita `tools/chat/evaluacion/preguntas-desarrollo.json`, pregunta d06, como tabla "de oro" alternativa) · **Prioridad:** 2
- **Problemas:** formato de la primera versión: `date, value, serie, cod_serie`, con el sexo y la edad dentro del texto de `serie` (39 series, nombres con dos órdenes distintos, hay que filtrar con `LIKE`); solo nacional y duplica `mercado_paro_trimestral.tasa_paro` (98 trimestres desde 2002).
- **Cambio propuesto:** **borrar** `sources/mother/unemployment.sql` (el modelo dbt `unemployment` se puede borrar también; `stg_ine_paro` sigue usándolo `metricas_base`). Pérdida real: el cruce sexo x grupo de edad quinquenal (`mercado_paro_grupos` da sexo y edad **por separado** y con 5 grupos). Si el dueño quiere conservar ese cruce, convertirla en `mercado_paro_sexo_edad` (`fecha, anio, trimestre, sexo, grupo_edad, tasa_paro`) parseando `serie`, en vez de borrarla. Mi propuesta es borrar; actualizar d06 quitando `mother.unemployment` de `tablas_oro`.
- **Páginas:** ninguna.
- **Ficha:** sale del lote (su ficha explicaba el `LIKE` y la serie por defecto).
- **Esfuerzo/riesgo:** bajo si se borra; medio si se reconvierte.

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

## Prioridad 3: cosmético (53)

### almacenamiento_diario
- **Modelo:** transform/models/marts/almacenamiento_diario.sql · **Páginas:** energia-clima/almacenamiento (4 traducciones) · **Prioridad:** 3
- **Problemas:** mezcla energía (MWh, se suma) y picos (MW, no se suman) en una fila, y el último día puede estar incompleto. No son errores: están bien nombradas con su unidad.
- **Cambio propuesto:** solo añadir `es_parcial` (último día de la serie) para que el chat no lo compare con días completos; no convertir unidades (la página ya divide entre 1000).
```sql
fecha = max(fecha) over () as es_parcial
```
- **Páginas:** conservar `fecha, bombeo_*_mwh, bombeo_*_pico_mw`.
- **Ficha:** la nota del último día incompleto se convierte en `tiempo.parcial` declarativo.
- **Esfuerzo/riesgo:** bajo; una columna.

### calor_normal_diaria
- **Modelo:** transform/models/marts/calor_normal_diaria.sql · **Páginas:** energia-clima/calor (4 traducciones), solo para dibujar la banda p10/p90 · **Prioridad:** 3
- **Problemas:** auxiliar (ficha `usar: false`), el territorio solo tiene `cod_prov`; no es duplicada: la usa la gráfica y no se puede derivar de `calor_provincia_diario`.
- **Cambio propuesto:** dejarla (no borrar); añadir `provincia` desde `territorios_provincias` para que el código no vaya solo. Nada más.
```sql
join {{ ref('territorios_provincias') }} tp using (cod_prov)  -- tp.nombre as provincia
```
- **Páginas:** conservar `cod_prov, dia_anio, tmax_media, tmax_p10, tmax_p90`.
- **Ficha:** sigue `usar: false` (auxiliar de gráfica); sin excepción nueva.
- **Esfuerzo/riesgo:** bajo; cosmético.

### calor_records
- **Modelo:** transform/models/marts/calor_records.sql · **Páginas:** energia-clima/calor (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo los 20 mejores días por provincia; hay que filtrar `posicion = 1` para el récord absoluto (trampa de la ficha).
- **Cambio propuesto:** añadir un booleano; no cambiar el filtro `qualify <= 20` (la página lo usa).
```sql
posicion = 1 as es_record_absoluto
```
- **Páginas:** conservar `cod_prov, provincia, estacion, fecha, tmax, anomalia_tmax, posicion`.
- **Ficha:** la nota «filtrar posicion = 1» pasa a ser una dimensión con valor claro (`es_record_absoluto`).
- **Esfuerzo/riesgo:** bajo; mejora menor.

### centrales_resumen
- **Modelo:** transform/models/marts/centrales_resumen.sql · **Páginas:** energia-clima/centrales (4 traducciones) · **Prioridad:** 3
- **Problemas:** total nacional por tecnología y estado, sin nivel/cod/nombre de España ni suma segura (misma trampa del estado); es casi `centrales_ccaa` sin comunidad.
- **Cambio propuesto:** mantenerla (da el total real, incluidas centrales sin comunidad, y el color de las tecnologías que usa la página); añadir
```sql
'pais' as nivel, '00' as cod, 'España' as nombre,
sum(u.potencia_mw) filter (where u.estado_grupo = 'En operación') as potencia_operacion_mw
```
  No fusionar con `centrales_ccaa` ahora (obligaría a reescribir KPIs y gráficas); queda como posible paso posterior.
- **Páginas:** conservar `tecnologia, color, orden_tecnologia, renovable, estado_grupo, potencia_mw`.
- **Ficha:** `defecto` del estado sustituido por `potencia_operacion_mw`; `territorio` con `nivel/cod/nombre`.
- **Esfuerzo/riesgo:** bajo; cosmético.

### construccion_ccaa
- **Modelo:** transform/models/marts/construccion_ccaa.sql · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** 3
- **Problemas:** mezcla España (`cod = '00'`) y comunidades sin columna `nivel` (convención para tablas multinivel); el VAB en total (`vab_constr_meur`) solo en corrientes; `vab_constr_hab_real` ya cumple el principio.
- **Cambio propuesto:** añadir
```sql
case when b.cod = '00' then 'pais' else 'ccaa' end as nivel,
b.vab_constr_meur * d.factor as vab_constr_meur_real
```
- **Páginas:** conservar `cod, nombre, anio, pct_vab_construccion, vab_constr_hab_real, puesto, ...`.
- **Ficha:** `territorio.nivel = 'nivel'`; la excepción de España por `cod = '00'` pasa a `nivel = 'pais'`.
- **Esfuerzo/riesgo:** bajo.

### construccion_costes
- **Modelo:** transform/models/marts/construccion_costes.sql · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** 3
- **Problemas:** `pais` guarda el código ISO y `pais_nombre` el nombre (convención: `cod_pais` + `pais`); el coste real solo existe para España porque `ingestion/construccion.py` solo baja el IPCA de `geo=ES`; la serie de costes de España es idéntica a la de precios (dato de la fuente).
- **Cambio propuesto:** añadir `b.pais as cod_pais` y dejar `pais` hasta que ninguna página lo use (retirada posterior, con `pais_nombre` renombrado a `pais`). Para dar el coste real de todos los países habría que ingerir el IPCA de todos (`prc_hicp_aind` para cada país): datos que hoy no existen; solo se propone si el dueño lo quiere.
- **Páginas:** conservar `anio, pais, pais_nombre, es_referencia, coste_indice_2021, coste_real_indice_2021, var_coste_anual_pct`.
- **Ficha:** `territorio.codigo = cod_pais`; sin excepciones nuevas.
- **Esfuerzo/riesgo:** bajo para `cod_pais`; medio si se amplía la ingestión del IPCA.

### construccion_empleo
- **Modelo:** transform/models/marts/construccion_empleo.sql · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** 3
- **Problemas:** mezcla España y comunidades sin `nivel`; cifras en miles (convención: una columna, una unidad; está en el nombre `_miles`, vale); `periodo` en texto `2026T1` además de `fecha`.
- **Cambio propuesto:** solo añadir `nivel`.
```sql
case when cod = '00' then 'pais' else 'ccaa' end as nivel
```
- **Páginas:** conservar `cod, nombre, anio, trimestre, periodo, fecha, ocupados_*, pct_ocupados_constr, ocupados_constr_1000hab, tasa_paro_constr`.
- **Ficha:** `territorio.nivel`, `espana` por `nivel = 'pais'`.
- **Esfuerzo/riesgo:** bajo.

### construccion_grandes_constructoras
- **Modelo:** transform/models/marts/construccion_grandes_constructoras.sql (seed construccion_constructoras) · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** 3
- **Problemas:** el tiempo va en `edicion` (no `anio`); importes en millones de dólares (no hay deflactor ni cambio a euros: dato que no existe); solo ACS y Acciona tienen ingresos.
- **Cambio propuesto:** añadir `cast(edicion as integer) as anio`; no convertir a euros (faltaría un tipo de cambio por año y una fuente que no está ingerida). Son 7 filas: mantener la tabla.
- **Páginas:** conservar todas las columnas.
- **Ficha:** `tiempo.columna = anio`; la nota «importes en dólares» se queda.
- **Esfuerzo/riesgo:** bajo.

### construccion_produccion
- **Modelo:** transform/models/marts/construccion_produccion.sql · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** 3
- **Problemas:** `pais` es el código ISO y `pais_nombre` el nombre (igual que `construccion_costes`); índices (no euros, no se suman); el salto de España en 2025 ya está explicado en la columna `nota`. Sin problemas de unidad.
- **Cambio propuesto:** añadir `cod_pais` (copia de `pais`); no tocar índices ni `nota`.
- **Páginas:** conservar `anio, pais, pais_nombre, es_referencia, rama, rama_nombre, indice_2021, indice_2007, var_anual_pct, nota`.
- **Ficha:** `territorio.codigo = cod_pais`.
- **Esfuerzo/riesgo:** bajo.

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

### empleo_territorio
- **Modelo:** transform/models/marts/empleo_territorio.sql · **Páginas:** empleo-publico, index (portada), territorios/[ccaa]/index y [provincia] (16 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod` (provincia y comunidad comparten dígitos, hay que fijar `nivel`); `administracion = 'Total'` convive con sus partes (aceptado por la convención); falta `anio`.
- **Cambio propuesto:** añadir `nombre` y `anio`. Ya trae `por_1000_hab` y `poblacion`; no hay euros.
```sql
t.nombre, cast(year(e.fecha) as integer) as anio
-- left join {{ ref('territorios') }} t on t.nivel = e.nivel and t.cod = e.cod
```
- **Páginas:** conservar `nivel`, `cod`, `administracion`, `efectivos`, `por_1000_hab`, `fecha`. Ninguna necesita cambiar (las de territorio ya traen el nombre de otro sitio).
- **Ficha:** `territorio.nombre` pasa de null a `nombre`.
- **Esfuerzo/riesgo:** bajo, join con una dimensión de 72 filas.

### empresas_concursos
- **Modelo:** transform/models/marts/empresas_concursos.sql · **Páginas:** economia/empresas (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod` (`00` junto a comunidades); la serie termina en 2020 (el INE no publica más), no se dice en la tabla.
- **Cambio propuesto:** añadir `nivel` y `nombre`; se mantiene `concursos_100k` y `concursos_1000emp`. Documentar el fin de serie en la ficha, no en columnas.
```sql
case when b.cod='00' then 'pais' else 'ccaa' end as nivel, t.nombre
```
- **Páginas:** conservar `cod`, `anio`, `concursos`, `concursos_100k`, `concursos_1000emp`. Sin cambios.
- **Ficha:** desaparece «solo código».
- **Esfuerzo/riesgo:** bajo.

### empresas_dirce_sector
- **Modelo:** transform/models/marts/empresas_dirce_sector.sql · **Páginas:** economia/empresas (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod`; sin fila total (se suman los 11 sectores; la convención lo admite). Ya trae `por_1000hab` y `pct`.
- **Cambio propuesto:** añadir `nivel` y `nombre`. Opcional: renombrar `por_1000hab` a `por_1000_hab` como columna nueva igual (convención `_por_1000_hab`).
```sql
case when a.cod='00' then 'pais' else 'ccaa' end as nivel, t.nombre, 1000.0*a.empresas/p.poblacion as por_1000_hab
```
- **Páginas:** conservar `cod`, `sector`, `empresas`, `pct`, `por_1000hab`, `anio`.
- **Ficha:** desaparece «solo código».
- **Esfuerzo/riesgo:** bajo.

### empresas_dirce_tamano
- **Modelo:** transform/models/marts/empresas_dirce_tamano.sql · **Páginas:** economia/empresas (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod`; no tiene tasa por habitante (el sector hermano sí); sin fila total (se suman cinco tramos).
- **Cambio propuesto:** añadir `nivel`, `nombre` y `por_1000_hab` (empresas del tramo por 1.000 habitantes, mismo patrón que `empresas_dirce_sector`).
```sql
1000.0 * a.empresas / p.poblacion as por_1000_hab
-- left join pob p on p.cod = a.cod and p.anio = least(a.anio, r.max_anio)
```
- **Páginas:** conservar `cod`, `tamano`, `orden`, `empresas`, `pct`, `anio`.
- **Ficha:** desaparece «sin nombres»; medida nueva `por_1000_hab`.
- **Esfuerzo/riesgo:** bajo.

### empresas_dirce_territorio
- **Modelo:** transform/models/marts/empresas_dirce_territorio.sql · **Páginas:** economia/empresas, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 3
- **Problemas:** ya tiene `nivel`+`cod`+`empresas_1000hab`, pero sin `nombre`; `personas_fisicas + sociedades` no suman `empresas` (faltan otras formas jurídicas) y nada lo dice; `crecimiento` sin sufijo `_pct`.
- **Cambio propuesto:** añadir `nombre`, `otras_formas` (= empresas - personas_fisicas - sociedades) y `crecimiento_pct`; `empresas_1000hab` también como `por_1000_hab` si se quiere uniformar.
```sql
t.empresas - t.personas_fisicas - t.sociedades as otras_formas, crecimiento as crecimiento_pct
```
- **Páginas:** conservar `nivel`, `cod`, `anio`, `empresas`, `empresas_1000hab`, `pct_personas_fisicas`, `crecimiento`. Ya la usa también `empresas_concursos` (dbt), no se rompe.
- **Ficha:** desaparece «personas físicas más sociedades no suman»; se pierde «solo código».
- **Esfuerzo/riesgo:** bajo.

### empresas_id_ccaa
- **Modelo:** transform/models/marts/empresas_id_ccaa.sql · **Páginas:** economia/empresas, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod` (`00` = España mezclado con comunidades); `sector = 'Total'` suma Empresas+AAPP+Universidades+IPSFL, hay que filtrar siempre. Euros reales y por habitante ya existen (`eur_hab_real`, `anio_euros`), así que no se toca nada del principio rector.
- **Cambio propuesto:** añadir `nivel` y `nombre`. Opcional: `es_total_sector` BOOLEAN para que el chat no sume sectores.
```sql
case when n.cod='00' then 'pais' else 'ccaa' end as nivel, t.nombre, t.sectperf = 'TOTAL' as es_total_sector
```
- **Páginas:** conservar todo lo que usan (`cod`, `anio`, `sector`, `pct_pib`, `eur_hab_real`, `investigadores_1000ocup`, `anio_euros`).
- **Ficha:** desaparece «códigos sin nombres».
- **Esfuerzo/riesgo:** bajo.

### empresas_sociedades_anual
- **Modelo:** transform/models/marts/empresas_sociedades_anual.sql · **Páginas:** economia/empresas, territorios/[ccaa]/index (8 traducciones) · **Prioridad:** 3
- **Problemas:** solo falta nombre; ya trae por 100.000 hab y euros reales con `anio_euros` (es el modelo de referencia). `capital_real` y `capital_nominal` van en euros, no en miles (ya documentado).
- **Cambio propuesto:** añadir `nivel` y `nombre`; nada más. Nombres `capital_real` / `capital_nominal` se quedan (renombrar a `_eur_real` costaría 8 páginas por cosmética).
```sql
case when a.cod='00' then 'pais' else 'ccaa' end as nivel, t.nombre
```
- **Páginas:** conservar todas sus columnas; sin cambios.
- **Ficha:** desaparece «códigos sin nombres».
- **Esfuerzo/riesgo:** bajo.

### empresas_sociedades_mensual
- **Modelo:** transform/models/marts/empresas_sociedades_mensual.sql · **Páginas:** economia/empresas (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod` sin nombre; las columnas `_12m` son sumas móviles (no sumar) y nada en el nombre lo avisa. Real y por habitante ya están (`capital_real`, `*_12m_100k`).
- **Cambio propuesto:** añadir `nivel`, `nombre` y `capital_real_12m_hab` (capital 12 meses en euros reales por habitante, para cumplir el principio en la serie móvil).
```sql
case when meses_12 = 12 then capital_real_12m / poblacion end as capital_real_12m_hab
```
- **Páginas:** conservar `fecha`, `anio`, `mes`, `constituidas_12m*`, `disueltas_12m*`. Es dependencia dbt de `empresas_sociedades_anual` (usa `cod`, `anio`, `constituidas`, `disueltas`, `capital_nominal`): no tocarlos.
- **Ficha:** desaparece «códigos sin nombres»; el aviso de sumas móviles se queda en notas.
- **Esfuerzo/riesgo:** bajo.

### empresas_tamano_ue
- **Modelo:** transform/models/marts/empresas_tamano_ue.sql · **Páginas:** economia/empresas (4 traducciones) · **Prioridad:** 3
- **Problemas:** el código de país va en `geo` (convención: `cod_pais`) y el nombre en `pais`; `vab_meur` en euros corrientes sin real ni por habitante. Los `pct_*` son los que usa la página y ya son relativos.
- **Cambio propuesto:** añadir `cod_pais` (= geo) y `vab_meur_real` con el deflactor (la tabla es de 2021-2024); el por habitante necesitaría población de cada país, que existe en `raw_industria.eurostat_industria_poblacion` solo para los países que ya están en la UE-27, así que se puede para los 10 países pero no para `EU27_2020` como fila agregada sin sumarla (hay `EU27_2020` en esa tabla: sirve).
```sql
a.geo as cod_pais, a.vab_meur * d.factor as vab_meur_real, a.vab_meur * 1e6 / (p.miles*1000) as vab_eur_hab
```
- **Páginas:** conservar `geo`, `pais`, `tamano`, `orden`, `pct_empresas`, `pct_empleo`, `pct_vab`, `anio`.
- **Ficha:** `territorio.codigo` pasa de `geo` a `cod_pais`.
- **Esfuerzo/riesgo:** bajo, un join por país y año.

### gobierno_presupuestos
- **Modelo:** transform/models/marts/gobierno_presupuestos.sql · **Páginas:** transparencia/presupuestos (4 traducciones) · **Prioridad:** 3
- **Problemas:** el tiempo se llama `ejercicio` (convención `anio`); el ejercicio en curso está abierto (`Prorrogado (en curso)`) y `dias_prorroga` crece hasta hoy, sin `es_parcial`; no tiene euros ni habitantes (es de calendario, el principio no aplica).
- **Cambio propuesto:** añadir `anio` (= ejercicio) y `es_parcial` (= en_curso, ya existe como `en_curso`; aliasar). Mantener `ejercicio`, `en_plazo` y `en_curso`.
```sql
b.ejercicio as anio, b.en_curso as es_parcial
```
- **Páginas:** conservar `ejercicio`, `situacion`, `en_plazo`, `en_curso`, `dias_prorroga`, `presidente_responsable`, `partido_responsable`, `presidente_1_enero`, `url_html`. Sin cambios.
- **Ficha:** `tiempo.columna` pasa de `ejercicio` a `anio`.
- **Esfuerzo/riesgo:** bajo.

### industria_ccaa_ramas
- **Modelo:** transform/models/marts/industria_ccaa_ramas.sql · **Páginas:** economia/industria (4 traducciones) · **Prioridad:** 3
- **Problemas:** `ccaa` con formato INE («Madrid, Comunidad de», «Rioja, La»); mezcla ramas agregadas y finas (ya trae `es_agregado`); sin fila de España (correcto: la suma de comunidades con secreto no es el total); por habitante y real ya existen (`cifra_negocios_hab_real`).
- **Cambio propuesto:** cambiar el valor de `ccaa` por el nombre de `territorios` (ninguna página lo lee, todas hacen el join con `cod_ccaa`) y mantener el resto.
```sql
t.nombre as ccaa
-- left join {{ ref('territorios') }} t on t.nivel = 'ccaa' and t.cod = c.cod_ccaa
```
- **Páginas:** conservar `cod_ccaa`, `rama`, `es_agregado`, `anio`, `cuota_espana_pct`, `peso_en_industria_ccaa_pct`, `veces_peso_poblacion`, `puesto_en_espana`, `n_ccaa_con_dato`. Sin cambios.
- **Ficha:** desaparece «nombres con formato INE».
- **Esfuerzo/riesgo:** bajo.

### industria_ipi_mensual
- **Modelo:** transform/models/marts/industria_ipi_mensual.sql · **Páginas:** economia/industria (4 traducciones) · **Prioridad:** 3
- **Problemas:** `cod_ccaa` con `00` = España (mejor `nivel`/`cod`); `nombre` con formato INE («Madrid, Comunidad de»); `mes` en lugar de `fecha` y sin `anio`; destinos de bienes de consumo anidados (duradero/no duradero dentro de consumo) sin marca.
- **Cambio propuesto:** añadir `nivel`, `cod`, `fecha`, `anio`, `es_subdestino` BOOLEAN y cambiar `nombre` por el de territorios (la página no lo usa).
```sql
case when c.cod_ccaa='00' then 'pais' else 'ccaa' end as nivel, c.cod_ccaa as cod,
mes as fecha, cast(year(mes) as integer) as anio,
destino in ('Bienes de consumo duradero','Bienes de consumo no duradero') as es_subdestino
```
- **Páginas:** conservar `cod_ccaa`, `destino`, `mes`, `indice`, `variacion_anual_pct`, `variacion_acumulada_pct`, `es_ultimo_mes`.
- **Ficha:** desaparece «nombres con formato INE»; tiempo `fecha`.
- **Esfuerzo/riesgo:** bajo.

### industria_ramas_ue
- **Modelo:** transform/models/marts/industria_ramas_ue.sql · **Páginas:** economia/industria (4 traducciones) · **Prioridad:** 3
- **Problemas:** ya trae euros reales (`cifra_negocios_es_real_meur`, `anio_base`) y cuotas sobre UE; falta el equivalente por habitante (principio rector) y el nivel de la rama está en texto (`nivel`: seccion/division/grupo/clase, ya existe); la nota de «UE parcial» solo en `nota`.
- **Cambio propuesto:** añadir `cifra_negocios_es_real_eur_hab` (población de `poblacion_territorios`, España) y `ue_es_parcial` BOOLEAN (= `nota is not null`).
```sql
cifra_negocios_es_real_meur * 1e6 / p.poblacion as cifra_negocios_es_real_eur_hab, nota is not null as ue_es_parcial
```
- **Páginas:** conservar `rama`, `rama_nombre`, `nivel`, `cuota_cifra_negocios_pct`, `puesto_cifra_negocios`, `lider_cifra_negocios_nombre`, `veces_peso_poblacion`, `cifra_negocios_es_real_meur`, `peso_manuf_*`, `indice_especializacion`, `cuota_poblacion_pct`, `nota`, `es_ultimo_anio`. Sin cambios obligatorios.
- **Ficha:** medida principal pasa a euros reales por habitante.
- **Esfuerzo/riesgo:** bajo.

### inmigracion_flujos
- **Modelo:** transform/models/marts/inmigracion_flujos.sql · **Páginas:** ninguna en castellano (0 traducciones; solo la ficha y `schema_migracion.yml`; `metricas_sociedad` usa la tabla hermana `inmigracion_flujos_anuales`) · **Prioridad:** 3
- **Problemas:** ninguna página ni componente la usa y solo cubre 18 nacionalidades principales (no suman el total) y 3,5 años (175 filas); último trimestre incompleto sin marca; `trimestre` en vez de `fecha`/`anio`. No la propongo borrar: es la única serie trimestral por nacionalidad.
- **Cambio propuesto:** añadir `fecha` (= trimestre), `anio` y `es_parcial` (último trimestre). Ya trae `*_1000` por habitante.
```sql
trimestre as fecha, cast(year(trimestre) as integer) as anio, trimestre = max(trimestre) over () as es_parcial
```
- **Páginas:** ninguna usa la tabla; sin riesgo para páginas.
- **Ficha:** `tiempo.columna` pasa a `fecha`; `parcial` se apoya en `es_parcial`.
- **Esfuerzo/riesgo:** bajo.

### inmigracion_saldos
- **Modelo:** transform/models/marts/inmigracion_saldos.sql · **Páginas:** sociedad/inmigracion (4 traducciones) · **Prioridad:** 3
- **Problemas:** solo `cod`; `nacionalidad` mezcla países, grupos continentales y Española/Extranjera/Total (ya hay `es_grupo`); a nivel comunidad solo existen Total/Española/Extranjera; solo 2021-2024. Ya trae `saldo_1000` (por habitante).
- **Cambio propuesto:** añadir `nombre` (territorios; en `nivel = 'pais'` es España) y `cod_pais` solo si se acepta un mapa nacionalidad→ISO (no hay seed para los nombres INE; si no, no se propone). Dependencias dbt: `demografia_anual`, `mapas_personas`.
```sql
t.nombre  -- left join territorios t on t.nivel = case t.nivel when 'pais' ... end
```
- **Páginas:** conservar `nivel`, `cod`, `anio`, `nacionalidad`, `es_grupo`, `saldo_exterior`, `saldo_1000`. Sin cambios.
- **Ficha:** desaparece «solo código».
- **Esfuerzo/riesgo:** bajo; el mapa a ISO sería esfuerzo medio y no lo recomiendo ahora.

---

## Resumen del lote

Prioridad 1: 3 (`empleo_salarios_deciles`, `energia_emisiones_gei`, `inmigracion_poblacion`).
Prioridad 2: 9 (`empleo_salarios_ccaa`, `empresas_autonomos`, `energia_mix_electrico`, `energia_potencia_instalada`, `energia_resumen_anual_mix`, `gobierno_indultos_mensual`, `industria_exportaciones_ue`, `industria_ipi`, `inmigracion_nacionalizaciones`).
Prioridad 3: 15 (`empleo_territorio`, `empresas_concursos`, `empresas_dirce_sector`, `empresas_dirce_tamano`, `empresas_dirce_territorio`, `empresas_id_ccaa`, `empresas_sociedades_anual`, `empresas_sociedades_mensual`, `empresas_tamano_ue`, `gobierno_presupuestos`, `industria_ccaa_ramas`, `industria_ipi_mensual`, `industria_ramas_ue`, `inmigracion_flujos`, `inmigracion_saldos`).
Dejar como está (—): 3 (`gobierno_decretos_ley`, `gobierno_presidencias_resumen`, `gobiernos_presidentes`).
Borrar: 0.

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

### movilidad_modelos_mensual
- **Modelo:** transform/models/marts/movilidad_modelos_mensual.sql · **Páginas:** `movilidad/marcas-y-modelos.md` (4 traducciones) · **Prioridad:** 3
- **Problemas:** mismos códigos sin etiqueta que `movilidad_marcas_mensual`; el mismo coche con nombres distintos (`LEON` y `LEON SP`); solo 36 meses; sin `anio`.
- **Cambio propuesto:** añadir `grupo_etiqueta`, `energia_etiqueta`, `canal_etiqueta` y `anio` (como en marcas). La normalización de modelo (`modelo_base`) queda fuera: no hay reglas fiables y sería inventar; documentarlo en la ficha.
- **Páginas:** conservar `mes`, `grupo`, `energia`, `canal`, `marca`, `grupo_empresarial`, `modelo`, `matriculaciones`.
- **Ficha:** se elimina la explicación de códigos; se mantiene el aviso de variantes de nombre.
- **Esfuerzo/riesgo:** bajo.

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

## Dejar como están (30)

### alcaldes_historia
- **Modelo:** transform/models/marts/alcaldes_historia.sql (export acotado en sources/mother/alcaldes_historia.sql, mandatos >= 2007) · **Páginas:** territorios/municipios, medios/buscador (8 traducciones) · **Prioridad:** —
- **Problemas:** ninguno de datos; la ficha ya la marca `usar: false` (listado sin cifra) y es correcto. `es_actual` solapa con `alcaldes_actuales`, pero lo usa la página.
- **Cambio propuesto:** no tocarla. Es una tabla de listado con territorio ya en `cod_mun` + `municipio`, fechas ISO y booleanos BOOLEAN; cumple las convenciones.
- **Páginas:** conservar `cod_mun, mandato, alcalde, cargo, fecha_posesion, familia, color`.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** nulo.

### calor_espana_diario
- **Modelo:** transform/models/marts/calor_espana_diario.sql · **Páginas:** energia-clima/calor (4 traducciones) · **Prioridad:** —
- **Problemas:** ninguno real; tabla nacional por día con `fecha` + `anio`, grados con unidad clara; los recuentos por día no se suman y la nota basta.
- **Cambio propuesto:** no tocarla.
- **Páginas:** conservar `fecha, anomalia_tmax_media, n_provincias_por_encima, ...` (usa `SELECT *`).
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** nulo.

### construccion_afiliados
- **Modelo:** transform/models/marts/construccion_afiliados.sql · **Páginas:** economia/construccion (4 traducciones) · **Prioridad:** —
- **Problemas:** ninguno de fondo. Ya cumple las convenciones (`nivel`, `cod`, `nombre`, `fecha`, `anio`, `afiliados_constr_1000hab`, España como `pais`/`00`); la ficha solo avisa de no sumar niveles (inherente) y del cambio de CNAE.
- **Cambio propuesto:** no tocarla.
- **Páginas:** conservar todas las columnas.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** nulo.

### deflactor
- **Modelo:** transform/models/marts/deflactor.sql · **Páginas:** 10 páginas de cuentas-publicas, economía, territorios y transparencia (40 traducciones) · **Prioridad:** —
- **Problemas:** la ficha lo marca `usar: false` ("auxiliar"); es correcto, es una de las dos tablas de referencia permitidas (`territorios`, `deflactor`). Año en curso con `meses` < 12 (2026 con 8 meses).
- **Cambio propuesto:** no tocarla ni borrarla: la usan 10 páginas, 7 marts y las tablas nuevas de este plan. Opcional: `meses < 12 as es_parcial` para cumplir la convención de año incompleto; no hace falta.
- **Páginas:** conservar `anio`, `ipc_medio`, `meses`, `anio_base`, `factor`.
- **Ficha:** ninguna; sigue `usar: false` a propósito, y el chat debe consumir las columnas `_real` de cada tabla, no el deflactor.
- **Esfuerzo/riesgo:** ninguno.

### diputados_inmuebles_resumen
- **Modelo:** transform/models/marts/diputados_inmuebles_resumen.sql · **Páginas:** varios/diputados-caseros (4 traducciones) · **Prioridad:** —
- **Problemas:** una fila por definición de "casero" con los totales repetidos (`t.*`); las definiciones se solapan; sin territorio ni año (el ejercicio de rentas va en `ejercicio_rentas`). No son problemas del modelo, son del dato.
- **Cambio propuesto:** no tocarla: ya es una tabla de resumen con `definicion_id` + `definicion` legibles, `pct` en 0-100 y sin euros que deflactar. Quizá en el futuro `anio = ejercicio_rentas` si se cruza con otras tablas, no ahora.
- **Páginas:** conservar `definicion_id`, `definicion`, `n_cumplen`, `pct`, `n_validos`, `n_diputados`.
- **Ficha:** se mantiene la advertencia de solapamiento y la de elegir definición.
- **Esfuerzo/riesgo:** ninguno.

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

### gobierno_decretos_ley
- **Modelo:** transform/models/marts/gobierno_decretos_ley.sql · **Páginas:** transparencia/decretos-ley (4 traducciones) · **Prioridad:** —
- **Problemas:** ninguno de datos: es una lista de decretos uno por uno (fecha, presidente, familia, estado, enlace) que la página enseña tal cual y de la que cuelga `gobierno_presidencias_resumen` (`rdl_derogados`). La ficha dice `usar: false`, pero podría contestar «cuántos decretos derogó Sánchez».
- **Cambio propuesto:** no tocar el modelo. Sí cambiar la ficha a `usar: true` con tiempo `fecha_disposicion`, dimensiones `estado`, `presidente`, `familia`, y la cifra principal como recuento (sin columna numérica, así que hay que decidir si el chat acepta tablas de eventos).
- **Páginas:** conservar todas las columnas (`numero_oficial`, `estado`, `presidente`, `familia`, `titulo`, `url_html`).
- **Ficha:** `usar` de false a true (decisión del dueño).
- **Esfuerzo/riesgo:** bajo, sin tocar dbt; el riesgo es de chat (contar filas).

### gobierno_presidencias_resumen
- **Modelo:** transform/models/marts/gobierno_presidencias_resumen.sql · **Páginas:** transparencia/decretos-ley, indultos (8 traducciones) · **Prioridad:** —
- **Problemas:** diez filas, 7 presidentes y 3 partidos en la misma columna `grupo` distinguidas por `nivel`: no sumar niveles (ya lo cumple `nivel`); sin periodo (agregado de toda la democracia). Formato correcto para una tabla de ranking.
- **Cambio propuesto:** dejar como está. Es ya una tabla «dimensión + medidas por año gobernado» que cumple la convención de `nivel`. Solo añadir a la ficha que `rdl_por_anio` es lo comparable (ya en notas).
- **Páginas:** conservar `nivel`, `grupo`, `familia`, `orden`, `anios`, `rdl*`, `leyes*`, `indultos*`.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** bajo (cero).

### gobiernos_presidentes
- **Modelo:** transform/seeds/gobiernos_presidentes.csv (seed; `column_types` ya con `desde`/`hasta` DATE) · **Páginas:** transparencia/comparacion-internacional, varios/observatorios (8 traducciones) · **Prioridad:** —
- **Problemas:** ninguno. Es una tabla de referencia (presidentes estatales y autonómicos con fechas y familia política) de la que cuelgan al menos 12 modelos (medios, construcción, vivienda, observatorios, transparencia). La convención solo nombra `territorios` y `deflactor` como referencia; esta es la tercera.
- **Cambio propuesto:** no tocar ni borrar. Añadir `gobiernos_presidentes` a la lista de tablas de referencia de CONVENCIONES.md y dejar la ficha como `usar: false` (o `true` para «quién presidía X en tal año»). Para el nivel autonómico, `cod` ya es INE (01-19); el nombre de comunidad se saca con territorios.
- **Páginas:** conservar `nivel`, `cod`, `desde`, `hasta`, `presidente`, `familia`.
- **Ficha:** sin cambios.
- **Esfuerzo/riesgo:** bajo (cero).

### mapas_indicadores
- **Modelo:** transform/models/marts/mapas_indicadores.sql (une `mapas_personas` y `mapas_territorio`) · **Páginas:** `varios/mapas.md` (4 traducciones) · **Prioridad:** —
- **Problemas:** 151.206 filas y 257 indicadores con unidad y sentido propios (ya tiene `unidad` y `sentido` en cada fila); repite datos de las tablas temáticas; es la tabla que alimenta el explorador de mapas.
- **Cambio propuesto:** no tocarla (es una tabla de presentación; cambiarla rompe el explorador y sus 4 copias). Marcarla como auxiliar: campo `auxiliar: true` en la ficha para que `catalogo.mjs` la excluya del chat (el chat ya debe preferir la tabla del tema). Decisión del owner: si se quiere cumplir al pie de la letra «sin tablas auxiliares en mother», se movería a un esquema aparte (`web.*`), con cambio de `sources/mother/mapas_indicadores.sql` a `sources/web/` y de la página y sus 4 copias; no lo recomiendo ahora.
- **Páginas:** sin cambios.
- **Ficha:** se mantiene como auxiliar y se oculta; no se corrige nada dentro.
- **Esfuerzo/riesgo:** bajo si solo se marca; alto si se mueve de esquema.

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

### mercado_energia_ipc
- **Modelo:** transform/models/marts/mercado_energia_ipc.sql · **Páginas:** `economia/ipc.md` (4 traducciones) · **Prioridad:** —
- **Problemas:** solo la trampa de la ficha (tasas no se suman); `mes` DATE primer día de mes sirve como `fecha`; las unidades por columna son claras (`indice`, `var_anual` en %, `indice_2019`, `ponderacion` por mil, `contribucion_aprox` en puntos).
- **Cambio propuesto:** no tocarla. Decisión transversal del owner: declarar en CONVENCIONES que `mes`, `trimestre` y `semana` (DATE de inicio del periodo) valen como `fecha` y que `var_*` es % aunque no lleve `_pct`.
- **Páginas:** sin cambios.
- **Ficha:** se mantiene, añadiendo `unidad_columna` para `var_anual` (%) y `ponderacion` (por mil).
- **Esfuerzo/riesgo:** bajo (solo ficha y convención).

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

### movilidad_matriculaciones_mensual
- **Modelo:** transform/models/marts/movilidad_matriculaciones_mensual.sql · **Páginas:** `index.md`, `movilidad/camiones-y-autobuses.md`, `coche-electrico.md`, `flotas-e-impuestos.md`, `index.md`, `marcas-y-modelos.md`, `parque.md` (28 traducciones) · **Prioridad:** —
- **Problemas:** el filtro `nuevo_usado = 'N'` y la ausencia de fila de total son reales (dimensión que no se mezcla) y todas las páginas ya lo gestionan; ya trae etiquetas, orden y color; falta `anio` pero `mes` sirve.
- **Cambio propuesto:** no tocar. Partirla en nuevos/usados rompería 7 páginas y 28 copias por un beneficio pequeño. Documentar `defecto: nuevo_usado = 'N'` en la ficha.
- **Páginas:** sin cambios.
- **Ficha:** se queda como `defecto` explícito (con cuándo usar `U`).
- **Esfuerzo/riesgo:** bajo (solo ficha).

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

### territorios
- **Modelo:** transform/models/marts/territorios.sql · **Páginas:** 35 páginas (140 traducciones) y `src/lib/chat/decision.js` · **Prioridad:** — (dejar como está)
- **Problemas:** ninguno de datos. Es la dimensión de referencia (nivel, cod, cod_ccaa, cod_ccaa_hacienda, nombre, slug, ruta, poblacion_ultima). La ficha ya dice `usar: false`.
- **Cambio propuesto:** no tocarla. Solo cuando llegue la fase de municipios del plan de territorios se le añadirán las filas de nivel `municipio`; no es parte de esta limpieza.
- **Páginas:** todas dependen de ella; cualquier cambio de columnas rompe 140 copias.
- **Ficha:** sin cambios (no usable por diseño).
- **Esfuerzo/riesgo:** ninguno.

### vivienda_alquiler
- **Modelo:** transform/models/marts/vivienda_alquiler.sql · **Páginas:** pages/territorios/[ccaa]/index.md, [provincia].md, pages/vivienda/alquiler.md, pages/vivienda/index.md (16 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** ya tiene euros reales, `nivel/cod/nombre` y por 1.000 hab (`alquiladas_1000`). Dos filas por territorio y año (`tipologia` Colectiva/Unifamiliar, 14 años en España, 243 en CCAA, 681 en provincias cada una), y la ficha las filtra con `tipologia='Colectiva'`.
- **Cambio propuesto:** no tocar. `tipologia` es una dimensión legítima con valor por defecto; no vale la pena crear una tabla por tipología porque las páginas filtran por ella. Si molesta, solo mover el filtro de la ficha al campo `defecto`.
- **Páginas:** todas las columnas actuales; ninguna cambia.
- **Ficha:** el filtro fijo `tipologia=Colectiva` pasa a `defecto` de la dimensión (un cambio solo de ficha).
- **Esfuerzo/riesgo:** ninguno (solo ficha).

### vivienda_ipv
- **Modelo:** transform/models/marts/vivienda_ipv.sql · **Páginas:** pages/vivienda/precios.md (4 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** ninguno de fondo: índice base 2015=100 con `indice` y `indice_real`, `interanual_*`, `nivel/cod/nombre`. Tres tipos (General 1.520 filas, Nueva y Segunda mano 1.368 cada una) y la ficha usa `tipo='General'` como total.
- **Cambio propuesto:** no tocar. `tipo` es una dimensión con total `General`, que es exactamente lo que CONVENCIONES permite (`Total` o equivalente legible).
- **Páginas:** todas las columnas actuales.
- **Ficha:** el filtro fijo `tipo=General` pasa a `total: General` en la dimensión (solo ficha).
- **Esfuerzo/riesgo:** ninguno.

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

### vivienda_resumen_territorios
- **Modelo:** transform/models/marts/vivienda_resumen_territorios.sql · **Páginas:** pages/territorios/[ccaa]/index.md, [provincia].md, pages/vivienda/alquiler.md, compraventas.md, index.md, precios.md (24 traducciones) · **Prioridad:** — (dejar como está)
- **Problemas:** es una "foto" derivada que reúne la última cifra de precio, alquiler, mercado, obra y esfuerzo (72 filas, cada indicador con su fecha: `precio_periodo`, `alquiler_anio`, `mercado_fecha`, `obra_anio`, `esfuerzo_anio`). Choca con "sin tablas duplicadas o auxiliares", pero seis páginas (24 copias) dependen de ella para dibujar los mapas y rankings en una sola consulta; todo está ya en reales o por 1.000 hab.
- **Cambio propuesto:** no tocar. Cuando el modelo de `vivienda_esfuerzo` tenga las columnas `_real` (ver arriba), no hará falta añadirlas aquí (solo `anios_salario`, `pct_alquiler`, que ya están).
- **Páginas:** todas las columnas actuales (24 copias).
- **Ficha:** sin cambios; la ficha ya avisa de que es solo foto del último dato y remite a las tablas con serie.
- **Esfuerzo/riesgo:** ninguno.
