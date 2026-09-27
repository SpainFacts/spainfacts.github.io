# Desarrollo en local con DuckDB (sin MotherDuck)

Toda la cadena (dlt → dbt → Evidence) puede trabajar contra **un fichero
DuckDB local** en lugar de MotherDuck. Sirve para desarrollar sin tocar los
datos de producción, sin conexión o sin token.

Un único interruptor decide a dónde leen y escriben las tres capas:

| Variable | Valor | Efecto |
|---|---|---|
| `SPAINFACTS_DESTINO` | `motherduck` (por defecto) | dlt carga en `md:SpainFacts`, dbt usa el target `prod`, `deploy_web` dispara el deploy |
| | `local` | dlt y dbt escriben en el fichero de `SPAINFACTS_DUCKDB`; `deploy_web` no hace nada |
| `SPAINFACTS_DUCKDB` | ruta **absoluta** al `.duckdb` | Por defecto `<repo>/data/spainfacts.duckdb` (ignorado por git) |
| `EVIDENCE_SOURCE__mother__filename` | `../../data/spainfacts.duckdb` | Evidence lee del fichero en vez de `md:SpainFacts`. **Relativa a `sources/mother/`**: el conector siempre antepone esa carpeta, una ruta absoluta no funciona |

Dónde está implementado:

- **dlt**: [`ingestion/destino.py`](../ingestion/destino.py) → `pipeline(nombre)` devuelve un pipeline contra MotherDuck o DuckDB.
- **dbt**: [`transform/profiles.yml`](../transform/profiles.yml) elige el target `local` o `prod` según `SPAINFACTS_DESTINO`.
- **Evidence**: [`sources/mother/connection.yaml`](../sources/mother/connection.yaml) usa el conector DuckDB con `filename: md:SpainFacts`. La variable `EVIDENCE_SOURCE__mother__filename` lo sustituye por la ruta local. Las consultas (`mother.<tabla>`) son idénticas en los dos modos.

## 1. Requisitos (una vez)

```bash
uv venv
uv pip install -r orchestration/requirements.txt
npm install
```

## 2. Variables en `.env`

Añade al `.env` de la raíz (usa **tu** ruta absoluta, con barras `/` también en Windows):

```dotenv
SPAINFACTS_DESTINO=local
SPAINFACTS_DUCKDB=C:/Users/<tu-usuario>/Documents/GitHub/spainfacts.github.io/data/spainfacts.duckdb
# relativa a sources/mother/ (el conector de Evidence siempre antepone esa carpeta)
EVIDENCE_SOURCE__mother__filename=../../data/spainfacts.duckdb
# solo si vas a recargar AEMET en local
AEMET_API_KEY=...
```

Para volver a MotherDuck basta con comentar esas tres líneas (o poner
`SPAINFACTS_DESTINO=motherduck` y quitar `EVIDENCE_SOURCE__mother__filename`).

Cargar el `.env` en la terminal:

```bash
# Git Bash / Linux / macOS
set -a; . ./.env; set +a
```

```powershell
# PowerShell
Get-Content .env | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object {
  $k, $v = $_ -split '=', 2; Set-Item "env:$($k.Trim())" $v.Trim()
}
```

## 3. Rellenar la base local

Dos caminos, según tengas o no token de MotherDuck.

**A. Copiar MotherDuck (rápido, ~30 s, recomendado).** Necesita `MOTHERDUCK_TOKEN` (solo lectura basta):

```bash
.venv/Scripts/python -m orchestration.copiar_motherduck_a_local
```

Copia `raw`, `staging` y `main` al fichero de `SPAINFACTS_DUCKDB`. Si el fichero
ya existe, se detiene: bórralo antes para empezar de cero.

**B. Cargar todo desde las fuentes oficiales (sin MotherDuck).** Con
`SPAINFACTS_DESTINO=local`, materializa todos los assets de Dagster:

```bash
.venv/Scripts/dagster asset materialize -m orchestration.definitions --select "*"
```

o, de forma interactiva, `.venv/Scripts/dagster dev -m orchestration.definitions`
y "Materialize all" en http://localhost:3000. Tarda varios minutos: MITECO
(~2 min), INE población (~1 min) y, sobre todo, el histórico de AEMET la
primera vez (ver `ingestion/aemet.py`).

Para una sola fuente sin Dagster:

```bash
.venv/Scripts/python -c "from ingestion.destino import pipeline; from ingestion.miteco import miteco; print(pipeline('miteco').run(miteco()))"
```

## 4. Transformar con dbt

```bash
.venv/Scripts/dbt build --project-dir transform --profiles-dir transform
# comprobar a qué base apunta:
.venv/Scripts/dbt debug --project-dir transform --profiles-dir transform
```

`dbt debug` debe mostrar `path: .../data/spainfacts.duckdb`. Si muestra `md:SpainFacts`, `SPAINFACTS_DESTINO` no está a `local` en esa terminal.

## 5. Ver la web

```bash
npx evidence sources          # extrae las tablas del DuckDB local
npm run dev -- --port 3100    # http://localhost:3100 (el 3000 es de Dagster)
```

## Cosas a tener en cuenta

- **Un solo escritor.** DuckDB bloquea el fichero mientras dlt o dbt escriben. Para
  el servidor de Evidence (`npm run dev`) mientras recargas datos y vuelve a
  lanzar `npx evidence sources` al terminar.
- **Rutas.** dbt resuelve las rutas relativas desde el directorio desde el que
  se ejecuta, así que `SPAINFACTS_DUCKDB` va en absoluto. Evidence, al revés:
  siempre antepone `sources/mother/`, así que su ruta va en relativo
  (`../../data/spainfacts.duckdb`). Si mueves el fichero, cambia las dos.
- **El deploy no se dispara en local.** `deploy_web` se salta a sí mismo con
  `SPAINFACTS_DESTINO=local`: la web publicada siempre lee de MotherDuck
  (GitHub Actions no ve tu fichero).
- **Producción no cambia.** En GitHub Actions la variable `motherduck_token`
  (secret `EVIDENCE_SOURCE__MOTHER__TOKEN`) hace que el conector DuckDB lea de
  `md:SpainFacts`.
- **Datos que no están en el pipeline.** Todas las tablas que usa la web salen de
  dlt + dbt, así que el camino B reproduce la web completa. Si añades una
  página, crea su fuente en `ingestion/`, sus modelos en `transform/` y su
  consulta en `sources/mother/`: funcionará en los dos modos sin más cambios.
