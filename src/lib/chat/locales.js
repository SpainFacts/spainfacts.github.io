// Modelos que corren en el equipo de quien usa el chat (navegador con WebGPU o Node), con
// transformers.js. Los pesos se descargan de Hugging Face, nunca de spainfacts.org.
//
//   crearDecisor()   -> decidir(contexto, pregunta, opciones) con Gemma 4 E2B o el decisor
//                       propio ({ propio: true }): una pasada por pregunta y se lee la
//                       puntuación de cada letra (modo decisión)
//   crearEmbebedor() -> vector de un texto con EmbeddingGemma (búsqueda semántica)

import { promptDecision } from './decision.js';

export const MODELO_DECISOR = 'onnx-community/gemma-4-E2B-it-ONNX';
export const MODELO_EMBEDDINGS = 'onnx-community/embeddinggemma-300m-ONNX';

// Decisor propio: decider-0.8b (Qwen3.5 0,8B) afinado con LoRA en local con preguntas de
// nuestras fichas (tools/chat/entrenamiento/LEEME.md). Medido el mejor en modo decisión
// (197/270 frente a 191 de Ministral 3 3B y 187 de Gemma 4 E2B) y pesa ~0,95 GB.
// Publicado en Hugging Face el 2026-10-15. Si se vuelve a poner un marcador que empiece por
// PENDIENTE/, el chat deja de ofrecer la opción.
export const MODELO_DECISOR_PROPIO = 'Jotapostre/decider-0.8b-lora-onnx';
export const DECISOR_PROPIO_DISPONIBLE = !MODELO_DECISOR_PROPIO.startsWith('PENDIENTE/');
// El q4 normal del decodificador y las incrustaciones en fp16 (el q4 de embed_tokens usa
// GatherBlockQuantized, que onnxruntime-web no tiene). Probado en WASM y WebGPU (2026-10-04)
const DTYPE_DECISOR_PROPIO = { embed_tokens: 'fp16', decoder_model_merged: 'q4' };

let transformers = null;
async function cargarLibreria(opciones = {}) {
	transformers ??= await import('@huggingface/transformers');
	if (opciones.cacheDir) transformers.env.cacheDir = opciones.cacheDir;
	return transformers;
}

/** Progreso agregado de varios ficheros: (fraccion 0-1, texto) */
function progreso(alProgreso) {
	const ficheros = new Map();
	return (info) => {
		if (!alProgreso) return;
		if (info.status === 'progress_total') return alProgreso((info.progress ?? 0) / 100, '');
		if (info.status === 'progress' && info.file) {
			ficheros.set(info.file, { cargado: info.loaded ?? 0, total: info.total ?? 0 });
			let c = 0;
			let t = 0;
			for (const f of ficheros.values()) {
				c += f.cargado;
				t += f.total;
			}
			if (t) alProgreso(c / t, `${(c / 1e9).toFixed(2)} / ${(t / 1e9).toFixed(2)} GB`);
		}
	};
}

/**
 * Decisor con Gemma 4 E2B (solo texto: ni audio ni visión) u otro modelo de transformers.js
 * (`modelo`: id de Hugging Face; `propio: true` = el decisor propio con su dtype).
 * @param {{ modelo?: string, propio?: boolean, device?: 'webgpu'|'wasm'|'cpu', dtype?: string|object, alProgreso?: Function, cacheDir?: string }} [o]
 */
export async function crearDecisor({ modelo: id, propio = false, device = 'webgpu', dtype, alProgreso, cacheDir } = {}) {
	id ??= propio ? MODELO_DECISOR_PROPIO : MODELO_DECISOR;
	dtype ??= propio ? DTYPE_DECISOR_PROPIO : 'q4f16';
	const { AutoTokenizer, AutoModelForCausalLM, LogitsProcessor, LogitsProcessorList } = await cargarLibreria({ cacheDir });
	const tok = await AutoTokenizer.from_pretrained(id);
	const modelo = await AutoModelForCausalLM.from_pretrained(id, {
		dtype,
		device,
		use_external_data_format: true,
		progress_callback: progreso(alProgreso)
	});

	// Captura las puntuaciones del primer token: no se genera nada útil, se leen las letras
	class Captura extends LogitsProcessor {
		logits = null;
		_call(_ids, logits) {
			this.logits ??= logits;
			return logits;
		}
	}
	const gemma = /gemma/i.test(modelo.config?.model_type ?? id);
	const idLetra = new Map();
	const idDe = (letra) => {
		if (!idLetra.has(letra)) idLetra.set(letra, tok.encode(letra, { add_special_tokens: false })[0]);
		return idLetra.get(letra);
	};

	return async function decidir(contexto, pregunta, opciones) {
		const captura = new Captura();
		const lista = new LogitsProcessorList();
		lista.push(captura);
		// Gemma necesita el token de inicio; sin él responde casi al azar (Qwen no lleva)
		const entrada = tok((gemma ? (tok.bos_token ?? '<bos>') : '') + promptDecision(contexto, pregunta, opciones), { add_special_tokens: false });
		await modelo.generate({ ...entrada, max_new_tokens: 1, do_sample: false, logits_processor: lista });
		const n = captura.logits.dims.at(-1);
		const fila = captura.logits.data.subarray(captura.logits.data.length - n);
		// Probabilidad de cada opción: softmax de los logits de sus letras
		const logits = opciones.map((_, i) => Number(fila[idDe(String.fromCharCode(65 + i))]));
		const max = Math.max(...logits);
		const e = logits.map((x) => Math.exp(x - max));
		const suma = e.reduce((a, b) => a + b, 0);
		const probs = e.map((x) => x / suma);
		return { indice: probs.indexOf(Math.max(...probs)), probs };
	};
}

/**
 * Embebedor de consultas (el catálogo trae ya los vectores de las tablas y su configuración:
 * catalogo.embeddings = { modelo, dtype, dims }). Si el modelo da más dimensiones que las del
 * catálogo, se recortan (Matryoshka) y se renormaliza.
 *
 * `archivo` elige otra variante del modelo: el q4 normal de EmbeddingGemma usa el nodo
 * GatherBlockQuantized, que onnxruntime-web no tiene («Could not find an implementation for
 * GatherBlockQuantized»; en Node sí funciona). model_no_gather_q4 es el mismo q4 sin ese nodo.
 * pipeline() no deja elegir el fichero, así que se carga el modelo y se hace la media a mano
 * (lo mismo que hace pipeline('feature-extraction') con pooling 'mean').
 * @param {{ modelo?: string, dtype?: string, archivo?: string, dims?: number, device?: string, alProgreso?: Function, cacheDir?: string }} [o]
 */
export async function crearEmbebedor({ modelo = MODELO_EMBEDDINGS, dtype = 'q4', archivo, dims, device, alProgreso, cacheDir } = {}) {
	const { AutoTokenizer, AutoModel, mean_pooling } = await cargarLibreria({ cacheDir });
	const alCargar = progreso(alProgreso);
	const tok = await AutoTokenizer.from_pretrained(modelo, { progress_callback: alCargar });
	const red = await AutoModel.from_pretrained(modelo, {
		dtype,
		...(archivo ? { model_file_name: archivo } : {}),
		...(device ? { device } : {}),
		progress_callback: alCargar
	});
	return async (texto) => {
		const entrada = tok([texto], { padding: true, truncation: true });
		const v = mean_pooling((await red(entrada)).last_hidden_state, entrada.attention_mask).normalize(2, -1).data;
		if (!dims || dims >= v.length) return v;
		const r = v.slice(0, dims);
		const norma = Math.hypot(...r);
		return r.map((x) => x / norma);
	};
}
