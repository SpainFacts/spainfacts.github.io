// Modelos que corren en el equipo de quien usa el chat (navegador con WebGPU o Node), con
// transformers.js. Los pesos se descargan de Hugging Face, nunca de spainfacts.org.
//
//   crearDecisor()   -> decidir(contexto, pregunta, opciones) con Gemma 4 E2B: una pasada
//                       por pregunta y se lee la puntuación de cada letra (modo decisión)
//   crearEmbebedor() -> vector de un texto con EmbeddingGemma (búsqueda semántica)

import { promptDecision } from './decision.js';

export const MODELO_DECISOR = 'onnx-community/gemma-4-E2B-it-ONNX';
export const MODELO_EMBEDDINGS = 'onnx-community/embeddinggemma-300m-ONNX';

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
 * Decisor con Gemma 4 E2B (solo texto: ni audio ni visión).
 * @param {{ device?: 'webgpu'|'wasm'|'cpu', dtype?: string, alProgreso?: Function, cacheDir?: string }} [o]
 */
export async function crearDecisor({ device = 'webgpu', dtype = 'q4f16', alProgreso, cacheDir } = {}) {
	const { AutoTokenizer, AutoModelForCausalLM, LogitsProcessor, LogitsProcessorList } = await cargarLibreria({ cacheDir });
	const tok = await AutoTokenizer.from_pretrained(MODELO_DECISOR);
	const modelo = await AutoModelForCausalLM.from_pretrained(MODELO_DECISOR, {
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
	const idLetra = new Map();
	const idDe = (letra) => {
		if (!idLetra.has(letra)) idLetra.set(letra, tok.encode(letra, { add_special_tokens: false })[0]);
		return idLetra.get(letra);
	};

	return async function decidir(contexto, pregunta, opciones) {
		const captura = new Captura();
		const lista = new LogitsProcessorList();
		lista.push(captura);
		// Gemma necesita el token de inicio; sin él responde casi al azar
		const entrada = tok((tok.bos_token ?? '<bos>') + promptDecision(contexto, pregunta, opciones), { add_special_tokens: false });
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
 * @param {{ modelo?: string, dtype?: string, dims?: number, device?: string, alProgreso?: Function, cacheDir?: string }} [o]
 */
export async function crearEmbebedor({ modelo = MODELO_EMBEDDINGS, dtype = 'q4', dims, device, alProgreso, cacheDir } = {}) {
	const { pipeline } = await cargarLibreria({ cacheDir });
	const extraer = await pipeline('feature-extraction', modelo, {
		dtype,
		...(device ? { device } : {}),
		progress_callback: progreso(alProgreso)
	});
	return async (texto) => {
		const v = (await extraer(texto, { pooling: 'mean', normalize: true })).data;
		if (!dims || dims >= v.length) return v;
		const r = v.slice(0, dims);
		const norma = Math.hypot(...r);
		return r.map((x) => x / norma);
	};
}
