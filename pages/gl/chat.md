---
title: Pregúntalles aos datos
description: "Chat para consultar en linguaxe natural os datos públicos que reúne SpainFacts. Funciona cun modelo no teu navegador, un no teu ordenador ou a túa clave de Claude: SpainFacts non ve as túas preguntas."
i18n_origen: 9211e06742b0
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import Chat from '../../../../../../src/lib/components/Chat.svelte';
</script>

Fai unha pregunta e un modelo de IA buscará as táboas que a responden entre as máis de 250 que publica a web, escribirá a consulta e contestarache coas cifras, un gráfico se axuda e a páxina onde comprobalo.

Todo ocorre no teu navegador: o modelo pós ti e as consultas execútanse no teu ordenador sobre os mesmos ficheiros que usan as páxinas. **SpainFacts non recibe as túas preguntas** nin paga nada por elas.

<Chat />

## Desde Claude Code, Claude Desktop ou outro cliente MCP

Os mesmos datos pódense consultar desde o teu asistente de IA co servidor MCP de SpainFacts. Funciona no teu ordenador, descarga só as táboas que use e non precisa ningunha clave:

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io
cd spainfacts.github.io/tools/mcp
npm install
claude mcp add spainfacts -- node "$PWD/servidor.mjs"
```

En Claude Desktop, engade o servidor no ficheiro de configuración (`claude_desktop_config.json`) coa ruta completa a `servidor.mjs`:

```json
{
  "mcpServers": {
    "spainfacts": { "command": "node", "args": ["/ruta/a/spainfacts.github.io/tools/mcp/servidor.mjs"] }
  }
}
```

Ofrece tres ferramentas: `buscar_tablas`, `describir_tabla` e `consultar_sql` (só lectura, con SQL de DuckDB).
