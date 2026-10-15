import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { importarDelRepo } from '../raiz.mjs';
import { crearClasificador } from '../clasificador.mjs';
const { crearEmbebedor } = await importarDelRepo('src/lib/chat/locales.js');
const aqui = path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Z]:)/, '$1'));
const clas = crearClasificador(JSON.parse(fs.readFileSync(path.join(aqui, '../clasificador.json'), 'utf8')));
const e = await crearEmbebedor({ modelo: 'onnx-community/embeddinggemma-300m-ONNX', dtype: 'q4', archivo: 'model_no_gather', dims: 256, cacheDir: path.join(os.homedir(), '.cache', 'tjs') });
for (const q of ['¿Cuántos parados hay en Andalucía?', '¿Cuánto cuesta alquilar un piso en Madrid?', '¿Cuántas hectáreas se quemaron en 2022?'])
	console.log(q, '->', clas.mejores(await e(`task: search result | query: ${q}`), 3).map((x) => x.tabla).join(', '));
