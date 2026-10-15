# Entrenamiento local del decisor del chat

Todo corre en el equipo (CPU y la gráfica integrada con ROCm), sin nube ni GPU alquilada.
Las baterías de `tools/chat/evaluacion/` son el examen: **nunca** se usan para entrenar.

## Qué hay

| Pieza | Para qué |
|---|---|
| `datos/gen-lote-*.json` | ~5.200 preguntas escritas por agentes a partir de las fichas (`tools/chat/semantica`), con su tabla, cifra, territorio, periodo y filtros. ~15 % en ca/gl/eu/en. |
| `trazas.mjs` | Pasa cada pregunta por el modo decisión real con un «decisor oráculo» que sabe la respuesta y guarda cada decisión (prompt exacto, opciones, la buena) en `datos/trazas.jsonl`. |
| `vectores.mjs` | Vectores de EmbeddingGemma (los mismos del navegador) de las preguntas generadas y de las baterías. |
| `entrenar-clasificador.py` | Clasificador de tabla: regresión logística (tablas × 256) sobre el vector de la pregunta. Segundos en CPU. Sale `clasificador.json` (~110 kB). |
| `clasificador.mjs` | El clasificador en JavaScript, sin dependencias (Node y navegador). En el chat va como `src/lib/chat/clasificador.js`. |
| `entrenar-decisor.py` | LoRA de un decisor (entropía cruzada sobre las letras de `Answer: (`, como Mapika/decider). |
| `servir.py` | Servidor local de decisiones para medir modelos de Hugging Face y afinados. |
| `exportar-onnx.py` | Lleva decider-0.8b (con o sin LoRA) al navegador sustituyendo los pesos del grafo de onnx-community/Qwen3.5-0.8B-ONNX (mismo grafo, mismos operadores). Comprueba cada transformación con los números. |
| `evaluar-decisor.mjs` | Mide cualquier decisor (Ollama, servidor, ONNX) con o sin clasificador sobre las baterías. |
| `comparar.sh` | Compara decisores con y sin clasificador en las 6 baterías viejas + validacion6, con los parquets limpios (`SPAINFACTS_PARQUETS`). |
| `exp/` | Páginas de prueba en el navegador (decisor ONNX y clasificador, WASM y WebGPU). |

## En el chat

`src/lib/chat/clasificador.js` es `clasificador.mjs`. `tools/chat/catalogo.mjs` mete `clasificador.json` en el catálogo (`catalogo.clasificador`) si sus dimensiones coinciden con las de los vectores, y `decision.js` lo usa al elegir tabla: sus 3 mejores tablas entran entre las candidatas y su probabilidad se suma a la del modelo. `ctx.clasificador = null` lo apaga. `Chat.svelte` lo crea al cargar el catálogo y lo usa con cualquier decisor (solo actúa si hay vector de EmbeddingGemma).

El decisor propio (decider-0.8b + LoRA) es la opción «Decisor de SpainFacts» de /chat
(`DECISOR_PROPIO` en `Chat.svelte`, `crearDecisor({ propio: true })` en `src/lib/chat/locales.js`).
**Solo aparece cuando `MODELO_DECISOR_PROPIO` (en `src/lib/chat/locales.js`) deja de ser el
marcador `PENDIENTE/...`**; entonces pasa a ser también el modelo predeterminado del navegador.

### Resultados que justifican la integración (2026-10-04)

270 preguntas (6 baterías viejas + validacion6), catálogo v7 y parquets limpios (`comparar.sh`):
decider-0.8b + LoRA 196 sin clasificador / **197 con clasificador** (bf16 y ONNX q4 iguales);
Ministral 3 3B (Ollama) 187/191; Gemma 4 E2B (Ollama) 181/187; Gemma ONNX del navegador 164/177.
validacion7 (60, limpia; ya gastada, la próxima medida necesita validacion8): LoRA bf16 sin
clasificador 49/60 con EmbeddingGemma y 50/60 solo con BM25 (pero la tabla baja de 56 a 53).

## Subir el decisor a Hugging Face (lo hace el dueño)

El modelo exportado está en `C:\Users\jota\venvs\onnx-decider\decider-08-lora` (lo genera
`exportar-onnx.py`; no va al repo). El navegador usa `onnx/decoder_model_merged_q4.onnx(+_data)`
y `onnx/embed_tokens_fp16.onnx(+_data)` (~0,95 GB); `decoder_model_merged_q4f16` (~0,44 GB) es
opcional (no lo usa el chat ahora mismo). Antes de publicar, revisa la licencia del modelo base
(`Mapika/decider-0.8b`, derivado de Qwen3.5-0.8B) y ponla en la tarjeta del modelo.

```bash
pip install -U "huggingface_hub[cli]"
huggingface-cli login                      # token con permiso de escritura (no lo guardes en el repo)
huggingface-cli repo create decider-0.8b-lora-onnx --type model   # o --organization SpainFacts
cd C:/Users/jota/venvs/onnx-decider/decider-08-lora
huggingface-cli upload <usuario-u-organizacion>/decider-0.8b-lora-onnx . . \
  --exclude "onnx/decoder_model_merged_q4f16*" --commit-message "decider-0.8b + LoRA SpainFacts (ONNX q4)"
```

(En versiones nuevas de `huggingface_hub` el comando es `hf` en vez de `huggingface-cli`:
`hf auth login`, `hf repo create ...`, `hf upload ...` con los mismos argumentos.)

El repo tiene que ser **público** (el navegador lo descarga sin token) y conservar la estructura
de la carpeta: `config.json`, `generation_config.json`, `tokenizer.json`, `tokenizer_config.json`,
`chat_template.jinja`, `preprocessor_config.json` y `onnx/`.

Después, en `src/lib/chat/locales.js`:

```js
export const MODELO_DECISOR_PROPIO = '<usuario-u-organizacion>/decider-0.8b-lora-onnx';
```

y prueba /chat en el navegador (WebGPU) antes de subir: elegir «Decisor de SpainFacts»,
«Descargar y cargar» y hacer 2-3 preguntas (el modelo y el dtype nuevos se prueban siempre en el
navegador: el q4 de EmbeddingGemma ya rompió producción una vez con un operador que onnxruntime-web
no tiene). Para medirlo en Node con el id publicado:
`node tools/chat/entrenamiento/evaluar-decisor.mjs --decisor onnx:<id> --dtype '{"embed_tokens":"fp16","decoder_model_merged":"q4"}' --clasificador tools/chat/entrenamiento/clasificador.json`.

## Qué no va al repo

`.gitignore` de esta carpeta: `modelos/` (~1,4 GB), `runs/` (adaptadores LoRA, ~75 MB),
`datos/trazas.jsonl` (~16 MB, se rehace con `trazas.mjs`), `datos/vectores-*.json` (~27 MB, se
rehacen con `vectores.mjs`), `datos/catalogo.json` (copia de build/chat) y cualquier
`.onnx`/`.safetensors`. Sí van el código, `clasificador.json` (~110 kB), las preguntas generadas
`datos/gen-lote-*.json` (~1,7 MB, no se pueden rehacer sin agentes) y `resultados/` (~1,2 MB).

## Rehacer el clasificador (cuando cambian tablas o fichas)

Desde la raíz del repo con datos (o con `SPAINFACTS_RAIZ`):

```bash
node tools/chat/entrenamiento/vectores.mjs entrenamiento
python tools/chat/entrenamiento/entrenar-clasificador.py --catalogo build/chat/catalogo.json --l2 1e-5 --todo --salida tools/chat/entrenamiento/clasificador.json
```

Para tablas nuevas hacen falta preguntas generadas para ellas (`datos/gen-*.json`); sin
ejemplos el clasificador no las propone y el chat se apoya en la búsqueda como hasta ahora.
`l2` y la temperatura (0,75) se eligieron con una reserva del 10 % de las preguntas
generadas (`--reserva 0.1`, sin `--todo`), nunca con las baterías.

## Entorno

- PyTorch ROCm para Windows (Radeon 8060S, gfx1151): Python 3.12 y las ruedas de
  `repo.radeon.com/rocm/windows/rocm-rel-7.2.1` (rocm_sdk_* y torch 2.9.1+rocm7.2.1).
- Qwen3.5 (decider) entrena por la vía lenta de PyTorch (sin flash-linear-attention):
  ~2,5 s por ejemplo con la gráfica libre.
- Gemma 4 E2B (5.000 millones de parámetros con PLE) no cabe para entrenar con la memoria compartida ocupada.
