# Retribuciones de los cargos electos remitidas al ISPA

**Elaboración propia.** Indicador `ispa_retribuciones` del índice de publicidad activa y remisión de información.

## Qué se mide

Si cada ayuntamiento ha facilitado a la Administración del Estado las cantidades que cobraron el año anterior sus cargos electos (alcaldía y concejalías): retribuciones, asistencias a órganos colegiados y cualquier otra cantidad que no compense un gasto. Se recogen en el sistema ISPA (Información Salarial de Puestos de la Administración), que gestiona la Secretaría de Estado de Función Pública.

## Base legal

- **Disposición adicional tercera del Real Decreto-ley 20/2012**, de 13 de julio: obligación de las comunidades autónomas y entidades locales de remitir información sobre sus gastos de personal y retribuciones.
- **Art. 7.4.d de la Orden HAP/2105/2012**, de 1 de octubre, en la redacción de la **Orden HAP/2082/2014**, de 7 de noviembre: remisión individualizada de las cantidades percibidas por los cargos electos de las corporaciones locales.
- **Plazo**: lo fijan las instrucciones generales de cada edición de ISPA. Comprobado: «antes del 30 de abril» en ISPA 2024, 2025 y 2026. Para las ediciones anteriores se aplica la misma fecha; el estado no depende de ella, porque el indicador mide si el ayuntamiento figura en el listado de no remitentes.
- **No es** el art. 75 bis de la Ley 7/1985 de Bases del Régimen Local: ese artículo fija los **límites** de las retribuciones, no la obligación de remitirlas.

Fuentes: [Instrucciones generales ISPA 2026](https://digital.gob.es/content/dam/portal-mtdfp/funcion-publica/dgfp/ispa/ispa2026/documentos/INSTRUCCIONES_GENERALES_2026.pdf), apartados 2 y 4.

## Fuente

Espacio ISPA › Estadísticas (`https://digital.gob.es/funcion-publica/dgfp/espacio-ispa/estadisticas/informac_estad_AAAA`, donde AAAA es el año de las retribuciones). Cada página enlaza la «Relación de ayuntamientos que no han facilitado información sobre las cantidades percibidas…». Las rutas cambian casi cada año, así que la ingesta las lee de la página:

| Año de las retribuciones | Edición | Fichero |
|---|---|---|
| 2013 | ISPA 2014 | `ispa_anteriores/ispa_2014/ayunt_sinremitir_ispa2014.xlsx` |
| 2016 | ISPA 2017 | `Ispa-2017/retribuc_2016/ayunt_sin_remitir.xlsx` |
| 2024 | ISPA 2025 | `ispa2025/retrib_2024/ayuntamientos_sin_remitir.xlsx` |

El listado trae ayuntamiento, provincia, comunidad y, desde 2017, población, pero **no el código INE**. Marcas: «(*) Han remitido la información pero falta la firma» y «(**) Incorpora información dudosa o incompleta, solicitada aclaración».

## Cómo se calcula

Una fila por ayuntamiento y año de las retribuciones, con la **última foto** guardada de cada edición:

| Estado | Regla |
|---|---|
| `no_consta` | figura en el listado de esa edición. Si lleva marca, va en `x_marca` (`remitida_sin_firma`, `informacion_dudosa`): sigue en el listado oficial de no remitentes |
| `consta` | no figura en el listado. La fuente no da la fecha de remisión |
| `no_aplica` | Navarra |

`fecha_plazo` = 30 de abril del año siguiente al de las retribuciones. Ceuta y Melilla van como `Comunidad autónoma` (C18, C19).

### Casado por nombre

Nombre + provincia, con claves normalizadas (`transform/macros/pa_nombres.sql`): minúsculas, sin tildes ni signos, artículo pospuesto («Coruña, A», «Ejido (El)») y nombres bilingües («Jávea/Xàbia» = «Xàbia/Jávea»). Primero se busca una clave fuerte (nombre completo); si no casa, una débil (cada parte del nombre bilingüe o el nombre sin artículo), y se desempata por la población más parecida. Los municipios renombrados que el ISPA sigue listando con el nombre antiguo están en una tabla de alias revisada a mano dentro del modelo (Benisanó → Benissanó, Candín → Valle de Ancares, Sopelana → Sopela, Torla → Torla-Ordesa, Villanueva de Castellón → Castelló…).

| Año | Listados | Sin casar | Casados | Ayuntamientos medidos | No constan | % no consta |
|---|---|---|---|---|---|---|
| 2013 | 693 | 7 | 99,0 % | 7.845 | 447 | 5,7 % |
| 2014 | 1.845 | 4 | 99,8 % | 7.845 | 1.841 | 23,5 % |
| 2015 | 1.510 | 5 | 99,7 % | 7.847 | 1.505 | 19,2 % |
| 2016 | 1.176 | 0 | 100 % | 7.853 | 1.176 | 15,0 % |
| 2017 | 1.170 | 2 | 99,8 % | 7.852 | 1.168 | 14,9 % |
| 2018 | 1.055 | 0 | 100 % | 7.852 | 1.055 | 13,4 % |
| 2019 | 1.336 | 0 | 100 % | 7.859 | 1.336 | 17,0 % |
| 2020 | 935 | 1 | 99,9 % | 7.859 | 934 | 11,9 % |
| 2021 | 1.104 | 1 | 99,9 % | 7.859 | 1.103 | 14,0 % |
| 2022 | 1.207 | 0 | 100 % | 7.859 | 1.207 | 15,4 % |
| 2023 | 1.360 | 0 | 100 % | 7.859 | 1.359 | 17,3 % |
| 2024 | 1.195 | 0 | 100 % | 7.860 | 1.194 | 15,2 % |

En 2013 los 245 de Navarra listados no cuentan (no aplica).

**No casados** (20 filas, revisados uno a uno):
- Municipios creados después del padrón del año, que no están en el universo de ese año: Balanegra, Montecorto, Serrato, Dehesas Viejas, Domingo Pérez de Granada, Pueblonuevo de Miramontes y Tiétar (ediciones 2015-2016).
- Municipios que ya no existían: Cerdedo y Cotobade (fusionados en Cerdedo-Cotobade en 2016, todavía listados en ISPA 2018).
- La Bisbal de Falset (Tarragona, ISPA 2021 y 2022): no figura con ese nombre en el padrón del repositorio. Queda pendiente.
- Municipios de Navarra (Egüés, Goñi, Noáin, Oitz, Ollo, Urrotz, ISPA 2014): no aplica de todos modos.

Un municipio que aparece dos veces en el listado cuenta una sola vez (por eso «no constan» puede ser uno menos que «listados − sin casar»).

## Exclusiones y trampas

- **Navarra → `no_aplica`.** Tiene una plataforma propia, «ISPA Navarra», con un «procedimiento especial de remisión de la información de las entidades locales… acordado en el seno de la Comisión Coordinadora del Convenio Económico». El listado estatal incluye a 245 municipios navarros en ISPA 2014 y a ninguno (o uno) después.
- **País Vasco: sí aplica.** Las corporaciones de los territorios históricos pueden remitir también a través de su diputación foral, que lo envía al Ministerio (instrucciones de ISPA, apartado 3.2), y sus municipios figuran en el listado estatal (208 en ISPA 2014, 33 en ISPA 2025). La alta cifra de los primeros años puede reflejar el arranque del cauce foral: conviene decirlo en la página.
- **La foto.** «Los listados ahora publicados no tienen carácter definitivo y se irán ampliando en la medida de que nuevos ayuntamientos remitan su información» (nota explicativa). La ingesta guarda la fecha de la foto: el `Last-Modified` del fichero o, si falta, el día de la descarga. Ojo: en ISPA 2014-2024 esa fecha es el 20-may-2025 (migración del portal), no la de elaboración del listado. El de ISPA 2025 se actualizó el 19-may-2026, un año después del plazo. Merge por edición + fecha de foto: cada foto nueva se guarda sin borrar las anteriores.
- **Año 2013.** La obligación de remitir lo cobrado por los cargos electos, de forma individualizada, la regula la Orden HAP/2082/2014 (noviembre de 2014). La primera edición (ISPA 2014, retribuciones de 2013) se recogió ese mismo año, así que su tasa no es comparable con las siguientes.
- Redacción: «figura en la relación de ayuntamientos que no han facilitado información al ISPA (Secretaría de Estado de Función Pública, foto de [fecha])».

## Código

- Ingesta: `ingestion/pa_registros.py`, recurso `ispa_sin_remitir` (source `pa_registros`). Copia de cada Excel en `data/ispa_cache/`.
- Modelo: `transform/models/marts/pa_ind_ispa.sql`; claves de nombres en `transform/macros/pa_nombres.sql`; pruebas en `schema_pa_registros.yml`.
