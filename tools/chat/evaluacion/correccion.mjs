// Corrección de las respuestas del chat contra las baterías (preguntas-*.json): una respuesta es
// correcta si contiene, para cada grupo de «acepta.cifras» y «acepta.textos», al menos una de sus
// variantes. Las cifras casan también redondeadas: dentro de media unidad de su último decimal o
// del 0,5 % («68,6» con «68,58», «8,6 millones» con 8.614.703, «1.658» con «1.657,79»).

export const sinAcentos = (s) => String(s).toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');

/** Números de un texto en castellano (1.234,5 · 8,6 millones · 215,2 mil), con su escala */
export function numeros(texto) {
	const out = [];
	const re = /(-?\d{1,3}(?:\.\d{3})+(?:,\d+)?|-?\d+(?:,\d+)?)(\s*(?:mil millones|millones|millon|mil)\b)?/g;
	for (const m of sinAcentos(texto).matchAll(re)) {
		const decimales = m[1].includes(',') ? m[1].split(',')[1].length : 0;
		const escala = !m[2] ? 1 : /mil millones/.test(m[2]) ? 1e9 : /millon/.test(m[2]) ? 1e6 : 1e3;
		const v = Number(m[1].replace(/\./g, '').replace(',', '.'));
		out.push({ v: v * escala, crudo: v, unidad: 0.5 * 10 ** -decimales * escala });
	}
	return out;
}

/** ¿Alguna cifra del texto es la de la variante, redondeada? */
export function casaNumero(texto, variante) {
	const [b] = numeros(variante);
	if (!b) return false;
	const tol = Math.max(Math.abs(b.v) * 0.005, b.unidad);
	return numeros(texto).some((a) => Math.abs(a.v - b.v) <= tol || Math.abs(a.crudo - b.v) <= tol);
}

export function correcta(texto, acepta) {
	const r = sinAcentos(texto);
	const cifras = acepta?.cifras ?? [];
	const textos = acepta?.textos ?? [];
	return (
		cifras.every((g) => !g.length || g.some((v) => r.includes(sinAcentos(v)) || casaNumero(texto, v))) &&
		textos.every((g) => !g.length || g.some((v) => r.includes(sinAcentos(v))))
	);
}
