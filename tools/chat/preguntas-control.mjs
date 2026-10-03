// Batería de control: preguntas que NO se usaron para ajustar el chat (respuestas sacadas
// de los datos antes de probar ningún modelo). Sirve para ver si las mejoras generalizan.
// No ajustar el código mirando estas preguntas: si se hace, crear otra batería de control.
// Datos de octubre de 2026; si se refrescan, actualizar las cifras.
const cifra = (r, v) => r.includes(v) || r.includes(v.replace('.', ','));
export const PREGUNTAS = [
	{ q: '¿Cuál es la esperanza de vida en España?', ok: (r) => /\b84\b/.test(r) && r.includes('2024') },
	{ q: '¿Cuántos nacimientos hubo en España en 2023?', ok: (r) => /320[.\s]?656/.test(r) },
	{ q: '¿A qué porcentaje están llenos los embalses?', ok: (r) => cifra(r, '59.2') },
	{ q: '¿Cuántos turistas llegaron a España en 2025?', ok: (r) => /96[.\s]?803[.\s]?893|96[.,]8/.test(r) },
	{ q: '¿Qué comunidad tiene el salario más alto?', ok: (r) => r.includes('madrid') && /2[.\s]?903/.test(r) },
	{ q: '¿Cuál es la tasa de pobreza en España?', ok: (r) => cifra(r, '19.5') && r.includes('2025') },
	{ q: '¿Cuántas hectáreas se han quemado este año?', ok: (r) => /311[.\s]?908/.test(r) },
	{ q: '¿Cuántas toneladas de CO2 emite cada español al año?', ok: (r) => cifra(r, '5.48') || cifra(r, '5.49') },
	// Dos tipologías sin total (colectiva / unifamiliar), nominal o real
	{ q: '¿Cuál es el alquiler mediano mensual en Barcelona?', ok: (r) => /\b(753|760|773|780)\b/.test(r) && r.includes('2024') },
	{ q: '¿Cuántas personas fueron condenadas en 2024?', ok: (r) => /306[.\s]?807/.test(r) }
];
