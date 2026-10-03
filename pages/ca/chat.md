---
title: Pregunta a les dades
description: "Xat per consultar en llenguatge natural les dades públiques que reuneix SpainFacts. Funciona amb un model al teu navegador, un al teu ordinador o la teva clau de Claude: SpainFacts no veu les teves preguntes."
i18n_origen: 9211e06742b0
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import Chat from '../../../../../../src/lib/components/Chat.svelte';
</script>

Fes una pregunta i un model d’IA cercarà les taules que la responen entre les més de 250 que publica el web, escriurà la consulta i et contestarà amb les xifres, un gràfic si ajuda i la pàgina on comprovar-ho.

Tot passa al teu navegador: el model el poses tu i les consultes s’executen al teu ordinador sobre els mateixos fitxers que fan servir les pàgines. **SpainFacts no rep les teves preguntes** ni paga res per elles.

<Chat />

## Des de Claude Code, Claude Desktop o un altre client MCP

Les mateixes dades es poden consultar des del teu assistent d’IA amb el servidor MCP de SpainFacts. Funciona al teu ordinador, descarrega només les taules que fa servir i no necessita cap clau:

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io
cd spainfacts.github.io/tools/mcp
npm install
claude mcp add spainfacts -- node "$PWD/servidor.mjs"
```

A Claude Desktop, afegeix el servidor al fitxer de configuració (`claude_desktop_config.json`) amb la ruta completa a `servidor.mjs`:

```json
{
  "mcpServers": {
    "spainfacts": { "command": "node", "args": ["/ruta/a/spainfacts.github.io/tools/mcp/servidor.mjs"] }
  }
}
```

Ofereix tres eines: `buscar_tablas`, `describir_tabla` i `consultar_sql` (només lectura, amb SQL de DuckDB).
