<script>
    // Filtro de territorio en cascada (comunidad → provincia → municipio) con URL compartible:
    // ?ccaa=<slug>, ?provincia=<slug> o ?m=<código INE del municipio>. Publica como input de
    // Evidence un texto «nivel-código» ('pais-00', 'ccaa-01', 'provincia-41', 'municipio-41039')
    // que las consultas leen con split_part('${inputs.<name>}', '-', 1) y split_part(..., 2).
    import { onMount } from 'svelte';
    import { afterNavigate } from '$app/navigation';
    import { getInputContext } from '@evidence-dev/sdk/utils/svelte';

    /** Filas de mother.territorios con nivel ('ccaa' | 'provincia'), cod, nombre, slug, cod_ccaa */
    export let territorios = [];
    /** Filas con cod_mun, municipio, cod_prov */
    export let municipios = [];
    export let name = 'territorio';
    /** Textos visibles (se traducen en cada página) */
    export let etiquetas = {
        comunidad: 'Comunidad autónoma',
        todaEspana: 'Toda España',
        provincia: 'Provincia',
        todaComunidad: 'Toda la comunidad',
        municipio: 'Municipio',
        todaProvincia: 'Toda la provincia'
    };

    const inputs = getInputContext();
    let ccaa = '';
    let prov = '';
    let mun = '';
    let montado = false;
    let leidaUrl = false;

    $: lista = Array.from(territorios ?? []);
    $: comunidades = lista.filter((t) => t.nivel === 'ccaa').sort((a, b) => a.nombre.localeCompare(b.nombre));
    $: provincias = lista.filter((t) => t.nivel === 'provincia' && t.cod_ccaa === ccaa).sort((a, b) => a.nombre.localeCompare(b.nombre));
    $: muns = prov ? Array.from(municipios ?? []).filter((m) => m.cod_prov === prov).sort((a, b) => a.municipio.localeCompare(b.municipio)) : [];

    function valor() {
        if (mun) return `municipio-${mun}`;
        if (prov) return `provincia-${prov}`;
        if (ccaa) return `ccaa-${ccaa}`;
        return 'pais-00';
    }
    function publicar() {
        $inputs[name] = valor();
    }
    function escribirUrl() {
        if (typeof window === 'undefined') return;
        const url = new URL(window.location.href);
        for (const p of ['ccaa', 'provincia', 'm']) url.searchParams.delete(p);
        const slug = (nivel, cod) => lista.find((t) => t.nivel === nivel && t.cod === cod)?.slug;
        if (mun) url.searchParams.set('m', mun);
        else if (prov) url.searchParams.set('provincia', slug('provincia', prov) ?? prov);
        else if (ccaa) url.searchParams.set('ccaa', slug('ccaa', ccaa) ?? ccaa);
        window.history.replaceState(window.history.state, '', url);
    }
    function cambiar(nivel, v) {
        if (nivel === 'ccaa') { ccaa = v; prov = ''; mun = ''; }
        if (nivel === 'provincia') { prov = v; mun = ''; }
        if (nivel === 'municipio') mun = v;
        // Comunidad de una sola provincia: se elige también la provincia
        if (nivel === 'ccaa' && ccaa) {
            const ps = lista.filter((t) => t.nivel === 'provincia' && t.cod_ccaa === ccaa);
            if (ps.length === 1) prov = ps[0].cod;
        }
        publicar();
        escribirUrl();
    }

    publicar();

    onMount(() => { montado = true; });

    // Un enlace de la propia página (p. ej. pulsar un municipio en el mapa) cambia la URL sin
    // volver a montar el componente: se vuelven a leer los parámetros
    afterNavigate(({ from, to }) => {
        if (!montado || !from?.url || !to?.url || from.url.pathname !== to.url.pathname || from.url.search === to.url.search) return;
        ccaa = ''; prov = ''; mun = '';
        publicar();
        leidaUrl = false;
    });

    // Los parámetros de la URL se aplican cuando ya han llegado las listas (consultas asíncronas)
    $: if (montado && !leidaUrl && lista.length) {
        const q = new URL(window.location.href).searchParams;
        const m = q.get('m');
        const p = q.get('provincia');
        const c = q.get('ccaa');
        const buscar = (nivel, v) => lista.find((t) => t.nivel === nivel && (t.slug === v || t.cod === v));
        if (m && Array.from(municipios ?? []).length) {
            const fila = Array.from(municipios).find((x) => x.cod_mun === m);
            if (fila) {
                prov = fila.cod_prov;
                ccaa = buscar('provincia', prov)?.cod_ccaa ?? '';
                mun = m;
            }
            leidaUrl = true;
        } else if (!m) {
            if (p) {
                const t = buscar('provincia', p);
                if (t) { prov = t.cod; ccaa = t.cod_ccaa; }
            } else if (c) {
                const t = buscar('ccaa', c);
                if (t) {
                    ccaa = t.cod;
                    const ps = lista.filter((x) => x.nivel === 'provincia' && x.cod_ccaa === ccaa);
                    if (ps.length === 1) prov = ps[0].cod;
                }
            }
            leidaUrl = true;
        }
        if (leidaUrl && valor() !== 'pais-00') {
            publicar();
            const v = valor();
            setTimeout(() => { if (valor() === v && $inputs[name] !== v) publicar(); }, 300);
        }
    }

    const clase = 'w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-900 px-3 py-2 text-sm text-gray-900 dark:text-white';
</script>

<div class="not-prose my-4 grid gap-3 sm:grid-cols-3">
    <label class="block text-sm">
        <span class="mb-1 block font-semibold text-gray-700 dark:text-gray-300">{etiquetas.comunidad}</span>
        <select class={clase} value={ccaa} on:change={(e) => cambiar('ccaa', e.currentTarget.value)}>
            <option value="">{etiquetas.todaEspana}</option>
            {#each comunidades as c (c.cod)}<option value={c.cod}>{c.nombre}</option>{/each}
        </select>
    </label>
    <label class="block text-sm">
        <span class="mb-1 block font-semibold text-gray-700 dark:text-gray-300">{etiquetas.provincia}</span>
        <select class={clase} value={prov} disabled={!ccaa} on:change={(e) => cambiar('provincia', e.currentTarget.value)}>
            <option value="">{etiquetas.todaComunidad}</option>
            {#each provincias as p (p.cod)}<option value={p.cod}>{p.nombre}</option>{/each}
        </select>
    </label>
    <label class="block text-sm">
        <span class="mb-1 block font-semibold text-gray-700 dark:text-gray-300">{etiquetas.municipio}</span>
        <select class={clase} value={mun} disabled={!prov} on:change={(e) => cambiar('municipio', e.currentTarget.value)}>
            <option value="">{etiquetas.todaProvincia}</option>
            {#each muns as m (m.cod_mun)}<option value={m.cod_mun}>{m.municipio}</option>{/each}
        </select>
    </label>
</div>
