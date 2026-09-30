// Fija el idioma de cada página prerenderizada (build/**/*.html): lang="es" en la raíz
// y lang="en" | "ca" | "gl" | "eu" bajo build/en/, build/ca/, build/gl/ y build/eu/.
// La plantilla de Evidence (.evidence/template/src/app.html) trae <html lang="en"> y se
// regenera en cada build, así que se corrige aquí. Se ejecuta tras `npm run build:strict`.
import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const BUILD = 'build';
const PREFIJOS = ['en', 'ca', 'gl', 'eu'];
let cambiadas = 0;

function recorrer(dir, lang) {
    for (const nombre of readdirSync(dir)) {
        const ruta = join(dir, nombre);
        if (statSync(ruta).isDirectory()) {
            if (nombre === '_app') continue;
            // la carpeta de primer nivel /en, /ca... fija el idioma de todo lo que cuelga
            recorrer(ruta, dir === BUILD && PREFIJOS.includes(nombre) ? nombre : lang);
        } else if (nombre.endsWith('.html')) {
            const html = readFileSync(ruta, 'utf8');
            const nuevo = html.replace(/<html lang="[a-z-]+"/, `<html lang="${lang}"`);
            if (nuevo !== html) {
                writeFileSync(ruta, nuevo);
                cambiadas++;
            }
        }
    }
}

recorrer(BUILD, 'es');
console.log(`lang: ${cambiadas} páginas corregidas`);
