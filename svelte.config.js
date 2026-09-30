// Configuración de SvelteKit que Evidence fusiona con la suya (.evidence/template/svelte.config.js).
// Solo actúa en los builds parciales (tools/build-parcial.mjs pone BUILD_PARCIAL=1): allí
// faltan a propósito casi todas las páginas, así que los enlaces del menú a ellas dan 404
// al prerenderizar y eso no debe parar el build. En el build normal no cambia nada.
const parcial = process.env.BUILD_PARCIAL === '1';

export default parcial
	? {
			kit: {
				prerender: {
					handleHttpError: 'warn',
					handleMissingId: 'warn'
				}
			}
		}
	: {};
