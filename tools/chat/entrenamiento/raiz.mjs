// Dónde están el código del chat, el catálogo y los parquets que usan los scripts de
// entrenamiento. Por defecto, la carpeta desde la que se lanzan (la raíz del repo); con
// SPAINFACTS_RAIZ, otra copia del repo (p. ej. la principal desde un worktree sin datos).

import path from 'node:path';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';

export const RAIZ = path.resolve(process.env.SPAINFACTS_RAIZ ?? process.cwd());
export const AQUI = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, '$1'));
const requerir = createRequire(path.join(RAIZ, 'package.json'));

/** Módulo del repo (ruta relativa a la raíz) */
export const importarDelRepo = (rel) => import(pathToFileURL(path.join(RAIZ, rel)).href);
/** Paquete de node_modules de la raíz */
export const importarPaquete = (nombre) => import(pathToFileURL(requerir.resolve(nombre)).href);
// SPAINFACTS_PARQUETS: otra carpeta de parquets (p. ej. data/parquets-integracion, con mother/<tabla>/<tabla>.parquet)
const DIR_PARQUETS = process.env.SPAINFACTS_PARQUETS
	? path.resolve(RAIZ, process.env.SPAINFACTS_PARQUETS)
	: path.join(RAIZ, '.evidence/template/static/data');
export const rutaParquet = (tabla) => path.join(DIR_PARQUETS, 'mother', tabla, `${tabla}.parquet`).replace(/\\/g, '/');
