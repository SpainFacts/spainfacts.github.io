# Contratación: anuncios en el perfil del contratante a tiempo

**Elaboración propia de SpainFacts.** Tres indicadores del índice de publicidad activa, calculados a partir de las fechas que publican las propias plataformas de contratación:

| Indicador (`obligacion`) | Qué mide | Base legal | Plazo |
|---|---|---|---|
| `contratos_adjudicacion` | Adjudicaciones con su anuncio en el perfil del contratante a tiempo | art. 151.1 de la Ley 9/2017, de Contratos del Sector Público (LCSP): la adjudicación «deberá ser publicada en el perfil de contratante en el plazo de 15 días» | 15 días desde la adjudicación |
| `contratos_formalizacion` | Formalizaciones con su anuncio en el perfil a tiempo | art. 154.1 LCSP: la formalización se publica «en un plazo no superior a quince días tras el perfeccionamiento del contrato en el perfil de contratante» | 15 días desde la formalización |
| `contratos_menores` | Contratos menores publicados cada trimestre | art. 63.4 LCSP: los menores se publican «al menos trimestralmente» | **Regla de elaboración propia**: hasta el último día del mes siguiente al cierre del trimestre de adjudicación |

Los días son **naturales** (disposición adicional 12ª de la LCSP).

### La regla de los menores es interpretativa

El art. 63.4 dice «al menos trimestralmente», pero no fija un día. SpainFacts aplica, **por analogía con el art. 154.4 LCSP** (los contratos basados en un acuerdo marco se publican de forma agrupada «dentro de los 30 días siguientes al fin de cada trimestre»), el último día del mes siguiente al trimestre: un menor adjudicado entre enero y marzo debe estar publicado el 30 de abril. Así hay que decirlo en la página: es un criterio nuestro, no un plazo literal de la ley. El art. 63.4 exime de publicar los menores de menos de 5.000 € pagados con anticipo de caja fija; esos no aparecen en la plataforma y no cuentan ni a favor ni en contra.

## Fuentes

- **Plataforma de Contratación del Sector Público (PLACSP)**, Ministerio de Hacienda, sindicación de datos abiertos (Atom + CODICE), índice en <https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx>. Tres conjuntos:
  - `sindicacion_643/licitacionesPerfilesContratanteCompleto3_AAAA[MM].zip`: perfiles alojados en PLACSP (sin menores).
  - `sindicacion_1044/PlataformasAgregadasSinMenores_AAAA[MM].zip`: plataformas autonómicas agregadas (sin menores y sin fecha de adjudicación).
  - `sindicacion_1143/contratosMenoresPerfilesContratantes_AAAA[MM].zip`: menores de los perfiles alojados.
  - Registro de órganos de contratación: <https://contrataciondelsectorpublico.gob.es/datosabiertos/OrganosContratacion.xlsx> (NIF, DIR3).
  - Licencia: reutilización de la información del sector público (Ley 37/2007), citando la fuente.
- **Cataluña: Plataforma de serveis de contractació pública (PSCP)**, Generalitat de Catalunya, conjunto «Contractació pública a Catalunya: publicacions a la Plataforma de serveis de contractació pública» (Socrata `ybgg-dgi6`): <https://analisi.transparenciacatalunya.cat/Sector-P-blic/Contractaci-p-blica-a-Catalunya-publicacions-a-la-/ybgg-dgi6>. Las entidades catalanas no publican en PLACSP (45 órganos de 947 municipios en el registro) y lo que llega a PLACSP por la agregación catalana duplica la PSCP sin fecha de adjudicación ni menores.

## Cómo se calcula

### Fechas (PLACSP, campos CODICE)

| Hecho | Campo |
|---|---|
| Adjudicación | `TenderResult/AwardDate` (la primera de los lotes del expediente) |
| Formalización | `TenderResult/Contract/IssueDate` (la primera) |
| Anuncio de adjudicación | `ValidNoticeInfo` con `NoticeTypeCode = DOC_CAN_ADJ` y medio `PublicationMediaName = «Perfil del contratante»`: `AdditionalPublicationDocumentReference/IssueDate` (el primero) |
| Anuncio de formalización | ídem con `DOC_FORM` |
| Publicación de un menor | su anuncio `DOC_CAN_ADJ` (el menor es la propia publicación) |

### Fechas (PSCP)

- Adjudicación y formalización: `data_adjudicacio_contracte` / `data_publicacio_adjudicacio` y `data_formalitzacio_contracte` / `data_publicacio_formalitzacio`, con la mínima por expediente (la PSCP tiene una fila por lote; se agrega en el servidor con SoQL `$group` por órgano y expediente).
- Menores: `data_adjudicacio_contracte` y la fecha de la «publicació agregada» (`data_publicacio_contracte`; si no hay, `data_publicacio_adjudicacio`). Se agrega en el servidor por órgano, mes de adjudicación, mes de publicación y días (`date_diff_d`). Con el mes de publicación basta para saber si pasa del último día del mes del plazo.

### Fórmulas

- `retraso = fecha del anuncio − fecha del hecho` (días naturales).
- Adjudicación y formalización: **fuera de plazo** si `retraso > 15` o si **no consta anuncio** en el perfil (`x_n_sin_anuncio`).
- Menores: fuera de plazo si la publicación es posterior al último día del mes siguiente al trimestre de adjudicación. Un menor publicado sin fecha de anuncio no cuenta (`x_n_sin_fecha`): consta publicado, pero no sabemos cuándo.
- **Retrasos negativos** (anuncio con fecha anterior al hecho, por errores de carga): se recortan a 0 y se cuentan en `x_n_negativos`.
- Solo cuentan los elementos cuyo plazo **ya venció** en la fecha de corte (`x_fecha_corte`, el último `updated` leído de PLACSP o la última actualización de la PSCP). Los demás van en `x_n_pendientes`.
- Por entidad y año (año del hecho, no del fichero): `n_total` (elementos vencidos), `n_fuera_plazo` y `mediana_dias` (mediana exacta, calculada sumando los histogramas de días de todos los órganos de la entidad; tope 999 días). `x_pct_fuera_plazo = 100 · n_fuera_plazo / n_total`.
- `estado`: `con_registros` (n_total > 0; el modelo común convierte el porcentaje en estado), `sin_registros`, `no_vencido` (año en curso, o plazo del último elemento del año aún no vencido) y `no_aplica`.
- `fecha_plazo`: la del último elemento del año: 15 de enero del año siguiente (adjudicación y formalización) o 31 de enero (menores del cuarto trimestre).

### Exclusiones de elementos

- Expedientes **anulados** (`ContractFolderStatusCode = ANUL`; en la PSCP, fase «Anul·lació») y entradas borradas (`deleted-entry` posterior a la última versión).
- **Contratos basados en un acuerdo marco o en un sistema dinámico de adquisición** (`ContractingSystemCode` 3 y 4, procedimientos 7 y 12; en la PSCP, «Contracte basat en acord marc» y «Específic de sistema dinàmic»): el art. 154.4 permite publicar su formalización de forma agrupada cada trimestre, así que el plazo de 15 días no es exigible.
- En adjudicación y formalización de la PSCP, los menores y las publicaciones agregadas.

## De órgano a entidad

Se mide a la **administración territorial matriz**: lo que publican sus órganos (alcaldía, pleno, junta de gobierno, concejalías, distritos, consejerías…), identificados por su **NIF**. Los **organismos autónomos, consorcios, sociedades y fundaciones** tienen NIF y perfil propios y **no** se atribuyen a la entidad matriz (aunque compartan su DIR3, como el OPAEF con la Diputación de Sevilla o el Instituto Municipal de la Vivienda con el Ayuntamiento de Barcelona).

| Entidad (`cod_entidad`) | Regla (PLACSP) |
|---|---|
| Ayuntamiento (INE de 5 cifras) | NIF del ayuntamiento (`P` + provincia + municipio + `00` + control) casado con el INE por los DIR3 `L01` + INE + dígito de control válidos del registro de órganos y de la propia sindicación (votación por NIF, misma provincia en NIF y DIR3). El número del NIF **no** siempre es el INE (Llíria: NIF P4614900A, INE 46147), por eso se usa el DIR3. Si un NIF de ayuntamiento nunca aparece con un DIR3 válido, se acepta el número del NIF solo si ese INE no tiene ya otro NIF. Sin NIF (plataformas agregadas): DIR3 `L01`. |
| Diputación (`D` + provincia) | NIF `P` + provincia + `00000` + control; sin NIF, DIR3 `L02` + `0000` + provincia |
| Cabildo o consell (`I` + DIR3 L03) | NIF de cada corporación (tabla fija sacada del registro de órganos) |
| Comunidad autónoma (`C` + código INE) | NIF `S` (administración general), cadena de dependencias «COMUNIDADES Y CIUDADES AUTÓNOMAS» sin «SOCIEDADES, FUNDACIONES Y CONSORCIOS», y DIR3 `A01`..`A19` en el órgano o su cadena (si no hay, el nombre de la comunidad en la cadena o la provincia del NIF). En las agregadas, que no traen NIF: nivel autonómico según la cadena y la plataforma. |

En la PSCP: ayuntamiento = `codi_ine10` con forma INE (5) + dígito de control + `000` + control; diputación = «Diputació de …» con DIR3 `L02`; Generalitat = los departamentos y sus unidades (servicios territoriales, direcciones generales) y los órganos con el DIR3 de un departamento.

DIR3 erróneos: se corrige la errata «LO1» (letra O) y se descarta todo DIR3 L01 cuyo INE no exista o cuyo dígito de control no coincida con la Relación de municipios del INE (<https://www.ine.es/daco/daco42/codmun/diccionario26.xlsx>), así como longitudes distintas de 9 («L0146477») o una provincia distinta de la del NIF. Los NIF de ayuntamiento que nunca traen un DIR3 válido se casan por el **nombre del municipio** de la cadena de dependencias («Illescas > Ayuntamientos > Toledo») con la misma Relación del INE (sin tildes ni artículos, dentro de la provincia del NIF); así se recuperan Illescas, La Oliva, San Bartolomé de Tirajana o Llíria, que antes quedaban fuera. EATIM, mancomunidades, comarcas, organismos y patronatos con NIF de forma municipal se descartan por el nombre.

## Universo

Todas las entidades de cada año, aparezcan o no en la fuente: los ayuntamientos de `poblacion_municipios` (8.131-8.132; Ceuta y Melilla como comunidad autónoma, `C18` y `C19`), 41 diputaciones (38 provinciales y 3 forales), 11 cabildos y consells y 19 comunidades y ciudades autónomas, cruzados con las tres obligaciones. Población: padrón del año (o el último disponible); suma de la provincia o la comunidad; nula en cabildos y consells.

## Exclusiones de entidades (`aplica_indicador = false`)

- **País Vasco y Navarra**: sus entidades publican en KontratazioA y en el Portal de Contratación de Navarra, no en PLACSP (19 y 3 órganos en el registro). Lo que llega por la agregación no trae fecha de adjudicación ni menores, y la plataforma propia no está cubierta todavía. No es un dato de incumplimiento.
- **Comunidades con plataforma propia agregada a PLACSP** (Andalucía, Galicia, Comunidad de Madrid y La Rioja): su **adjudicación** y sus **menores** no se pueden medir (la agregación no trae `AwardDate` ni menores). Su **formalización** sí se mide.
- **Entidades locales cuyos anuncios ese año llegan solo por una plataforma agregada** (sin perfil ni menores en PLACSP): mismo motivo, para adjudicación y menores.
- **Consell Insular de Formentera**: es también el ayuntamiento; se mide como Ayuntamiento de Formentera (07024), como en el PMP.
- **2018**: la LCSP entró en vigor el 9-mar-2018 y los expedientes iniciados antes se rigen por el TRLCSP (DT 1ª). La serie comparable empieza en 2019.
- **2020**: estado de alarma, plazos administrativos suspendidos del 14 de marzo al 1 de junio (DA 3ª RD 463/2020).
- **Cataluña antes de 2022** (menores, antes de 2023): la PSCP está incompleta (en 2021, 4.090 adjudicaciones de ayuntamientos frente a 10.174 en 2022; en 2022, 13.871 menores frente a 107.492 en 2023).

## `sin_registros` no es incumplimiento

«No consta ninguna publicación en la plataforma» es el dato factual. En municipios pequeños es frecuente que contrate la **diputación**, una **mancomunidad** o una **central de contratación** (disposición adicional 2ª LCSP y art. 36 de la Ley 7/1985 de Bases del Régimen Local), o que el municipio no haga ningún contrato de ese tipo en el año. La página debe redactarlo así, nunca como incumplimiento.

## Trampas

- **Cada ZIP trae las ACTUALIZACIONES del periodo**: un expediente reaparece cada vez que cambia (en el fichero de octubre de 2026 hay `AwardDate` de 2021). Se deduplica por (conjunto, id de la entrada) quedándose con la última versión (`updated`) y el año se asigna por la fecha del hecho. Un año queda completo cuando también se ha leído el año siguiente (lo adjudicado en diciembre se publica en enero): la carga de mantenimiento recalcula siempre el año pasado y el año en curso.
- `atom:updated` **no** es la fecha de publicación.
- Puede haber varios `DOC_FORM`: se toma el primero en «Perfil del contratante».
- Las plataformas agregadas no traen `AwardDate`, ni NIF del órgano, ni `ContractingPartyTypeCode`, ni menores.
- PSCP: los menores se publican casi todos en lotes («publicació agregada»), a menudo meses después; la fecha es la de esa publicación agregada.
- PSCP: los textos llegan con la codificación rota en algún campo («SÃ­» en `es_agregada`), por eso se filtra por `es_agregada = 'NO'`.

## Galicia

Medido con los datos de 2024-2025: la Plataforma de Contratos Públicos de Galicia llega a PLACSP por la agregación **con DIR3** en casi todas sus entradas (3.205 de 3.229 en 2024), así que los concellos que publican allí se identifican bien (869 entradas de concellos con DIR3 L01 en 2024). Decisión:

- **Formalización**: se mide para todos (perfiles de PLACSP + agregación gallega).
- **Adjudicación y menores**: los concellos que ese año solo aparecen en la agregación (48 en 2025, 63 en 2024) van a `no_aplica` (la agregación no trae fecha de adjudicación ni menores). El resto se mide con PLACSP.
- De los 313 concellos, 269 tienen algún anuncio en 2025. 128 no tienen ningún menor en PLACSP ese año, entre ellos Vigo y A Coruña, que sí publican sus licitaciones en PLACSP: publican los menores en otro sitio. No es exclusivo de Galicia (Gijón, Oviedo, Salamanca, León, Alcalá de Henares, Fuenlabrada… hacen lo mismo): por eso los menores llevan `x_publica_en_perfil` (tiene adjudicaciones o formalizaciones en el perfil ese año) para que la página distinga «no consta ningún menor en la plataforma, aunque sí licitaciones» de «no consta nada».

## Limitaciones

- Solo se ve lo que está en las plataformas: un anuncio publicado en otra sede (no en el perfil alojado en PLACSP o en la PSCP) cuenta como «no consta».
- La unidad es el expediente (no el lote): un expediente con varios lotes adjudicados en fechas distintas cuenta una vez, con la primera adjudicación y el primer anuncio.
- Las fechas son las que carga cada órgano; hay erratas (años imposibles, anuncios anteriores al hecho). Las fechas fuera de 2000-2100 se descartan y los retrasos negativos se recortan a 0.
- La PSCP podría mostrar la fecha de la última republicación de un lote agregado en lugar de la primera (no verificado).
- Menores: un mismo contrato puede figurar en la PSCP como varias filas si tiene lotes.
- Los menores de los primeros años de la sindicación (2019-2022) incluyen cargas retroactivas en bloque (la fecha de publicación es la de la carga): en 2019 los menores de las comunidades tienen una mediana de 793 días. Tómense con cautela.
- PLACSP y `medios_contratos` descargan los mismos ZIP: hoy se descargan dos veces al mes.

## Cifras de control

Carga del 25-oct-2026 (PLACSP 2018-2026 y PSCP; fecha de corte 25-oct-2026). Entidades con registros / % de elementos fuera de plazo (todos los elementos de las entidades) / mediana de las medianas por entidad, en días.

| | 2023 | 2024 | 2025 | 2026 (en curso) |
|---|---|---|---|---|
| Adjudicación, ayuntamientos | 3.732 / 20,2 % / 4 | 3.994 / 20,8 % / 4 | 4.119 / 19,5 % / 3 | 3.692 / 15,0 % / 2,5 |
| Adjudicación, diputaciones | 38 / 8,3 % / 1 | 38 / 9,4 % / 1 | 38 / 8,3 % / 1 | 38 / 7,6 % / 1 |
| Adjudicación, cabildos y consells | 10 / 12,5 % / 2 | 10 / 18,7 % / 2 | 10 / 13,6 % / 1 | 10 / 12,5 % / 1 |
| Adjudicación, comunidades | 13 / 16,6 % / 1 | 13 / 13,6 % / 1 | 13 / 17,5 % / 1 | 13 / 10,6 % / 1 |
| Formalización, ayuntamientos | 3.061 / 23,7 % / 5 | 3.314 / 24,9 % / 5 | 3.425 / 23,1 % / 4,5 | 2.999 / 17,7 % / 3 |
| Formalización, diputaciones | 38 / 12,3 % / 1,3 | 38 / 12,2 % / 2 | 38 / 9,7 % / 2 | 38 / 6,4 % / 2 |
| Formalización, cabildos y consells | 10 / 14,1 % / 2,8 | 10 / 16,4 % / 2 | 10 / 14,8 % / 2 | 10 / 13,0 % / 2,5 |
| Formalización, comunidades | 17 / 20,6 % / 4 | 17 / 19,0 % / 3 | 17 / 20,7 % / 3 | 17 / 15,7 % / 2 |
| Menores, ayuntamientos | 2.937 / 38,0 % / 55 | 3.067 / 35,4 % / 52 | 3.176 / 36,6 % / 44 | 2.487 / 25,3 % / 15 |
| Menores, diputaciones | 30 / 39,8 % / 14,5 | 33 / 45,9 % / 10 | 32 / 36,1 % / 11,5 | 32 / 44,9 % / 8 |
| Menores, cabildos y consells | 9 / 28,0 % / 35 | 9 / 27,1 % / 38 | 8 / 20,4 % / 13,5 | 8 / 16,1 % / 15,5 |
| Menores, comunidades | 12 / 40,4 % / 32,5 | 12 / 30,2 % / 24 | 12 / 19,9 % / 18 | 12 / 16,5 % / 7 |

- Cataluña pesa mucho en los menores: en la PSCP los ayuntamientos publican los menores en lotes, a menudo meses después (en 2025, 66,9 % fuera de plazo en 531 ayuntamientos; mediana conjunta 107 días), frente a una mediana conjunta de 13 días en los menores de ayuntamientos de PLACSP.
- Réplica de las muestras de la investigación previa con la misma definición (todas las entradas del fichero, sin deduplicar): perfiles de octubre de 2026, formalización > 15 días 16,3 % (muestra: 15,8 %) y adjudicación 9,4 % (8,8 %); menores de 2025 de órganos con DIR3 L01, mediana 14 días (14) y 19,6 % > 90 días (19,9 %). La diferencia viene de que el fichero de octubre se ha leído más tarde (más días del mes).
- Atribución (2024-2025): el 98 % de las entradas con NIF de forma municipal se casan con un INE; quedan fuera, a propósito, organismos autónomos, gerencias, patronatos, fundaciones, EATIM y mancomunidades.
- Cobertura de ayuntamientos con algún anuncio en 2025, por comunidad: Andalucía 662 de 785, Aragón 504/731, Asturias 77/78, Baleares 61/67, Canarias 87/88, Cantabria 85/102, Castilla y León 650/2.248, Castilla-La Mancha 549/919, Cataluña 777/947 (PSCP), C. Valenciana 481/542, Extremadura 305/388, Galicia 269/313, Madrid 160/179, Murcia 43/45, La Rioja 96/174; Navarra y País Vasco, `no_aplica`.

## Código

- Ingesta: `ingestion/pa_contratos.py` (source dlt `pa_contratos`, recursos `pa_contratos_organos` y `pa_contratos_control`). Reutiliza la descarga y el parser de `ingestion/medios_contratos.py` y el acceso a Socrata de `ingestion/medios_contratos_ccaa.py`.
  - `python -m ingestion.pa_contratos` → año pasado + año en curso (mantenimiento).
  - `--desde 2018` → histórico; `--periodos 202609` → un solo fichero para validar; `--cache-dir` guarda el parquet reducido de cada ZIP para no volver a descargar.
- Modelos: `transform/models/marts/pa_contratos_entidades.sql` (efímero, base común) y `pa_ind_contratos_adjudicacion.sql`, `pa_ind_contratos_formalizacion.sql`, `pa_ind_contratos_menores.sql`; pruebas en `schema_pa_contratos.yml`; fuente en `transform/models/sources_pa_contratos.yml`.
