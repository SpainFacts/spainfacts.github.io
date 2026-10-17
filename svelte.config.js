// Configuración de SvelteKit que Evidence fusiona con la suya (.evidence/template/svelte.config.js).
//
// prerender.concurrency: SvelteKit prerenderiza de una en una por defecto y con ~1.800 páginas
// (5 idiomas) eso eran ~28 min del deploy. PRERENDER_CONCURRENCIA lo cambia sin tocar el código.
//
// En los builds parciales (tools/build-parcial.mjs pone BUILD_PARCIAL=1) faltan a propósito
// casi todas las páginas, así que los enlaces del menú a ellas dan 404 al prerenderizar y eso
// no debe parar el build.
const parcial = process.env.BUILD_PARCIAL === '1';
const concurrency = Number(process.env.PRERENDER_CONCURRENCIA ?? 4);

export default {
	kit: {
		prerender: {
			concurrency,
			...(parcial ? { handleHttpError: 'warn', handleMissingId: 'warn' } : {})
		}
	}
};
