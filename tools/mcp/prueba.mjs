// Prueba del servidor MCP: lo arranca como lo haría Claude Code y llama a las herramientas.
//   node tools/mcp/prueba.mjs [--local]
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const transporte = new StdioClientTransport({
	command: process.execPath,
	args: [path.join(aqui, 'servidor.mjs'), ...process.argv.slice(2)],
	stderr: 'inherit'
});
const cliente = new Client({ name: 'prueba', version: '0.0.0' });
await cliente.connect(transporte);

const texto = (r) => r.content.map((c) => c.text).join('');
let fallos = 0;
async function caso(nombre, herramienta, args, comprobar) {
	const r = texto(await cliente.callTool({ name: herramienta, arguments: args }));
	const ok = comprobar(r);
	if (!ok) fallos++;
	console.log(`${ok ? 'OK ' : 'MAL'} ${nombre}: ${r.slice(0, 160).replace(/\n/g, ' ')}`);
}

const herramientas = (await cliente.listTools()).tools.map((t) => t.name);
console.log('Herramientas:', herramientas.join(', '));
console.log('Instrucciones:', (cliente.getInstructions() ?? '').slice(0, 80), '...');

await caso('buscar deuda', 'buscar_tablas', { texto: 'deuda de las comunidades autónomas' }, (r) => r.includes('ccaa_deuda'));
await caso('buscar paro juvenil', 'buscar_tablas', { texto: 'paro juvenil' }, (r) => r.includes('paro'));
await caso('describir', 'describir_tabla', { tabla: 'mother.ccaa_deuda' }, (r) => r.includes('"columnas"'));
await caso('tabla inexistente', 'describir_tabla', { tabla: 'mother.no_existe' }, (r) => r.includes('error'));
await caso('consulta', 'consultar_sql', { sql: 'SELECT count(*) AS n FROM mother.ccaa_deuda' }, (r) => /"n":\s*\d/.test(r));
await caso('bloquea escritura', 'consultar_sql', { sql: 'DROP TABLE mother.ccaa_deuda' }, (r) => r.includes('error'));
await caso('bloquea ficheros', 'consultar_sql', { sql: "SELECT * FROM read_csv('/etc/passwd')" }, (r) => r.includes('error'));
await caso('bloquea ruta directa', 'consultar_sql', { sql: "SELECT * FROM 'C:/Windows/win.ini'" }, (r) => r.includes('error'));
await caso('bloquea dos órdenes', 'consultar_sql', { sql: 'SELECT 1; SELECT 2' }, (r) => r.includes('error'));

await cliente.close();
console.log(fallos ? `${fallos} fallos` : 'Todo bien');
process.exit(fallos ? 1 : 0);
