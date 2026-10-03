// Bucle del chat de datos en el navegador. Nada pasa por un servidor nuestro: el modelo lo
// pone quien lo usa y el SQL se ejecuta con DuckDB-WASM sobre los parquets de la web.
//
// Proveedores:
//   anthropic -> clave de API de Anthropic del usuario, llamadas directas desde el navegador
//                con herramientas nativas.
//   local     -> servidor compatible con la API de OpenAI en su ordenador (Ollama, LM Studio)
//                o un servicio con su clave (OpenRouter...). Protocolo JSON.
//   navegador -> modelo pequeño dentro del navegador con WebLLM (WebGPU). Los pesos se
//                descargan de Hugging Face, no de spainfacts.org. Protocolo JSON.

import {
	HERRAMIENTAS,
	buscarTablas,
	ejecutarHerramienta,
	leerAccionJSON,
	promptProtocoloJSON,
	promptSistema
} from './herramientas.js';
import { promptDecision, probabilidadesDeLetras } from './decision.js';

const MAX_PASOS = 12;
const MAX_PASOS_JSON = 8;
const MAX_RESULTADO_JSON = 6000; // caracteres de cada resultado para modelos pequeños

export const MODELOS_ANTHROPIC = [
	{ id: 'claude-opus-5-5', nombre: 'Claude Opus 5.5', precio: '4 $ / 20 $ por millón de tokens' },
	{ id: 'claude-sonnet-5-5', nombre: 'Claude Sonnet 5.5', precio: '2 $ / 10 $ por millón de tokens' },
	{ id: 'claude-haiku-4-5', nombre: 'Claude Haiku 4.5', precio: '1 $ / 5 $ por millón de tokens' }
];

export const WEBLLM_URL = 'https://esm.run/@mlc-ai/web-llm@0.2.85';

/**
 * Responde una pregunta.
 * @param {object} o
 * @param {'anthropic'|'local'|'navegador'} o.proveedor
 * @param {object} o.config  clave, modelo, url...
 * @param {any} o.estado     estado de la conversación de este proveedor (se reutiliza entre preguntas)
 * @param {string} o.pregunta
 * @param {{ catalogo: any, indice: any, consultar: Function }} o.ctx
 * @param {string} o.lang
 * @param {(paso: {herramienta: string, entrada: any}) => void} o.alPaso  antes de ejecutar cada herramienta
 * @param {(grafico: any) => void} o.alGrafico
 * @returns {Promise<{ texto: string, estado: any }>}
 */
export async function responder(o) {
	if (o.proveedor === 'anthropic') return responderAnthropic(o);
	return responderJSON(o);
}

// ---------- Anthropic: herramientas nativas ----------

let clienteAnthropic = null;
let claveCliente = '';

async function obtenerCliente(clave) {
	if (!clienteAnthropic || claveCliente !== clave) {
		const { default: Anthropic } = await import('@anthropic-ai/sdk');
		// La clave es del usuario y la petición va de su navegador a Anthropic: no hay
		// servidor intermedio que pueda filtrarla.
		clienteAnthropic = new Anthropic({ apiKey: clave, dangerouslyAllowBrowser: true });
		claveCliente = clave;
	}
	return clienteAnthropic;
}

async function responderAnthropic({ config, estado, pregunta, ctx, lang, alPaso, alGrafico }) {
	const cliente = await obtenerCliente(config.clave);
	const modelo = config.modelo || MODELOS_ANTHROPIC[0].id;
	// El historial solo crece (los bloques de razonamiento deben volver tal cual)
	const mensajes = estado?.mensajes ?? [];
	mensajes.push({ role: 'user', content: pregunta });

	const esHaiku = modelo.startsWith('claude-haiku');
	const peticion = {
		model: modelo,
		max_tokens: 16000,
		system: promptSistema(ctx.catalogo, lang),
		tools: HERRAMIENTAS,
		cache_control: { type: 'ephemeral' },
		messages: mensajes,
		// Haiku 4.5 no acepta effort; en los demás, medio basta para consultas de datos
		...(esHaiku ? {} : { output_config: { effort: 'medium' } }),
		// Si el modelo rechaza por error una pregunta legítima, la API la reintenta con otro
		...(esHaiku ? {} : { betas: ['server-side-fallback-2026-07-01'], fallbacks: 'default' })
	};

	const textos = [];
	for (let paso = 0; paso < MAX_PASOS; paso++) {
		const r = await cliente.beta.messages.create(peticion);
		mensajes.push({ role: 'assistant', content: r.content });
		if (r.stop_reason === 'refusal') {
			textos.push('El modelo no ha querido responder a esta pregunta.');
			break;
		}
		for (const b of r.content) if (b.type === 'text' && b.text.trim()) textos.push(b.text);
		if (r.stop_reason !== 'tool_use') break;

		const usos = r.content.filter((b) => b.type === 'tool_use');
		const resultados = await Promise.all(
			usos.map(async (u) => {
				alPaso?.({ herramienta: u.name, entrada: u.input });
				const res = await ejecutarHerramienta(u.name, u.input, ctx);
				if (res.grafico) alGrafico?.(res.grafico);
				return { type: 'tool_result', tool_use_id: u.id, content: res.resultado };
			})
		);
		// Todos los resultados en un único mensaje
		mensajes.push({ role: 'user', content: resultados });
		if (paso === MAX_PASOS - 1) textos.push('(He llegado al máximo de pasos sin terminar.)');
	}
	return { texto: textos.at(-1) ?? '', estado: { mensajes } };
}

// ---------- Modelos pequeños: protocolo JSON ----------

async function completarLocal(config, mensajes) {
	const base = (config.url || 'http://localhost:11434/v1').replace(/\/+$/, '');
	// Ollama: por su API compatible con OpenAI usa un contexto corto y recorta la
	// conversación sin avisar; con la nativa se fija el contexto.
	if (/:11434(\/|$)/.test(base)) {
		const raiz = base.replace(/\/v1$/, '');
		const r = await fetch(`${raiz}/api/chat`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				model: config.modelo,
				messages: mensajes,
				stream: false,
				format: 'json',
				// Los modelos con modo de razonamiento (Qwen3...) solo ganan tiempo sin él aquí
				...(/qwen3|deepseek-r1|gpt-oss/i.test(config.modelo) ? { think: false } : {}),
				options: { temperature: 0, num_ctx: 16384 }
			})
		});
		if (!r.ok) throw new Error(`${raiz}: HTTP ${r.status} ${(await r.text()).slice(0, 200)}`);
		return (await r.json()).message?.content ?? '';
	}
	const r = await fetch(`${base}/chat/completions`, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			...(config.clave ? { Authorization: `Bearer ${config.clave}` } : {})
		},
		body: JSON.stringify({
			model: config.modelo,
			messages: mensajes,
			temperature: 0,
			response_format: { type: 'json_object' }
		})
	});
	if (!r.ok) throw new Error(`${base}: HTTP ${r.status} ${(await r.text()).slice(0, 200)}`);
	const j = await r.json();
	return j.choices?.[0]?.message?.content ?? '';
}

/**
 * Decisor con un modelo de Ollama (modo decisión): una pasada por pregunta, sin generar
 * texto, leyendo la probabilidad de cada letra (necesita Ollama con logprobs).
 */
export function crearDecisorOllama({ url = 'http://localhost:11434/v1', modelo }) {
	const raiz = url.replace(/\/+$/, '').replace(/\/v1$/, '');
	return async function decidir(contexto, pregunta, opciones) {
		const r = await fetch(`${raiz}/api/generate`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				model: modelo,
				raw: true,
				prompt: promptDecision(contexto, pregunta, opciones),
				stream: false,
				logprobs: true,
				top_logprobs: 20,
				...(/qwen3|deepseek-r1|gpt-oss/i.test(modelo) ? { think: false } : {}),
				options: { num_predict: 1, temperature: 0, num_ctx: 8192 }
			})
		});
		if (!r.ok) throw new Error(`${raiz}: HTTP ${r.status} ${(await r.text()).slice(0, 200)}`);
		const j = await r.json();
		const porLetra = new Map();
		for (const x of j.logprobs?.[0]?.top_logprobs ?? []) {
			const l = x.token.trim();
			if (/^[A-Z]$/.test(l) && !porLetra.has(l)) porLetra.set(l, x.logprob);
		}
		if (!porLetra.size && j.response) porLetra.set(j.response.trim()[0], 0);
		const probs = probabilidadesDeLetras(porLetra, opciones.length);
		return { indice: probs.indexOf(Math.max(...probs)), probs };
	};
}

let motorWebLLM = null;
let modeloWebLLM = '';

export async function listarModelosWebLLM() {
	const webllm = await import(/* @vite-ignore */ WEBLLM_URL);
	// Modelos de chat de los fabricantes con algo que aportar; fuera los base, de
	// matemáticas, visión o razonamiento largo y las variantes de contexto corto
	return webllm.prebuiltAppConfig.model_list
		.filter(
			(m) =>
				/(qwen|llama|phi|gemma|ministral|mistral|hermes|olmo|smollm)/i.test(m.model_id) &&
				!/(base|math|vision|reasoning|distill|-1k|q0f|tinyllama|llama-2|redpajama)/i.test(m.model_id) &&
				/q4f16/i.test(m.model_id)
		)
		.map((m) => ({ id: m.model_id, vram: m.vram_required_MB }))
		.filter((m) => !m.vram || m.vram < 6000)
		.sort((a, b) => (a.vram ?? 0) - (b.vram ?? 0));
}

export async function cargarWebLLM(modelo, alProgreso) {
	if (motorWebLLM && modeloWebLLM === modelo) return motorWebLLM;
	if (!('gpu' in navigator)) throw new Error('Este navegador no tiene WebGPU (prueba con Chrome o Edge recientes).');
	const webllm = await import(/* @vite-ignore */ WEBLLM_URL);
	motorWebLLM?.unload?.();
	motorWebLLM = await webllm.CreateMLCEngine(modelo, {
		initProgressCallback: (p) => alProgreso?.(p.progress ?? 0, p.text ?? '')
	});
	modeloWebLLM = modelo;
	return motorWebLLM;
}

async function completarNavegador(config, mensajes, alProgreso) {
	const motor = await cargarWebLLM(config.modelo, alProgreso);
	const r = await motor.chat.completions.create({
		messages: mensajes,
		temperature: 0,
		response_format: { type: 'json_object' }
	});
	return r.choices?.[0]?.message?.content ?? '';
}

async function responderJSON({ proveedor, config, estado, pregunta, ctx, lang, alPaso, alGrafico, alProgreso }) {
	// Entre preguntas solo se guardan pregunta y respuesta final: los modelos pequeños
	// tienen poco contexto.
	const historial = estado?.historial ?? [];
	const hechas = new Set();

	// Búsqueda previa: se ahorra un paso y el modelo empieza con las fichas de las tres
	// mejores tablas delante, que es lo que más falla a los modelos pequeños
	let primerMensaje = pregunta;
	if (config.prebusqueda !== false) {
		const entrada = { texto: pregunta };
		alPaso?.({ herramienta: 'buscar_tablas', entrada });
		const vector = ctx.embeber ? await ctx.embeber((ctx.catalogo.embeddings?.prefijo_consulta ?? '') + pregunta) : null;
		const r = buscarTablas(ctx.indice, pregunta, 6, 3, vector);
		hechas.add(JSON.stringify(['buscar_tablas', entrada]));
		primerMensaje = `${pregunta}\n\nTablas candidatas (búsqueda ya hecha; las tres primeras con su ficha):\n${JSON.stringify(r)}`;
	}
	const mensajes = [
		{ role: 'system', content: promptSistema(ctx.catalogo, lang) + '\n' + promptProtocoloJSON() },
		...historial.slice(-6),
		{ role: 'user', content: primerMensaje }
	];
	const completar = proveedor === 'local' ? (m) => completarLocal(config, m) : (m) => completarNavegador(config, m, alProgreso);

	let texto = '';
	let reintentos = 0;
	for (let paso = 0; paso < MAX_PASOS_JSON; paso++) {
		const salida = await completar(mensajes);
		mensajes.push({ role: 'assistant', content: salida });
		const a = leerAccionJSON(salida);
		if (a.error) {
			mensajes.push({ role: 'user', content: `${a.error} Responde solo con un objeto JSON con "accion".` });
			continue;
		}
		if (a.accion === 'responder') {
			// Tras un error o un resultado vacío los modelos pequeños se rinden aunque la
			// ficha que acaban de recibir les diga cómo arreglarlo: un intento más
			const seRinde = /lo siento|no puedo|no he podido|no encuentro|no se puede|asegúrate/i.test(a.texto);
			if (seRinde && reintentos < 2 && paso < MAX_PASOS_JSON - 2) {
				reintentos++;
				mensajes.push({
					role: 'user',
					content:
						'No te rindas: corrige la consulta. Usa los valores exactos de la ficha y no pidas periodos posteriores al «Último periodo con datos» que indica (para el dato actual usa max() de la columna de fecha). Si la tabla no sirve, busca otra.'
				});
				continue;
			}
			texto = a.texto;
			break;
		}
		// Los modelos pequeños a veces repiten la misma acción en bucle
		const firma = JSON.stringify([a.accion, a.entrada]);
		if (hechas.has(firma)) {
			mensajes.push({
				role: 'user',
				content: 'Ya has hecho exactamente esa acción y tienes su resultado arriba. Si te sirve, responde con {"accion": "responder", ...}; si no, cambia la consulta.'
			});
			continue;
		}
		hechas.add(firma);
		alPaso?.({ herramienta: a.accion, entrada: a.entrada });
		const res = await ejecutarHerramienta(a.accion, a.entrada, { ...ctx, estricto: true });
		if (res.grafico) alGrafico?.(res.grafico);
		const recorte =
			res.resultado.length > MAX_RESULTADO_JSON ? res.resultado.slice(0, MAX_RESULTADO_JSON) + '… (recortado)' : res.resultado;
		mensajes.push({ role: 'user', content: `Resultado de ${a.accion}: ${recorte}` });
	}
	if (!texto) texto = 'No he conseguido terminar la respuesta con este modelo. Prueba a reformular la pregunta o con un modelo mayor.';
	historial.push({ role: 'user', content: pregunta }, { role: 'assistant', content: JSON.stringify({ accion: 'responder', texto }) });
	return { texto, estado: { historial } };
}
