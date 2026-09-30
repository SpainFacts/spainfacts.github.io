<script>
    import { page } from "$app/stores";
    import { IDIOMAS, idiomaDeRuta, t } from "../i18n.js";
    import { textosIndicador } from "../i18n_internacional.js";
    import { paisesReferencia } from "../paisesReferencia.js";
    $: lang = idiomaDeRuta($page.url.pathname);

    // Comparación discreta de un indicador de España con otros países y medias
    // internacionales (mart internacional_ultimo). Una línea de "chips":
    //   España 11,4 · UE 5,9 · Francia 7,3 · Portugal 6,4 · Marruecos 13,0 · …
    // España va destacada y coloreada según esté mejor o peor que la media de la UE.
    //
    // Uso en una página:
    //   ```sql comp_paro
    //   SELECT * FROM mother.internacional_ultimo WHERE indicador_id = 'paro'
    //   ```
    //   <Comparativa data={comp_paro} />

    export let data = [];
    /** decimales a mostrar */
    export let decimales = 1;
    /** texto antes de los chips (por defecto, el nombre del indicador) */
    export let etiqueta = undefined;
    /** países a mostrar, en este orden (ISO3 del Banco Mundial; EUU = UE, OED = OCDE) */
    export let paises = ["EUU", "OED", "FRA", "PRT", "DEU", "ITA", "MAR", "USA", "CHN"];
    /** países de referencia del indicador, al final y destacados (por defecto,
     *  los de src/lib/paisesReferencia.js; [] para no mostrarlos) */
    export let referencia = undefined;

    // anio_ultimo en internacional_ultimo; anio en internacional_comparativa
    $: filas = Array.from(data ?? []).map((f) => ({ ...f, anio: f.anio ?? f.anio_ultimo }));
    $: espana = filas.find((f) => f.cod_pais === "ESP");
    $: otros = paises.map((c) => filas.find((f) => f.cod_pais === c)).filter(Boolean);
    // Países de referencia del indicador (Noruega en coches eléctricos, Japón en
    // envejecimiento...): no están en los fijos y se marcan con borde discontinuo
    $: refs = (referencia ?? paisesReferencia(filas[0]?.indicador_id))
        .filter((c) => c !== "ESP" && !paises.includes(c))
        .map((c) => filas.find((f) => f.cod_pais === c))
        .filter(Boolean);
    $: ue = filas.find((f) => f.cod_pais === "EUU");
    // nombre, unidad y fuente vienen en castellano de los datos: se traducen aquí
    $: textos = textosIndicador(filas[0], lang);
    $: unidad = textos.unidad ?? "";
    $: sentido = filas[0]?.sentido ?? "neutro";
    $: fuente = textos.fuente ?? "";

    const num = (v) => (v == null ? "–" : Number(v).toLocaleString(IDIOMAS[lang].locale, { maximumFractionDigits: decimales, minimumFractionDigits: 0 }));
    const nombre = (f) => t(`pais.${f.cod_pais}`, lang) ?? f.pais;

    // Color de España frente a la UE según si más es mejor o peor
    $: tono = (() => {
        if (!espana || !ue || sentido === "neutro") return "neutro";
        const mejor = sentido === "positivo" ? espana.valor > ue.valor : espana.valor < ue.valor;
        return Math.abs(espana.valor - ue.valor) < 1e-9 ? "neutro" : mejor ? "mejor" : "peor";
    })();

    // Año de cada dato solo si difiere del de España (evita repetirlo en todos)
    const anioSi = (f) => (espana && f.anio !== espana.anio ? ` (${f.anio})` : "");
</script>

{#if espana && (otros.length || refs.length)}
    <p class="comparativa" aria-label={t('comparativa', lang)}>
        <span class="etiqueta">{etiqueta ?? textos.nombre}:</span>
        <span class="chip espana {tono}" title="{t('pais.ESP', lang)}, {espana.anio}">{t('pais.ESP', lang)} {num(espana.valor)}</span>
        {#each otros as f (f.cod_pais)}
            <span class="chip" title="{f.pais}, {f.anio}">{nombre(f)} {num(f.valor)}{anioSi(f)}</span>
        {/each}
        {#each refs as f (f.cod_pais)}
            <span class="chip referencia" title="{t('comparativa.referencia', lang)} · {nombre(f)}, {f.anio}">{nombre(f)} {num(f.valor)}{anioSi(f)}</span>
        {/each}
        <span class="nota">{unidad}{espana ? ` · ${espana.anio}` : ""}{fuente ? ` · ${fuente}` : ""}</span>
    </p>
{/if}

<style>
    .comparativa {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 4px 6px;
        margin: 0.25rem 0 1rem;
        font-size: 12px;
        line-height: 1.4;
        color: var(--base-content-muted, #6b7280);
    }
    .etiqueta {
        margin-right: 2px;
    }
    .chip {
        padding: 1px 7px;
        border: 1px solid var(--base-300);
        border-radius: 999px;
        white-space: nowrap;
        color: var(--base-content);
        font-variant-numeric: tabular-nums;
    }
    /* país de referencia del indicador: borde discontinuo, sin más ruido */
    .chip.referencia {
        border-style: dashed;
    }
    .chip.espana {
        font-weight: 700;
    }
    .chip.espana.mejor {
        border-color: #15803d;
        color: #15803d;
    }
    .chip.espana.peor {
        border-color: #b91c1c;
        color: #b91c1c;
    }
    :global(.theme-dark) .chip.espana.mejor {
        border-color: #4ade80;
        color: #4ade80;
    }
    :global(.theme-dark) .chip.espana.peor {
        border-color: #f87171;
        color: #f87171;
    }
    .nota {
        font-size: 11px;
    }
</style>
