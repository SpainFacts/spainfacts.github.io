# Traspaso: publicidad activa para todas las administraciones (2026-10-25)

Estado del trabajo para ampliar `/transparencia/publicidad-activa` a todas las administraciones con una medición propia de SpainFacts. **Todo está en el árbol de trabajo, sin commit ni push. Producción (MotherDuck) aún no tiene estos datos.**

## Qué pidió el dueño

- Completar la página para todas las administraciones, también en las fichas de municipio, provincia (diputación) y comunidad.
- Que SpainFacts sea su propia fuente («elaboración propia»), con un apartado en `/fuentes` con los criterios y el código.
- Destacar los incumplimientos como en `/varios/diputados-caseros` (caja roja).
- Las verificaciones humanas (cortafuegos, CAPTCHA, muestra de validación) se le pasan a él.

## Hecho y probado en local

Build parcial de las cinco páginas en los cinco idiomas, sin errores. Pruebas estática y de humo correctas. dbt build de todos los modelos nuevos en PASS.

### 1. Evaluaciones oficiales nuevas

Están en `ingestion/transparencia_publicidad_activa.py` y `transform/models/marts/transparencia_publicidad_activa.sql`.

- `pa_sindic`: Síndic de Greuges de Catalunya, IDPAC 2026, CSV con licencia CC0. Cubre los 947 ayuntamientos, las 4 diputaciones, los consejos comarcales y la Generalitat. Casado con el INE por nombre: 947 de 947.
- `pa_murcia`: Consejo de Transparencia de Murcia, ICPA 2020-2023, del Anexo I del PDF. «NP» (no participó) nunca cuenta como 0.
- `pa_ctbg_agregados`: tablas de los informes agregados del CTBG de 2022 a 2026: sector público estatal, entidades privadas, corporaciones y órganos constitucionales.
- Lo que no publica nadie más está documentado en `investigacion/inv_evaluaciones.md`.

### 2. Índice propio (registros oficiales con fecha)

Contrato común de columnas: `investigacion/contrato_indicadores.md`. Criterios generales: `indice.md`. Hay una ficha por indicador en este directorio.

| Indicador | Ingesta | Modelo |
|---|---|---|
| Liquidación, presupuesto y líneas a Hacienda, PMP comunicado, Tribunal de Cuentas | existentes | `pa_ind_existentes` |
| Retribuciones de los cargos electos (ISPA) | `ingestion/pa_registros.py` | `pa_ind_ispa` |
| Presupuesto prorrogado (CONPREL, avance) | `pa_registros.py` | `pa_ind_presupuesto` |
| Ley de presupuestos autonómica (BOE) | `pa_registros.py` | `pa_ind_presupuestos_ccaa` |
| Pago a proveedores de CCAA y diputaciones (bloque «pago», fuera del índice) | `pa_registros.py` y `hacienda_transparencia.py` | `pa_ind_pmp_ccaa`, `pa_ind_pmp_entidades_locales` |
| Contratos: adjudicación, formalización y menores (PLACSP y PSCP) | `ingestion/pa_contratos.py` | `pa_ind_contratos_*` |
| Subvenciones registradas a tiempo en la BDNS | `ingestion/pa_bdns.py` | `pa_ind_bdns` |

Cómo se combinan:
- `transparencia_cumplimiento` une todos los indicadores, puntúa cada obligación y atribuye el gobierno del día del plazo. Puntuación: en plazo 1, fuera de plazo 0,5, no consta 0.
- `transparencia_cumplimiento_entidad` da el índice de 0 a 100 por entidad.
- Una obligación entra en el índice y en los incumplimientos destacados solo si cubre al menos el 80 % de las entidades de su tipo. Por eso el rastreo parcial del Tribunal de Cuentas aún no señala a nadie.
- Los criterios públicos salen del seed `transform/seeds/elaboracion_propia_indicadores.csv`, que lee `/fuentes`.

### 3. Páginas

- `pages/transparencia/publicidad-activa.md`:
  - caja roja de incumplimientos;
  - secciones de Cataluña, Murcia y el sector público estatal;
  - «Medición propia: todas las administraciones», con KPI, tablas, mapa, ranking y comparación por partido ajustada.
- `pages/territorios/municipios.md`, `[ccaa]/index.md` y `[ccaa]/[provincia].md`: sección «Transparencia».
- `pages/fuentes/index.md`: apartado «Datos de elaboración propia».
- Traducciones en `pages/{en,ca,gl,eu}/…` con su `i18n_origen` al día.
- Catálogo: `transform/seeds/fuentes_catalogo.csv` y `fuentes_ingesta.csv` (4 fuentes nuevas). `static/fuentes/linaje.json` regenerado.
- Dagster: `pa_registros`, `pa_contratos` y `pa_bdns` registrados en `orchestration/definitions.py`.

## Pendiente para publicar

1. **Arreglar `transform/seeds/fuentes_catalogo.csv`:** la fila `ine_condenados_25645` tiene 10 columnas y debe tener 9. La añadió otra sesión que trabaja en criminalidad e inmigración, y rompe `dbt seed`.
2. **Cargar en MotherDuck:**
   - `python -m ingestion.transparencia_publicidad_activa`
   - `python -m ingestion.pa_registros boe_leyes_ccaa desde=1999-09-01` (la primera vez, por el estado incremental de dlt) y luego `python -m ingestion.pa_registros`
   - `python -m ingestion.pa_contratos --desde 2018 --cache-dir <caché>`: unos 12 GB de PLACSP; hay parquets ya reducidos (227 MB) en `C:\Users\jota\AppData\Local\Temp\claude\C--Users-jota-Documents-GitHub-spainfacts-github-io\fc5632ee-74ac-40fb-954a-6209d8e8db24\scratchpad\pa_contratos\cache` (carpeta temporal: cópiala a `data/pa_contratos_cache` si quieres conservarla).
   - `python -m ingestion.pa_bdns --anios 2022-2026`: caché en `data/bdns_cache/`.
3. `dbt seed` y `dbt build` en producción de `pa_ind_*`, `transparencia_cumplimiento`, `transparencia_cumplimiento_entidad`, `transparencia_publicidad_activa` y `trazabilidad_fuentes`.
4. **Commit solo de los ficheros de este trabajo.** No van los de criminalidad, migración, `tools/mcp`, `src/lib/chat`, `tools/chat` ni `.gitignore`, que son de otras sesiones. Después, push a main y revisar el deploy.

## Robot de portales (sin construir)

- Diseño, plataformas, 16 comprobaciones, reglas de fecha y validación manual: `investigacion/inv_robot.md`.
- Comprobaciones y estados ya escritos: `ingestion/transparencia_robot/tipos.py`.
- Gestiona/esPúblico (~61 % de los ayuntamientos) y la Seu-e del AOC prohíben en robots.txt rastrear sus portales de transparencia. Esta sesión no construyó el rastreador.

## Otros

- El rastreo del Tribunal de Cuentas (`python -m ingestion.tcu --crawl`) se relanzó el 2026-10-25; iba por 8.100 de 14.770 cuentas. Progreso en `data/tcu_cache/stdout.log`.
- Trampas conocidas:
  - territorios forales (01, 20, 48, 31);
  - Cataluña, País Vasco y Navarra fuera de PLACSP;
  - la BDNS solo enseña 4 años y borra las concesiones a personas físicas al segundo año;
  - «CP» = prorrogado está deducido, sin confirmación de Hacienda;
  - el plazo de los contratos menores es un criterio propio por analogía.
