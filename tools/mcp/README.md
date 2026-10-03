# Servidor MCP de SpainFacts

Deja consultar los datos de [spainfacts.org](https://spainfacts.org) desde Claude Code, Claude Desktop u otro cliente MCP. Corre en tu ordenador: el modelo lo pone el cliente y las consultas las ejecuta DuckDB en local. No usa MotherDuck ni ningún servidor de SpainFacts.

## Instalación

```bash
cd tools/mcp
npm install
claude mcp add spainfacts -- node "$PWD/servidor.mjs"
```

Claude Desktop (`claude_desktop_config.json`):

```json
{ "mcpServers": { "spainfacts": { "command": "node", "args": ["/ruta/completa/tools/mcp/servidor.mjs"] } } }
```

## Herramientas

| Herramienta | Qué hace |
|---|---|
| `buscar_tablas` | Busca por palabras en el catálogo (nombre, descripción, columnas y páginas de cada tabla) |
| `describir_tabla` | Columnas, rangos, valores posibles, filas de ejemplo y páginas que la usan |
| `consultar_sql` | Un `SELECT` de DuckDB sobre `mother.<tabla>`; devuelve hasta 60 filas |

## Datos

- Por defecto descarga `https://spainfacts.org/chat/catalogo.json`, `data/manifest.json` y, según los vaya necesitando, los parquets de cada tabla. Los guarda en `~/.cache/spainfacts-mcp` (o en `SPAINFACTS_CACHE`). Las rutas de los parquets llevan un hash del contenido: cuando cambian los datos cambia la ruta y se descarga la versión nueva.
- `--local` usa los datos del repositorio: `.evidence/template/static/data/mother` (tras `npm run sources`) y `build/chat/catalogo.json` (`node tools/chat/catalogo.mjs`).
- `SPAINFACTS_URL` cambia la web de origen (por ejemplo, una vista previa).

## Seguridad

Solo lectura en dos capas: `validarSQL` (en `src/lib/chat/herramientas.js`) rechaza todo lo que no sea un `SELECT` sobre las tablas, y DuckDB arranca con `enable_external_access = false`, acceso solo a la carpeta de datos y la configuración bloqueada.

## Pruebas

```bash
node tools/mcp/prueba.mjs --local
```

Las herramientas son las mismas que usa el chat de la web (`/chat`), definidas en `src/lib/chat/herramientas.js`.
