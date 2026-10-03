// Batería de validación: la medida limpia. Respuestas sacadas de los datos el 2026-10-03
// antes de pasarla a ningún modelo. NO ajustar el chat mirando sus fallos: si se hace,
// deja de valer y hay que escribir otra. Si se refrescan los datos, actualizar las cifras.
const cifra = (r, v) => r.includes(v) || r.includes(v.replace('.', ','));
export const PREGUNTAS = [
	{ q: '¿Cuántos extranjeros viven en España?', ok: (r) => /6[.\s]?911[.\s]?971|6[.,]9 millones|6[.,]91/.test(r) },
	// Encuesta ECV (15.620 nominal / 16.038 real, 2025) o Atlas de renta (15.866 real, 2023): dos fuentes oficiales
	{
		q: '¿Cuál es la renta media por persona en España?',
		ok: (r) => (/15[.\s]?620|16[.\s]?03[78]/.test(r) && r.includes('2025')) || (/15[.\s]?866/.test(r) && r.includes('2023'))
	},
	{ q: '¿Cuántas personas murieron en España en 2024?', ok: (r) => /436[.\s]?118/.test(r) },
	{ q: '¿Cuál es la tasa de paro en Andalucía?', ok: (r) => cifra(r, '14.56') && r.includes('2026') },
	{ q: '¿A qué edad se tiene el primer hijo en España?', ok: (r) => cifra(r, '31.52') || cifra(r, '31.5') },
	{ q: '¿Qué provincia tiene más habitantes?', ok: (r) => r.includes('madrid') && /7[.\s]?137[.\s]?031/.test(r) },
	// Millones de euros, nominal o real
	{ q: '¿Cuánto gastaron los turistas en España en 2025?', ok: (r) => /134[.\s]?(743|650|649)/.test(r) },
	{ q: '¿Cuántos hijos tiene de media cada mujer en España?', ok: (r) => cifra(r, '1.1') && r.includes('2024') },
	{ q: '¿Cuántas pensiones se pagan en España?', ok: (r) => /10[.\s]?547[.\s]?417|10[.,]5/.test(r) },
	{ q: '¿Qué comunidad tiene la esperanza de vida más alta?', ok: (r) => r.includes('madrid') && cifra(r, '85.58') }
];
