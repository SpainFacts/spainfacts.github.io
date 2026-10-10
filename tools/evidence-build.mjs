import { spawn, spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const heapLimitMb = Number(process.env.EVIDENCE_BUILD_HEAP_MB ?? 12288);
if (!Number.isSafeInteger(heapLimitMb) || heapLimitMb < 4096 || heapLimitMb > 32768) {
	throw new Error('EVIDENCE_BUILD_HEAP_MB debe ser un entero entre 4096 y 32768.');
}

const nodeOptions = (process.env.NODE_OPTIONS ?? '')
	.replace(/(^|\s)--max-old-space-size(?:=\d+|\s+\d+)(?=\s|$)/g, ' ')
	.trim();
const env = {
	...process.env,
	NODE_OPTIONS: [nodeOptions, `--max-old-space-size=${heapLimitMb}`].filter(Boolean).join(' ')
};
const cli = fileURLToPath(new URL('../node_modules/@evidence-dev/evidence/cli.js', import.meta.url));
const child = spawn(process.execPath, [cli, ...process.argv.slice(2)], { stdio: 'inherit', env });

console.log(`Build de Evidence con heap de hasta ${heapLimitMb} MB.`);
child.on('error', (error) => {
	console.error(`No se pudo iniciar Evidence: ${error.message}`);
	process.exitCode = 1;
});
child.on('exit', (code, signal) => {
	process.exitCode = code ?? (signal === 'SIGINT' ? 130 : signal === 'SIGTERM' ? 143 : 1);
	// La plantilla de Evidence prerenderiza <html lang="en">: se corrige al terminar
	// para que el build local coincida con el de producción (deploy.yml también lo ejecuta).
	if (code === 0) {
		const lang = spawnSync(process.execPath, [fileURLToPath(new URL('./html-lang-es.mjs', import.meta.url))], { stdio: 'inherit' });
		if (lang.status !== 0) process.exitCode = lang.status ?? 1;
	}
});
