# SpainFacts

Dashboards de datos públicos de España ([spainfacts.org](https://spainfacts.org)), construidos con [Evidence](https://evidence.dev) sobre [MotherDuck](https://motherduck.com), con ingesta y transformación orquestadas por Dagster.

## Arquitectura

```
Dagster (servidor, schedule diario 6:00 Europe/Madrid)
  ├─ ingestion/  dlt: API del INE ──► MotherDuck (schema raw)
  ├─ transform/  dbt: staging ──► marts (main.ipc, main.unemployment, ...)
  └─ deploy_web: repository_dispatch ──► GitHub Actions ──► Evidence ──► GitHub Pages
```

| Carpeta          | Qué es                                                        |
| ---------------- | ------------------------------------------------------------- |
| `pages/`, `src/` | La web (Evidence: markdown + SQL + componentes Svelte)         |
| `sources/`       | Consultas de Evidence contra MotherDuck                        |
| `ingestion/`     | Pipelines de carga con [dlt](https://dlthub.com)               |
| `transform/`     | Proyecto [dbt](https://getdbt.com) (adaptador dbt-duckdb)      |
| `orchestration/` | Definiciones de [Dagster](https://dagster.io)                  |
| `docker/`        | Imagen y configuración para desplegar Dagster en el servidor   |

## Requisitos

- Node.js ≥ 18 y npm (web)
- [uv](https://docs.astral.sh/uv/) (stack de datos)
- Un token de MotherDuck (Settings → Access Tokens)

Copia `.env.example` a `.env` y rellena las variables. El `.env` **nunca** se versiona.

## La web (Evidence) en local

```bash
npm install
npm run sources     # ejecuta las consultas contra MotherDuck (necesita EVIDENCE_SOURCE__mother__token)
npm run build       # por defecto permite hasta 12 GB de heap para compilar los cinco idiomas
npm run dev         # abre http://localhost:3000
```

Si el equipo tiene menos memoria disponible, ajusta el límite del build, por ejemplo
`$env:EVIDENCE_BUILD_HEAP_MB = "8192"` en PowerShell o
`export EVIDENCE_BUILD_HEAP_MB=8192` en bash. Cierra antes otras aplicaciones pesadas:
un heap mayor evita el límite de Node, pero necesita memoria física disponible.
Usa `npm run build` para que se aplique ese ajuste. Si ejecutas directamente el CLI
global con `evidence build`, configura en su lugar `NODE_OPTIONS` (por ejemplo,
`$env:NODE_OPTIONS = "--max-old-space-size=8192"` en PowerShell); el CLI global no
lee `EVIDENCE_BUILD_HEAP_MB`.

`npm run build` también corrige al terminar el `<html lang>` de cada página prerenderizada
(`tools/html-lang-es.mjs`), igual que el despliegue; con el CLI global hay que ejecutarlo a mano.

## El stack de datos (Dagster) en local

```bash
uv venv
uv pip install -r orchestration/requirements.txt

# PowerShell:
$env:MOTHERDUCK_TOKEN = "..."; $env:GITHUB_DISPATCH_TOKEN = "..."
# bash:
export MOTHERDUCK_TOKEN=... GITHUB_DISPATCH_TOKEN=...

uv run dagster dev -m orchestration.definitions    # UI en http://localhost:3000
```

Desde la UI: **Catalog** lista los assets, **Lineage** muestra el grafo
`dlt → staging → marts → deploy_web`, y en **Automation** está el schedule
`actualizacion_diaria` (apagado por defecto; en local no hace falta encenderlo —
puedes materializar assets a mano con *Materialize*).

Solo el pipeline de dbt (sin Dagster):

```bash
uv run dbt build --project-dir transform --profiles-dir transform
```

### Sin MotherDuck: todo contra un DuckDB local

Con `SPAINFACTS_DESTINO=local` en el `.env`, dlt, dbt y Evidence leen y escriben
en `data/spainfacts.duckdb` en vez de MotherDuck, y `deploy_web` no dispara el
deploy. Paso a paso (variables, cómo rellenar la base copiando MotherDuck en
~30 s o cargando desde las fuentes oficiales, y problemas típicos):
**[docs/desarrollo-local.md](docs/desarrollo-local.md)**.

## Despliegue en el servidor

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io.git && cd spainfacts.github.io
cp .env.example .env    # rellenar MOTHERDUCK_TOKEN, GITHUB_DISPATCH_TOKEN, DAGSTER_PG_PASSWORD
docker compose up -d --build
```

UI en `http://<servidor>:3000` — no la expongas a internet sin autenticación
delante (Dagster OSS no trae login). Activa el schedule `actualizacion_diaria`
en **Automation** la primera vez. Para actualizar: `git pull && docker compose up -d --build`.

Más detalle en [orchestration/README.md](orchestration/README.md).

## Variables de entorno

| Variable                         | Dónde              | Para qué                                        |
| -------------------------------- | ------------------ | ----------------------------------------------- |
| `EVIDENCE_SOURCE__mother__token` | local + secret CI  | Evidence lee MotherDuck (basta read_only)       |
| `MOTHERDUCK_TOKEN`               | local + servidor   | dlt y dbt escriben en MotherDuck (read_write)   |
| `GITHUB_DISPATCH_TOKEN`          | servidor           | Dagster dispara el deploy (PAT scope Actions)   |
| `DAGSTER_PG_PASSWORD`            | servidor           | Postgres interno de Dagster                     |

El deploy de la web corre en GitHub Actions ([deploy.yml](.github/workflows/deploy.yml)):
se dispara con cada push a `main` y con el `repository_dispatch` que envía
Dagster al terminar la carga diaria.
