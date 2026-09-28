// Prueba del handler HTTP (CORS, rutas, caché) con Node, simulando `caches.default` y `ctx`.
const almacen = new Map();
globalThis.caches = { default: { match: async (r) => almacen.get(r.url)?.clone(), put: async (r, resp) => void almacen.set(r.url, resp) } };
const { default: worker } = await import('../src/index.js');
const ctx = { waitUntil: (p) => p };
const pedir = (ruta, origen, method = 'GET') =>
    worker.fetch(new Request('https://spainfacts-ree-directo.ejemplo.workers.dev' + ruta, { method, headers: origen ? { Origin: origen } : {} }), {}, ctx);

let r = await pedir('/snapshot', 'https://spainfacts.org');
console.log('GET /snapshot (spainfacts.org):', r.status, r.headers.get('access-control-allow-origin'), r.headers.get('cache-control'), (await r.text()).length, 'bytes');
r = await pedir('/snapshot', 'https://evil.example');
console.log('GET /snapshot (otro origen):', r.status, 'ACAO =', r.headers.get('access-control-allow-origin'), '(desde caché:', almacen.size === 1, ')');
r = await pedir('/snapshot', 'http://localhost:3300', 'OPTIONS');
console.log('OPTIONS preflight localhost:3300:', r.status, r.headers.get('access-control-allow-origin'));
r = await pedir('/nada');
console.log('GET /nada:', r.status);
r = await pedir('/salud');
console.log('GET /salud:', r.status, await r.text());
