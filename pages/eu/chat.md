---
title: Galdetu datuei
description: "SpainFactsek biltzen dituen datu publikoak hizkuntza naturalean kontsultatzeko txata. Zure nabigatzaileko eredu batekin, zure ordenagailukoarekin edo zure Claude gakoarekin dabil: SpainFactsek ez ditu zure galderak ikusten."
i18n_origen: 9211e06742b0
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import Chat from '../../../../../../src/lib/components/Chat.svelte';
</script>

Egin galdera bat, eta AA eredu batek webguneak argitaratzen dituen 250 taula baino gehiagoren artean erantzuten duten taulak bilatuko ditu, kontsulta idatziko du eta zifrekin erantzungo dizu, grafiko batekin laguntzen badu, eta egiaztatzeko orriarekin.

Dena zure nabigatzailean gertatzen da: eredua zuk jartzen duzu eta kontsultak zure ordenagailuan exekutatzen dira, orriek erabiltzen dituzten fitxategi berberen gainean. **SpainFactsek ez ditu zure galderak jasotzen** eta ez du ezer ordaintzen haiengatik.

<Chat />

## Claude Codetik, Claude Desktopetik edo beste MCP bezero batetik

Datu berberak zure AA laguntzailetik kontsulta daitezke SpainFactsen MCP zerbitzariarekin. Zure ordenagailuan exekutatzen da, erabiltzen dituen taulak bakarrik deskargatzen ditu eta ez du gakorik behar:

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io
cd spainfacts.github.io/tools/mcp
npm install
claude mcp add spainfacts -- node "$PWD/servidor.mjs"
```

Claude Desktopen, gehitu zerbitzaria konfigurazio-fitxategian (`claude_desktop_config.json`), `servidor.mjs` fitxategirako bide osoarekin:

```json
{
  "mcpServers": {
    "spainfacts": { "command": "node", "args": ["/bidea/spainfacts.github.io/tools/mcp/servidor.mjs"] }
  }
}
```

Hiru tresna eskaintzen ditu: `buscar_tablas`, `describir_tabla` eta `consultar_sql` (irakurtzeko soilik, DuckDBren SQLarekin).
