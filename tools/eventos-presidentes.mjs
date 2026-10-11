// Genera el módulo de presidentes autonómicos que usan las líneas de eventos de las gráficas
// (patch de @evidence-dev/core-components, ui/eventos.js) a partir del seed
// transform/seeds/presidentes_autonomicos.csv.
//
//   node tools/eventos-presidentes.mjs
//   npx patch-package @evidence-dev/core-components     (para guardar el cambio en patches/)
//
// Una gráfica de una sola comunidad pide sus presidentes con echartsOptions={{ eventos: { ccaa: '13' } }}.
// Los mandatos interinos (en funciones) no se dibujan, salvo la intervención del artículo 155.
import fs from 'node:fs';

const SEED = 'transform/seeds/presidentes_autonomicos.csv';
const DESTINO = 'node_modules/@evidence-dev/core-components/dist/unsorted/ui/presidentes_autonomicos.js';

// CSV sencillo con comillas dobles
function leerCsv(texto) {
	const filas = [];
	let fila = [], campo = '', comillas = false;
	for (let i = 0; i < texto.length; i++) {
		const c = texto[i];
		if (comillas) {
			if (c === '"' && texto[i + 1] === '"') { campo += '"'; i++; }
			else if (c === '"') comillas = false;
			else campo += c;
		} else if (c === '"') comillas = true;
		else if (c === ',') { fila.push(campo); campo = ''; }
		else if (c === '\n' || c === '\r') {
			if (c === '\r' && texto[i + 1] === '\n') i++;
			fila.push(campo); campo = '';
			if (fila.some((x) => x !== '')) filas.push(fila);
			fila = [];
		} else campo += c;
	}
	if (campo !== '' || fila.length) { fila.push(campo); filas.push(fila); }
	const [cab, ...resto] = filas;
	return resto.map((f) => Object.fromEntries(cab.map((k, i) => [k.trim(), (f[i] ?? '').trim()])));
}

const filas = leerCsv(fs.readFileSync(SEED, 'utf8'));
const porCcaa = {};
for (const f of filas) {
	const interino = /^(true|1|s[ií])$/i.test(f.interino ?? '');
	if (interino && !/155/.test(f.presidente)) continue;
	(porCcaa[f.cod_ccaa] ??= []).push({ desde: f.desde, etiqueta: /155/.test(f.presidente) ? 'Art. 155' : f.etiqueta, partido: f.partido });
}
for (const lista of Object.values(porCcaa)) lista.sort((a, b) => a.desde.localeCompare(b.desde));

const js = `// SpainFacts: presidentes autonómicos (toma de posesión) para las líneas de eventos de las gráficas.
// GENERADO por tools/eventos-presidentes.mjs desde transform/seeds/presidentes_autonomicos.csv: no editar a mano.
export const PRESIDENTES_AUTONOMICOS = ${JSON.stringify(porCcaa, null, '\t')};
`;
fs.writeFileSync(DESTINO, js);
console.log(`${DESTINO}: ${Object.keys(porCcaa).length} comunidades, ${Object.values(porCcaa).flat().length} mandatos`);
