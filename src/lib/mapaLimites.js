// Limita todos los mapas de Leaflet del sitio (AreaMap, BubbleMap... de Evidence):
// cuando el mapa se encuadra en sus datos (fitBounds), ese encuadre pasa a ser el
// zoom mínimo y el área máxima, así que no se puede alejar más de lo que muestra
// todo ni arrastrar el mapa lejos de los datos. Acercarse sigue permitido.
//
// Se registra como "init hook" de Leaflet antes de que Evidence cree sus mapas
// (se importa desde pages/+layout.svelte, a nivel de módulo).

const MARGEN = 0.15; // holgura alrededor de los datos al arrastrar (15 % del encuadre)

export function instalarLimitesMapas() {
    if (typeof window === 'undefined' || window.__limitesMapas) return;
    window.__limitesMapas = true;
    import('leaflet')
        .then((m) => {
            const L = m.default ?? m;
            L.Map.addInitHook(function () {
                const mapa = this;
                mapa.getContainer().__mapaLeaflet = mapa; // para depurar desde la consola
                const encuadrar = mapa.fitBounds.bind(mapa);
                mapa.fitBounds = function (limites, opciones) {
                    // Se quitan los límites previos para poder reencuadrar si cambian los datos
                    mapa.setMinZoom(0);
                    mapa.setMaxBounds(null);
                    const r = encuadrar(limites, opciones);
                    try {
                        const b = L.latLngBounds(limites);
                        if (b.isValid()) {
                            mapa.setMinZoom(mapa.getBoundsZoom(b, false));
                            mapa.options.maxBoundsViscosity = 1.0;
                            mapa.setMaxBounds(b.pad(MARGEN));
                        }
                    } catch {
                        /* si algo falla, el mapa sigue funcionando sin límites */
                    }
                    return r;
                };
            });
        })
        .catch(() => {});
}
