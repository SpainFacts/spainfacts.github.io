# Índice SpainFacts de publicidad activa y remisión de información

**Elaboración propia.** Casi ningún órgano de control publica, entidad por entidad, si cada administración cumple sus obligaciones de transparencia. Por eso SpainFacts mide por su cuenta a todos los ayuntamientos, diputaciones, cabildos y consells insulares y comunidades autónomas. Usa solo registros oficiales que traen fecha y comprueba si cada obligación se cumplió y cuándo, frente a su plazo legal.

Todo el cálculo es código abierto y se puede repetir: ingesta en `ingestion/`, modelos en `transform/models/marts/pa_ind_*.sql` y `transparencia_cumplimiento*.sql`, y la ficha de cada indicador en este directorio.

## Qué se mide

Una fila por **entidad, obligación y periodo** (`transparencia_cumplimiento`). Cada indicador tiene su ficha con la base legal, la fuente y las trampas:

| Indicador | Ficha |
|---|---|
| Liquidación del presupuesto, presupuesto y líneas fundamentales remitidos a Hacienda, PMP comunicado cada trimestre, Cuenta General, control interno y relación de contratos al Tribunal de Cuentas | este documento y los modelos `transparencia_liquidaciones`, `transparencia_pie`, `transparencia_pmp` y `transparencia_tcu` |
| Subvenciones registradas en la BDNS a tiempo | [bdns.md](bdns.md) |
| Contratos publicados en el perfil del contratante a tiempo | [contratos.md](contratos.md) |
| Retribuciones de los cargos electos remitidas al ISPA, presupuesto prorrogado, PMP de las comunidades y leyes de presupuestos autonómicas | fichas propias en este directorio |
| Revisión automática de los portales de transparencia | [robot-portales.md](robot-portales.md) |

El seed `transform/seeds/elaboracion_propia_indicadores.csv` resume los criterios de cada indicador, y de ahí lee la web.

## Estados y puntuación

| Estado | Significado | Puntuación |
|---|---|---|
| `en_plazo` | Consta y dentro de plazo | 1 |
| `consta` | Consta, pero la fuente no da la fecha | 1 |
| `fuera_plazo` | Consta, después del plazo | 0,5 |
| `no_consta` | El plazo venció y no consta en la fuente oficial | 0 |
| `con_registros` | Obligaciones con muchos elementos (subvenciones, contratos, trimestres) | 1 − elementos fuera de plazo / elementos |
| `sin_registros` | No hay ningún elemento: puede que no conceda subvenciones o que contrate otra administración por ella | No puntúa (se informa aparte) |
| `no_vencido` | El plazo aún no ha vencido | No puntúa |
| `no_aplica` | La fuente no mide a esa entidad (régimen foral, plataforma propia…) | No puntúa |

**Índice de la entidad (0-100)** = 100 × la media de la puntuación del **último periodo medido** de cada obligación. Solo se calcula con 3 o más obligaciones medidas. Todas las obligaciones pesan lo mismo, porque la ley no prioriza unas sobre otras.

**Cobertura mínima.** Una obligación solo entra en el índice cuando mide al menos al 80 % de las entidades de su tipo. Si no, el índice premiaría o castigaría según dónde haya datos (por ejemplo, mientras el rastreo del Tribunal de Cuentas no esté completo). Por la misma razón, hasta entonces sus incumplimientos tampoco se destacan, aunque se ven en la ficha de cada entidad.

**Incumplimiento destacado.** El último periodo de una obligación figura como `no_consta` y su plazo venció hace más de 3 meses. Es lo que se señala en rojo en la ficha de la entidad.

## Reglas comunes

- **Universo completo.** Entran todas las entidades del tipo existentes ese año, no solo las que aparecen en la fuente. Quien no aparece figura como «no consta», salvo que la fuente no lo mida.
- **Régimen foral.** Álava (01), Gipuzkoa (20), Bizkaia (48) y Navarra (31) remiten muchas obligaciones por su propio cauce (diputación foral, Gobierno de Navarra, órgano de control propio). Antes de dar por bueno un indicador se comprueba su cobertura en cada uno de estos territorios. Si el hueco se debe al cauce, `no_aplica`.
- **Plataformas propias.** Cataluña, País Vasco y Navarra no publican sus contratos en la Plataforma de Contratación del Estado. Se usa su plataforma o se excluyen, y se dice.
- **Atribución.** El incumplimiento se atribuye al gobierno en funciones **el día del plazo** (alcalde, según el registro del Ministerio de Política Territorial; presidente autonómico), no al actual.
- **Comparación justa.** Cada entidad se compara con las de su tipo y su tramo de población, en España y en su provincia. Las comparaciones por partido se ajustan por tamaño y comunidad, con intervalo de confianza.
- **Redacción.** Siempre factual: «no consta en [fuente] a [fecha]». Puede haberse remitido por otro cauce o tarde, y la fuente puede tener errores.
- **Año en curso.** Está incompleto: o no vence o se etiqueta «(incompleto)».

## Limitaciones

- Medimos lo que consta **en los registros oficiales**, no si la información es veraz o completa.
- Algunas fuentes no dan la fecha de remisión (liquidación, control interno, relación de contratos al Tribunal de Cuentas): solo se sabe si consta.
- La retención de la participación en los tributos es mensual, así que su retraso es aproximado (meses × 30).
- Si ves un error en una entidad, [abre una incidencia](https://github.com/SpainFacts/spainfacts.github.io/issues) con el enlace a la fuente: lo corregimos y lo anotamos.
