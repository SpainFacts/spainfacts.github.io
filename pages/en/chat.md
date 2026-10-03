---
title: Ask the data
description: "Chat to query the public data gathered by SpainFacts in plain language. It works with a model in your browser, one on your computer or your Claude key: SpainFacts never sees your questions."
i18n_origen: 9211e06742b0
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import Chat from '../../../../../../src/lib/components/Chat.svelte';
</script>

Ask a question and an AI model will look for the tables that answer it among the more than 250 the site publishes, write the query and reply with the figures, a chart if it helps and the page where you can check it.

Everything happens in your browser: you bring the model and the queries run on your computer over the same files the pages use. **SpainFacts does not receive your questions** and pays nothing for them.

<Chat />

## From Claude Code, Claude Desktop or another MCP client

The same data can be queried from your AI assistant with the SpainFacts MCP server. It runs on your computer, downloads only the tables it uses and needs no key:

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io
cd spainfacts.github.io/tools/mcp
npm install
claude mcp add spainfacts -- node "$PWD/servidor.mjs"
```

In Claude Desktop, add the server to the configuration file (`claude_desktop_config.json`) with the full path to `servidor.mjs`:

```json
{
  "mcpServers": {
    "spainfacts": { "command": "node", "args": ["/path/to/spainfacts.github.io/tools/mcp/servidor.mjs"] }
  }
}
```

It offers three tools: `buscar_tablas` (search tables), `describir_tabla` (describe a table) and `consultar_sql` (read-only DuckDB SQL queries). The table and column names are in Spanish.
