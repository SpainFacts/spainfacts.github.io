# Pruebas automáticas

Hay tres niveles de pruebas. En GitHub se ejecutan las tres en cada despliegue, **antes** de
publicar: si alguna falla, la web publicada se queda como estaba.

| Prueba | Qué comprueba | Comando |
|---|---|---|
| Traducciones | Cada página en `pages/en|ca|gl|eu` tiene las mismas consultas SQL, componentes e imports que la original, sin enlaces internos sin prefijo ni anclas rotas; y avisa de las traducciones desfasadas | `npm run test:i18n` |
| Estática | En `build/`: `lang` de cada página según su carpeta, `<title>`, enlaces internos que apuntan a páginas que no existen, «undefined»/«NaN» en el HTML prerenderizado | `npm run test:estatico` |
| Humo | Abre ~150 páginas (todas las secciones, los 5 idiomas, páginas dinámicas y casos que ya se rompieron) en Chromium y falla si hay errores de JavaScript, cuadros de error de Evidence, «undefined»/«NaN» visibles, «Loading...» que no termina o gráficas sin pintar | `npm run test:humo` |

`npm test` las ejecuta todas (necesita un `build/` completo).

Además, `.github/workflows/pruebas-publicada.yml` revisa cada día **la web publicada**
(`npm run test:publicada`): los datos cambian solos con Dagster y una página puede romperse
sin tocar el código. Si falla, GitHub avisa por correo.

## Mientras se trabaja

Lo más rápido es compilar solo lo que se está tocando y probarlo:

```bash
npm run build:parcial -- territorios/municipios --idiomas en --probar
```

La prueba de humo también acepta páginas sueltas, otra carpeta compilada o la web publicada:

```bash
node tools/pruebas/humo.mjs --solo territorios/municipios/?m=41091 --solo varios/mapas/
node tools/pruebas/humo.mjs --base https://spainfacts.org --solo territorios/
node tools/pruebas/humo.mjs --servir     # solo sirve build/ (con rangos, como GitHub Pages) para mirarlo
```

El servidor de la prueba admite peticiones por rangos como GitHub Pages; algunos fallos solo
aparecen así (DuckDB lee trozos de los parquet).

## Añadir un caso

Cuando algo se rompa, añade la página afectada a `ESPECIALES` en `tools/pruebas/humo.mjs` con lo
que debería verse (`h1`, `h2` o un `texto`). Así no vuelve a pasar sin que la prueba lo detecte.

## Lo que se aprendió

- **Municipios con `?m=` (2026-10-01):** la página mostraba «undefined» unos 25 s en la web
  publicada. Evidence creaba en el navegador una vista por cada una de las ~200 tablas, una tras
  otra, leyendo la cabecera de cada parquet por red. El parche
  `patches/@evidence-dev+universal-sql+2.2.10.patch` crea cada vista solo cuando una consulta la
  usa (de 463 a ~60 peticiones). En local no se notaba porque la latencia es casi cero.
