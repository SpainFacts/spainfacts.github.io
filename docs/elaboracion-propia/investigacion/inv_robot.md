# Robot de transparencia municipal: investigación y verificación

Fecha: 25-10-2026. Todo lo que sigue sale de peticiones reales hechas hoy con User-Agent
`SpainFactsTransparenciaBot/0.1 (+https://spainfacts.org/fuentes)`, comprobando robots.txt antes
de cada host y con pausas (2-3 s por petición en las pruebas secuenciales; en la muestra de 300 portadas,
16 hilos y **una sola petición por host**). No se ha tocado el repo. Ficheros de trabajo en
`scratchpad/robot/` (scripts) y `scratchpad/dl/` (descargas: BDGEL, DIR3, Wikidata, muestra).

---

## 0. Conclusiones en una página

1. **Fuente de URLs: no hay ninguna oficial completa.** BDGEL (Hacienda) trae campo `WEB`, pero solo en el
   33 % de los ayuntamientos. Wikidata (P856) llega al 80 %. Juntas: 82 %. Si se añade el dominio propio del
   correo (BDGEL/DIR3): 89 %. Y si se prueban subdominios de las plataformas (`{municipio}.sedelectronica.es`,
   `{municipio}.sedipualba.es`), **88 % de la muestra queda ligada a una plataforma común** (hay que validar
   los homónimos).
2. **Concentración muy alta.** En una muestra aleatoria de 300 municipios, el **61 % tiene sede en Gestiona
   (esPúblico, `*.sedelectronica.es`)**, a lo que se suma un 3 % en su marca catalana/balear
   (`*.eadministracio.cat`) y un 7 % en Sedipualba. En Cataluña manda la Seu-e del Consorci AOC
   (`seu-e.cat`). Con unas 10-12 plataformas se cubre el ~85-90 % de los municipios.
3. **Problema grave: robots.txt.** **Gestiona prohíbe en robots.txt todo salvo `/` y `/info`** (`Disallow: /*`),
   así que su portal `/transparency` (el de la mayoría de los municipios) **está prohibido en su robots.txt**.
   La Seu-e de la AOC bloquea justo las actas de pleno, la RLT, la plantilla y las subvenciones concedidas. La
   Generalitat (`governobert.gencat.cat`) y la Diputació de Barcelona (`diba.cat`) tienen `Disallow: /` para
   cualquier robot que no sea un buscador de su lista. Entre las dos plataformas, sus robots.txt cubren el
   ~65-75 % de los municipios.
4. **Atención a urllib.robotparser.** El `urllib.robotparser` de Python no cumple el RFC 9309: no entiende
   `*` ni `$` y aplica la primera regla que coincide, no la más específica. Con él, Gestiona y Seu-e salían
   como «permitido», y es falso. Hay que usar **Protego** (el parser de Scrapy), que da el resultado correcto.
5. **Fechas: fiables solo dentro del contenido.** El `Last-Modified` del HTML es la hora de la petición
   (Barcelona, Ciudad Real, Zizur) o la fecha de compilación de la SPA (dipucr), así que no sirve. Las
   señales útiles son: año en el título o en el nombre del fichero («PRESUPUESTO GASTOS 2020», «ACTA DEL
   PLENO 2022-0006»), `fecha_publicacion` en las API (dipucr), y `/CreationDate` del PDF más el
   `Last-Modified` del fichero estático (Zaragoza: PDF de declaración de bienes con año 2026 en la ruta,
   creado el 28-07-2026 y servido con fecha del 13-08-2026).
6. **Fallos que no son de la entidad.** Hoy mismo, `*.transparencialocal.gob.es` (el «Portal de
   Transparencia Local en la nube» de Hacienda/FEMP, más de 1.300 entidades adheridas) lleva caído desde que
   **su certificado caducó el 27-09-2026**: devuelve 500 Proxy Error. Además, en la muestra hay un 14 % de
   errores de red o TLS, un 2 % de cortafuegos (AWS WAF «challenge» en las webs de la Diputación de Málaga,
   403/429 en Gipuzkoa) y un 6 % de dominios caducados o secuestrados (uno lleva a un casino). **Todo eso es
   «no evaluable», nunca «incumple».**

---

## 1. Fuentes oficiales de la URL de cada entidad

| Fuente | Qué tiene | Cobertura medida (ayuntamientos) | Formato / acceso | Veredicto |
|---|---|---|---|---|
| **BDGEL (Hacienda, SGFAL)**: «Consultas más frecuentes → Direcciones postales de Entidades Locales» | 17.164 entes vigentes, con dirección, teléfono, fax, **`siteWeb`** y email. Códigos CDAD/PROV/CORP/TIPO1/TIPO2 (ayuntamiento = `A`/`A`; diputación, cabildo o consejo = `D`/`D`) | 8.130 ayuntamientos: **web 2.696 (33 %)**, email 6.853 (84 %), email de dominio propio (no gmail, yahoo…) 5.607 (69 %). Diputaciones, cabildos y consejos: 42 de 52 con web | JSON por POST. Flujo verificado: `GET Home/ConsultaBDGEL` → `GET Home/AccesoAnonimoBDGEL` → `POST Reports/GetDirecciones` con `{ProvinciaId:27, ComunidadId:1, Ambito:0}` (0 = nacional). Son 10 MB y una sola petición | **Fuente primaria de identidad**: código, teléfono y CP sirven para validar. Web escasa y anticuada: la de Huesca apunta a `ayuntamientohuesca.es`; muchas son `//www.dipalme.org/...` genéricas o textos como «no tiene» |
| **DIR3 (CTT, administracionelectronica.gob.es)**: «Listado Unidades EELL.xlsx» | 26.608 unidades; `C_ID_UD_ORGANICA` (L01+INE), NIF, nivel jerárquico, columna `CONTACTOS` | 8.132 L01 de nivel 1 (todos vigentes). Contacto 86,5 % (**solo emails**); URL 0,01 % | XLSX directo (2 MB) | Sirve para el NIF (validar sedes) y como pista de dominio por el email. No da URL |
| **Wikidata** P856 con P772 (código INE de 5 cifras) | 8.188 ítems con código INE | **6.503 con web (80 %)** | SPARQL, una consulta | El mejor relleno, pero con errores: Bilbao → `bilbaoturismo.net`, Abejar → `abejar.techpanga.com`, La Guardia (Toledo) → dominio caducado que hoy es un casino. Filtrar por `P31 = Q2074737` deja fuera ~2.000 municipios (los catalanes usan otra clase), así que **no hay que filtrar por P31** |
| datos.gob.es | La ficha BDGEL (e05250001) remite a la misma aplicación. La del REL «búsqueda por provincias» es del ministerio extinto | — | — | Nada que no esté en BDGEL o DIR3 |
| REL (Ministerio de Política Territorial) | Registro jurídico: nombre, código, población | No se encontró descarga masiva con web | Consulta HTML | Innecesario: BDGEL lo replica |
| **Subdominios de plataforma** (sección 2) | `{slug}.sedelectronica.es`, `{slug}.sedipualba.es`, `{slug}.eadministracio.cat` | En la muestra de 300, **81 de los 92 municipios sin web válida** tienen sede en Gestiona o Sedipualba | DNS + `GET /` (permitido por robots) | Muy útil, con cuidado (ver abajo) |

**Combinación medida** (8.130 ayuntamientos): BDGEL ∪ Wikidata = 6.683 (82 %); solo dominio propio del email:
565 (7 %); sin nada: 882 (11 %). De los 1.702 con web en ambas fuentes, el host no coincide en 547 (32 %).
Suele ser `//` frente a `http://`, pero también son webs distintas: Adra, `ayuntamientoadra.com` frente a
`adra.es`.

**Trampas al descubrir URLs:**
- `*.sedelectronica.es` tiene **DNS comodín**: un nombre inventado devuelve 200 «Sede Electrónica
  Indeterminada» (411 bytes). Hay que descartar ese título.
- `*.eadministracio.cat` también responde a cualquier nombre, pero con un certificado que no coincide.
- **Homónimos**: `arroyomolinos.sedelectronica.es` es Arroyomolinos (Madrid: BOCM, teléfono 91…), no
  Arroyomolinos (Cáceres). Hay que validar con el teléfono o el CP de BDGEL, o con el NIF de DIR3.
- La validación por contenido de portada (nombre del municipio + «ayuntamiento/ajuntament/concello/udala/sede»)
  marcó **11 de 173 portadas (6 %)** como sospechosas: dominios caducados (`expireddomains.com/...arbizu`),
  web de una cuadrilla en vez del municipio (Berantevilla → `cuadrilladeanana.es`), o Arraya de Oca →
  `belorado.org`.

---

## 2. Plataformas que concentran portales

### 2.1 Reparto medido (muestra aleatoria de 300 ayuntamientos, semilla 2026)

- Portada accesible (HTTP 200): 174 (58 %). Sin URL en ninguna fuente: 59 (20 %). Errores de red o TLS: 42
  (14 %; 12 se recuperan con la URL alternativa o sin verificar el certificado). Robots prohíbe hasta la
  portada: 8 (2,7 %; Cabanes, Borja, Alaior…). WAF/403/429: 6 (2 %).
- **Sede detectada por subdominio:** `sedelectronica.es` 182 (61 %), `sedipualba.es` 20 (7 %),
  `eadministracio.cat` 10 (3 %). Sin ninguna de ellas: 88.
  - Por comunidad: Castilla y León 75 de 79 en Gestiona; Castilla-La Mancha 30 Gestiona y 5 Sedipualba de 43;
    Aragón 14 Gestiona y 7 Sedipualba de 22; C. Valenciana 19 y 3 de 23; La Rioja 7 de 7; Extremadura 10 de 12;
    Madrid 6 de 7. **Sin Gestiona:** Cataluña (AOC), País Vasco (13 de 13 sin ella), Galicia (13 de 14),
    Andalucía (9 de 23 sin ella).
- **Plataforma común detectada (portada o subdominio): 264 de 300 (88 %).**
- **Adónde lleva el enlace de transparencia de la portada** (174 portadas): sin enlace visible en la portada
  59 (34 %); Gestiona 49; Seu-e AOC 25; página propia 23; transparencialocal.gob.es 2; y uno por cada otra
  (dipucr, dipalme, cumpletransparencia, gipuzkoairekia, transparenciasalamanca, EPRINSA
  `transparencia.{x}.es`…).

### 2.2 Ficha de cada plataforma (probada)

| Plataforma | Patrón URL | Estructura | ¿Robots permite? | Cobertura aprox. |
|---|---|---|---|---|
| **Gestiona (esPúblico)** | `{slug}.sedelectronica.es/transparency/{uuid}/`; en Cataluña y Baleares, `{slug}.eadministracio.cat/transparency/` | Árbol normalizado e igual para todos: «1. INSTITUCIONAL (n) … 3. ECONÓMICA → 3.1 PRESUPUESTOS → 3.1.1 PRESUPUESTOS / 3.1.2 MODIFICACIONES / 3.1.3 EJECUCIÓN / 3.1.4 ESTABILIDAD», con **recuento de documentos en cada nodo**. Los UUID cambian por municipio, los rótulos no. Wicket (stateful), sin API ni RSS. Las fechas solo están en el título (ej. Abejar: el último presupuesto publicado es el de **2020**; última acta visible, «ACTA DEL PLENO 2022-0006») | **NO.** `User-agent: * / Disallow: /* / Allow: /$ / Allow: /info$` | **~60-64 % de los municipios** (sobre todo los de menos de 5.000 habitantes de CyL, CLM, Aragón, Valencia, Rioja y Extremadura) |
| **Seu-e (Consorci AOC)** | `seu-e.cat/{ca}/web/{municipi}/govern-obert-i-transparencia/...` | Árbol fijo de la Llei 19/2014: «Informació institucional i organitzativa / Contractes, convenis i subvencions / Gestió econòmica / Acció de govern i normativa», bloque «Darreres actualitzacions». Liferay | **Parcial.** Bloquea `actes-de-ple`, `subvencions-atorgades`, `ajuts-atorgats`, `convocatories-de-personal`, `plantilla-empleats-publics`, `relacio-de-llocs-de-treball-rlt` y los recursos de datos abiertos equivalentes | ~70 % de Cataluña en la muestra (≈ 650 municipios) |
| **Sedipualba (Dip. Albacete; muy usada en Huesca, Valencia y algo en Navarra y Murcia)** | `{slug}.sedipualba.es`; el enlace de «Portal de transparencia» suele salir de la plataforma: a la web del municipio (Huesca: `www.{x}.es/transparencia`, Liferay de la DPH), a `transparencialocal.gob.es` (Estubeny), a ANIMSA (Lizoain) o a nada (Alfara de la Baronia: enlace vacío) | La sede no aloja el contenido de transparencia; en Huesca es una página de la plantilla DPH (Salas Altas: **la página está vacía**, solo el título) | Sí (solo bloquea tablón, firma y TSA) | ~7 % de la muestra |
| **Dip. Ciudad Real (nuevo 2026)** | `{x}-transparencia.dipucr.es/portal/{id}` | SPA con **API JSON pública**: `/api/publicas/entidades/{id}/indicadores` (árbol con **códigos ITA**: A, A-S1, A-1…), `/api/publicas/indicadores-con-publicaciones/{id}`, `/api/publicas/ultimas?entidad_id=…` con `fecha_publicacion`. Muestra además su propio «% de cumplimiento» (La Solana: 61 de 64 indicadores, última publicación 26-06-2026) | **Sí, explícito:** `Allow: /portal/` y `Allow: /api/publicas/` | ~100 municipios de Ciudad Real (estimado) |
| **ANIMSA (Navarra)** | `transparencia.animsa.es/{NIF}` (ej. `P3190700I`, Zizur Mayor) | Blazor Server por websocket: **hace falta navegador sin cabeza**. Árbol de la Ley Foral 5/2018 (11 apartados). Zizur: en «5.1 Información económica…» solo hay «Bases ejecución presupuesto 2024», aunque su WordPress tiene más. **Hay doble portal: riesgo de falso negativo** | No tiene robots.txt (permitido) | Buena parte de los ~270 municipios navarros |
| **Expert@ (Región de Murcia)** | `sede.{x}.regiondemurcia.es/web/transparencia?entidad={INE}` | HTML de la sede | robots 404 (permitido) | Varios municipios murcianos |
| **Dip. Badajoz** | Webs municipales en `dip-badajoz.es/municipios/...codigo=N` y `transparenciabadajoz.es/transparencia.php?codigo=N&anno=AAAA` | Por año. Hoy el dominio redirige a un host mal formado (`turismoapps.dip-badajoz.es` + ruta pegada): **enlace roto** | Dip: permitido | ~160 municipios de Badajoz |
| **La Rioja** | `ayto{x}.larioja.org` (WordPress del Gobierno riojano) | WordPress con sitemap | Sí | La mayoría de los pequeños de La Rioja |
| **Galicia «sxc»** | `sede.{concello}.gal/sxc/gl/portal_transparencia/` | HTML de la sede | Sí | Muchos concellos (estimado) |
| **Gipuzkoa** | `{x}.gipuzkoairekia.eus`, `gardentasuna.{x}.eus` | Diputación Foral; régimen y portal propios | 403/429 en algunas webs | Gipuzkoa |
| **EPRINSA (Dip. Córdoba)** | `transparencia.{x}.es` (WordPress con `/feed/`) | Índice «Publicidad activa / Datos abiertos / Participación» con **RSS** | Sí | Municipios de Córdoba |
| **transparencialocal.gob.es (Hacienda/FEMP)** | `{x}.transparencialocal.gob.es/es_ES/` | — | **Caído hoy**: certificado FNMT caducado el 27-09-2026 y 500 Proxy Error | Más de 1.300 entidades adheridas en 2016 (dato de prensa); su uso actual es desconocido |
| **cumpletransparencia.es** | `{x}.cumpletransparencia.es` | Árbol «Información institucional…» | `Allow: /` | Pocos |
| **Plataforma SaaS multi-inquilino (Teror y otros)** | `transparencia.{x}.es` → API `/api/v1/navbar`, `/api/v1/info-portal` (tenant id 40) | SPA con API JSON. El enlace «Plenos» de la portada de Teror lleva a **404**: migración con enlaces rotos | `Disallow:` vacío (permitido) | Desconocida |
| **Diputación de Málaga** | Webs municipales tras CloudFront | **AWS WAF «challenge»** (HTTP 202, cuerpo vacío): Algatocín, El Borge, Almargen, Iznate | No se debe sortear | ~100 municipios de Málaga |
| **Webs propias** (grandes ciudades) | `madrid.es` → `transparencia.madrid.es`; `ajuntament.barcelona.cat/transparencia`; `zaragoza.es/sede/portal/transparencia/`; `sevilla.org/transparencia` | Heterogéneas. **Zaragoza publica su propio catálogo con estado «Actualizado/Pendiente»** por obligación | Madrid: permitido. Barcelona: lista larga de bots de IA bloqueados, el nuestro no está. Sevilla: bloquea `/*?` | Unos 150 municipios grandes |

**Sobre el objetivo «10-15 plataformas cubren la mayoría»:** se confirma para municipios pequeños y medianos.
Pero las dos mayores (Gestiona y AOC) están cerradas por robots.txt, del todo o en parte.

---

## 3. Comprobaciones automatizables (base estatal + LBRL)

Principios: (a) medir la **base estatal común** (Ley 19/2013, arts. 5-8; LBRL; LCSP; RD 635/2014) para comparar
a todos por igual. Lo que añade cada ley autonómica (Cataluña 19/2014, Navarra LF 5/2018, Aragón 8/2015,
Andalucía 1/2014, Galicia 1/2016, Castilla y León 3/2015, Murcia 12/2014, Canarias 12/2014, Madrid 10/2019,
C. Valenciana 1/2022, CLM 4/2016, Asturias 8/2018, Cantabria 1/2018, La Rioja 3/2014, Extremadura 4/2013;
**las de Baleares y País Vasco, por verificar**) va en indicadores aparte. (b) Cada indicador binario lleva su
**evidencia archivada** (URL, captura WARC y hash). (c) Si hay fuente central, se cruza con ella.

| # | Comprobación | Base legal | Detección | Fecha de la última actualización | Riesgo de falso negativo |
|---|---|---|---|---|---|
| C0 | Existe portal o sección de transparencia accesible | art. 5.4 y 10 Ley 19/2013 | Enlace desde la portada o la sede con texto «transparencia / transparència / gardentasuna / goberno aberto»; árbol de plataforma reconocido | — | **Alto**: el 34 % de las portadas accesibles **no enlaza** transparencia (está en la sede); enlaces vacíos (Alfara) o rotos (Teror, Badajoz). Mitigación: buscar también en la sede, el sitemap y el subdominio `transparencia.` |
| C1 | Organigrama / estructura | 6.1 | Nodo «Institucional / Organización» con documento o página que contenga «organigrama» o una imagen o PDF | Año en el nombre; `CreationDate` del PDF | Medio (puede ser una página HTML sin esa palabra) |
| C2 | Cargos: identificación y perfil o trayectoria | 6.1 | Página de corporación con nombres de concejales (cruzar con las listas de concejales del Ministerio del Interior, que el repo ya tiene) | — | Bajo si se cruza con Interior |
| C3 | Retribuciones de altos cargos y electos | 8.1.f | Palabras «retribuciones / dedicación exclusiva / indemnizaciones / asistencias» + importes (€) en el nodo correspondiente | Año en el documento | **Medio-alto**: suele estar dentro del acta del pleno de organización y no en una sección propia. Se puede dar como «consta en sección específica» |
| C4 | **Presupuesto del año en curso** (o prorrogado) | 8.1.d | Documento con «presupuesto» y el año N (o N-1 + «prórroga») | **Año en el título**, que es lo más fiable; `CreationDate` del PDF | Medio. Cruzar con CONPREL (si consta el presupuesto N en Hacienda pero no en el portal → «aprobado pero no publicado en el portal») |
| C5 | Ejecución presupuestaria y estabilidad | 8.1.d | Nodos «ejecución / estabilidad / PMP» | Trimestre en el título | Alto (muchos solo enlazan a Hacienda) |
| C6 | Cuentas anuales / liquidación | 8.1.e | «cuenta general / liquidación» + año N-1 o N-2 | Año | Medio; cruzar con rendiciondecuentas.es (crawl del TCU ya en el repo) |
| C7 | **Contratos / perfil del contratante** | 8.1.a; LCSP arts. 63 y 347 | Enlace a `contrataciondelestado.es` o a la plataforma autonómica; o listado de contratos (incluidos los menores, trimestral) | Fecha de la última licitación en PLACSP (sindicación ATOM que el repo ya ingiere) | Bajo para el «enlace»; alto para «contratos menores trimestrales» |
| C8 | Convenios y encomiendas | 8.1.b | Nodo «convenios» con documentos | Año en el título | Alto (muchos municipios pequeños no firman convenios: **no consta ≠ incumple**). Indicador débil |
| C9 | Subvenciones y ayudas concedidas | 8.1.c | Nodo «subvenciones» o enlace a BDNS | Año; cruzar con la API de BDNS por órgano DIR3 | Medio. En la Seu-e está **bloqueado por robots** |
| C10 | **Actas de pleno: existencia y fecha de la última** | LBRL art. 70.1, ROF art. 229 (y la mayoría de las leyes autonómicas) | Lista de actas con fecha de sesión (en el título: «ACTA DEL PLENO 2022-0006», o «sesión de dd/mm/aaaa» dentro del PDF) | **Fecha de la sesión** (contenido). Umbral: pleno ordinario al menos trimestral en municipios de menos de 5.000 habitantes (LBRL 46.2.a), así que más de 6 meses sin acta es una señal | Medio (actas en el tablón o en un videoacta aparte). En la Seu-e está **bloqueado** |
| C11 | **Declaraciones de bienes y actividades de los concejales** | **LBRL 75.7** + art. 8.1.h Ley 19/2013 | Documentos «declaración de bienes / registro de intereses» + nombres de concejales | Año en la ruta o el título (Zaragoza: `/declaraciones/2026/bienes/…pdf`); `CreationDate` | Medio |
| C12 | RPT / plantilla | LBRL 90 y TRRL 127 (plantilla); RPT según la ley autonómica | «relación de puestos / RPT / plantilla» | Año | Medio. En la Seu-e está **bloqueado** |
| C13 | Inventario de bienes inmuebles | 8.3 | «inventario / patrimonio / bienes inmuebles» | Año | Medio |
| C14 | Normativa vigente y en tramitación | 7.c y 7.e | «ordenanzas»; «información pública / consulta pública» | Fecha del anuncio | Alto para «en tramitación» (va al BOP o al tablón) |
| C15 | Periodo medio de pago publicado | RD 635/2014 art. 6 | «periodo medio de pago / PMP» + mes | Mes en el título | Medio. Hacienda ya lo publica (el repo lo tiene): se mide solo la publicación propia |

**Reglas de fecha** (en este orden): 1) fecha estructurada de la plataforma (`fecha_publicacion` de dipucr,
«Darreres actualitzacions» de la Seu-e); 2) fecha **dentro del contenido**: sesión del acta, año del presupuesto
o de la declaración; 3) año o fecha en el título o en el nombre del fichero; 4) `/CreationDate` y `/ModDate` del
PDF (pypdf); 5) `Last-Modified` **solo en ficheros estáticos**, nunca en el HTML (comprobado: el HTML devuelve
la hora de la petición). Se guarda la fecha y también **qué regla la produjo**.

**Estados por comprobación:** `consta` · `consta_desactualizado` (con umbral por indicador) ·
`no_consta` · `no_evaluable` (con motivo: robots, WAF, caída de plataforma, TLS, SPA no renderizada,
URL no validada). El último estado nunca cuenta como incumplimiento.

---

## 4. Ética y legalidad

- **robots.txt** no es vinculante en España. Para leerlo bien hay que usar **Protego** (RFC 9309: comodines, `$`, regla más larga), no urllib. Comprobado con
  Protego: Gestiona `/transparency` → **prohibido**; Seu-e `.../actes-de-ple` → **prohibido**;
  `.../gestio-economica` → permitido; `governobert.gencat.cat` y `diba.cat` → **prohibidos** (lista blanca
  de buscadores); `transparencia.madrid.es` → permitido; `comunidad.madrid` → permitido con `Crawl-delay: 10`;
  Tineo `/documents/` → prohibido.
- **Cortafuegos y CAPTCHA** (Málaga): pasan a la cola de verificación humana del dueño.
- **Ritmo:** como máximo 1 petición cada 5 s por host. En plataformas compartidas (un mismo backend para miles
  de subdominios), un límite global por plataforma (≤ 1 petición/s en total), franja nocturna (22-07 h),
  `If-Modified-Since`/ETag en la segunda ronda, parar ante 429/503 con espera exponencial, y obedecer
  `Crawl-delay`.
- **Identificación:** UA `SpainFactsTransparenciaBot/1.0 (+https://spainfacts.org/robot-transparencia)`. Esa
  página debe explicar el propósito, el código, cómo excluirse y un contacto. Nada de datos personales en la URL.
- **Datos personales:** las declaraciones de bienes y las RPT llevan datos personales. Solo se registra **si
  existe y su fecha**; no se republica el contenido. Las capturas WARC se guardan en local, no se publican, y
  solo se enseñan si alguien pide una revisión (art. 6.1.f RGPD + interés público; base: art. 5.4 Ley
  19/2013).
- **Redacción factual** (plantillas):
  - «A fecha 25-10-2026, en el portal de transparencia del Ayuntamiento de X (URL) **no consta** el
    presupuesto de 2026 ni su prórroga. El documento más reciente de esa sección es el presupuesto de 2020.
    Revisión automática; criterios y código en …; para corregir un error, …»
  - «A fecha F **no ha sido posible evaluar** el portal de X: su plataforma (Gestiona) no permite el acceso a
    robots / el servidor no respondía / la plataforma estatal transparencialocal.gob.es estaba caída.»
  - Nunca «oculta», «incumple la ley» ni «opaco» como afirmación del robot. Se puede añadir «la Ley 19/2013
    (art. 8.1.d) exige publicar…» como contexto. Y siempre la **tasa de error medida** del indicador y un
    canal de rectificación con su plazo.
- Este proyecto ya tiene sus reglas: atribuir al gobierno en funciones en la fecha del plazo, **ajustar por
  tamaño y CCAA** y ojo con la vía foral (Navarra con ANIMSA y ley foral; País Vasco con portales forales).

---

## 5. Propuesta de arquitectura

```
ingestion/transparencia_robot/
  descubrir.py     BDGEL (POST GetDirecciones) + DIR3 (NIF) + Wikidata P856 + dominio del email
                   + sondeo de subdominios (sedelectronica/sedipualba/eadministracio) → candidatos
                   con puntuación; validar por título y teléfono/CP (BDGEL), NIF (DIR3), sin comodín
                   «Sede Indeterminada»; detector de dominios caducados o secuestrados
  huella.py        identifica la plataforma (patrones de la sección 2) en portada, sede y enlaces
  analizadores/    gestiona.py · aoc_seue.py · dipucr_api.py · animsa.py (Playwright) · expert_murcia.py
                   · larioja_wp.py · eprinsa_wp.py (RSS) · sxc_galicia.py · saas_api.py · badajoz.py
                   · generico.py (enlaces + diccionario es/ca/gl/eu + códigos ITA + clasificador)
  fechas.py        reglas de fecha 1-5 con la regla de origen guardada
  robots.py        Protego + caché del robots 24 h + Crawl-delay
  cola.py          estado reanudable en DuckDB/SQLite: (ronda, ine, url, estado, intentos, siguiente_intento)
data/transparencia_robot_cache/{ronda}/   (en .gitignore, como data/tcu_cache)
  warc/{plataforma}/{ine}.warc.gz          lo que vio el robot (warcio), lo que hace la evidencia auditable
  resultados.parquet                       ine × comprobación × estado × fecha × regla × url_evidencia
```

- **Reanudable** igual que `ingestion.tcu --crawl`: cada URL es una fila con su estado; un solo proceso
  (fichero de bloqueo); stdout.log con el progreso.
- **Detección de caídas de plataforma:** si el porcentaje de errores de una plataforma en una ronda supera el
  20 %, se marca la plataforma como caída y todas sus entidades pasan a `no_evaluable`. Se reintenta a los 7
  días (lo de transparencialocal.gob.es pasa ahora mismo).
- **Frecuencia:** **trimestral** (enero, abril, julio, octubre), alineada con la periodicidad trimestral de
  los contratos menores y la ejecución presupuestaria.
- **Tiempo estimado:** unas 40 peticiones por entidad (portada, sede, índice, unas 15 secciones y unos 20 HEAD
  de documentos), es decir, unas 330.000 por ronda. Sin Gestiona: unas 3.000 entidades × 40 = 120.000
  peticiones repartidas entre muchos hosts a 1 cada 5 s por host. En paralelo y con el límite por
  plataforma salen **~2-3 días** de reloj. Con Gestiona (unas 5.000 × 40 = 200.000 a 1 petición/s global)
  se añaden **~55 h**. Una ronda completa cabe en **≤ 1 semana** en el PC del usuario, como el crawl del TCU.
  Playwright solo para ANIMSA y otras SPA sin API (pocos cientos).
- **Integración en el repo:** la caché solo vive en ese PC (como la del TCU), así que no va en Dagster. Carga
  con dlt → dbt `transparencia_portales` → página `/transparencia/portales` con un ranking ajustado por
  tamaño y CCAA (IC 95 %), mapa y ficha por municipio.

### 5.1 Validación manual (tasa de error)

- **Unidad:** par entidad × comprobación, juzgado sobre la **misma captura WARC** que vio el robot (para
  separar el error del robot de los cambios posteriores del portal) y también sobre la web en vivo (para
  medir la caducidad).
- **Métrica clave:** **precisión de «no consta»** (VPP: de lo que el robot dice que falta, cuánto falta de
  verdad). Es lo que se publica como incumplimiento. Además, la **sensibilidad de «consta»** y la tasa de
  `no_evaluable`.
- **Tamaño:** para estimar una proporción en torno al 90-95 % con ±3 puntos al 95 %:
  n = 1,96²·p(1−p)/0,03² ≈ **385 (p = 0,5, peor caso) / 203 (p = 0,95)**. Propuesta:
  - **Muestra A** (precisión): 60 pares «no consta» por plataforma o estrato × ~8 estratos = **480**, que da
    ≈ ±3 puntos en el total y ±6-8 por estrato.
  - **Muestra B** (sensibilidad): 300 pares «consta».
  - **Muestra C** (entidades): 150 entidades completas (las 15 comprobaciones), estratificadas por tamaño
    (<1.000, 1-5 mil, 5-20 mil, 20-100 mil, >100 mil) y CCAA, para medir el error de descubrimiento de URL
    (C0) y el efecto de conglomerado (efecto de diseño de 1,2-1,5 con varios pares por entidad; inflar n en
    consecuencia).
  - **Dos revisores independientes** en el 20 % de la muestra; kappa de Cohen ≥ 0,8 o se reescribe el
    criterio.
  - Intervalos de **Wilson**. **Regla de publicación:** solo se destacan los indicadores cuyo **límite inferior
    del IC 95 % de precisión de «no consta» sea ≥ 95 %**; el resto va como «experimental» sin ranking.
  - La validación se repite en cada ronda con una muestra reducida (≈ 100 pares) para vigilar regresiones
    (las plataformas migran: Teror, Badajoz).
- **Referencias para contrastar:** Mapa Infoparticipa (UAB; 41-52 indicadores, evaluación manual de webs
  municipales en varias CCAA). El «% de cumplimiento ITA» que publica dipucr por municipio sirve como
  autoevaluación oficial con la que cruzar.

---

## 6. Ejemplos reales de esta prueba

| Entidad | URL probada | Hallazgo |
|---|---|---|
| Madrid | `www.madrid.es` → `transparencia.madrid.es/portal/site/transparencia` | Accesible. robots bloquea bots concretos y algunas rutas (`/csvfiles`, `/FicherosDatosPersonales`) |
| Barcelona | `ajuntament.barcelona.cat/transparencia/ca` | Drupal 11. `Last-Modified` = hora de la petición |
| Sevilla | `www.sevilla.org/transparencia` | Plone. robots bloquea `/*?` (no se pueden usar parámetros) |
| Zaragoza | `zaragoza.es/sede/portal/transparencia/` | Catálogo propio con estado Actualizado/Pendiente; PDF de bienes 2026 (`CreationDate` 28-07-2026, `Last-Modified` 13-08-2026) |
| Abejar (Soria) | `abejar.sedelectronica.es/transparency` (vista manual) | Gestiona; «3.1.1 PRESUPUESTOS (4)»: el último es el de 2020; actas hasta 2022. **robots prohíbe el rastreo** |
| Ágreda, Adalia, San Vicente del Valle, Berberana, Valdeavero, Regueras de Arriba | `{x}.sedelectronica.es/transparency` | Gestiona; la web municipal enlaza directamente a la sede |
| Adalia (Valladolid) | `adalia.gob.es` → `adalia.ayuntamientosdevalladolid.es` | Web de la Diputación de Valladolid + transparencia en Gestiona |
| Zizur Mayor (Navarra) | `transparencia.animsa.es/P3190700I` | Blazor; Ley Foral 5/2018; económica solo «Bases ejecución 2024»; además tiene un WordPress propio con más contenido (doble portal) |
| La Solana (C. Real) | `aytolasolana-transparencia.dipucr.es/api/publicas/...` | API JSON; 61 de 64 indicadores ITA; última publicación 26-06-2026 |
| Puerto Lumbreras (Murcia) | `sede.puertolumbreras.regiondemurcia.es/web/transparencia?entidad=30033` | Expert@, además de una página propia en WordPress |
| Teror (Gran Canaria) | `transparencia.teror.es` (API `/api/v1/...`) | SPA multi-inquilino; enlace «Plenos» de la portada → **404** |
| Acedera (Badajoz) | `acedera.es` → `dip-badajoz.es/municipios/...codigo=1` | Enlace a `transparenciabadajoz.es` **roto** (redirección a un host mal formado) |
| Dosrius, Agullana, Sant Martí Sesgueioles | `seu-e.cat/ca/web/{x}/govern-obert-i-transparencia` | Seu-e AOC; actas y RLT bloqueadas por robots |
| Sa Pobla (Baleares) | `sapobla.eadministracio.cat/transparency/` | Gestiona (marca catalana); robots prohíbe |
| Ibieca, Salas Altas (Huesca) | `www.{x}.es/transparencia` | Liferay de la DPH; **página de transparencia vacía** en Salas Altas |
| Estubeny (Valencia) | sede Sedipualba → `estubeny.transparencialocal.gob.es` | **Plataforma estatal caída** (certificado caducado el 27-09-2026) |
| Alfara de la Baronia | `alfaradelabaronia.sedipualba.es` | Enlace «Portal de transparencia» **vacío** |
| Montilla (Córdoba) | `transparencia.montilla.es` | EPRINSA/WordPress, con RSS `/feed/` |
| Zas (A Coruña) | `sede.concellodezas.gal/sxc/gl/portal_transparencia/` | Sede «sxc» gallega |
| Algatocín, El Borge, Almargen, Iznate (Málaga) | webs tras CloudFront | **AWS WAF challenge**: no evaluable |
| La Guardia (Toledo) | Wikidata P856 `aytolaguardia.org` | **Dominio caducado que hoy redirige a un casino** |
| Arroyomolinos (Cáceres) | `arroyomolinos.sedelectronica.es` | Es la sede de **Arroyomolinos (Madrid)**: homónimo |
| Benavente, Gorliz | https | Certificado inválido (`SSLCertVerificationError`) |

## 7. Pendientes y dudas

- Medir cuántos municipios usan de verdad `transparencialocal.gob.es` cuando vuelva a funcionar.
- Volumen exacto por plataforma: hacer el sondeo de subdominios de los 8.131 municipios (solo `/`, permitido;
  unas 24.000 peticiones DNS+GET) y validar los homónimos con el teléfono o CP de BDGEL.
- Confirmar los números de las leyes autonómicas de Baleares y País Vasco antes de publicar los criterios.
- Decidir si las comprobaciones C3, C8 y C14 (alto riesgo de falso negativo) se publican o se quedan como
  experimentales.
