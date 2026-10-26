# Presupuesto prorrogado (entidades locales)

**Elaboración propia.** Indicador `presupuesto_prorrogado` del índice de publicidad activa y remisión de información.

## Qué se mide

Si cada ayuntamiento, diputación, cabildo o consell insular (y Ceuta y Melilla) tiene **aprobado el presupuesto del año** o sigue con el **prorrogado** del anterior, según la información que la propia entidad ha comunicado al Ministerio de Hacienda.

## Base legal

- **Art. 169.2 del Texto Refundido de la Ley Reguladora de las Haciendas Locales** (RDLeg. 2/2004): la aprobación definitiva del presupuesto general «deberá realizarse antes del día 31 de diciembre del año anterior al del ejercicio en que deba aplicarse».
- **Art. 169.6 TRLRHL**: si al iniciarse el ejercicio no ha entrado en vigor el presupuesto, «se considerará automáticamente prorrogado el del anterior».
- Remisión a Hacienda: art. 169.4 TRLRHL y art. 15.2 de la Orden HAP/2105/2012.

## Fuente

CONPREL, Secretaría General de Financiación Autonómica y Local (Ministerio de Hacienda), presupuestos, **avance** del año en curso para toda España:
`https://serviciostelematicosext.hacienda.gob.es/SGFAL/CONPREL/Consulta/DescargaFichero?CCAA=&TipoDato=Presupuestos&Ejercicio=AAAA&TipoPublicacion=Avance` (EP{AAAA}CT.xlsx, ~3 MB). Hojas «<Comunidad>-Entidades», columna **«Estado Inf. (*)»** con los valores C, CP, E y N. Licencia: reutilización de la información del sector público (Ley 37/2007), citando la fuente.

## Cómo se calcula

Una fila por entidad y ejercicio con la **última foto** guardada de ese ejercicio:

| Estado Inf. | Estado del índice | Lectura |
|---|---|---|
| CP | `fuera_plazo` | En la fecha de la foto la entidad tiene el presupuesto **prorrogado**: no lo aprobó antes del 31 de diciembre y aún no lo ha aprobado |
| C, E | `consta` | Ha comunicado el presupuesto del ejercicio. La fuente no da la fecha de aprobación: puede haberse aprobado tarde |
| N o ausente | `no_consta` | No consta información del presupuesto del ejercicio en la foto |

`fecha_plazo` = 31 de diciembre del año anterior. `dias_retraso` es nulo: ninguna fuente estatal da la fecha de aprobación (está en el anuncio de cada boletín provincial, art. 169.3 TRLRHL, sin un acceso común). En `x_estado_inf`, `x_fecha_foto`, `x_primera_foto` y `x_estado_primera_foto` quedan el dato bruto y la primera foto.

## Qué significa «CP» y con qué certeza

El fichero no trae leyenda y la nota metodológica de CONPREL (idFichero 809 y 814) solo define C («datos de la administración general y sus organismos consolidados») y E («clasificación económica de la administración general»). **«CP» = presupuesto prorrogado es una deducción**, con estas pruebas:

- En el avance de 2026, de los ayuntamientos con «CP» que tienen presupuesto definitivo de 2025, **24 de 40 en Madrid y 41 de 71 en la Comunitat Valenciana tienen exactamente las mismas previsiones de ingresos por capítulo (1 a 9) que en 2025**. Entre los «C», 0 de 113 y 9 de 444. Una prórroga repite los créditos del año anterior (con los ajustes del art. 21 del RD 500/1990), así que la coincidencia exacta es la huella esperable.
- Los «CP» que no coinciden suelen tener prorrogado también el de 2025 o ajustes de prórroga.
- Certeza: **alta, pero no confirmada por escrito**. Pendiente de pedir confirmación a la SGFAL; hasta entonces la página debe decir «Hacienda lo marca como presupuesto prorrogado (CP)».

Un valor aislado «P» (1 ayuntamiento en 2026) se trata como `no_consta`.

## Universo

- Ayuntamientos: todos los municipios del padrón del año (8.130 sin Ceuta y Melilla).
- Diputaciones: 38 provinciales y 3 forales (`D` + provincia). No hay en las comunidades uniprovinciales (Asturias, Cantabria, La Rioja, Madrid, Murcia, Navarra) ni en Baleares y Canarias.
- Cabildos y consells (11): código `I` + provincia + ordinal del DIR3 L03 (comprobado en el registro de órganos de PLACSP y en datos.gob.es: L03070001 Formentera, L03070006 Eivissa, L03070008 Mallorca, L03070009 Menorca, L03350002 Fuerteventura, L03350004 Gran Canaria, L03350007 Lanzarote, L03380003 La Gomera, L03380005 El Hierro, L03380010 La Palma, L03380011 Tenerife). CONPREL los numera 001-004 por orden alfabético: la tabla de equivalencia está en el modelo.
- Ceuta y Melilla (tipo Z00 en CONPREL) como `Comunidad autónoma` C18/C19.

## Exclusiones y trampas

- **Régimen foral**: Álava, Gipuzkoa, Bizkaia y Navarra → `no_aplica`. En el avance de 2026, 241 entidades de Navarra y 101 del País Vasco figuran con N: remiten a su diputación foral o al Gobierno de Navarra. Se excluyen también las tres diputaciones forales, cuyo presupuesto es una norma foral de las Juntas Generales con su propio régimen.
- **Consell de Formentera**: es a la vez ayuntamiento y figura como tal (07024) → `no_aplica` como consell.
- **Sin histórico**: el avance solo se sirve para el ejercicio en curso (2025 devuelve HTTP 500) y las publicaciones definitivas (EP{AAAA}C{cc}, Access) solo traen C/E/N: la marca CP desaparece. La Wayback Machine **no** archivó ningún EP{AAAA}CT (consulta CDX del 25-oct-2026: solo hay una captura de DescargaFichero, del Access de liquidaciones 2024). Por eso la ingesta guarda una **foto con fecha** en cada ejecución (merge por ejercicio + fecha de foto + entidad) y el histórico empieza en 2026.
- **La foto cambia**: el avance se publica a final de mes de junio a noviembre y en cada publicación se incorporan entidades. Un «CP» de junio puede pasar a «C» en septiembre (aprobado tarde). El indicador usa la última foto del ejercicio, así que «prorrogado» quiere decir «seguía prorrogado en la fecha de la foto».
- Proxy relacionado ya en el índice: la retención de la PIE por no remitir el presupuesto antes del 1 de julio (`presupuesto_hacienda`). No es la misma obligación (remitir frente a aprobar a tiempo).

## Limitaciones

- No se sabe la fecha de aprobación de quienes figuran con C: «consta» no quiere decir «a tiempo».
- La marca es la que comunica la entidad; Hacienda no la verifica.

## Código

- Ingesta: `ingestion/pa_registros.py`, recurso `conprel_presupuestos_avance` (source dlt `pa_registros`). Copia de cada fichero en `data/hacienda_cache/conprel_avance/`.
- Modelo: `transform/models/marts/pa_ind_presupuesto.sql`; pruebas en `schema_pa_registros.yml`.
