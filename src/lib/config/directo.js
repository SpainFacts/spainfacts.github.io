// URL pública del Cloudflare Worker "spainfacts-ree-directo" (workers/ree-directo).
//
// Tras desplegarlo con `npx wrangler deploy`, pega aquí la URL que imprime wrangler
// (termina en .workers.dev) y haz commit. No es un secreto.
// Ejemplo: 'https://spainfacts-ree-directo.tu-subdominio.workers.dev'
//
// También se puede sobrescribir en el build con la variable de entorno
// VITE_REE_DIRECTO_URL (tiene prioridad sobre la constante).
//
// Si queda vacía, la página /energia-clima/directo usa solo los datos
// horneados en el build desde el pipeline (mother.electricidad_ultimas_24h).
const URL_WORKER = '';

let desdeEntorno = '';
try {
    desdeEntorno = import.meta.env?.VITE_REE_DIRECTO_URL || '';
} catch {
    desdeEntorno = '';
}

export const REE_DIRECTO_URL = (desdeEntorno || URL_WORKER).replace(/\/+$/, '');

/** Cada cuánto consulta la página al Worker (ms). El Worker cachea 5 min. */
export const REE_DIRECTO_INTERVALO_MS = 5 * 60 * 1000;
