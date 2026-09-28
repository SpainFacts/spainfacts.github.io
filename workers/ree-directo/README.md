# spainfacts-ree-directo

Cloudflare Worker que sirve a la página **/energia-clima/directo** ("El sistema eléctrico, ahora") los datos **en directo** de Red Eléctrica (REE): demanda y generación cada 5 minutos de Península, Baleares y Canarias, intercambios por frontera, % renovable, intensidad de CO₂ y precios (spot OMIE y PVPC).

- Sin dependencias npm y sin secretos (REE es público).
- Caché de 5 minutos en el borde de Cloudflare: da igual cuántas visitas haya, a REE le llega como mucho una consulta cada 5 minutos por centro de datos.
- CORS solo para `https://spainfacts.org` (y `www`, `spainfacts.github.io` y `localhost:3000/3100/3200/3300` para desarrollo).
- Si falla un sistema, devuelve los demás (lista `errores`). Si no responde nada, la web usa los datos horneados en el build y muestra "No en directo".
- El plan gratuito de Cloudflare Workers (100.000 peticiones/día) sobra.

## Desplegarlo (una sola vez, ~10 minutos)

Necesitas Node.js 18 o superior (ya lo usas para el sitio).

1. **Crea una cuenta gratuita de Cloudflare** en <https://dash.cloudflare.com/sign-up> y confirma el correo. No hace falta dominio ni tarjeta.
2. En el panel, entra una vez en **Workers & Pages** y elige un subdominio `*.workers.dev` (por ejemplo `spainfacts`). Será parte de la URL.
3. En una terminal, desde la raíz del repositorio:

   ```bash
   cd workers/ree-directo
   npx wrangler login      # abre el navegador para autorizar wrangler en tu cuenta
   npx wrangler deploy     # sube el Worker
   ```

   Al terminar, wrangler imprime la URL, del estilo:

   ```
   https://spainfacts-ree-directo.<tu-subdominio>.workers.dev
   ```

4. **Compruébalo** abriendo `https://spainfacts-ree-directo.<tu-subdominio>.workers.dev/snapshot` en el navegador: debe verse un JSON con `sistemas.peninsula.ultimo.demanda_mw`, etc.

## Conectarlo con la web

Edita **`src/lib/config/directo.js`** y pega la URL (sin barra final):

```js
const URL_WORKER = 'https://spainfacts-ree-directo.<tu-subdominio>.workers.dev';
```

Haz commit y push; en el siguiente despliegue de GitHub Pages la página empezará a consultar el Worker cada 5 minutos y mostrará la etiqueta verde **En directo**. La URL no es secreta.

(Alternativa: definir la variable de entorno `VITE_REE_DIRECTO_URL` al construir el sitio; tiene prioridad sobre la constante. Es útil para probar en local sin tocar el archivo.)

## Probar en local

### Sin cuenta de Cloudflare (solo Node)

Ejecuta la misma lógica del Worker contra los servicios reales de REE:

```bash
cd workers/ree-directo
node test/probar.mjs          # resumen legible (demanda, % renovable, gCO2/kWh, flujos, balance)
node test/probar.mjs --json   # el JSON completo que devolvería el Worker
node test/handler.mjs         # prueba el handler HTTP: rutas, CORS y caché (simulada)
```

### Con wrangler (emula Cloudflare en tu equipo; no necesita login)

```bash
cd workers/ree-directo
npx wrangler dev              # sirve en http://localhost:8787
curl -H "Origin: http://localhost:3000" -i http://localhost:8787/snapshot
```

Para ver la página usando ese Worker local:

```bash
VITE_REE_DIRECTO_URL=http://localhost:8787 npm run dev
```

## Rutas

| Ruta | Respuesta |
|:---|:---|
| `GET /snapshot` (también `/` y `/v1/snapshot`) | JSON de la instantánea (abajo) |
| `GET /salud` | `ok` |
| `OPTIONS *` | preflight CORS |

## Formato de la respuesta

Los campos de cada fila son **los mismos** que la consulta del pipeline `mother.electricidad_ultimas_24h` (mart `electricidad_5min`), para que el componente consuma un único formato:

```json
{
  "actualizado": "2026-09-28T06:55:00.000Z",
  "generado": "2026-09-28T07:01:12.000Z",
  "fuente": "Red Eléctrica (REE)",
  "sistemas": {
    "peninsula": {
      "ultimo": {
        "sistema": "peninsula", "ts_utc": "2026-09-28T06:55:00.000Z", "ts_local": "2026-09-28 08:55",
        "demanda_mw": 31448, "eolica": 3144, "solar_fv": 2924, "solar_termica": 9, "hidraulica": 2575,
        "nuclear": 6969, "carbon": 0, "ciclo_combinado": 10864, "cogeneracion_residuos": 1549,
        "turbinacion_bombeo": 2033, "consumo_bombeo": 0, "baterias_descarga": 0, "baterias_carga": 0,
        "diesel": 0, "turbina_gas": 0, "motores_vapor": 350, "otras_renovables": 416, "otras_no_renovables": 0,
        "intercambio_neto": 452, "imp_francia": 1001, "exp_francia": 0, "imp_portugal": 0, "exp_portugal": 143,
        "imp_marruecos": 0, "exp_marruecos": 364, "imp_andorra": 0, "exp_andorra": 41, "enlace_baleares": 154,
        "generacion_total_mw": 30729, "renovable_mw": 8924, "pct_renovable": 29.04,
        "co2_t_h": 4592.6, "intensidad_gco2_kwh": 149.5
      },
      "serie24h": [ { "ts_utc": "…", "demanda_mw": 0, "eolica": 0, "…": "cada 15 min, últimas 24 h" } ]
    },
    "baleares": { "ultimo": { "…": "…" }, "serie24h": [] },
    "canarias": { "ultimo": { "…": "…" }, "serie24h": [] }
  },
  "precios": { "spot_eur_mwh": 255.75, "pvpc_eur_mwh": 262.95, "ts": "…", "spot_ts": "…", "pvpc_ts": "…" },
  "errores": []
}
```

Convenciones (idénticas al mart `electricidad_5min`; la lógica de `normalizarFila` replica `transform/models/staging/stg_ree_visiona_5min.sql` y `marts/electricidad_5min.sql`, que son la referencia):

- Potencias en **MW** medios del intervalo de 5 minutos. Todas las tecnologías (también `consumo_bombeo`, `baterias_carga` e `imp_*`/`exp_*`) en positivo, salvo `intercambio_neto` (> 0: la península **importa**) y `enlace_baleares` (> 0: flujo **Península → Baleares**; `-icb` en la península y `cb` en Baleares).
- `demanda_mw` y `solar_fv` de la península **sin el autoconsumo FV** estimado que REE suma en la curva `DEMANDAAU` (autoconsumo = `solFot + solTer − sol` si es > 0), como en las estadísticas oficiales de demanda b.c.
- `null` donde el pipeline da null: `intercambio_neto` en las islas, `turbinacion_bombeo`/`consumo_bombeo` sin desglose de bombeo (y en Baleares), `imp_*`/`exp_*` cuando el desglose por frontera no existe o no cuadra con `inter` (±300 MW), y `enlace_baleares` en Canarias.
- Renovable (criterio de REE): eólica + solar FV + solar térmica + hidráulica sin bombeo + otras renovables. La turbinación de bombeo y las baterías **no** son renovables, pero sí cuentan en `generacion_total_mw`. `pct_renovable` = renovable / generación × 100.
- `co2_t_h` e `intensidad_gco2_kwh` (= t CO₂/h ÷ MW generados × 1000) con los factores de emisión que publica REE **para cada sistema** (servicio `coeficientesCO2` con `curva=`, cacheado 24 h; hay valores de respaldo en el código, a mantener en sincronía con la tabla `ree_coeficientes_co2` del pipeline).
- `ts_local` es la hora local del sistema (Canarias, una hora menos), con la hora repetida de octubre (`2A`/`2B` en REE) normalizada a `02:MM`. Usa `ts_utc` para comparar.
- `serie24h` va cada 15 minutos (para aligerar: ~165 KB sin comprimir, ~18 KB con gzip); `ultimo` es siempre la última lectura de 5 minutos.

## Fuentes y advertencias

- `https://demanda.ree.es/WSvisionaMoviles{Peninsula|Baleares|Canarias}Rest/resources/demandaGeneracion…` (JSONP) y `…/coeficientesCO2`: servicios del visor de demanda de REE. **No están documentados oficialmente**; si REE los cambia o su CDN (Imperva) bloquea las IP de Cloudflare, el Worker devolverá error y la web pasará a los datos del build.
- `https://apidatos.ree.es/es/datos/mercados/precios-mercados-tiempo-real`: API pública REData (precio spot cada 15 min y PVPC horario).
- En REE el campo `impAnd` es en realidad lo que **sale** hacia Andorra (el saldo `inter` solo cuadra si se invierte); el Worker ya lo corrige.
- Cita siempre: **Fuente: Red Eléctrica (REE)**.
