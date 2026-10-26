# Ley de presupuestos autonómica aprobada a tiempo

**Elaboración propia.** Indicador `ley_presupuestos_ccaa` del índice de publicidad activa y remisión de información.

## Qué se mide

Si cada comunidad autónoma tiene su **ley de presupuestos del ejercicio aprobada antes del 1 de enero** y, si no, con cuántos días de retraso llegó o si el año entero funcionó con el presupuesto **prorrogado** del anterior. Ejercicios 2000 → año en curso.

## Base legal

Cada estatuto de autonomía y cada ley de hacienda autonómica fija que, si la ley de presupuestos no se aprueba antes del primer día del ejercicio, se prorrogan automáticamente los del anterior (por ejemplo, art. 56.4 del Estatuto de La Rioja). Es el mismo esquema que el art. 134.4 de la Constitución para el Estado.

## Fuente

1. **Sumarios diarios del BOE**, sección I, departamentos autonómicos (API de datos abiertos, `https://www.boe.es/datosabiertos/api/boe/sumario/AAAAMMDD`), con la misma descarga que `ingestion/transparencia_gobierno.py`, cuyas funciones se reutilizan. Se leen desde el 1-sep-1999 (unos 9.800 días, 20 minutos con 4 hilos). Se guardan **todas** las leyes autonómicas de la sección I (5.296), no solo las de presupuestos, para poder revisar el criterio.
2. Para las que llevan «presupuest» en el título, el **documento** del BOE (`https://www.boe.es/diario_boe/xml.php?id=BOE-A-…`): fecha de la disposición, entrada en vigor y la nota «Publicada en el "Boletín Oficial de…" número N, de D de MES de AAAA».
3. **Comprobación manual** (tablas `leyes_manual` y `prorrogas_verificadas` del modelo) de los ejercicios sin ley en el BOE, con la norma de prórroga en el diario autonómico o una fuente oficial equivalente. Revisión del 25-oct-2026.

## Cómo se calcula

**Ley de presupuestos del ejercicio**: título «Ley [Foral] [del Principado de Asturias] N/AAAA, de D de MES, de / del / por la que se aprueban [los] Presupuesto(s) [Generales] … para [el] [año | ejercicio] AAAA», que no sea una modificación, un crédito extraordinario o suplemento, una ley de medidas o de acompañamiento, una liquidación ni el presupuesto de un organismo. Si el título no dice el año (Cantabria, Ley 8/2001), se toma el siguiente al de la ley si es de octubre a diciembre. Si hubiera dos, la primera.

**Fecha que cuenta: la de la ley** (fecha de sanción y promulgación, la del título; `fecha_disposicion` en el BOE).
- Es la más cercana a la **aprobación**, que es lo que piden los estatutos («si no se aprobara antes del primer día del ejercicio»).
- Es homogénea entre comunidades.
- La publicación en el diario autonómico va en `x_fecha_publicacion_diario`. Suele ser 1-8 días después (mediana 3), y la ingesta la encuentra en 377 de las 419 leyes. **En ningún ejercicio cambia el estado**: de las 377 con fecha de publicación, no hay ninguna fechada antes del 1 de enero y publicada en el diario autonómico el 1 de enero o después.
- La del BOE no se usa (llega semanas o meses después; las leyes vascas de los años 80 a 2000 se republicaron en 2011-2012).

| Estado | Regla |
|---|---|
| `en_plazo` | ley fechada el 31 de diciembre o antes; `dias_retraso` = 0 |
| `fuera_plazo` | ley fechada el 1 de enero o después; `dias_retraso` = fecha de la ley − 1 de enero |
| `no_consta` | ninguna ley de presupuestos del ejercicio: **prorrogado todo el año**, con la prórroga comprobada (`x_evidencia_prorroga`) |
| `no_vencido` | ejercicios cuyo plazo (31 de diciembre anterior) no ha pasado |
| `no_aplica` | Ceuta y Melilla (su presupuesto lo aprueba el Pleno de la Asamblea, no es una ley) y ejercicios vencidos sin ley cuya prórroga **aún no se ha comprobado** |

En el año en curso, una comunidad que sigue prorrogada puede aprobar su ley más tarde: entonces pasa a `fuera_plazo`. Como el BOE republica con semanas de retraso, una ley reciente puede faltar: se añade a `leyes_manual` (Cataluña 2026, Ley 10/2026, de 9 de julio, aún no está en el BOE).

## Validaciones

**Casos conocidos** (todos coinciden):

| Comunidad y ejercicio | Resultado |
|---|---|
| Andalucía 2025 | Ley 7/2024, de 23 de diciembre (BOJA 251, 30-12-2024) → en plazo |
| Andalucía 2019 | Ley 3/2019, de 22 de julio → 202 días |
| Cataluña 2020 | Ley 4/2020, de 29 de abril → 119 días |
| Cataluña 2023 | Ley 2/2023, de 16 de marzo → 74 días |
| C. de Madrid 2024 | Ley 15/2023, de 27 de diciembre → en plazo |
| C. de Madrid 2017 | Ley 6/2017, de 11 de mayo → 130 días |
| C. Valenciana 2025 | Ley 6/2025, de 30 de mayo → 149 días |
| País Vasco 2017 | Ley 2/2017, de 11 de abril → 100 días |
| Navarra 2024 | Ley Foral 2/2024, de 13 de marzo → 72 días |
| Extremadura 2026 | Ley 2/2026, de 3 de agosto (DOE 149, 4-8-2026) → 214 días |
| Asturias 2026 | «Ley del Principado de Asturias 5/2025, de 31 de diciembre» → en plazo (obligó a ampliar el patrón del título) |

**Ejercicios sin ley en el BOE.** Hay 47; se revisaron todos en fuentes oficiales:
- **7 tenían ley que el BOE no republicó en la sección I**: Aragón 2006 (Ley 12/2005, de 30 de diciembre, BOA 31-12-2005), Cataluña 2017 (Ley 4/2017, de 28 de marzo, DOGC 7340), Cataluña 2026 (Ley 10/2026, de 9 de julio), Murcia 2001 (Ley 6/2000), 2002 (Ley 8/2001), 2003 (Ley 14/2002) y 2005 (Ley 10/2004).
- **40 fueron prórrogas**, con su norma o evidencia oficial en el modelo: Andalucía 2022; Aragón 2019, 2025 y 2026; Asturias 2008, 2012, 2014, 2016 y 2018; Baleares 2011 y 2026; Castilla y León 2019, 2020, 2022, 2025 y 2026; Castilla-La Mancha 2019; Cataluña 2013, 2016, 2018, 2019, 2021, 2024 y 2025; Extremadura 2025; Madrid 2020, 2021 y 2023; Murcia 2026; Navarra 2002, 2003, 2013, 2014 y 2015; País Vasco 2001, 2002, 2004, 2013 y 2019; La Rioja 2019.
- Evidencia más débil: Navarra 2003, 2013 y 2014 (documentos del Parlamento de Navarra, no una norma del BON) y Madrid 2020 (decreto citado por una orden posterior del BOCM).

**Trampas de títulos** que el patrón descarta: País Vasco 2002, Ley 1/2002 «relativa a los presupuestos generales», que el TC dijo que no es la ley de presupuestos y anuló (STC 3/2003); leyes de «medidas presupuestarias urgentes» (País Vasco 2019, La Rioja 2019); «autorizaciones financieras durante la prórroga» (Baleares 2011); liquidaciones y presupuestos de organismos (EITB).

## Cifras de control

| Ejercicio | En plazo | Fuera de plazo | Prorrogado | Mediana del retraso (días) |
|---|---|---|---|---|
| 2017 | 6 | 11 | 0 | 89 |
| 2019 | 9 | 2 | 6 | 112 |
| 2021 | 9 | 6 | 2 | 37 |
| 2023 | 15 | 1 | 1 | 74 |
| 2024 | 13 | 3 | 1 | 72 |
| 2025 | 10 | 3 | 4 | 203 |
| 2026 | 9 | 4 | 4 | 196 |

En 2017 se retrasaron casi todas porque el Estado fijó tarde los objetivos de déficit, tras un 2016 con el Gobierno en funciones. Conviene decirlo en la página.

## Limitaciones

- Se mide la fecha de la ley, no la votación final en el parlamento autonómico (suele ser 1-10 días antes).
- Para años futuros, la lista de prórrogas comprobadas hay que mantenerla a mano: un ejercicio vencido sin ley y sin comprobar sale `no_aplica` con su motivo, y no como incumplimiento.

## Código

- Ingesta: `ingestion/pa_registros.py`, recurso `boe_leyes_ccaa` (source `pa_registros`, merge por identificador; caché en `data/boe_cache/ccaa/AAAA.json` y `data/boe_cache/ccaa_docs/`). Para releer un tramo: `python -m ingestion.pa_registros boe_leyes_ccaa desde=AAAA-MM-DD`.
- Modelo: `transform/models/marts/pa_ind_presupuestos_ccaa.sql` (con `leyes_manual` y `prorrogas_verificadas`); pruebas en `schema_pa_registros.yml`.
