import os from 'node:os';
import path from 'node:path';
import { crearDecisorONNX } from '../decisor-onnx.mjs';
const [modelo, dtype] = process.argv.slice(2);
const t0 = Date.now();
const d = await crearDecisorONNX({ modelo, dtype: dtype?.startsWith('{') ? JSON.parse(dtype) : (dtype ?? 'q4'), cacheDir: path.join(os.homedir(), '.cache', 'tjs') });
console.log('cargado', (Date.now() - t0) / 1000, 's');
for (let i = 0; i < 3; i++) {
	const t1 = Date.now();
	const r = await d('Pregunta del usuario: ¿cuántos parados hay en España?', 'Which data table answers the user question?', ['turismo_anual: turistas que llegan', 'mercado_paro_registrado: paro registrado en el SEPE', 'pensiones_mensual: pensiones']);
	console.log(JSON.stringify(r), (Date.now() - t1) + ' ms');
}
