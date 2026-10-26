# Índice propio de cumplimiento de transparencia: registros oficiales con fechas

Investigación del 2026-10-25, fase 1: solo lo que se puede comprobar en registros oficiales que traen fechas. Se ha verificado descargando muestras pequeñas: PLACSP octubre 2026 completo, menores y agregadas de 2025, registro de órganos, árbol de órganos y búsquedas de la BDNS, CONPREL presupuestos (avance 2026 y definitivas), ISPA 2025 y PMP de las CCAA. Las muestras y los scripts están en `scratchpad/placsp`, `bdns`, `conprel`, `ispa`, `pmp` y `scripts`. No se ha tocado el repo.

## 0. Qué hay ya en el repo (no repetir)

| Ingesta | Qué cubre | Fechas útiles para el índice |
|---|---|---|
| `ingestion/tcu.py` → `transparencia_tcu` | Tres obligaciones ante el TCu (rendiciondecuentas.es): Cuenta General (art. 212.5/223.2 TRLRHL, plazo 15-oct N+1), control interno (art. 218.3, plazo 30-abr), relación anual de contratos (art. 335 LCSP, plazo fin de febrero) | Fecha de envío solo en la Cuenta General. Ya calcula `en_plazo`/`fuera_plazo`/`dias_retraso`. País Vasco y Navarra no están (tienen OCEX propio). El rastreo sigue en curso |
| `ingestion/conprel.py` → `transparencia_liquidaciones` | Liquidación remitida o no (Estado Inf. C/E/N) desde 2013 | Sin fecha (dato binario) |
| `ingestion/hacienda_transparencia.py` → `transparencia_pie(_mensual)`, `transparencia_pmp` | Retenciones de la PIE (art. 36 Ley 2/2011): liquidación, presupuesto antes del 1-jul y líneas fundamentales antes del 15-sep (DA 87ª Ley 22/2021); PMP trimestral de las EELL (fichero2) | Mes de la retención, así que el «retraso» se puede aproximar en meses. El PMP mide días de pago, no días de remisión |
| `medios_contratos.py` | Descarga TODA la sindicación de PLACSP (perfiles, agregadas, menores) desde 2018, pero solo guarda las adjudicaciones a medios. `pcsp_cobertura` guarda MB, entradas y órganos por fichero | Las fechas se leen (`AwardDate`) pero se tiran. **Oportunidad: en la misma pasada se podría emitir un agregado por órgano y año, sin descargar nada nuevo** |
| `medios_contratos_ccaa.py` | Plataformas autonómicas (PSCP y RPC de Cataluña, KontratazioA, Junta de Andalucía, Galicia, La Rioja, Ayuntamiento de Madrid, C. de Madrid, Navarra), filtradas a medios | Igual que arriba: el código de acceso ya existe |
| `medios_subvenciones.py` | API de la BDNS, solo para convocatorias de medios | Ya lee `fechaConcesion` y `fechaAlta` |
| `transparencia_publicidad_activa` | Evaluaciones del ITCanarias y del CTBG (MESTA) | No son registros con fecha; quedan fuera de la fase 1 |

## 1. PLACSP: contratos por órgano, con fechas

**Fuente**
- Sindicación Atom + CODICE (índice: hacienda.gob.es › Datos abiertos › licitaciones_plataforma_contratacion), con tres conjuntos:
  - `sindicacion_643/licitacionesPerfilesContratanteCompleto3_AAAA[MM].zip`: perfiles alojados en PLACSP, sin menores.
  - `sindicacion_1143/contratosMenoresPerfilesContratantes_AAAA[MM].zip`: menores de esos perfiles, desde 2018.
  - `sindicacion_1044/PlataformasAgregadasSinMenores_AAAA[MM].zip`: plataformas autonómicas, sin menores.
- Registro de órganos: `contrataciondelsectorpublico.gob.es/datosabiertos/OrganosContratacion.xlsx`, de 1,5 MB y 23.493 órganos, generado el 01/10/2026. Trae ID Plataforma, NIF, DIR3, CP y la marca Activo/Inactivo.
- Licencia: reutilización de Hacienda (Ley 37/2007), con cita de la fuente.

**Tamaño anual** (de `raw_staging.pcsp_cobertura`)

| Año | perfiles | menores | agregadas | Total |
|---|---|---|---|---|
| 2025 | 2.072 MB | 283 MB | 133 MB | ≈2,5 GB al año |
| 2023 | 1.591 MB | 240 MB | 84 MB | |
| 2018 | 264 MB | 48 MB | 52 MB | |

- 2018-2026 suman ≈12 GB.
- Octubre de 2026, con 25 días, ya pesa 145 MB en perfiles.
- Se lee en streaming y la ingesta de medios ya lo hace (unos 20 s de proceso por fichero).

**Campos CODICE con fecha (verificados)**

| Campo | Dónde | Uso |
|---|---|---|
| `TenderResult/AwardDate` | perfiles y menores. **No viene en las agregadas** (0 de 21.148 entradas) | Fecha de adjudicación |
| `TenderResult/Contract/IssueDate` | perfiles, agregadas y algunos menores | Fecha de formalización |
| `ValidNoticeInfo/NoticeTypeCode` + `AdditionalPublicationStatus/PublicationMediaName` («Perfil del contratante», DOUE, BOE…) + `AdditionalPublicationDocumentReference/IssueDate` | todos | Fecha de publicación de cada anuncio: `DOC_CN` licitación, `DOC_CAN_ADJ` adjudicación, `DOC_FORM` formalización, `DOC_MOD`, `DOC_PIN`… |
| `AdditionalPublicationRequest/SendDate` | envíos al DOUE/BOE | Fecha de envío al diario |
| `ContractFolderStatusCode` | | PUB, EV, ADJ, RES, ANUL |
| `atom:updated` | | Fecha de la actualización. **No es la de publicación** |
| Órgano: `LocatedContractingParty/Party/PartyIdentification/ID@schemeName` = NIF, DIR3 o ID_PLATAFORMA; `ContractingPartyTypeCode`; `ParentLocatedParty` (cadena de dependencias, también con DIR3) | | Casar con el territorio |

**Retrasos medidos en las muestras** (días = publicación en el perfil − fecha del hecho)

| Muestra | Plazo legal | n | Mediana | p90 | Fuera de plazo |
|---|---|---|---|---|---|
| Perfiles oct-2026, formalización → `DOC_FORM` | art. 154.1 LCSP, 15 días | 3.484 | 3 | 32 | 15,8 % > 15 d |
| Perfiles oct-2026, adjudicación → `DOC_CAN_ADJ` | art. 151.1 LCSP, 15 días | 6.845 | 1 | 14 | 8,8 % > 15 d |
| Agregadas oct-2026, formalización → `DOC_FORM` | 15 días | 3.540 | 4 | 62 | 22,4 % > 15 d |
| Menores 2025 (año entero, órganos con DIR3 L01), adjudicación → `DOC_CAN_ADJ` | art. 63.4 LCSP, «al menos trimestralmente» | 232.854 | 14 | 169 | 19,9 % > 90 d; 9,2 % > 180 d |
| Menores 2025 por municipio (1.815 con ≥5 menores) | | | mediana de medianas 21 d | 198 d | |

- Para los menores, la regla propuesta es: fuera de plazo si se publica después del último día del mes siguiente al cierre del trimestre de adjudicación. Es una analogía con el art. 154.4 (acuerdos marco: «30 días tras el trimestre») y hay que decirlo así en la página. El art. 63.4 exime los menores de menos de 5.000 € pagados por anticipo de caja fija.

**Casar con el código INE**
- DIR3: `L01` + INE de 5 cifras + dígito de control = ayuntamiento (L01280796 → 28079).
- `L02` + `0000` + provincia = diputación (L02000046 → Valencia).
- `L03` + provincia + ordinal = cabildo o consell insular (L03070001 Formentera).
- `L04` = EATIM o entidad local menor; `L05` = mancomunidad; `L06` = comarca; `L08` = comunidades de villa y tierra.
- `A01`..`A19` = CCAA con el orden del INE; `EA0`/`E0x` = Estado; `U0x` = universidades.
- En perfiles y menores casi todo trae NIF + DIR3: en oct-2026, 11.114 de 14.881 entradas con DIR3 en perfiles y 28.062 de 34.126 en menores.
- Si un órgano no tiene DIR3 (2.064 órganos locales del registro), se cruza el NIF (P+provincia+…): la tabla NIF→INE sale de los propios órganos del registro que sí tienen DIR3 L01. Ese NIF es el del ayuntamiento y lo comparten la Alcaldía, el Pleno y la Junta de Gobierno.
- Errores de DIR3 detectados: «L10…», «L11…» y códigos de 8 caracteres (L0500018). Hay que validar con el INE y el dígito de control.

**Cobertura por comunidad**

| CCAA | Municipios | Con órgano DIR3 L01 activo en el registro de PLACSP | Con ≥1 menor publicado en PLACSP en 2025 |
|---|---|---|---|
| Andalucía | 785 | 732 | 420 |
| Aragón | 731 | 706 | 327 |
| Castilla y León | 2.248 | 1.703 | 321 |
| Castilla-La Mancha | 919 | 755 | 388 |
| C. Valenciana | 542 | 500 | 349 |
| Galicia | 313 | 227 | 119 (260 con agregadas y perfiles) |
| Madrid | 179 | 173 | 92 |
| La Rioja | 174 | 169 | 35 |
| **Cataluña** | 947 | **45** | **0** |
| **Navarra** | 272 | **3** | **0** |
| **País Vasco** | 252 | **19** | **1** |
| Ceuta y Melilla | 1 + 1 | 0 (van como ciudad autónoma) | |
| **España** | 8.132 | 5.758 | 2.481 |

- Fuera de Cataluña, Navarra y País Vasco, por tramo de población:

| Tramo | Total | En el registro | Con menores en 2025 |
|---|---|---|---|
| < 1.000 hab | 4.217 | 3.466 | 1.041 |
| 1.000-5.000 | 1.431 | 1.295 | 760 |
| 5.000-20.000 | 675 | 614 | 425 |
| > 20.000 | 338 | 316 | 254 |

- **Respuesta a «cuántos no tienen nada»**: unos 970 ayuntamientos de régimen común (fuera de Cataluña, Navarra y País Vasco) no tienen ni un órgano registrado en PLACSP. Unos 4.180 no publicaron ni un menor en PLACSP en 2025. La unión de menores 2025 + agregadas 2025 + perfiles oct-2026 da 3.305 municipios con alguna actividad. No se ha leído el año completo de perfiles (2 GB).
- Antes de llamarlo incumplimiento: en municipios de menos de 1.000 habitantes contratan a menudo la diputación, la mancomunidad o una central de contratación (DA 2ª LCSP y art. 36 LRBRL). Que no conste un perfil no basta: «no consta ninguna publicación» es el dato factual.

**Trampa de las plataformas agregadas** (equivalente a la foral)
- Las agregadas de 2025 traen siete plataformas: Generalitat de Catalunya 110.872 entradas, Gobierno Vasco 57.934, Junta de Andalucía 35.661, C. de Madrid 28.913, Navarra 6.811, Xunta 6.032 + 1.637 con DIR3, La Rioja 2.780. Bilbao (11) y Murcia (1) son residuales.
- **No traen** `AwardDate`, NIF del órgano ni `ContractingPartyTypeCode`. Solo `ID_OC_PLAT` y, en Andalucía y Galicia, a veces DIR3.
- **No traen menores.**
- Consecuencia: Cataluña, País Vasco y Navarra (y parte de Galicia) **no pueden compararse con la fuente PLACSP**. O se excluyen (como se hizo con el foral) o se completan con su plataforma:
  - **Cataluña, PSCP (Socrata ybgg-dgi6)**: viable ya. Trae `codi_ine10`, `codi_dir3`, `data_adjudicacio_contracte`, `data_formalitzacio_contracte`, `data_publicacio_adjudicacio`, `data_publicacio_formalitzacio` y `procediment`. 382.116 menores adjudicados en 2025. 764 DIR3 L01 distintos en 2025. Se puede agregar en el servidor con SoQL (`$group`), sin descargar filas. El acceso ya existe en `medios_contratos_ccaa.py` (`cat_pscp`).
  - **País Vasco, KontratazioA** (`api.euskadi.eus/procurements/contracts`, 723.414 contratos, `minorContract`, `awardDate`, `companySignatureDate`, enlace al poder adjudicador con NIF): viable con trabajo. No trae fecha de publicación en el listado (habría que ir al anuncio) y hay fechas erróneas («2926-09-24»).
  - **Navarra**: menores en PDF/Excel trimestrales por entidad (ya parseados en `nav_portal`) y anuncios en la agregada sin DIR3. Medir publicación trimestral sí se puede (consta o no la relación del trimestre); el retraso en días no.
  - **Galicia**: contratosdegalicia, por organismo, con NIF. Viable con trabajo.
- Andalucía, Madrid y La Rioja: sus **ayuntamientos** publican casi todos en PLACSP (732/785, 173/179, 169/174). Las agregadas son sobre todo de la administración autonómica. Para las **CCAA** como entidad sí hacen falta las agregadas o la plataforma propia.

**Otras trampas**
- Cada fichero mensual trae las ACTUALIZACIONES del mes: un expediente reaparece al cambiar de estado o con anuncios antiguos (`AwardDate` de 2021 en el fichero de oct-2026). Hay que deduplicar por expediente + órgano + lote, quedarse con la última versión y asignar el año por la fecha del hecho, no por el fichero.
- Hay retrasos negativos (96 de 3.484): se publicó antes de la fecha del hecho, por errores de carga. Se recortan a 0 y se marcan.
- Puede haber varios `DOC_FORM`: se toma el primero en «Perfil del contratante».
- `deleted-entry`: anulaciones.
- El año en curso está incompleto; se etiqueta «(incompleto)».

**Coste**
- Si se reutiliza la pasada de `medios_contratos` (añadiendo un acumulador por órgano×año×tipo con nº de contratos, nº con fecha, retraso mediano, nº fuera de plazo), la descarga extra es **cero**. El histórico 2018-2026 ya se descarga entero (≈12 GB, unas 2-3 h). Lo único nuevo es el registro de órganos (1,5 MB).
- Una ingesta separada costaría lo mismo: 12 GB una vez y ~250 MB al mes.

## 2. BDNS: convocatorias y concesiones por órgano, con fechas

**Fuente**
- API REST sin clave: `https://www.infosubvenciones.es/bdnstrans/api/` (spec en `/bdnstrans/estaticos/doc/snpsap-api.json`, 350 kB). IGAE.
- Licencia: aviso legal propio del SNPSAP. Permite reutilizar, pero advierte que puede restringir el acceso si hay abuso: hay que ir con pausas.

**Endpoints verificados**
- `GET /organos/agrupacion?vpd=GE&idAdmon=L`: provincia › municipio, con **id = código INE de 6 cifras con dígito de control** (150026 = Ames). Hay 2.981 municipios en el árbol.
- `GET /organos/agrupacion?idAdmon=A`: id = código INE de la CCAA (01..19).
- `GET /organos?vpd=GE&idAdmon=L|A|C|O`: árbol con el **id interno** de cada órgano concedente (nivel 3), que es el que acepta el filtro `organos`. Hay 3.613 órganos locales: 2.738 «Ayuntamiento…», 37 diputaciones, cabildos, consells, patronatos, distritos… Madrid tiene 55 órganos: el «Ayuntamiento de Madrid» no tiene concesiones propias, las registran las áreas y los distritos, así que **hay que sumar todos los órganos del nodo municipio**.
- `GET /concesiones/busqueda`, con filtros `organos`, `tipoAdministracion` (C/A/L/O), `fechaDesde/fechaHasta` (fecha de concesión, dd/mm/aaaa), `fechaRegInicio/fechaRegFin` (fecha de registro en la BDNS), `pageSize` hasta 10.000 y `page`. Cada fila trae `fechaConcesion`, **`fechaAlta`** (alta en la BDNS), `numeroConvocatoria`, `nivel1/2/3` (LOCAL / AMES / AYUNTAMIENTO DE AMES), importe, instrumento y beneficiario.
- `GET /convocatorias/busqueda`, con los mismos filtros (fecha = recepción). Trae `fechaRecepcion`, `nivel1/2/3` y `codigoInvente` (casi siempre null).

**Volúmenes**

| Búsqueda | Resultado |
|---|---|
| Concesiones de EELL en 2025 | 839.221 (84 páginas de 10.000) |
| Concesiones de CCAA en 2025 | 5.187.568 (520 páginas) |
| Convocatorias de EELL en 2025 | 50.398 |
| Concesiones de EELL en 2021 | 0, por la ventana de 4 años |

- Las convocatorias locales de 2025 vienen de unos 1.835 municipios distintos (nivel2 con órgano «Ayuntamiento»), de 8.132. Casan por nombre con el árbol (2.003 nombres; solo 3 ambiguos entre provincias). Mejor hacerlo por id de órgano.

**Prueba con ayuntamientos reales** (concesiones 2025; retraso = `fechaAlta` − `fechaConcesion`)

| Ayuntamiento | Concesiones | Convocatorias | Mediana | p90 | > 30 d |
|---|---|---|---|---|---|
| Valladolid | 1.707 | 113 | 14 d | 66 d | 14 % |
| Tarancón | 71 | 40 | 3 d | 14 d | 7 % |
| Dos Hermanas | 247 | 45 | 16 d | 33 d | 11 % |
| Zaragoza | 3.312 | 88 | **338 d** | 338 d | 89 % (carga en bloque un año después) |
| Pamplona | 1.203 | 37 | 44 d | 119 d | 68 % |
| Madrid («Ayuntamiento de Madrid» solo) | 0 | | | | |

- Madrid sale a 0 porque registran los otros 54 órganos.

**Plazo legal** (RD 130/2019, BOE-A-2019-4671)
- Art. 5.2.b: concesiones, pagos, reintegros y sanciones «antes de que finalice el mes siguiente al de su producción». **Fecha límite = último día del mes siguiente a `fechaConcesion`.**
- Art. 6.2: la convocatoria se registra inmediatamente antes de publicarse en el diario oficial. La BDNS envía el extracto al BOP, así que ese retraso no se puede medir con sentido.
- Art. 4.1.a: no hay obligación de remitir concesiones de ≤100 €/año al mismo beneficiario.
- Art. 7.8: publicidad durante los 4 años naturales siguientes. A personas físicas, solo el año de concesión y el siguiente.
- Art. 20 LGS.

**Trampas**
- **Ventana de 4 años**: hoy se ve desde 2022. Hay que guardar en merge, nunca replace (ya documentado en `medios_subvenciones.py`).
- Las concesiones a personas físicas desaparecen al segundo año: el retraso de años viejos tiene sesgo de supervivencia. Se compara solo el año N-1 completo, medido el año N.
- STC 37/2021 anuló parte del art. 3.1 (conflicto planteado por el Gobierno Vasco). Aun así, las EELL vascas y navarras **sí registran**: hay órganos en las provincias 01, 20, 48 y 31, y Pamplona tiene 1.203 concesiones. Antes de comparar hay que medir la cobertura foral.
- Que no conste ninguna convocatoria no es un incumplimiento si el ayuntamiento no subvenciona nada. El indicador factual es «sin registros en la BDNS» más la tasa de retraso de quien sí registra.
- La diputación concede «en nombre» de muchos municipios pequeños.
- `nivel2` es el nombre del municipio, no un código: hay que casar por id de órgano.

**Coste**
- Unos 3.613 órganos locales × 1-N páginas, con 0,3-1 s entre peticiones: 1-2 h por año para las EELL.
- Alternativa sin órganos: `tipoAdministracion=L` + rangos de `fechaRegInicio/Fin` (84 páginas/año) y casar `nivel2/nivel3` con el árbol. Unos minutos.
- CCAA: 520 páginas al año, ≈5 M filas. Conviene agregar al vuelo (por órgano y mes: n, mediana, fuera de plazo) y no guardar filas.

## 3. Presupuesto a tiempo

**EELL (plazo: aprobación definitiva antes del 31 de diciembre, art. 169.2 TRLRHL; si no, prórroga automática, art. 169.6)**
- **CONPREL, avance del año en curso** (`DescargaFichero?CCAA=&TipoDato=Presupuestos&Ejercicio=2026&TipoPublicacion=Avance`, EP2026CT.xlsx, 3,1 MB):
  - La columna «Estado Inf. (*)» toma los valores **C / CP / E / N**.
  - **CP = presupuesto prorrogado**. Verificado en Madrid: 25 de los 42 «CP» de 2026 tienen exactamente las mismas previsiones de ingresos que el definitivo de 2025, como Alcalá de Henares y Ajalvir. El resto difiere porque el de 2025 también era prorrogado o hubo ajustes de prórroga. La hoja no trae leyenda: el significado está deducido y hay que confirmarlo con la SGFAL.
  - Ayuntamientos «CP» en 2026: Andalucía 197, CyL 312, CLM 148, Extremadura 90, Galicia 87, C. Valenciana 72, Madrid 42, Cataluña 39, Aragón 33…
  - Trae Pr + Cor = INE y Tip (A00 ayuntamiento, D00 diputación/cabildo/consell, M00…). Gratis y fácil.
- **Trampa**: el avance **solo se sirve para el año en curso** (2025 devuelve 500). Las definitivas (`EP{AAAA}C{cc}`) y el Access (`Presupuestos2025.accdb`, `tb_inventario.estado`) solo traen C/E/N: la marca CP desaparece. **Sin histórico**: hay que guardar una foto del avance cada año desde ya, en Dagster mensual con merge por ejercicio + fecha de foto. La Wayback devolvió 429; queda por comprobar si archivó EP{AAAA}CT.
- Navarra (241 «N») y País Vasco (101 «N») vienen casi vacíos: es la trampa foral, porque remiten a su diputación foral o a su gobierno.
- No hay fecha de aprobación en ninguna fuente estatal. Está en el anuncio del BOP (art. 169.3): son 50 boletines sin API común. No es viable en la fase 1.
- Proxy con fecha ya cubierto: la retención de la PIE por no remitir el presupuesto antes del 1 de julio (`transparencia_pie`).

**CCAA (plazo: ley de presupuestos antes del 1 de enero; si no, prórroga, según el estatuto y la ley de hacienda de cada una)**
- Las leyes de presupuestos autonómicas se publican en el **BOE, sección I, epígrafe «Comunidad Autónoma de …»**, con la fecha de la ley en el título (p. ej. BOE-A-2025-413 «Ley 7/2024, de 23 de diciembre, del Presupuesto de la Comunidad Autónoma de Andalucía para el año 2025»).
- `ingestion/transparencia_gobierno.py` ya recorre los sumarios desde 1977, pero solo guarda las leyes estatales (`RE_PGE`) y su caché `data/boe_cache` solo tiene lo filtrado (7 MB).
- Viable con trabajo: añadir una regex `Ley .* (de )?Presupuestos? .* (Comunidad|Generalitat|Región|Principado|Illes|Canarias|Navarra|Euskadi|Aragón…) .* para (el año|el ejercicio) AAAA` y releer los sumarios (~40 min).
- Días de retraso = fecha de la ley − 1 de enero del ejercicio. Año sin ley = prorrogado.
- Trampa: la fecha que cuenta es la de publicación en el diario autonómico, no la del BOE, que llega semanas después. La ley lleva la fecha de sanción; su entrada en vigor suele ser el 1 de enero o el día siguiente a publicarse en el diario autonómico. Navarra aprueba «Ley Foral de Presupuestos Generales de Navarra» y País Vasco «Ley de Presupuestos Generales de la Comunidad Autónoma de Euskadi»: incluirlas en la regex.

## 4. Otros registros con fecha

| Registro | Fuente / formato / licencia | Qué permite | Casado | Trampas | Estado |
|---|---|---|---|---|---|
| **ISPA, retribuciones de cargos electos** | digital.gob.es › espacio-ispa › estadísticas › informac_estad_AAAA: `ayuntamientos_sin_remitir.xlsx`, `retribuciones_alcaldes.xlsx`, `retribuciones_concejales.xlsx`, `presidentes_diputaciones.xlsx`… (2013-2024, rutas que cambian: `ispa_2023/retrib_2022/ayunt_sin_remitir.xlsx`, `ispa2025/retrib_2024/ayuntamientos_sin_remitir.xlsx`). Datos públicos de la SEFP | Lista de ayuntamientos que **no han facilitado** las retribuciones: 1.197 en ISPA 2025 (CyL 327, CLM 269, Aragón 96…). Dato binario por año | Nombre + provincia + población, sin INE: hay que casar por nombre (como las retenciones antiguas de la PIE) | «Los listados no tienen carácter definitivo y se irán ampliando»: guardar la fecha de la foto. Navarra tiene ISPA propia (espacio-ispa/navarra2026). Base legal: art. 75 bis LRBRL (límites) y la remisión que regula cada LPGE; **comprobar el artículo exacto** antes de citarlo | Viable ya (Excel pequeño, ~1 h de trabajo) |
| **Registro de Entidades Locales (REL, MPTFP)** | ssweb.seap.minhap.es/REL | Maestro de entidades (municipios, EATIM, mancomunidades, comarcas) con fechas de alta y baja | INE | No mide cumplimiento | Útil como denominador, no como indicador |
| **INVENTE / Inventario de Entes del Sector Público Local (BDGEL)** | IGAE / SGFAL | Entes dependientes, de los que salen los «(*)» de la retención de la PIE | codbdgel (INE + tipo) | No mide cumplimiento | Maestro, no indicador |
| **DIR3** (Directorio Común) | administracionelectronica.gob.es, datos abiertos | Tabla DIR3↔INE para PLACSP y datos.gob.es | DIR3 | | Maestro, recomendable |
| **datos.gob.es por publicador** | `datos.gob.es/apidata/catalog/dataset/publisher/{DIR3}.json` (p. ej. L01280796) | Nº de conjuntos y fechas de alta/modificación por ayuntamiento | DIR3 L01 = INE | **No es una obligación legal** (la Ley 37/2007 no obliga a publicar en datos.gob.es): no debe entrar en un índice de incumplimientos | Viable, pero fuera del índice |
| **Ejecución trimestral EELL** (art. 16 Orden HAP/2105/2012, plazo último día del mes siguiente al trimestre; los ayuntamientos de menos de 5.000 hab solo están obligados en el 4.º trimestre) | datos.gob.es e05250001 | Solo agregados por CCAA + las 6 ciudades > 500.000 hab | — | **Hacienda no publica quién no remite**. La retención de la PIE no cubre la ejecución trimestral. El PMP (quien no aparece no lo ha comunicado) es el único rastro trimestral por entidad | No viable |
| **PMP CCAA** (RD 635/2014; máximo legal 30 días, art. 13.6 LOEPSF y DA 1ª LO 9/2013) | pmp_net `descarga.aspx?ejercicio=AAAA&periodo=<Mes>&tipoPublicacion=2&fichero=fichero1`, Excel mensual (58 kB, «Informe_Ejecutivo_PMP_Completo»; tipoPublicacion=1 da el PDF). Hacienda | PMP mensual por CCAA = días de pago por encima de 30 | Nombre de CCAA (17 + 2) | Todas remiten: mide **retraso en pagar**, no en publicar. Separarlo del índice de remisión | Viable ya; ampliar `hacienda_transparencia.py` con fichero1 |
| **Ejecución mensual CCAA** (art. 14 Orden HAP/2105/2012) | Hacienda, ejecución presupuestaria mensual | Todas remiten | | Sin variación útil | No viable / sin interés |
| **Cuenta General CCAA** | TCu, «Informe anual de fiscalización de las CCAA y ciudades autónomas» (las que no tienen OCEX: Cantabria, CLM, Extremadura, La Rioja, Murcia, Ceuta, Melilla) + informes de cada OCEX | Fecha de rendición frente al plazo de cada ley de hacienda autonómica (suele ser el 31 de octubre de N+1) | 17 + 2 entidades | PDF por CCAA y año, con plazos distintos | Viable con trabajo: seed manual ~19×10 filas |
| **Cuenta General, control interno y relación de contratos EELL** | rendiciondecuentas.es | — | — | — | Ya cubierto (`tcu.py`) |

## 5. Tabla priorizada

| # | Indicador | Entidades | Fuente | Plazo | Medida | Cubierto | Esfuerzo | Veredicto |
|---|---|---|---|---|---|---|---|---|
| 1 | Cuenta General al TCu | Ayto, dip, cabildo (sin PV y Navarra) | rendiciondecuentas.es | 15-oct N+1 (art. 212/223 TRLRHL) | Días de retraso | Sí | Terminar el rastreo | **Viable ya** |
| 2 | Liquidación, presupuesto y líneas fundamentales (retención PIE) | Ayto, dip | OVEELL PDF | 31-mar / 1-jul / 15-sep | Meses retenido | Sí | 0 | **Viable ya** |
| 3 | Adjudicación publicada ≤15 d (art. 151.1) y formalización ≤15 d (art. 154.1) | Ayto, dip, cabildo, CCAA | PLACSP perfiles (+ PSCP Cataluña) | 15 días | % fuera de plazo, mediana de días | No (datos ya descargados) | Medio: un acumulador en `medios_contratos` + PSCP con SoQL | **Viable ya** (con exclusión explícita de PV y Navarra) |
| 4 | Menores publicados y su retraso (art. 63.4) | Ayto, dip, cabildo | PLACSP menores + PSCP | Trimestral (regla interpretativa) | % > fin del mes siguiente al trimestre; «sin ningún menor publicado» | No | Igual que 3 | **Viable ya**, con aviso de centrales y diputaciones |
| 5 | Concesiones en la BDNS ≤ fin del mes siguiente (RD 130/2019 art. 5.2.b) | Ayto (todos sus órganos), dip, cabildo, CCAA | API BDNS | Mes siguiente | % fuera de plazo, mediana | No (solo medios) | Medio: 1-2 h/año de API; merge por la ventana de 4 años | **Viable ya** |
| 6 | Presupuesto prorrogado (CP) | Ayto, dip | CONPREL avance | 31-dic (art. 169 TRLRHL) | Sí/no | No | Bajo; solo hacia delante | **Viable ya** (sin histórico) |
| 7 | Retribuciones de cargos electos no remitidas | Ayto | ISPA `ayuntamientos_sin_remitir.xlsx` 2013-2024 | Anual | Sí/no | No | Bajo; casado por nombre | **Viable ya** |
| 8 | PMP CCAA | CCAA | pmp_net fichero1 | 30 d | Días por encima de 30 | No (solo EELL) | Bajo | **Viable ya** (aparte del índice de remisión) |
| 9 | Ley de presupuestos CCAA a tiempo | CCAA | BOE sumarios sección I | 1-ene | Días de retraso / prorrogado | No | Medio (regex + relectura ~40 min) | **Viable con trabajo** |
| 10 | Contratación en País Vasco y Navarra | Ayto, dip forales | KontratazioA API; Portal de Navarra | 15 d / trimestral | Fechas de adjudicación y firma; publicación no siempre | Parcial (medios) | Alto | **Viable con trabajo** |
| 11 | Galicia (EELL fuera de PLACSP) | Ayto | contratosdegalicia | ídem | | Parcial | Medio | **Viable con trabajo** |
| 12 | Cuenta General CCAA | CCAA | TCu y OCEX (PDF) | Ley de cada CCAA | Días | No | Seed manual | **Viable con trabajo** |
| 13 | Fecha de aprobación del presupuesto municipal | Ayto | BOP (50 boletines) | 31-dic | Días | No | Muy alto | **No viable** en la fase 1 |
| 14 | Ejecución trimestral EELL | Ayto | Hacienda | Mes siguiente al trimestre | — | — | — | **No viable** (no hay datos por entidad ni lista de no remitentes) |
| 15 | Datos abiertos en datos.gob.es | Ayto | apidata | — (no es una obligación) | Nº de conjuntos | — | Bajo | **Fuera del índice** |

**Reglas transversales**
- Foral: los indicadores 1, 2 y 6 no valen para 01, 20, 48 y 31. La BDNS sí, pero comprobando la cobertura.
- Cataluña, Navarra y País Vasco no aparecen en PLACSP: o se usa su plataforma o se excluyen y se dice.
- Canarias y Baleares: cabildos y consells (D00 en CONPREL; L03 en DIR3) son otro tipo de entidad, no una diputación. Se comparan entre sí.
- Atribución al gobierno en funciones en la fecha límite, como en `transparencia_tcu`.
- Ajuste por población y CCAA.
- Redacción: «no consta».
