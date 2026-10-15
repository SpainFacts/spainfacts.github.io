// Decisor con transformers.js (ONNX) para cualquier modelo: el mismo código que
// src/lib/chat/locales.js crearDecisor, con el modelo como parámetro (id de Hugging Face o
// carpeta local con config.json, tokenizer y onnx/). Sirve para medir en Node lo que correría
// en el navegador.

import fs from 'node:fs';
import path from 'node:path';
import { importarDelRepo, importarPaquete } from './raiz.mjs';

const { promptDecision } = await importarDelRepo('src/lib/chat/decision.js');

export async function crearDecisorONNX({ modelo, dtype = 'q4', device = 'cpu', cacheDir, archivo }) {
	const tjs = await importarPaquete('@huggingface/transformers');
	const { AutoTokenizer, AutoModelForCausalLM, LogitsProcessor, LogitsProcessorList, env } = tjs;
	if (cacheDir) env.cacheDir = cacheDir;
	let id = modelo;
	if (fs.existsSync(modelo)) {
		// Carpeta local: transformers.js la busca como <localModelPath>/<id>
		env.localModelPath = path.dirname(path.resolve(modelo)) + path.sep;
		env.allowLocalModels = true;
		id = path.basename(modelo);
	}
	const tok = await AutoTokenizer.from_pretrained(id);
	const red = await AutoModelForCausalLM.from_pretrained(id, { dtype, device, use_external_data_format: true, ...(archivo ? { model_file_name: archivo } : {}) });
	class Captura extends LogitsProcessor {
		logits = null;
		_call(_ids, logits) {
			this.logits ??= logits;
			return logits;
		}
	}
	const letra = (l) => tok.encode(l, { add_special_tokens: false })[0];
	const gemma = /gemma/i.test(red.config?.model_type ?? id);
	return async function decidir(contexto, pregunta, opciones) {
		const captura = new Captura();
		const lista = new LogitsProcessorList();
		lista.push(captura);
		const texto = (gemma ? (tok.bos_token ?? '<bos>') : '') + promptDecision(contexto, pregunta, opciones);
		const entrada = tok(texto, { add_special_tokens: false });
		await red.generate({ ...entrada, max_new_tokens: 1, do_sample: false, logits_processor: lista });
		const n = captura.logits.dims.at(-1);
		const fila = captura.logits.data.subarray(captura.logits.data.length - n);
		const logits = opciones.map((_, i) => Number(fila[letra(String.fromCharCode(65 + i))]));
		const max = Math.max(...logits);
		const e = logits.map((x) => Math.exp(x - max));
		const s = e.reduce((a, b) => a + b, 0);
		const probs = e.map((x) => x / s);
		return { indice: probs.indexOf(Math.max(...probs)), probs };
	};
}
