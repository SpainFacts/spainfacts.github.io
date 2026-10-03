// Batería de preguntas del chat de datos, común a probar-modelo.mjs y probar-decision.mjs.
// Preguntas con la respuesta correcta según los datos de octubre de 2026 (texto en minúsculas).
// Exigen la cifra y el periodo: un modelo que coge un año viejo falla.
// Si se refrescan los datos, actualizar las cifras.
const cifra = (r, v) => r.includes(v) || r.includes(v.replace('.', ','));
export const PREGUNTAS = [
	{ q: '¿Qué comunidad autónoma tiene más deuda en porcentaje del PIB?', ok: (r) => r.includes('valenciana') && /\b40\b/.test(r) && r.includes('2026') },
	{ q: '¿Cuál es la tasa de paro actual en España?', ok: (r) => cifra(r, '9.87') && r.includes('2026') },
	{ q: '¿Cuántos habitantes tiene España?', ok: (r) => (cifra(r, '49.1') || /49[.,\s]?114/.test(r)) && r.includes('2025') },
	{
		q: '¿Cuál es la inflación interanual más reciente?',
		ok: (r) => (cifra(r, '4.9') && /septiembre|2026-09/.test(r)) || (cifra(r, '4.3') && /agosto|2026-08/.test(r))
	},
	// EPA (2T 2026) o la serie mensual de Eurostat (agosto de 2026): las dos son válidas
	{ q: '¿Cuál es la tasa de paro de los menores de 25 años ahora mismo?', ok: (r) => cifra(r, '23.77') || cifra(r, '23.8') || (cifra(r, '22.7') && /agosto|2026-08/.test(r)) },
	{ q: '¿Qué comunidad tenía más deuda sobre el PIB a finales de 2010?', ok: (r) => r.includes('valenciana') && cifra(r, '19.7') },
	// Nominal o en euros reales (el principio de la web): las dos son correctas
	{ q: '¿Cuál es la pensión media de jubilación más reciente?', ok: (r) => /1[.\s]?(576|550)/.test(r) && /2026/.test(r) },
	// Comunidad o provincia (4.089 nominal, 3.965 real) o el municipio de Madrid (5.318 real): la pregunta es ambigua
	{ q: '¿Cuánto cuesta el metro cuadrado de vivienda en Madrid?', ok: (r) => /4[.\s]?0(89|90)|3[.\s]?96[45]|5[.\s]?318/.test(r) && r.includes('2026') },
	{ q: '¿Cuántos habitantes tenía Andalucía en 2020?', ok: (r) => /8[.\s]?464[.\s]?411|8[.,]46/.test(r) },
	// Nominal (4,47 % en septiembre) o real, descontada la inflación (0,18 % en agosto)
	{ q: '¿Cuánto han subido las pensiones de jubilación en el último año?', ok: (r) => /4[.,](47|5)\b|4[.,]467|0[.,]18\b/.test(r) }
];
