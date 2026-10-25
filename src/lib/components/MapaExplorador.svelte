<script>
    // Mapa de toda España por municipio o por sección censal (barrio) con MapLibre y teselas
    // vectoriales propias (static-extra/geo/espana.pmtiles, ver tools/geo/teselas_mapas.sh).
    // Las teselas solo traen la geometría y el código; el color de cada territorio se pone con
    // feature-state a partir de `data`, así sirve para cualquier indicador.
    //
    // - nivel 'municipio': `data` con todas los años; barra de años con reproducción (evolución).
    // - nivel 'seccion': `data` con geo_anio (versión del seccionado de cada fila); al alejarse se
    //   pintan los municipios con `datosMunicipio` (si los hay) y al acercarse, las secciones.
    // - Escala: toda España (todos los años, para comparar en la animación) o lo que se ve.
    // - Buscador de municipios (lista propia) y de direcciones (Nominatim, OpenStreetMap).
    // - Destacados: los tres mejores y los tres peores; la vista y el año van en el enlace (#).
    // Callejero gris del IGN solo desde el zoom 7 (sin mapa base de otros países).
    import { onMount, onDestroy } from 'svelte';
    import { page } from '$app/stores';
    import { fmt } from '@evidence-dev/component-utilities/formatting';
    import { idiomaDeRuta } from '../i18n.js';
    import { calcularEscala, colorEn } from '../escalaMapa.js';
    import LeyendaMapa from './LeyendaMapa.svelte';
    import RayadoMapa from './RayadoMapa.svelte';

    export let data = [];
    export let nivel = 'municipio';
    export let datosMunicipio = [];
    export let colorPalette = ['#dbeafe', '#60a5fa', '#1e3a8a'];
    export let valueFmt = '#,##0.0';
    export let unidad = '';
    export let sentido = 'neutro';
    export let teselas = '/geo/espana.pmtiles';
    export let height = 580;
    export let title = undefined;

    $: lang = idiomaDeRuta($page.url.pathname);
    const TXT = {
        es: { buscar: 'Busca un municipio o una dirección', anio: 'Año', play: 'Reproducir la evolución', pausa: 'Pausar', acercate: 'Acércate a una ciudad para ver los barrios', mejores: 'Más altos', peores: 'Más bajos', mejor: 'Mejores', peor: 'Peores', puesto: 'Puesto', sin: 'Sin datos', ir: 'Ir a', peninsula: 'Península', canarias: 'Canarias', direccion: 'Buscar la dirección', nada: 'Sin resultados', cargando: 'Cargando el mapa…', error: 'No se pudo cargar el mapa', ctrl: 'Usa Ctrl + rueda para ampliar el mapa', mac: 'Usa ⌘ + rueda para ampliar el mapa', movil: 'Usa dos dedos para mover el mapa', de: 'de', empate: 'más con el mismo valor' },
        en: { buscar: 'Search for a municipality or an address', anio: 'Year', play: 'Play the evolution', pausa: 'Pause', acercate: 'Zoom into a city to see the neighbourhoods', mejores: 'Highest', peores: 'Lowest', mejor: 'Best', peor: 'Worst', puesto: 'Rank', sin: 'No data', ir: 'Go to', peninsula: 'Mainland', canarias: 'Canary Islands', direccion: 'Search the address', nada: 'No results', cargando: 'Loading the map…', error: 'The map could not be loaded', ctrl: 'Use Ctrl + scroll to zoom the map', mac: 'Use ⌘ + scroll to zoom the map', movil: 'Use two fingers to move the map', de: 'of', empate: 'more with the same value' },
        ca: { buscar: 'Cerca un municipi o una adreça', anio: 'Any', play: "Reprodueix l'evolució", pausa: 'Pausa', acercate: 'Apropa’t a una ciutat per veure els barris', mejores: 'Més alts', peores: 'Més baixos', mejor: 'Millors', peor: 'Pitjors', puesto: 'Posició', sin: 'Sense dades', ir: 'Ves a', peninsula: 'Península', canarias: 'Canàries', direccion: "Cerca l'adreça", nada: 'Sense resultats', cargando: 'Carregant el mapa…', error: "No s'ha pogut carregar el mapa", ctrl: 'Fes servir Ctrl + roda per ampliar el mapa', mac: 'Fes servir ⌘ + roda per ampliar el mapa', movil: 'Fes servir dos dits per moure el mapa', de: 'de', empate: 'més amb el mateix valor' },
        gl: { buscar: 'Busca un concello ou un enderezo', anio: 'Ano', play: 'Reproducir a evolución', pausa: 'Pausar', acercate: 'Achégate a unha cidade para ver os barrios', mejores: 'Máis altos', peores: 'Máis baixos', mejor: 'Mellores', peor: 'Peores', puesto: 'Posto', sin: 'Sen datos', ir: 'Ir a', peninsula: 'Península', canarias: 'Canarias', direccion: 'Buscar o enderezo', nada: 'Sen resultados', cargando: 'Cargando o mapa…', error: 'Non se puido cargar o mapa', ctrl: 'Usa Ctrl + roda para ampliar o mapa', mac: 'Usa ⌘ + roda para ampliar o mapa', movil: 'Usa dous dedos para mover o mapa', de: 'de', empate: 'máis co mesmo valor' },
        eu: { buscar: 'Bilatu udalerri bat edo helbide bat', anio: 'Urtea', play: 'Bilakaera erreproduzitu', pausa: 'Pausatu', acercate: 'Hurbildu hiri batera auzoak ikusteko', mejores: 'Altuenak', peores: 'Baxuenak', mejor: 'Onenak', peor: 'Txarrenak', puesto: 'Postua', sin: 'Daturik ez', ir: 'Joan', peninsula: 'Penintsula', canarias: 'Kanariak', direccion: 'Helbidea bilatu', nada: 'Emaitzarik ez', cargando: 'Mapa kargatzen…', error: 'Ezin izan da mapa kargatu', ctrl: 'Erabili Ktrl + gurpila mapa handitzeko', mac: 'Erabili ⌘ + gurpila mapa handitzeko', movil: 'Erabili bi hatz mapa mugitzeko', de: '/', empate: 'gehiago balio berarekin' }
    };
    $: tx = TXT[lang] ?? TXT.es;

    // ------------------------------------------------------------------ datos
    const ok = (v) => v !== null && v !== undefined && v !== '' && Number.isFinite(Number(v));
    $: esSeccion = nivel === 'seccion';
    $: filas = Array.from(data ?? []).filter((r) => r && ok(r.valor) && r.cod);
    $: anios = esSeccion ? [] : [...new Set(filas.map((r) => Number(r.anio)))].filter(Number.isFinite).sort((a, b) => a - b);
    let anio = null;
    // al cambiar de indicador: el año del enlace si existe, si no el último
    let clave = '';
    $: {
        const k = `${nivel}|${filas.length}|${anios[0]}|${anios[anios.length - 1]}|${filas[0]?.cod}`;
        if (k !== clave) {
            clave = k;
            parar();
            const pedido = Number(leerHash().a);
            anio = anios.includes(pedido) ? pedido : anios[anios.length - 1] ?? null;
        }
    }
    $: actuales = esSeccion ? filas : filas.filter((r) => Number(r.anio) === anio);
    $: porCod = new Map(actuales.map((r) => [String(r.cod), r]));
    $: filasMun = Array.from(datosMunicipio ?? []).filter((r) => r && ok(r.valor));
    $: munPorCod = new Map(filasMun.map((r) => [String(r.cod), r]));
    // en secciones, la versión del seccionado que se dibuja en cada municipio
    $: versiones = esSeccion ? [...new Set(filas.map((r) => `${String(r.cod).slice(0, 5)}-${r.geo_anio}`))] : [];
    $: munConSecciones = esSeccion ? new Set(filas.map((r) => String(r.cod).slice(0, 5))) : new Set();

    // puesto de cada territorio (1 = el mejor; en indicadores neutros, el más alto)
    $: puestos = (() => {
        const orden = [...actuales].sort((a, b) => (sentido === 'negativo' ? a.valor - b.valor : b.valor - a.valor));
        return new Map(orden.map((r, i) => [String(r.cod), i + 1]));
    })();
    $: destacados = (() => {
        const orden = [...actuales].sort((a, b) => (sentido === 'negativo' ? a.valor - b.valor : b.valor - a.valor));
        // empates en los extremos (p. ej. las secciones agrupadas en el tope del ADRH)
        const empates = (v) => orden.filter((r) => r.valor === v).length;
        return {
            arriba: orden.slice(0, 3),
            abajo: orden.slice(-3).reverse(),
            empatesArriba: orden.length ? Math.max(0, empates(orden[0].valor) - 3) : 0,
            empatesAbajo: orden.length ? Math.max(0, empates(orden[orden.length - 1].valor) - 3) : 0
        };
    })();

    // ------------------------------------------------------------------ escala
    $: paleta = (colorPalette ?? []).filter(Boolean);
    let modoEscala = 'ref';
    let numerosVista = null;
    // España: todos los años juntos (los colores se comparan en la animación), sin los años en que
    // casi todo vale 0 (p. ej. un partido antes de presentarse), que aplastarían la escala
    $: numerosEspana = (() => {
        const porAnio = new Map();
        for (const r of filas) {
            const k = esSeccion ? 0 : Number(r.anio);
            if (!porAnio.has(k)) porAnio.set(k, []);
            porAnio.get(k).push(Number(r.valor));
        }
        const utiles = [...porAnio.values()].filter((v) => v.filter((x) => x === 0).length < 0.9 * v.length);
        return (utiles.length ? utiles : [...porAnio.values()]).flat();
    })();
    $: escala = calcularEscala({ numeros: modoEscala === 'local' && numerosVista?.length ? numerosVista : numerosEspana, paleta });
    $: escalaMun = filasMun.length ? calcularEscala({ numeros: filasMun.map((r) => Number(r.valor)), paleta }) : null;
    const modosEscala = [{ id: 'ref', nombre: 'espana' }, { id: 'local', nombre: 'vista' }];
    let marca = null;

    const formatear = (v) => {
        if (!ok(v)) return '—';
        try { return fmt(Number(v), valueFmt); } catch (e) { return Number(v).toLocaleString(lang === 'en' ? 'en-GB' : 'es-ES', { maximumFractionDigits: 1 }); }
    };

    // ------------------------------------------------------------------ enlace (#v=zoom/lat/lon&a=año)
    function leerHash() {
        if (typeof window === 'undefined') return {};
        return Object.fromEntries(new URLSearchParams(window.location.hash.replace(/^#/, '')));
    }
    function escribirHash(cambios) {
        if (typeof window === 'undefined') return;
        const h = { ...leerHash(), ...cambios };
        for (const k of Object.keys(h)) if (h[k] === null || h[k] === undefined || h[k] === '') delete h[k];
        const url = new URL(window.location.href);
        url.hash = new URLSearchParams(h).toString();
        window.history.replaceState(window.history.state, '', url);
    }
    $: if (anio !== null && !esSeccion) escribirHash({ a: anio });

    // ------------------------------------------------------------------ evolución
    let reproduciendo = false;
    let temporizador = null;
    function parar() {
        reproduciendo = false;
        if (temporizador) clearInterval(temporizador);
        temporizador = null;
    }
    function reproducir() {
        if (reproduciendo) return parar();
        if (anios.length < 2) return;
        if (anio === anios[anios.length - 1]) anio = anios[0];
        reproduciendo = true;
        temporizador = setInterval(() => {
            const i = anios.indexOf(anio);
            if (i < 0 || i >= anios.length - 1) return parar();
            anio = anios[i + 1];
        }, 1100);
    }

    // ------------------------------------------------------------------ MapLibre
    let caja;
    let maplibregl = null;
    let mapa = null;
    let listo = false;
    let fallo = false;
    let zoom = 5;
    let oscuro = false;
    let observador = null;
    const IGN = 'https://www.ign.es/wmts/ign-base?layer=IGNBase-gris&style=default&tilematrixset=GoogleMapsCompatible&Service=WMTS&Request=GetTile&Version=1.0.0&Format=image/jpeg&TileMatrix={z}&TileCol={x}&TileRow={y}';
    const PENINSULA = [[-9.6, 35.7], [4.5, 43.9]];
    const CANARIAS = [[-18.3, 27.5], [-13.3, 29.5]];

    function rellenoPaint(zMin, zMax, opMin, opMax) {
        const op = (o) => ['case', ['boolean', ['feature-state', 'd'], false], o, 0];
        return {
            'fill-color': ['coalesce', ['feature-state', 'c'], '#9ca3af'],
            'fill-opacity': ['interpolate', ['linear'], ['zoom'], zMin, op(opMin), zMax, op(opMax)]
        };
    }
    function estilo() {
        const url = `pmtiles://${new URL(teselas, window.location.origin).href}`;
        const capas = [
            { id: 'fondo', type: 'background', paint: { 'background-color': oscuro ? '#0b1220' : '#eef1f5' } },
            {
                id: 'ign', type: 'raster', source: 'ign', minzoom: 7,
                paint: { 'raster-opacity': ['interpolate', ['linear'], ['zoom'], 7, 0, 8.5, 1], ...pinturaIgn(oscuro) }
            },
            // municipios (en el nivel de secciones, solo al alejarse)
            {
                id: 'mun-rayado', type: 'fill', source: 't', 'source-layer': 'municipios', maxzoom: esSeccion ? 11 : 24,
                paint: { 'fill-pattern': 'rayado', 'fill-opacity': rayadoMun(filasMun.length > 0) }
            },
            {
                id: 'mun-relleno', type: 'fill', source: 't', 'source-layer': 'municipios', maxzoom: esSeccion ? 11 : 24,
                paint: esSeccion ? rellenoPaint(9.5, 10.5, 0.85, 0) : rellenoPaint(7, 11, 0.9, 0.6)
            },
            {
                id: 'mun-borde', type: 'line', source: 't', 'source-layer': 'municipios',
                paint: {
                    'line-color': oscuro ? '#0b1220' : '#ffffff',
                    'line-width': ['interpolate', ['linear'], ['zoom'], 5, 0.1, 8, 0.4, 12, 1.2],
                    'line-opacity': esSeccion ? ['interpolate', ['linear'], ['zoom'], 9.5, 0.7, 10.5, 0.25] : 0.7
                }
            }
        ];
        if (esSeccion)
            capas.push(
                {
                    id: 'secc-rayado', type: 'fill', source: 't', 'source-layer': 'secciones', minzoom: 9, filter: filtroVersiones(),
                    paint: { 'fill-pattern': 'rayado', 'fill-opacity': ['interpolate', ['linear'], ['zoom'], 9.5, 0, 10.5, ['case', ['boolean', ['feature-state', 'd'], false], 0, 0.55]] }
                },
                { id: 'secc-relleno', type: 'fill', source: 't', 'source-layer': 'secciones', minzoom: 9, filter: filtroVersiones(), paint: rellenoPaint(9.5, 10.5, 0, 0.72) },
                {
                    id: 'secc-borde', type: 'line', source: 't', 'source-layer': 'secciones', minzoom: 9, filter: filtroVersiones(),
                    paint: { 'line-color': '#ffffff', 'line-width': ['interpolate', ['linear'], ['zoom'], 10, 0.2, 14, 0.9], 'line-opacity': ['interpolate', ['linear'], ['zoom'], 9.5, 0, 10.5, 0.6] }
                }
            );
        // contorno del territorio bajo el ratón: halo oscuro + línea blanca
        for (const [capa, fuente, filtro] of [['mun', 'municipios', null], ...(esSeccion ? [['secc', 'secciones', filtroVersiones()]] : [])]) {
            const base = { source: 't', 'source-layer': fuente, ...(filtro ? { filter: filtro } : {}) };
            capas.push(
                { id: `${capa}-halo`, type: 'line', ...base, paint: { 'line-color': 'rgba(0,0,0,0.55)', 'line-blur': 2, 'line-width': ['case', ['boolean', ['feature-state', 'h'], false], 6, 0] } },
                { id: `${capa}-activo`, type: 'line', ...base, paint: { 'line-color': '#ffffff', 'line-width': ['case', ['boolean', ['feature-state', 'h'], false], 2.5, 0] } }
            );
        }
        return {
            version: 8,
            sources: {
                ign: { type: 'raster', tiles: [IGN], tileSize: 256, maxzoom: 19, attribution: '© <a href="https://www.ign.es" target="_blank" rel="noopener">IGN</a>' },
                t: { type: 'vector', url, promoteId: { municipios: 'cod', secciones: 'cod' }, attribution: 'Límites: IGN · INE' }
            },
            layers: capas
        };
    }
    // rayado de los municipios sin dato. En barrios: de lejos, solo si hay indicador municipal
    // con el que colorearlos; de cerca, los municipios sin secciones con dato
    function rayadoMun(hayMun) {
        const sin = (estado) => ['case', ['boolean', ['feature-state', estado], false], 0, 0.55];
        if (!esSeccion) return sin('d');
        return ['interpolate', ['linear'], ['zoom'], 9, hayMun ? sin('d') : 0, 10.5, sin('s')];
    }
    $: if (listo && esSeccion && mapa.getLayer('mun-rayado')) mapa.setPaintProperty('mun-rayado', 'fill-opacity', rayadoMun(filasMun.length > 0));
    const pinturaIgn = (o) => (o ? { 'raster-brightness-min': 0.92, 'raster-brightness-max': 0.08, 'raster-saturation': -1, 'raster-contrast': 0.1 } : { 'raster-brightness-min': 0, 'raster-brightness-max': 1, 'raster-saturation': -0.3, 'raster-contrast': 0 });
    // secciones: en cada municipio, solo la versión del seccionado que usan los datos
    const filtroVersiones = () => ['in', ['concat', ['get', 'm'], '-', ['to-string', ['get', 'v']]], ['literal', versiones.length ? versiones : ['-']]];

    function imagenRayado() {
        const t = 8, c = document.createElement('canvas');
        c.width = c.height = t;
        const g = c.getContext('2d');
        g.fillStyle = oscuro ? '#1f2937' : '#f3f4f6';
        g.fillRect(0, 0, t, t);
        g.strokeStyle = oscuro ? '#6b7280' : '#9ca3af';
        g.lineWidth = 1.5;
        g.beginPath();
        g.moveTo(0, t); g.lineTo(t, 0); g.moveTo(-t / 2, t / 2); g.lineTo(t / 2, -t / 2); g.moveTo(t / 2, t * 1.5); g.lineTo(t * 1.5, t / 2);
        g.stroke();
        return g.getImageData(0, 0, t, t);
    }

    // color de cada territorio con feature-state
    function pintar() {
        if (!mapa || !listo) return;
        const capa = esSeccion ? 'secciones' : 'municipios';
        mapa.removeFeatureState({ source: 't', sourceLayer: 'municipios' });
        if (esSeccion) mapa.removeFeatureState({ source: 't', sourceLayer: 'secciones' });
        for (const r of actuales) mapa.setFeatureState({ source: 't', sourceLayer: capa, id: String(r.cod) }, { c: colorEn(paleta, escala.t(Number(r.valor))), d: true });
        if (esSeccion) {
            // municipios: color del indicador municipal (al alejarse) y si tienen secciones con dato
            for (const cod of munConSecciones) mapa.setFeatureState({ source: 't', sourceLayer: 'municipios', id: cod }, { s: true });
            if (escalaMun) for (const r of filasMun) mapa.setFeatureState({ source: 't', sourceLayer: 'municipios', id: String(r.cod) }, { c: colorEn(paleta, escalaMun.t(Number(r.valor))), d: true });
        }
        if (hover) mapa.setFeatureState(hover, { h: true });
    }
    $: if (listo) pintar(actuales, escala, escalaMun, paleta);
    $: if (listo && esSeccion) for (const id of ['secc-rayado', 'secc-relleno', 'secc-borde', 'secc-halo', 'secc-activo']) mapa.getLayer(id) && mapa.setFilter(id, filtroVersiones(versiones));

    // escala «lo que se ve»: valores de los territorios dibujados
    function medirVista() {
        if (!mapa || !listo || modoEscala !== 'local') return;
        const capa = esSeccion && mapa.getZoom() >= 10 ? 'secc-relleno' : 'mun-relleno';
        const vistos = new Set(mapa.queryRenderedFeatures({ layers: [capa] }).map((f) => String(f.id)));
        const fuente = capa === 'mun-relleno' && esSeccion ? munPorCod : porCod;
        numerosVista = [...vistos].map((c) => fuente.get(c)?.valor).filter(ok).map(Number);
    }
    $: if (modoEscala === 'local') medirVista(); else numerosVista = null;

    // ------------------------------------------------------------------ ratón
    let hover = null;
    let info = null; // {x, y, nombre, valor, puesto, extra}
    function quitarHover() {
        if (hover && mapa) mapa.setFeatureState(hover, { h: false });
        hover = null;
        info = null;
        marca = null;
    }
    function alMover(e) {
        const capas = esSeccion && mapa.getZoom() >= 10 ? ['secc-relleno', 'secc-rayado'] : ['mun-relleno', 'mun-rayado'];
        const f = mapa.queryRenderedFeatures(e.point, { layers: capas.filter((c) => mapa.getLayer(c)) })[0];
        if (!f) return quitarHover();
        const id = { source: 't', sourceLayer: f.sourceLayer, id: f.id };
        if (!hover || hover.id !== id.id || hover.sourceLayer !== id.sourceLayer) {
            quitarHover();
            hover = id;
            mapa.setFeatureState(hover, { h: true });
        }
        const cod = String(f.id);
        const deMun = f.sourceLayer === 'municipios';
        const r = deMun ? (esSeccion ? munPorCod.get(cod) : porCod.get(cod)) : porCod.get(cod);
        marca = r && (!esSeccion || !deMun) ? Number(r.valor) : null;
        info = {
            x: e.point.x,
            y: e.point.y,
            nombre: deMun ? f.properties.n || r?.territorio || cod : r?.territorio || cod,
            valor: r ? formatear(r.valor) : tx.sin,
            puesto: r && (!esSeccion || !deMun) ? puestos.get(cod) : null,
            extra: r?.eleccion ?? (esSeccion && !deMun && r?.anio ? String(r.anio) : null)
        };
    }
    function alPulsar(e) {
        // en barrios, pulsar un municipio desde lejos lleva a él
        if (!esSeccion || mapa.getZoom() >= 10) return;
        const f = mapa.queryRenderedFeatures(e.point, { layers: ['mun-relleno', 'mun-rayado'] })[0];
        if (f) irAMunicipio(String(f.id));
    }

    // ------------------------------------------------------------------ buscar e ir a
    let cajas = null;
    let indice = null;
    async function cargarCajas() {
        if (!cajas) cajas = await fetch('/geo/municipios-cajas.json').then((r) => r.json()).catch(() => ({}));
        return cajas;
    }
    async function irAMunicipio(cod, zoomMin = null) {
        const c = (await cargarCajas())[cod];
        if (!c || !mapa) return;
        mapa.fitBounds([[c[0], c[1]], [c[2], c[3]]], { padding: 40, maxZoom: zoomMin ? Math.max(zoomMin, 12) : 13, duration: 1200 });
        if (zoomMin) mapa.once('moveend', () => mapa.getZoom() < zoomMin && mapa.zoomTo(zoomMin));
    }
    let consulta = '';
    let resultados = [];
    let buscando = false;
    let marcador = null;
    const normal = (s) => String(s ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();
    let silenciar = false; // al rellenar el buscador con lo elegido, no volver a abrir la lista
    async function buscarMunicipios(q) {
        if (silenciar) {
            silenciar = false;
            return (resultados = []);
        }
        if (q.trim().length < 2) return (resultados = []);
        if (!indice) indice = await fetch('/geo/municipios-busqueda.json').then((r) => r.json()).catch(() => []);
        const n = normal(q.trim());
        resultados = indice
            .filter((m) => normal(m[1]).includes(n))
            .sort((a, b) => (normal(a[1]).startsWith(n) ? 0 : 1) - (normal(b[1]).startsWith(n) ? 0 : 1) || b[3] - a[3])
            .slice(0, 6)
            .map((m) => ({ tipo: 'mun', cod: m[0], texto: m[1], sub: m[2] }));
        resultados.push({ tipo: 'dir', texto: `${tx.direccion}: «${q.trim()}»` });
    }
    $: buscarMunicipios(consulta);
    async function elegir(r) {
        if (r.tipo === 'mun') {
            irAMunicipio(r.cod, esSeccion ? 12 : null);
            silenciar = true;
            consulta = r.texto;
            resultados = [];
            return;
        }
        // dirección: Nominatim (OpenStreetMap), solo España
        buscando = true;
        try {
            const u = `https://nominatim.openstreetmap.org/search?format=jsonv2&countrycodes=es&limit=1&accept-language=${lang}&q=${encodeURIComponent(consulta.trim())}`;
            const [d] = await fetch(u, { headers: { Accept: 'application/json' } }).then((x) => x.json());
            if (!d) {
                resultados = [{ tipo: 'nada', texto: tx.nada }];
                return;
            }
            resultados = [];
            const p = [Number(d.lon), Number(d.lat)];
            marcador?.remove();
            marcador = new maplibregl.Marker({ color: '#111827' }).setLngLat(p).addTo(mapa);
            mapa.flyTo({ center: p, zoom: esSeccion ? 14 : 11, duration: 1400 });
            // al acabar el vuelo y cargarse las teselas, la ficha del territorio de esa dirección
            mapa.once('moveend', () => mapa.once('idle', () => alMover({ point: mapa.project(p) })));
        } catch (e) {
            resultados = [{ tipo: 'nada', texto: tx.nada }];
        } finally {
            buscando = false;
        }
    }
    function irADestacado(r) {
        const cod = String(r.cod);
        if (!esSeccion) return irAMunicipio(cod);
        irAMunicipio(cod.slice(0, 5), 12.5);
        mapa.once('idle', () => {
            quitarHover();
            hover = { source: 't', sourceLayer: 'secciones', id: cod };
            mapa.setFeatureState(hover, { h: true });
            marca = Number(r.valor);
        });
    }
    const CIUDADES = [['28079', 'Madrid'], ['08019', 'Barcelona'], ['46250', 'València'], ['41091', 'Sevilla'], ['48020', 'Bilbao'], ['29067', 'Málaga']];

    // ------------------------------------------------------------------ montaje
    onMount(async () => {
        oscuro = document.documentElement.classList.contains('theme-dark');
        try {
            const [ml, pm] = await Promise.all([import('maplibre-gl'), import('pmtiles'), import('maplibre-gl/dist/maplibre-gl.css')]);
            maplibregl = ml.default ?? ml;
            if (!window.__protocoloPmtiles) {
                const p = new pm.Protocol();
                maplibregl.addProtocol('pmtiles', p.tile);
                window.__protocoloPmtiles = p;
            }
            if (!caja?.isConnected) return;
            // MapLibre falla («failed to invert matrix») si el contenedor no tiene tamaño (pestaña
            // oculta, pintado a medias): se espera a que lo tenga
            if (!caja.clientWidth || !caja.clientHeight)
                await new Promise((listo) => {
                    const ro = new ResizeObserver(() => {
                        if (caja.clientWidth && caja.clientHeight) {
                            ro.disconnect();
                            listo();
                        }
                    });
                    ro.observe(caja);
                });
            if (!caja?.isConnected) return;
            const h = leerHash();
            const v = String(h.v ?? '').split('/').map(Number);
            // vista del enlace o, si no hay, la Península (sin claves undefined: pisarían los valores
            // por defecto de MapLibre y el mapa no se podría calcular)
            const vista = v.length === 3 && v.every(Number.isFinite) ? { center: [v[2], v[1]], zoom: v[0] } : { bounds: PENINSULA, fitBoundsOptions: { padding: 10 } };
            mapa = new maplibregl.Map({
                container: caja,
                style: estilo(),
                ...vista,
                minZoom: 4,
                maxZoom: 16,
                maxBounds: [[-25, 25], [10, 47]],
                cooperativeGestures: true,
                attributionControl: { compact: true },
                locale: { 'CooperativeGesturesHandler.WindowsHelpText': tx.ctrl, 'CooperativeGesturesHandler.MacHelpText': tx.mac, 'CooperativeGesturesHandler.MobileHelpText': tx.movil },
                dragRotate: false,
                pitchWithRotate: false
            });
            mapa.touchZoomRotate.disableRotation();
            mapa.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'bottom-right');
            mapa.on('styleimagemissing', (e) => {
                if (e.id === 'rayado' && !mapa.hasImage('rayado')) mapa.addImage('rayado', imagenRayado());
            });
            mapa.on('load', () => {
                listo = true;
                zoom = mapa.getZoom();
                pintar();
            });
            caja.__mapa = mapa; // para depurar desde la consola
            mapa.on('error', (e) => {
                console.warn('[MapaExplorador]', e?.sourceId ?? '', e?.error?.message ?? e);
                if (String(e?.error?.message ?? '').includes('pmtiles') || e?.sourceId === 't') fallo = true;
            });
            mapa.on('mousemove', alMover);
            mapa.on('mouseout', quitarHover);
            mapa.on('click', alPulsar);
            mapa.on('zoom', () => (zoom = mapa.getZoom()));
            mapa.on('moveend', () => {
                const c = mapa.getCenter();
                escribirHash({ v: `${mapa.getZoom().toFixed(2)}/${c.lat.toFixed(4)}/${c.lng.toFixed(4)}` });
                medirVista();
            });
            // modo oscuro de la web: fondo, callejero y rayado
            observador = new MutationObserver(() => {
                const o = document.documentElement.classList.contains('theme-dark');
                if (o === oscuro || !mapa) return;
                oscuro = o;
                mapa.setPaintProperty('fondo', 'background-color', o ? '#0b1220' : '#eef1f5');
                for (const [k, val] of Object.entries(pinturaIgn(o))) mapa.setPaintProperty('ign', k, val);
                mapa.setPaintProperty('mun-borde', 'line-color', o ? '#0b1220' : '#ffffff');
                mapa.updateImage('rayado', imagenRayado());
            });
            observador.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] });
        } catch (e) {
            console.error(e);
            fallo = true;
        }
    });
    onDestroy(() => {
        parar();
        observador?.disconnect();
        mapa?.remove();
        mapa = null;
    });
    function irA(limites) {
        mapa?.fitBounds(limites, { padding: 20, duration: 1000 });
    }
</script>

<figure class="my-6 not-prose" data-mapa-explorador>
    {#if title}<figcaption class="mb-2 text-sm font-semibold text-gray-800 dark:text-gray-200">{title}</figcaption>{/if}
    <RayadoMapa />
    <div class="mb-2 flex flex-wrap items-center gap-2 text-xs">
        <div class="relative grow min-w-[14rem] max-w-md">
            <input
                type="search"
                bind:value={consulta}
                on:keydown={(e) => e.key === 'Enter' && resultados.length && elegir(resultados.find((r) => r.tipo === 'mun' && normal(r.texto) === normal(consulta)) ?? resultados[resultados.length - 1])}
                placeholder={tx.buscar}
                aria-label={tx.buscar}
                class="w-full rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-900 px-3 py-1.5 text-sm text-gray-900 dark:text-gray-100"
            />
            {#if resultados.length}
                <ul class="absolute z-20 mt-1 w-full overflow-hidden rounded-md border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-900 shadow-lg" role="listbox">
                    {#each resultados as r}
                        <li>
                            <button type="button" class="w-full px-3 py-1.5 text-left text-sm hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-60" disabled={r.tipo === 'nada' || buscando} on:click={() => elegir(r)}>
                                {r.texto}{#if r.sub}<span class="ml-1 text-gray-500">· {r.sub}</span>{/if}
                            </button>
                        </li>
                    {/each}
                </ul>
            {/if}
        </div>
        <span class="text-gray-500 dark:text-gray-400">{tx.ir}:</span>
        <button type="button" class="rounded border border-gray-300 dark:border-gray-600 px-2 py-0.5 hover:bg-gray-100 dark:hover:bg-gray-800" on:click={() => irA(PENINSULA)}>{tx.peninsula}</button>
        <button type="button" class="rounded border border-gray-300 dark:border-gray-600 px-2 py-0.5 hover:bg-gray-100 dark:hover:bg-gray-800" on:click={() => irA(CANARIAS)}>{tx.canarias}</button>
        {#each CIUDADES as [cod, nombre]}
            <button type="button" class="rounded border border-gray-300 dark:border-gray-600 px-2 py-0.5 hover:bg-gray-100 dark:hover:bg-gray-800" on:click={() => irAMunicipio(cod, esSeccion ? 11.5 : null)}>{nombre}</button>
        {/each}
    </div>

    <div class="relative rounded-lg overflow-hidden border border-gray-200 dark:border-gray-800" style="height:{height}px">
        <!-- alto y ancho explícitos: MapLibre pone position:relative al contenedor (anula inset-0) -->
        <div bind:this={caja} style="width:100%;height:100%" role="region" aria-label={title ?? tx.buscar}></div>
        {#if !listo && !fallo}
            <div class="absolute inset-0 grid place-items-center text-sm text-gray-500 bg-gray-100 dark:bg-gray-900 animate-pulse">{tx.cargando}</div>
        {/if}
        {#if fallo}
            <div class="absolute inset-0 grid place-items-center text-sm text-gray-500 bg-gray-100 dark:bg-gray-900">{tx.error}</div>
        {/if}
        {#if esSeccion && listo && zoom < 9.5}
            <div class="pointer-events-none absolute left-1/2 top-3 -translate-x-1/2 rounded-full bg-gray-900/80 px-3 py-1 text-xs text-white shadow">{tx.acercate}</div>
        {/if}
        {#if info}
            <div class="pointer-events-none absolute z-10 rounded-md border border-gray-200 dark:border-gray-700 bg-white/95 dark:bg-gray-900/95 px-3 py-2 text-xs shadow-md text-gray-800 dark:text-gray-100"
                style="left:{Math.min(info.x + 14, (caja?.clientWidth ?? 600) - 220)}px; top:{Math.min(info.y + 14, height - 90)}px; max-width:240px">
                <div class="font-semibold">{info.nombre}</div>
                <div class="text-sm font-bold tabular-nums">{info.valor}{#if unidad && info.valor !== tx.sin}<span class="ml-1 text-xs font-normal text-gray-500">{unidad}</span>{/if}</div>
                {#if info.puesto}<div class="text-gray-500">{tx.puesto} {info.puesto.toLocaleString(lang === 'en' ? 'en-GB' : 'es-ES')} {tx.de} {actuales.length.toLocaleString(lang === 'en' ? 'en-GB' : 'es-ES')}</div>{/if}
                {#if info.extra}<div class="text-gray-500">{info.extra}</div>{/if}
            </div>
        {/if}
        {#if anios.length > 1}
            <div class="absolute bottom-3 left-3 right-14 sm:right-auto sm:w-[26rem] flex items-center gap-2 rounded-md bg-white/90 dark:bg-gray-900/90 px-2 py-1.5 text-xs shadow">
                <button type="button" class="rounded border border-gray-300 dark:border-gray-600 px-2 py-0.5 font-semibold" on:click={reproducir} aria-label={reproduciendo ? tx.pausa : tx.play} title={reproduciendo ? tx.pausa : tx.play}>{reproduciendo ? '❚❚' : '▶'}</button>
                <span class="tabular-nums text-gray-500">{anios[0]}</span>
                <input type="range" class="grow" min="0" max={anios.length - 1} step="1" value={anios.indexOf(anio)} on:input={(e) => { parar(); anio = anios[Number(e.currentTarget.value)]; }} aria-label={tx.anio} />
                <span class="tabular-nums text-gray-500">{anios[anios.length - 1]}</span>
                <span class="ml-1 text-sm font-bold tabular-nums text-gray-900 dark:text-gray-100">{anio}</span>
            </div>
        {/if}
    </div>

    <!-- en barrios, de lejos se ven los municipios: su escala -->
    <LeyendaMapa escala={esSeccion && zoom < 10 && escalaMun ? escalaMun : escala} {paleta} {lang} {marca} modos={modosEscala} bind:modo={modoEscala} formatear={formatear} />

    {#if actuales.length >= 6}
        <div class="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
            {#each [['arriba', sentido === 'neutro' ? tx.mejores : tx.mejor], ['abajo', sentido === 'neutro' ? tx.peores : tx.peor]] as [lado, rotulo]}
                <div>
                    <div class="mb-1 font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">{rotulo}{#if !esSeccion && anio} · {anio}{/if}</div>
                    <ol class="space-y-1">
                        {#each destacados[lado] as r}
                            <li>
                                <button type="button" class="flex w-full items-baseline justify-between gap-2 rounded px-2 py-1 text-left hover:bg-gray-100 dark:hover:bg-gray-800" on:click={() => irADestacado(r)}>
                                    <span class="truncate"><span class="text-gray-400 tabular-nums">{puestos.get(String(r.cod))}.</span> {r.territorio ?? r.cod}</span>
                                    <span class="font-semibold tabular-nums whitespace-nowrap">{formatear(r.valor)}</span>
                                </button>
                            </li>
                        {/each}
                    </ol>
                    {#if destacados[lado === 'arriba' ? 'empatesArriba' : 'empatesAbajo'] > 0}
                        <p class="mt-1 px-2 text-gray-500 dark:text-gray-400">+{destacados[lado === 'arriba' ? 'empatesArriba' : 'empatesAbajo'].toLocaleString(lang === 'en' ? 'en-GB' : 'es-ES')} {tx.empate}</p>
                    {/if}
                </div>
            {/each}
        </div>
    {/if}
</figure>

<style>
    :global([data-mapa-explorador] .maplibregl-ctrl-attrib) {
        font-size: 10px;
    }
</style>
