// Genera build/sitemap.xml a partir de las páginas prerenderizadas (build/**/index.html),
// incluidas las rutas dinámicas de territorios. Se ejecuta tras `npm run build:strict`.
import { readdirSync, statSync, writeFileSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

const DOMINIO = 'https://spainfacts.org';
const BUILD = 'build';
const EXCLUIR = ['_app', 'api', 'data', 'indicadores'];  // /indicadores es una redirección

function paginas(dir) {
    const rutas = [];
    for (const nombre of readdirSync(dir)) {
        const ruta = join(dir, nombre);
        if (statSync(ruta).isDirectory()) {
            if (dir === BUILD && EXCLUIR.includes(nombre)) continue;
            rutas.push(...paginas(ruta));
        } else if (nombre === 'index.html') {
            const url = '/' + relative(BUILD, dir).split(sep).join('/');
            rutas.push(url === '/' ? '/' : url.replace(/\/$/, ''));
        }
    }
    return rutas;
}

const hoy = new Date().toISOString().slice(0, 10);
const urls = [...new Set(paginas(BUILD))].sort();
const xml = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    ...urls.map(u => `  <url><loc>${DOMINIO}${encodeURI(u === '/' ? '/' : u)}</loc><lastmod>${hoy}</lastmod></url>`),
    '</urlset>',
    '',
].join('\n');
writeFileSync(join(BUILD, 'sitemap.xml'), xml);
console.log(`sitemap.xml: ${urls.length} páginas`);
