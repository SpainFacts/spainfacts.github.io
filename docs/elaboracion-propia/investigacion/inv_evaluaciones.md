# Evaluaciones oficiales de publicidad activa con nota por entidad

Investigación del 2026-10-25. Todas las URL dieron HTTP 200 ese día; las tres principales (CSV del Síndic, PDF de Murcia 2023 y PDF del CTBG SPI 2025) se volvieron a comprobar al final.

Muestras y scripts:
- Muestras: carpeta `scratchpad\` (subcarpetas `ctbg\`, `ccaa1\`, `ccaa2\`, `ccaa3\`).
- Scripts:
  - PDF del CTBG 2025: `scratchpad\ctbg_scripts\anexo_plumber.py`, que genera `ctbg\dl\agr\spi2025.csv` con 225 filas.
  - PDF de Murcia: `scratchpad\anexo.py`.

## Tabla priorizada

| Prioridad | Fuente | Ámbito | Años | Entidades | Formato | Clasificación |
|---|---|---|---|---|---|---|
| 1 | **Síndic de Greuges de Catalunya: IDPAC + IADAIP = ITC** | Todos los ayuntamientos catalanes (947), 46 entes supramunicipales, 16 departamentos de la Generalitat, 7 universidades y 6 organismos estatutarios | 2026 (primera edición) | 1.022 | **CSV con licencia CC0** | **Incorporable ya** |
| 2 | **CTBG: informes agregados del sector público institucional estatal (SPI)** | Organismos, empresas, fundaciones, autoridades portuarias, consorcios estatales | 2022 a 2026 | 74 / 81 / 128 / 225 / 153 | Tabla del anexo en .docx (2022-2024) y en PDF (2025-2026) | **Incorporable ya** (docx y PDF 2025); el PDF 2026 requiere trabajo |
| 3 | **CTBG: entidades privadas / perceptoras de subvenciones** (incluye sindicatos y patronales) | ONG, fundaciones privadas, empresas, sindicatos, CEOE, etc. | 2022 a 2025 | 76 / 69 / 79 / 84 | .docx (en 2023, PDF con tabla limpia) | **Incorporable ya** |
| 4 | **Murcia: ICPA (Anexo I del informe IT-Región de Murcia 2023)** | Comunidad Autónoma, 45 ayuntamientos, sector público, universidades, colegios profesionales, sindicatos, partidos | 2020 a 2023 | 334 emplazadas; con nota 47 / 74 / 60 / 47 | PDF con tabla extraíble | **Incorporable ya** |
| 5 | CTBG: partidos políticos (PP, PSOE, Vox, Podemos, Sumar, IU) | 6 partidos | 2024 y 2025 | 6 | .docx individual, con la frase del ICIO | Incorporable ya, con el mismo lector de docx que la ingesta actual |
| 6 | CTBG: terceras y cuartas evaluaciones, corporaciones de derecho público 2022 | Entidades reevaluadas, colegios profesionales y cámaras | 2022 y 2025 | 20 a 136 | .docx | Incorporable ya (es seguimiento; marcar el número de evaluación) |
| 7 | CTBG: órganos constitucionales y autoridades administrativas independientes (AAI) y reguladores | 6 a 10 al año | 2020 a 2022 | ~10 | Solo informes individuales .docx; el agregado no trae tabla | Con trabajo (leer cada docx) |
| 8 | CTBG: SPI 2021 | 49 | 2021 | 49 | El agregado en PDF no tiene tabla por entidad; hay 49 docx individuales | Con trabajo |
| 9 | Síndic: test del solicitante oculto 2024 (`tso_v2.csv`) y piloto de publicidad activa 2023 (`publicitat_activa_v3.csv`) | 743 y 192 entidades | 2023 y 2024 | — | CSV con licencia CC0 | Incorporable como dato aparte; la metodología es distinta y no forma serie con el IDPAC |
| 10 | Castilla-La Mancha: informe anual de la Oficina de Transparencia de la Junta | ~25 entes autonómicos (organismos autónomos, fundaciones, empresas) | 2024 (el de 2023 parece imagen) | ~25 | PDF; los % salen bien, las cabeceras no | Con trabajo (casar los nombres a mano; es autoevaluación del Gobierno) |
| — | Andalucía (CTPDA), Aragón (CTAR), Castilla y León (CTCyL), GAIP, C. Valenciana, Galicia, Navarra, País Vasco, Baleares, Madrid, Asturias, Cantabria, Extremadura, La Rioja, Ceuta, Melilla, CRT de Castilla-La Mancha, diputaciones | | | | | **No** (ver detalle) |

## 1. CTBG

### Comunidades y ayuntamientos con convenio
**No hubo evaluaciones después de 2021.**
- Las páginas `/evaluacion/evaluacion{2022..2025}/{año}/ccaa` y `/eell` dan 404.
- La Memoria 2025 del CTBG cuenta 393 entidades evaluadas, y ninguna es autonómica ni local: https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/nosotros/memorias-y-plan-estrategico/memoria-2025/Memoria_2025_CTBG.pdf
- Lo que ya ingerimos (2020 y revisión de 2021) es todo lo territorial que existe.

### Categorías publicadas por año
| Año | Categorías |
|---|---|
| 2020 | aai, ccaa, corporaciones-de-derecho-publico, eell, sector-publico-institucional-estatal, subvencionadas |
| 2021 | aai, age, ccaa, cdp, eell, eps, organos-constitucionales, spi |
| 2022 | aai, age, cdp, eps, organos-constitucionales, spi |
| 2023 | age, eps, spi, terceras |
| 2024 | age, eps, partidos-politicos, spi |
| 2025 | age, SPI, terceras, cuartas, entidades-perceptoras-subvenciones-ayudas-publicas, partidos-politicos1 |
| 2026 | SPI (publicada el 31-7-2026) |

### Informes agregados con tabla del ICIO por entidad
Todas las rutas cuelgan de `https://consejodetransparencia.es/content/dam/ctransparencia/portal-ctbg/evaluacion/`.

Columnas de la tabla del anexo:
- Entidad
- ICIO
- Diferencia en puntos porcentuales respecto del año anterior, o «Primera evaluación»
- Recomendaciones efectuadas
- Recomendaciones aplicadas
- Mejoras implantadas

| Año / grupo | Ruta | Filas |
|---|---|---|
| 2026 SPI | `evaluaci%C3%B3n-de-2026/spi/Informe-agregado-de-evaluacion-Sector-Publico-Institucional%202026.pdf` | ~153 (PDF con 15 columnas y celdas fusionadas) |
| 2025 SPI | `evaluacion-de-2025/Sector_P%C3%BAblico_Institucional/Informe-agregado-de-evaluacion-Sector-Publico-Institucional%202025.pdf` (Anexo II) | 225 |
| 2025 entidades privadas | `evaluacion-de-2025/entidades-perceptoras-de-subvenciones-y-ayudas-p%C3%BAblicas/Informe-agregado-de-evaluacion-Entidades-Privadas_2025.docx` | 84 |
| 2025 terceras | `evaluacion-de-2025/terceras-evaluaciones/Informe_agregado_evaluacion_terceras-evaluaciones-2025.docx` | 53+24+59 |
| 2025 cuartas | `evaluacion-de-2025/cuartas-evaluaciones/Informe_agregado_evaluacion_cuartas-evaluaciones.docx` | 26 |
| 2024 SPI | `evaluacion-de-2024/spi/Informe-agregado-de-evaluacion-Sector-Publico-Institucional_20241.docx` | 128 |
| 2024 entidades privadas | `evaluacion-de-2024/Sujetos-Privados/241002_Informe_agregado_evaluacion_entidades_privadas_2024.docx` | 79 |
| 2023 SPI | `evaluacion-de-2023/SPI/Informe-agregado-de-evaluacion-Sector-Publico-Institucional-20231.docx` | 81 |
| 2023 perceptoras | `evaluacion-de-2023/Sujetos%20privados/Informe-agregado-de-evaluacion-Entidades-perceptoras-subvenciones-2023.pdf` | ~69 |
| 2022 SPI | `evaluacion-de-2022/SPI/Informe-agregado-de-evaluacion-Sector-Publico-Institucional_20221.docx` | 74 |
| 2022 perceptoras | `evaluacion-de-2022/entidades-perceptoras-subvenciones/Informe-agregado-de-evaluacion-Entidades-perceptoras-subvenciones-2022.docx` | 76 |
| 2022 corporaciones de derecho público | `evaluacion-de-2022/Corporaciones_Derecho_Publico/Informe-agregado-de-evaluacion-Corporaciones-Derecho-Publico.docx` | 20 |
| 2021 SPI | `evaluacion-de-2021/Sector_Publico_Institucional/Informe-agregado-de-evaluacion-Sector-Publico-Institucional.pdf` | Sin tabla; hay que leer los 49 docx individuales |

Grupos sin informe agregado (hay que leer los individuales):
- **Partidos 2024:** `evaluacion-de-2024/Partidos-politicos/Informe-Definitivo-PA-{PARTIDO}-2024.docx`
- **Partidos 2025:** `evaluacion-de-2025/partidos-pol%C3%ADticos/{PARTIDO}/1-Informe-Definitivo-{Partido}-2025.docx`. Ejemplo de la frase: «ICIO se sitúa en el 34,2%».
- **Sindicatos y patronales:** no tienen categoría propia. Van dentro de entidades perceptoras / entidades privadas:
  - 2021-2022: FSP-UGT, CSI-F, CEOE
  - 2024-2025: CEPES, Hostelería
- **Órganos constitucionales y AAI:** sus agregados no traen tabla.

### Fiabilidad de la extracción
**.docx**
- Basta zipfile + XML (`w:tbl`), sin dependencias nuevas.
- Las filas salen limpias.

**PDF 2025**
- Herramientas:
  - `pdftotext -layout` **no sirve**: descuadra nombres y cifras.
  - `pdfplumber.extract_tables` sí sirve, uniendo los nombres partidos en dos filas.
- Comprobaciones:
  - Salen exactamente 225 filas.
  - La media da 38,86, que coincide con el 38,9 % oficial de la nota de prensa del 14-11-2025.
  - ICO (91,7) y AEMPS (52,6) coinciden con sus informes individuales.
- Trampas:
  - **Nombres:**
    - Algunos salen truncados («Barcelona Supercomputing» sin «Center»).
    - Hay abreviaturas que cambian de un año a otro («AP Valencia» frente a «Autoridad Portuaria de Valencia»), así que hace falta una tabla de equivalencias.
  - **Cifras:**
    - El agregado redondea: ISDEFE 2024 sale con 100,0 y el individual dice 99,6.
    - Algunas diferencias en p.p. no cuadran por décimas.
    - Hay decimales con punto.

**PDF 2026**
- Al extraerlo en bruto sale sucio (159 filas con basura).
- Hace falta un parser propio por página del Anexo II, o raspar los 153 docx individuales.

**Patrón de URL**
- No es regular: desde 2025 hay una subcarpeta por entidad.
- La forma fiable es raspar los enlaces `/content/dam/` de cada página de categoría.

**Datos abiertos**
- No hay datos abiertos de evaluaciones: `/datos-abiertos` da 404.
- En datos.gob.es solo figuran reclamaciones.

Muestra:
- SPI 2025: `Fundación Thyssen-Bornemisza | 100 | +46,3` · `ICO | 91,7 | +53,9` · `ETSA | 35,7 | -7,6` · `Obra Pía | 0,0 | primera evaluación`
- SPI 2024: `ISDEFE | 100,0` · `ENSA | 96,6`
- Entidades privadas 2025: `Médicos del Mundo | 100` · `Stellantis España | 3,3`

## 2. Órganos autonómicos

### Cataluña: Síndic de Greuges (incorporable ya)
**Páginas**
- Avaluació de la transparència: https://www.sindic.cat/ca/page.asp?id=892
- IDPAC: https://www.sindic.cat/ca/page.asp?id=904
- IADAIP: https://www.sindic.cat/ca/page.asp?id=902

**CSV**
- URL: https://dadesobertes.seu-e.cat/dataset/5f8e4974-9cb0-4483-b7e7-ec844500b6c3/resource/6b81069f-19ce-4b75-b9d2-33ad43c1d70d/download/idpac.csv (826 KB)
- Publicado el 29-09-2026.
- Licencia CC0.
- `itc.csv`, del conjunto de datos dab198f5, es idéntico.

**Columnas**
- `nom`, `Municipi`, `provincia`, `Comarca`
- `CategoriaN1/N2/N3`
- `cens` (población)
- `IADAIP` y sus subnotas
- `IDPAC`
- `ITC` = (IADAIP + IDPAC) / 2
- `LinkPublicitatActiva` (informe individual)

**Metodología**
- Revisión externa del Síndic.
- El IDPAC (0-100) combina contenido obligatorio (ICOB, 70 %) y espacio web (IET, 30 %).
- Trabajo de campo de enero a mayo de 2026, alegaciones hasta julio y verificación hasta septiembre.
- El IADAIP sale del test del solicitante oculto de 2025.
- Guía: https://www.sindic.cat/site/files/informe_transparencia/guia_metodologica_municipis_no_rurals_2026.pdf

**Cifras**
- IDPAC: media 66,5, rango 44,9-97,9.

**Muestra (IADAIP / IDPAC / ITC)**

| Municipio | IADAIP | IDPAC | ITC |
|---|---|---|---|
| Barcelona | 88,93 | 91,88 | 90,41 |
| Terrassa | 96,03 | 91,20 | 93,61 |
| Sabadell | 94,43 | 94,34 | 94,38 |
| Tarragona | 64,26 | 78,96 | 71,61 |

**Trampas**
- No trae código INE: hay que cruzar por `Municipi` + `provincia` y comprobar con `cens`.
- Algunos nombres llevan espacios sobrantes.
- Los números vienen como texto con punto decimal.
- Los enlaces a los informes llevan `Cookie=` y pueden caducar.

**Extras**
- Test del solicitante oculto 2024, 743 entidades: https://dadesobertes.seu-e.cat/dataset/5df2e390-eb04-4b65-9dfe-9c7e97d0cad3/resource/ea4a5409-0f3f-40f0-96b0-7f68d51b1a30/download/tso_v2.csv
- Piloto de publicidad activa 2023, 192 entidades, con otra metodología: https://dadesobertes.seu-e.cat/dataset/e801136d-fd9f-484c-bf9e-006382d5f95c/resource/c50cf973-af0c-41eb-82c5-a02616987f31/download/publicitat_activa_v3.csv
- Base de datos de 2024 en ZIP: respuestas ítem a ítem, sin nota.

### Región de Murcia (incorporable ya)
**Fuentes**
- Índice: https://comisionadotransparencia.carm.es/informes-de-evaluacion
- Informe 2023 (PDF de 9,5 MB, 78 páginas): https://comisionadotransparencia.carm.es/documents/d/guest/INFOR_-EVAL_CTRM_2023-IT-RM_Y_PORTADA-cleaned
  - El **Anexo I (páginas 67-78)** da el ICPA 2020, 2021, 2022 y 2023 de 334 entidades.
  - Cuando no hay nota aparece NP (no participó) o NC.

**Extracción**
- `pdfplumber.extract_tables` saca 334 filas de 6 columnas limpias; hay que unir los saltos de línea en los nombres.
- Es **fiable**.
- En 2021 salen 74 entidades con nota y el texto dice 78: hay que revisarlo.

**Muestra**
- `AYUNTAMIENTO DE MULA | Ayuntamientos | 8,34 | 9,11 | 9,31 | 9,57`
- `COMUNIDAD AUTÓNOMA DE LA REGIÓN DE MURCIA | 8,67 | 8,84 | 8,59 | 8,80`
- `AYUNTAMIENTO DE CARTAGENA | 7,55 | 8,45 | 7,98 | 7,72`
- `AYUNTAMIENTO DE YECLA | 3,85 | 1,96 | 7,90 | 8,44`

**Metodología**
- ICPA (0-10) = 0,7 × ICIO (MESTA) + 0,3 × ICS (soporte web).
- Es una autoevaluación de cada entidad en la plataforma T-Región de Murcia, verificada por el Consejo.
- La participación es voluntaria y baja: hay que mostrar NP como «no participó», nunca como 0.

**Trampas**
- No mezclar con el «IT-Región» del informe 2020, que es otro índice e incluye transparencia voluntaria.
- Licencia: no se indica (la web dice «todos los derechos reservados»). Citar la fuente según la Ley 37/2007.

**Futuro**
- SEPA_RM, con evaluación desde 2026 y metodología nueva: https://comisionadotransparencia.carm.es/sepa_rm
- Rompe la serie 2020-2023.

**Otros documentos**
- El informe ejecutivo solo trae agregados.
- El informe 2022 trae tablas por entidad en las páginas 14-16 y 34.

### Castilla-La Mancha
**Informe anual de la Oficina de Transparencia de la Junta (con trabajo)**
- 2024: https://transparencia.castillalamancha.es/sites/default/files/documentos/pdf/20251217/informe_2024.pdf (29 páginas)
- Da el % de cumplimiento de unos 25 entes autonómicos. Ejemplos: Fundación Impulsa 62,16 %, RTVCLM 86,37 %.
- Extracción: los % salen bien con pdfplumber, pero las cabeceras con los nombres no.
- El informe de 2023 parece imagen.
- Es una autoevaluación del Gobierno, no de un órgano independiente.

**Consejo Regional de Transparencia (CRT)**
- Web: https://www.consejotransparenciaclm.es/
- Funciona desde noviembre de 2023.
- Su sistema de evaluación está previsto para 2026.
- La herramienta Evalua-T no publica resultados.
- Clasificación: no, de momento.

### Comunidad de Madrid
- El Consejo de Transparencia y Protección de Datos funciona desde mayo de 2024. Memoria 2025: https://www.comunidad.madrid/docs/assets/2026/04/21/memoria_de_actividad_2025_ctpd.pdf
- Empezó a evaluar a las entidades locales a finales de 2025 y a la Comunidad en febrero de 2026.
- Los resultados irán en la Memoria 2026, hacia abril de 2027.
- **Es la candidata más clara a futuro**: todos los ayuntamientos madrileños.
- «Evaluando la transparencia» (https://www.comunidad.madrid/transparencia/evaluando-transparencia) es cualitativo, sin nota.

### Sin nota por entidad (no)
- **Andalucía (CTPDA):**
  - La herramienta de autoevaluación no publica resultados.
  - Los Planes de Control e Inspección dan agregados, y sus PDF de 2019-21 y 2023-24 están escaneados: https://www.ctpdandalucia.es/transparencia-del-consejo/planificacion-evaluacion-estadistica/planes-anuales-de-control-e-inspeccion/planes-anuales-de-control-e-inspeccion-sobre-publicidad-activa
  - Como contexto sirve el CSV de resoluciones de denuncias por organismo (datos abiertos de la Junta).
- **Aragón (CTAR):** solo resoluciones y estadísticas de acceso.
- **Castilla y León (https://www.ctcyl.es):**
  - Las memorias traen autoevaluación narrativa por cuestionario (91 de 112 devueltos en 2025), sin índice.
  - Solo se podría sacar a mano un dato binario: si la entidad remitió o no el cuestionario.
- **GAIP:** no tiene competencia sobre publicidad activa.
- **Comunitat Valenciana:** el Consell dice en sus memorias de 2024 y 2025 que evaluar es «absolutamente imposible» con sus medios. Memorias: https://conselltransparencia.gva.es/es/memorias
- **Galicia:** la Valedora y la Comisión da Transparencia solo tramitan quejas.
- **Navarra:**
  - La aplicación de evaluación sigue a medio hacer (memoria 2024).
  - Los análisis de 2019 y 2020 son cualitativos.
  - Hay una reforma de la Ley Foral en 2026: vigilarla.
- **País Vasco:**
  - La ley vasca de transparencia no está aprobada y la autoridad Gardena aún no existe.
  - La CVAIP solo resuelve reclamaciones de acceso.
- **Baleares:**
  - La CRAIP está suspendida y el CTBG lleva las reclamaciones por convenio.
  - El informe del Govern no trae puntuaciones.
- **Asturias:** el Consejo no está operativo; su creación está prevista entre 2026 y 2027.
- **Cantabria, Extremadura, La Rioja, Ceuta y Melilla:** tienen convenio con el CTBG y no hay órgano propio.
- **Diputaciones:** la de Badajoz aloja indicadores sin nota; en las demás no hay evaluaciones con nota.

## Recomendación de implementación
1. **Nuevo recurso `pa_sindic`.**
   - Leer `idpac.csv` con licencia CC0.
   - Cruzar con el código INE por nombre + provincia (y comprobar con `cens`).
   - Guardar IDPAC, IADAIP e ITC.
   - Escala 0-100, comparable en forma con el ICIO, pero la metodología no es la misma.
2. **Ampliar `pa_ctbg` con los informes agregados.**
   - Leer las tablas `w:tbl` de los .docx de 2022, 2023 y 2024 (SPI y privadas).
   - Leer con pdfplumber los PDF de 2023 (perceptoras) y 2025 (SPI).
   - Añadir los docx de partidos de 2024 y 2025 con el regex actual.
   - Hace falta una tabla de equivalencias de nombres de entidades entre años.
   - Dejar para después: SPI 2021 (49 docx individuales), SPI 2026 (parser propio) y órganos constitucionales / AAI.
3. **Nuevo recurso `pa_murcia`.**
   - Extraer el Anexo I del informe 2023 con pdfplumber.
   - Escala 0-10, como el ITCanarias.
   - Marcar NP como «no participó» (nunca como 0) y etiquetar la fuente como «autoevaluación verificada».
   - Cruzar los 45 ayuntamientos con el código INE por nombre.
4. **Vigilar:**
   - CTPD de Madrid (Memoria 2026, hacia abril de 2027).
   - CRT de Castilla-La Mancha (2026-2027).
   - SEPA_RM de Murcia (resultados de 2026).
   - Reforma navarra y Gardena en el País Vasco.
   - Segunda edición del IDPAC (2027).
