# Stack de datos: Dagster + dlt + dbt

```
Dagster (tu servidor, schedule 6:00 Europe/Madrid)
  ├─ ingesta   ingestion/ine.py  (dlt)  ──►  MotherDuck raw.ine_ipc / raw.ine_paro
  ├─ transform transform/        (dbt)  ──►  staging.* (vistas) y main.ipc / main.unemployment
  └─ deploy_web: repository_dispatch ───►  GitHub Actions ──► Evidence ──► GitHub Pages
```

Los marts se escriben en `main` con los nombres que ya esperan las fuentes de
Evidence (`sources/mother/*.sql`), así que Evidence no necesita cambios de
conexión. Ojo: `main.ipc` y `main.unemployment` ahora traen **todas** las
series del INE con columnas `date`, `value`, `serie`, `cod_serie` — las
páginas deben filtrar por serie.

## En el servidor

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io.git && cd spainfacts.github.io
cp .env.example .env   # rellena MOTHERDUCK_TOKEN, GITHUB_DISPATCH_TOKEN, DAGSTER_PG_PASSWORD
docker compose up -d --build
```

UI en `http://<servidor>:3000` (no la expongas a internet sin auth delante:
Dagster OSS no trae login; usa un reverse proxy con basic auth o VPN/Tailscale).
Activa el schedule `actualizacion_diaria` desde la UI (Automation) la primera vez.

Actualizar: `git pull && docker compose up -d --build`.

## En local (desarrollo)

```bash
python -m venv .venv && .venv/Scripts/activate   # o source .venv/bin/activate
pip install -r orchestration/requirements.txt
set MOTHERDUCK_TOKEN=...                          # o export en bash
dagster dev -m orchestration.definitions          # desde la raíz del repo
```

`dagster dev` genera el manifest de dbt automáticamente; en Docker lo hace el
`entrypoint.sh` con `dbt parse`.

## Notas

- `dbt build` ejecuta también los tests; si un test falla, `deploy_web` no se
  ejecuta y la web sigue publicada con los últimos datos buenos.
- Para añadir una fuente nueva: recurso dlt en `ingestion/`, entrada en
  `transform/models/sources.yml`, modelos staging/mart, y listo — Dagster la
  recoge sola en el grafo.
- Los scripts antiguos de `scripts/` (load_*.py) quedan obsoletos con este
  stack; se mantienen solo como referencia hasta validar la migración.
