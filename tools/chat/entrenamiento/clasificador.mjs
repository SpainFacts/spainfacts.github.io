// Clasificador de tabla sobre el vector de EmbeddingGemma de la pregunta (el mismo que ya
// calcula el chat para buscar): una capa lineal (tablas × dims) entrenada con
// entrenar-clasificador.py. Sin dependencias: corre igual en Node y en el navegador.
//
// Formato (JSON): { dims, tablas: [nombre...], pesos: base64 de Int8 (tablas × dims),
//                   escala: [por tabla], sesgo: [por tabla], temperatura }

const deBase64 = (s) => {
	if (typeof Buffer !== 'undefined') return new Int8Array(Buffer.from(s, 'base64'));
	const bin = atob(s);
	const out = new Int8Array(bin.length);
	for (let i = 0; i < bin.length; i++) out[i] = (bin.charCodeAt(i) << 24) >> 24;
	return out;
};

export function crearClasificador(modelo) {
	const { dims, tablas, escala, sesgo } = modelo;
	const T = modelo.temperatura ?? 1;
	const pesos = deBase64(modelo.pesos);
	const fila = new Map(tablas.map((t, i) => [t, i]));
	/** Puntuación (logit) de una tabla para un vector ya normalizado */
	const logit = (vec, i) => {
		let s = 0;
		const o = i * dims;
		for (let k = 0; k < dims; k++) s += pesos[o + k] * vec[k];
		return (s * escala[i] + sesgo[i]) / T;
	};
	return {
		tablas,
		/** Log-probabilidades entre las tablas dadas (las desconocidas, con la media) */
		logprobs(vec, nombres) {
			const l = nombres.map((n) => (fila.has(n) ? logit(vec, fila.get(n)) : null));
			const conocidos = l.filter((x) => x !== null);
			const media = conocidos.length ? conocidos.reduce((a, b) => a + b, 0) / conocidos.length : 0;
			const x = l.map((v) => v ?? media);
			const m = Math.max(...x);
			const lse = m + Math.log(x.reduce((a, v) => a + Math.exp(v - m), 0));
			return x.map((v) => v - lse);
		},
		/** Las k tablas más probables entre todas */
		mejores(vec, k = 6) {
			return tablas
				.map((t, i) => ({ tabla: t, s: logit(vec, i) }))
				.sort((a, b) => b.s - a.s)
				.slice(0, k);
		}
	};
}
