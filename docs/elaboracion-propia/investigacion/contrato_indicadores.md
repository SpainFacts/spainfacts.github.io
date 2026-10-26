# Contrato común de los indicadores del índice propio de publicidad activa (SpainFacts)

Cada indicador es un modelo dbt `transform/models/marts/pa_ind_<nombre>.sql` (materializado como tabla, como el resto de marts) con EXACTAMENTE estas columnas (puedes añadir columnas extra al final si son útiles para la página, con prefijo `x_`):

| columna | tipo | contenido |
|---|---|---|
| obligacion | varchar | slug estable, p. ej. `bdns_concesiones`, `contratos_menores`, `contratos_formalizacion`, `ispa_retribuciones`, `presupuesto_prorrogado`, `pmp_ccaa`, `ley_presupuestos_ccaa` |
| obligacion_nombre | varchar | nombre corto legible en español («Subvenciones registradas en la BDNS a tiempo») |
| base_legal | varchar | artículo exacto y norma («art. 5.2.b RD 130/2019») |
| tipo_entidad | varchar | uno de: `Ayuntamiento`, `Diputación provincial`, `Cabildo o consell insular`, `Comunidad autónoma` |
| cod_entidad | varchar | Ayuntamiento: cod_mun INE 5 cifras; Diputación (incl. forales y Diputación de Barcelona…): `D` + cod_prov; Cabildo/consell: `I` + 5 dígitos del DIR3 L03 (provincia + ordinal, p. ej. L03380001 -> `I38001`); Comunidad autónoma: `C` + cod_ccaa INE (01..19) |
| nombre_entidad | varchar | nombre oficial legible |
| cod_mun, cod_prov, cod_ccaa | varchar | los que apliquen (cod_prov y cod_ccaa siempre que se sepan) |
| periodo | varchar | etiqueta del periodo medido: `2025`, `2025T3`, `2025-10` |
| anio | integer | año al que se refiere la obligación |
| fecha_plazo | date | fecha límite legal del periodo (para indicadores de muchos elementos, la del último elemento del periodo, p. ej. 31-ene del año siguiente) |
| estado | varchar | por entidad y periodo: `en_plazo`, `fuera_plazo`, `no_consta`, `no_vencido`, `no_aplica`, o para indicadores de muchos elementos `con_registros` / `sin_registros` (el modelo común convierte el % en estado) |
| dias_retraso | integer | obligaciones únicas: días desde el plazo hasta la remisión (0 si en plazo, null si no consta) |
| n_total | integer | indicadores de muchos elementos: nº de elementos (concesiones, contratos…) del periodo; null en obligaciones únicas |
| n_fuera_plazo | integer | de ellos, cuántos publicados/registrados fuera de plazo |
| mediana_dias | double | mediana de días entre el hecho y la publicación/registro |
| aplica_indicador | boolean | false cuando el dato no mide a la entidad (régimen foral, plataforma propia no cubierta, etc.) |
| motivo_no_aplica | varchar | explicación corta cuando aplica_indicador = false |
| poblacion | integer | padrón del año (ref('poblacion_municipios'), sexo = 'Total'; provincias y CCAA, suma) |
| url_fuente | varchar | URL oficial de donde sale el dato |

Reglas:
- Universo completo: TODAS las entidades del tipo existentes ese año (los 8.131 ayuntamientos de `poblacion_municipios` vigentes, las diputaciones, etc.), no solo las que aparecen en la fuente. Quien no aparece es `no_consta`/`sin_registros`, salvo `aplica_indicador = false`.
- Ceuta y Melilla (51, 52) se tratan como `Comunidad autónoma` (C18, C19), nunca como ayuntamiento.
- Régimen foral: Álava 01, Gipuzkoa 20, Bizkaia 48, Navarra 31. Comprobar SIEMPRE la cobertura real por provincia y año antes de dar por bueno un indicador; si el cauce es distinto, aplica_indicador = false con el motivo. Igual para Cataluña/País Vasco/Navarra en contratación si no se cubre su plataforma.
- Año en curso incompleto: o se excluye o `estado = no_vencido`.
- Nunca personas físicas ni nombres de beneficiarios particulares.
- Redacción factual («no consta en …»), nunca acusatoria.
- Tests en el schema yml: not_null en obligacion, tipo_entidad, cod_entidad, periodo, estado; unique en (obligacion, cod_entidad, periodo) con `dbt_utils` si está instalado o con un test singular / columna clave concatenada `clave` + unique.
- La atribución al partido la hace el modelo común; no hace falta en el indicador.

Convenciones del repo (leer antes): docs/GUIA_INGESTA_Y_METRICAS.md, docs/desarrollo-local.md, ejemplos `ingestion/transparencia_publicidad_activa.py`, `ingestion/hacienda_transparencia.py`, `transform/models/marts/transparencia_tcu.sql`, `transform/models/marts/transparencia_pmp.sql` (universo + foral), `transform/models/sources_*.yml`. Años siempre `CAST(CAST(anio AS INTEGER) AS VARCHAR)` en las páginas. Comentarios y textos en español.

Pruebas en local SIN MotherDuck y SIN pisar la base de los demás: copia `data/spainfacts.duckdb` a `data/pa_<nombre>.duckdb` y usa
`SPAINFACTS_DESTINO=local SPAINFACTS_DUCKDB=C:/Users/jota/Documents/GitHub/spainfacts.github.io/data/pa_<nombre>.duckdb` para dlt y dbt (`.venv/Scripts/python.exe -m ingestion.<x>`, `.venv/Scripts/dbt.exe build --project-dir transform --profiles-dir transform --select <modelo>`). Bórrala al acabar si ya no hace falta (pesa 2 GB).

Documentación de criterios: escribe `docs/elaboracion-propia/<nombre>.md` con: qué se mide, base legal con artículo, fuente con URL, cómo se calcula (fórmula del retraso, umbral), universo, exclusiones y trampas (foral, plataformas, ventanas), limitaciones conocidas y los ficheros de código (ingesta, modelo). Esto se publicará en /fuentes como «elaboración propia».

NO toques: `orchestration/definitions.py`, `transform/seeds/fuentes_*.csv`, `pages/`, ni los ficheros de los otros agentes. NO hagas commit ni push. Dime al final qué recursos dlt (nombre del source, recursos y disposición) hay que registrar en Dagster.
