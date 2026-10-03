---
title: Pregunta a los datos
description: "Chat para consultar en lenguaje natural los datos públicos que reúne SpainFacts. Funciona con un modelo en tu navegador, uno en tu ordenador o tu clave de Claude: SpainFacts no ve tus preguntas."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import Chat from '../../../../../src/lib/components/Chat.svelte';
</script>

Haz una pregunta y un modelo de IA buscará las tablas que la responden entre las más de 250 que publica la web, escribirá la consulta y te contestará con las cifras, un gráfico si ayuda y la página donde comprobarlo.

Todo ocurre en tu navegador: el modelo lo pones tú y las consultas se ejecutan en tu ordenador sobre los mismos ficheros que usan las páginas. **SpainFacts no recibe tus preguntas** ni paga nada por ellas.

<Chat />

## Desde Claude Code, Claude Desktop u otro cliente MCP

Los mismos datos se pueden consultar desde tu asistente de IA con el servidor MCP de SpainFacts. Corre en tu ordenador, descarga solo las tablas que use y no necesita ninguna clave:

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io
cd spainfacts.github.io/tools/mcp
npm install
claude mcp add spainfacts -- node "$PWD/servidor.mjs"
```

En Claude Desktop, añade el servidor en el fichero de configuración (`claude_desktop_config.json`) con la ruta completa a `servidor.mjs`:

```json
{
  "mcpServers": {
    "spainfacts": { "command": "node", "args": ["/ruta/a/spainfacts.github.io/tools/mcp/servidor.mjs"] }
  }
}
```

Ofrece tres herramientas: `buscar_tablas`, `describir_tabla` y `consultar_sql` (solo lectura, con SQL de DuckDB).
