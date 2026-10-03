// Une plan-1..6.md en un solo PLAN-tablas.md ordenado por prioridad, con un índice.
//   node tools/chat/semantica/plan/unir.mjs

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const dir = path.dirname(fileURLToPath(import.meta.url));
// Las que los agentes proponen borrar (comprobado que ninguna página, componente ni pipeline las usa)
const BORRAR = new Set(['alcaldes_resumen_familias', 'ipc', 'observatorios', 'totalAno', 'totalAnoProvincia', 'totalAnoSexo', 'totalAnoSexoEdad', 'unemployment']);
const secciones = [];
for (const f of fs.readdirSync(dir).filter((x) => /^plan-\d+\.md$/.test(x)).sort()) {
	const texto = fs.readFileSync(path.join(dir, f), 'utf8').replace(/\r/g, '');
	for (const bloque of texto.split(/\n(?=### )/).filter((b) => b.startsWith('### '))) {
		const tabla = bloque.match(/^### `?([^`\n]+)`?/)[1].trim();
		const prioridad = bloque.match(/\*\*Prioridad:\*\*\s*\**\s*([123—-])/)?.[1]?.replace('-', '—') ?? '?';
		const esfuerzo = bloque.match(/\*\*Esfuerzo\/riesgo:\*\*\s*(bajo|medio|alto)/i)?.[1]?.toLowerCase() ?? '?';
		const problema = (bloque.match(/\*\*Problemas:\*\*\s*(.+)/)?.[1] ?? '').replace(/\|/g, '/').slice(0, 140);
		const borrar = BORRAR.has(tabla);
		secciones.push({ tabla, prioridad, esfuerzo, problema, borrar, bloque: bloque.trim() });
	}
}
const orden = { 1: 0, 2: 1, 3: 2, '—': 3, '?': 4 };
secciones.sort((a, b) => orden[a.prioridad] - orden[b.prioridad] || a.tabla.localeCompare(b.tabla));
const cuenta = (p) => secciones.filter((s) => s.prioridad === p).length;
const cabecera = fs.readFileSync(path.join(dir, 'cabecera.md'), 'utf8');
const indice = [
	'| Tabla | Prioridad | Esfuerzo | Problema |',
	'|---|---|---|---|',
	...secciones.map((s) => `| [${s.tabla}](#${s.tabla.toLowerCase()}) | ${s.prioridad}${s.borrar ? ' (borrar)' : ''} | ${s.esfuerzo} | ${s.problema} |`)
].join('\n');
const titulos = { 1: 'Prioridad 1: por habitante, euros reales o rompe el chat', 2: 'Prioridad 2: mejora clara', 3: 'Prioridad 3: cosmético', '—': 'Dejar como están' };
const cuerpo = ['1', '2', '3', '—']
	.map((p) => `## ${titulos[p]} (${cuenta(p)})\n\n${secciones.filter((s) => s.prioridad === p).map((s) => s.bloque).join('\n\n')}`)
	.join('\n\n');
const salida = `${cabecera.trim()}\n\n## Índice (${secciones.length} tablas: ${cuenta('1')} de prioridad 1, ${cuenta('2')} de 2, ${cuenta('3')} de 3, ${cuenta('—')} sin cambios)\n\n${indice}\n\n${cuerpo}\n`;
fs.writeFileSync(path.join(dir, '..', 'PLAN-tablas.md'), salida);
console.log(`${secciones.length} tablas -> PLAN-tablas.md · P1 ${cuenta('1')} · P2 ${cuenta('2')} · P3 ${cuenta('3')} · — ${cuenta('—')} · ? ${cuenta('?')} · borrar ${secciones.filter((s) => s.borrar).map((s) => s.tabla).join(', ')}`);
