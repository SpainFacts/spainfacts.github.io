#!/usr/bin/env node
// Servidor MCP de SpainFacts: deja consultar los datos de la web desde Claude Code,
// Claude Desktop u otro cliente MCP. Corre en el ordenador de quien lo usa: el modelo lo
// pone el cliente y las consultas las hace DuckDB en local, sin servidor nuestro.
//
//   cd tools/mcp && npm install
//   claude mcp add spainfacts -- node <ruta>/tools/mcp/servidor.mjs
//
// Por defecto descarga el catálogo y los parquets publicados en https://spainfacts.org
// (solo los que use, y se guardan en ~/.cache/spainfacts-mcp: las rutas llevan un hash
// del contenido, así que nunca se sirven datos viejos). Con --local usa los datos del
// repositorio (.evidence/template/static/data/mother y build/chat/catalogo.json).

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { DuckDBInstance } from '@duckdb/node-api';
import { crearIndice, ejecutarHerramienta, promptSistema, URL_WEB } from '../../src/lib/chat/herramientas.js';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const raizRepo = path.resolve(aqui, '..', '..');
const args = process.argv.slice(2);
const LOCAL = args.includes('--local');
const BASE = (process.env.SPAINFACTS_URL || URL_WEB).replace(/\/+$/, '');
const CACHE = process.env.SPAINFACTS_CACHE || path.join(os.homedir(), '.cache', 'spainfacts-mcp');
const DATOS_LOCAL = path.join(raizRepo, '.evidence', 'template', 'static', 'data', 'mother');
const CATALOGO_LOCAL = path.join(raizRepo, 'build', 'chat', 'catalogo.json');

// stdout es el canal MCP: los avisos van a stderr
const log = (...a) => console.error('[spainfacts-mcp]', ...a);
const barra = (p) => p.replace(/\\/g, '/');

// ---------- Catálogo y ubicación de los parquets ----------

async function descargarJSON(url) {
	const r = await fetch(url);
	if (!r.ok) throw new Error(`${url}: HTTP ${r.status}`);
	return r.json();
}

let catalogo;
/** nombre de tabla -> ruta remota relativa (data/mother/x/<hash>/x.parquet) */
const rutasRemotas = new Map();

if (LOCAL) {
	if (!fs.existsSync(CATALOGO_LOCAL)) {
		log(`Falta ${CATALOGO_LOCAL}. Genéralo con: node tools/chat/catalogo.mjs`);
		process.exit(1);
	}
	catalogo = JSON.parse(fs.readFileSync(CATALOGO_LOCAL, 'utf8'));
} else {
	catalogo = await descargarJSON(`${BASE}/chat/catalogo.json`);
	const manifest = await descargarJSON(`${BASE}/data/manifest.json`);
	for (const r of manifest.renderedFiles?.mother ?? []) {
		const rel = r.replace(/^static\//, '');
		rutasRemotas.set(path.posix.basename(rel, '.parquet'), rel);
	}
}
const indice = crearIndice(catalogo);
const directorioDatos = LOCAL ? DATOS_LOCAL : CACHE;
fs.mkdirSync(directorioDatos, { recursive: true });

/** Ruta local del parquet de una tabla (lo descarga si hace falta) */
async function parquetLocal(nombre) {
	if (LOCAL) {
		const p = path.join(DATOS_LOCAL, nombre, `${nombre}.parquet`);
		if (!fs.existsSync(p)) throw new Error(`No existe la tabla mother.${nombre}`);
		return p;
	}
	const rel = rutasRemotas.get(nombre);
	if (!rel) throw new Error(`No existe la tabla mother.${nombre}`);
	const destino = path.join(CACHE, ...rel.split('/'));
	if (!fs.existsSync(destino)) {
		const r = await fetch(`${BASE}/${rel}`);
		if (!r.ok) throw new Error(`No se pudo descargar mother.${nombre}: HTTP ${r.status}`);
		fs.mkdirSync(path.dirname(destino), { recursive: true });
		const tmp = destino + '.tmp';
		fs.writeFileSync(tmp, Buffer.from(await r.arrayBuffer()));
		fs.renameSync(tmp, destino);
	}
	return destino;
}

// ---------- DuckDB de solo lectura ----------

const instancia = await DuckDBInstance.create(':memory:');
const con = await instancia.connect();
await con.run('CREATE SCHEMA mother');
// Solo puede leer ficheros de la carpeta de datos: nada de rutas arbitrarias ni URLs
await con.run(`SET allowed_directories = ['${barra(directorioDatos).replace(/'/g, "''")}']`);
await con.run('SET enable_external_access = false');
await con.run('SET autoinstall_known_extensions = false');
await con.run('SET autoload_known_extensions = false');
await con.run('SET lock_configuration = true');

const vistas = new Map(); // nombre -> promesa de creación
function asegurarVista(nombre) {
	if (!vistas.has(nombre)) {
		const p = parquetLocal(nombre).then((f) =>
			con.run(`CREATE OR REPLACE VIEW mother."${nombre}" AS SELECT * FROM read_parquet('${barra(f).replace(/'/g, "''")}')`)
		);
		p.catch(() => vistas.delete(nombre));
		vistas.set(nombre, p);
	}
	return vistas.get(nombre);
}

async function consultar(sql) {
	const nombres = new Set([...sql.matchAll(/mother\s*\.\s*"?([a-z0-9_]+)"?/gi)].map((m) => m[1].toLowerCase()));
	await Promise.all([...nombres].map(asegurarVista));
	const lector = await con.runAndReadAll(sql);
	return lector.getRowObjectsJS();
}

const ctx = { catalogo, indice, consultar };

// ---------- Servidor MCP ----------

const servidor = new McpServer(
	{ name: 'spainfacts', version: '0.1.0' },
	{ instructions: promptSistema(catalogo, 'es', { graficos: false }) }
);

const comoTexto = async (nombre, entrada) => {
	const r = await ejecutarHerramienta(nombre, entrada, ctx);
	return { content: [{ type: 'text', text: r.resultado }] };
};
const soloLectura = { readOnlyHint: true, openWorldHint: false };

servidor.registerTool(
	'buscar_tablas',
	{
		title: 'Buscar tablas de SpainFacts',
		description:
			'Busca en el catálogo de SpainFacts (datos públicos oficiales de España) las tablas relacionadas con un tema. Devuelve nombre, descripción, columnas y páginas de la web. Úsala primero.',
		inputSchema: { texto: z.string().describe('Palabras clave del tema, en castellano (p. ej. "paro juvenil", "deuda comunidades")') },
		annotations: soloLectura
	},
	({ texto }) => comoTexto('buscar_tablas', { texto })
);

servidor.registerTool(
	'describir_tabla',
	{
		title: 'Ficha de una tabla',
		description:
			'Columnas con tipo y rango, valores posibles de las columnas de texto, filas de ejemplo y páginas de spainfacts.org que usan la tabla. Léela antes de escribir SQL.',
		inputSchema: { tabla: z.string().describe('Nombre de la tabla, p. ej. mother.ccaa_deuda') },
		annotations: soloLectura
	},
	({ tabla }) => comoTexto('describir_tabla', { tabla })
);

servidor.registerTool(
	'consultar_sql',
	{
		title: 'Consultar los datos con SQL',
		description:
			'Ejecuta una consulta SELECT de DuckDB sobre las tablas mother.<nombre> y devuelve hasta 60 filas. Filtra y agrega en SQL. Compara por habitante y en euros reales cuando se pueda.',
		inputSchema: { sql: z.string().describe('Una sola consulta SELECT de DuckDB sobre mother.<tabla>') },
		annotations: soloLectura
	},
	({ sql }) => comoTexto('consultar_sql', { sql })
);

await servidor.connect(new StdioServerTransport());
log(`listo: ${catalogo.tablas.length} tablas (${LOCAL ? 'datos locales' : BASE})`);
