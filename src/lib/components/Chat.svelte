<script>
    // Chat para preguntar a los datos de SpainFacts. Todo corre en el navegador de quien lo
    // usa: el modelo lo pone él (Gemma en el navegador, su Ollama/LM Studio o su clave de
    // Anthropic) y el SQL lo ejecuta DuckDB-WASM sobre los parquets de la web. SpainFacts no ve
    // las preguntas.
    //
    // Dos modos (ver src/lib/chat):
    //   decisión -> el modelo solo elige entre opciones y el código hace SQL y respuesta
    //               (modelos pequeños: Gemma 4 E2B en el navegador, Ollama)
    //   agente   -> el modelo escribe el SQL con herramientas (Claude, modelos grandes)
    import { onMount, tick } from "svelte";
    import { page } from "$app/stores";
    import { query } from "@evidence-dev/universal-sql/client-duckdb";
    import { idiomaDeRuta, t } from "../i18n.js";
    import { crearIndice } from "../chat/herramientas.js";
    import { responder, MODELOS_ANTHROPIC, PROVEEDORES_API, listarModelosWebLLM, cargarWebLLM, crearDecisorOllama, crearDecisorWebLLM } from "../chat/agente.js";
    import { responderPorDecisiones } from "../chat/decision.js";
    import { markdownSeguro } from "../chat/markdown.js";
    import ChatGrafico from "./ChatGrafico.svelte";

    $: lang = idiomaDeRuta($page.url.pathname);

    const CLAVE_CONFIG = "spainfacts-chat";
    const PROVEEDORES = ["navegador", "local", "anthropic", "otro"];
    // Modelo de decisión del navegador (transformers.js); el resto de la lista son de WebLLM
    const DECISOR_NAVEGADOR = "decisor:gemma-4-e2b";
    // Modo decisión con modelos de WebLLM (WebGPU): el valor es "decisor-webllm:<id del modelo>"
    const DECISOR_WEBLLM = "decisor-webllm:";
    const esDecisorWebLLM = (m) => String(m ?? "").startsWith(DECISOR_WEBLLM);
    // Los que mejor eligen en las pruebas (tools/chat/evaluacion), si esta versión de WebLLM los tiene
    const PREFERIDOS_DECISION = [/^Ministral-3-3B/i, /^Qwen3\.5-4B/i, /^Qwen3-4B/i];
    // Predeterminado: Ministral 3 3B en modo decisión, el que mejor equilibra acierto, tamaño y
    // velocidad en las pruebas (2026-10-04: 144/210 frente a 139 de Gemma 4 E2B, 2,8 GB). Si esta
    // versión de WebLLM no lo tiene, se vuelve a Gemma 4 E2B (transformers.js)
    const DECISOR_PREDETERMINADO = DECISOR_WEBLLM + "Ministral-3-3B-Instruct-2512-BF16-q4f16_1-MLC";

    let config = {
        proveedor: "navegador",
        navegador: { modelo: DECISOR_PREDETERMINADO },
        local: { url: "http://localhost:11434/v1", modelo: "gemma4:e2b", clave: "", agente: false },
        anthropic: { modelo: MODELOS_ANTHROPIC[0].id, clave: "" },
        otro: { servicio: PROVEEDORES_API[0].id, url: PROVEEDORES_API[0].url, modelo: "", clave: "" },
        recordar: false
    };
    let ctx = null;
    let errorCatalogo = "";
    let modelosWebLLM = [];
    let progresoModelo = null; // { p, texto } mientras se descarga
    let modeloCargado = "";
    let hayWebGPU = false;
    // Decisores y embebedor ya cargados (no se vuelven a descargar en la sesión)
    const decisores = new Map();
    let embeber = null;

    /** @type {{ rol: 'usuario'|'asistente', texto: string, pasos: any[], graficos: any[], error?: string, enCurso?: boolean }[]} */
    let mensajes = [];
    let estados = {}; // estado de la conversación por proveedor
    let pregunta = "";
    let ocupado = false;
    let lista;

    // ---------- Configuración guardada (solo en este navegador) ----------
    function cargarConfig() {
        try {
            const g = JSON.parse(localStorage.getItem(CLAVE_CONFIG) ?? "null");
            if (g) config = { ...config, ...g, navegador: { ...config.navegador, ...g.navegador }, local: { ...config.local, ...g.local }, anthropic: { ...config.anthropic, ...g.anthropic }, otro: { ...config.otro, ...g.otro } };
        } catch {}
    }
    function guardarConfig() {
        try {
            const copia = JSON.parse(JSON.stringify(config));
            // Las claves solo se guardan si lo pide
            if (!config.recordar) {
                copia.anthropic.clave = "";
                copia.local.clave = "";
                copia.otro.clave = "";
            }
            localStorage.setItem(CLAVE_CONFIG, JSON.stringify(copia));
        } catch {}
    }
    $: if (ctx) (config, guardarConfig());

    // En la portada (perezoso) no se descarga nada hasta que alguien usa el chat: ni el
    // catálogo (~250 KB) ni la lista de modelos de WebLLM
    export let perezoso = false;
    let inicio = null;
    function iniciar() {
        inicio ??= (async () => {
            try {
                const r = await fetch("/chat/catalogo.json");
                if (!r.ok) throw new Error(`HTTP ${r.status}`);
                const catalogo = await r.json();
                ctx = { catalogo, indice: crearIndice(catalogo), consultar: (sql) => query(sql) };
            } catch (e) {
                errorCatalogo = String(e?.message ?? e);
            }
            if (hayWebGPU) {
                try {
                    modelosWebLLM = await listarModelosWebLLM();
                } catch {}
            }
            const idWebLLM = esDecisorWebLLM(config.navegador.modelo) ? config.navegador.modelo.slice(DECISOR_WEBLLM.length) : config.navegador.modelo;
            if (config.navegador.modelo !== DECISOR_NAVEGADOR && !modelosWebLLM.some((m) => m.id === idWebLLM)) {
                config.navegador.modelo = DECISOR_NAVEGADOR;
            }
            // Las opciones de WebLLM llegan después de pintar el desplegable: se vuelve a poner el
            // valor para que muestre el modelo elegido y no la primera opción
            await tick();
            config.navegador = { ...config.navegador };
        })();
        return inicio;
    }

    onMount(() => {
        cargarConfig();
        hayWebGPU = "gpu" in navigator;
        // Pregunta que llega por la URL (?p=...), p. ej. desde la portada
        const p = new URLSearchParams(location.search).get("p");
        if (p) pregunta = p;
        if (!perezoso || p) iniciar();
    });

    const enModoDecision = (proveedor) =>
        (proveedor === "navegador" && (config.navegador.modelo === DECISOR_NAVEGADOR || esDecisorWebLLM(config.navegador.modelo))) ||
        (proveedor === "local" && !config.local.agente);

    /** Decisor del proveedor actual (lo descarga la primera vez) */
    async function obtenerDecisor(proveedor) {
        const clave = proveedor === "local" ? `local:${config.local.url}:${config.local.modelo}` : config.navegador.modelo;
        if (!decisores.has(clave)) {
            if (proveedor === "local") decisores.set(clave, crearDecisorOllama({ url: config.local.url, modelo: config.local.modelo }));
            else if (esDecisorWebLLM(clave))
                decisores.set(clave, await crearDecisorWebLLM(clave.slice(DECISOR_WEBLLM.length), (p, texto) => (progresoModelo = { p, texto })));
            else {
                const { crearDecisor } = await import("../chat/locales.js");
                decisores.set(clave, await crearDecisor({ device: "webgpu", dtype: "q4f16", alProgreso: (p, texto) => (progresoModelo = { p, texto }) }));
            }
        }
        return decisores.get(clave);
    }

    /** Embebedor de la búsqueda semántica (~195 MB, solo en modo decisión). Si no carga en este
     *  navegador, el chat sigue buscando solo por palabras en vez de fallar */
    let sinEmbebedor = false;
    async function obtenerEmbebedor() {
        if (!embeber && !sinEmbebedor && ctx?.catalogo?.embeddings) {
            try {
                const { crearEmbebedor } = await import("../chat/locales.js");
                embeber = await crearEmbebedor({ modelo: ctx.catalogo.embeddings.modelo, dtype: ctx.catalogo.embeddings.dtype, archivo: ctx.catalogo.embeddings.archivo, dims: ctx.catalogo.embeddings.dims, alProgreso: (p, texto) => (progresoModelo = { p, texto }) });
            } catch (e) {
                console.warn("Búsqueda semántica no disponible; se busca solo por palabras:", e);
                sinEmbebedor = true;
            }
        }
        return embeber;
    }

    async function descargarModelo() {
        progresoModelo = { p: 0, texto: "" };
        try {
            if (config.navegador.modelo === DECISOR_NAVEGADOR || esDecisorWebLLM(config.navegador.modelo)) {
                await obtenerEmbebedor();
                await obtenerDecisor("navegador");
            } else await cargarWebLLM(config.navegador.modelo, (p, texto) => (progresoModelo = { p, texto }));
            modeloCargado = config.navegador.modelo;
        } catch (e) {
            mensajes = [...mensajes, { rol: "asistente", texto: "", pasos: [], graficos: [], error: String(e?.message ?? e) }];
        }
        progresoModelo = null;
    }

    function faltaConfig() {
        if (config.proveedor === "anthropic" && !config.anthropic.clave.trim()) return t("chat.faltaClave", lang);
        if (config.proveedor === "local" && !config.local.modelo.trim()) return t("chat.faltaModelo", lang);
        if (config.proveedor === "otro" && !config.otro.clave.trim()) return t("chat.faltaClave", lang);
        if (config.proveedor === "otro" && !config.otro.modelo.trim()) return t("chat.faltaModelo", lang);
        if (config.proveedor === "navegador" && !config.navegador.modelo) return t("chat.faltaModelo", lang);
        return "";
    }

    /**
     * @param {string} texto
     * @param {{ tablaForzada?: string, sinAclarar?: boolean, mostrar?: string }} [opciones]
     *   tablaForzada: la tabla que eligió la persona tras «¿qué datos quieres usar?»;
     *   sinAclarar: contestar con la que elija el modelo; mostrar: texto de la burbuja de la persona
     */
    async function enviar(texto = pregunta, opciones = {}) {
        texto = texto.trim();
        if (!texto || ocupado) return;
        await iniciar();
        if (!ctx) return;
        const falta = faltaConfig();
        if (falta) {
            mensajes = [...mensajes, { rol: "asistente", texto: "", pasos: [], graficos: [], error: falta }];
            return;
        }
        pregunta = "";
        ocupado = true;
        const respuesta = { rol: "asistente", texto: "", pasos: [], graficos: [], enCurso: true };
        mensajes = [...mensajes, { rol: "usuario", texto: opciones.mostrar ?? texto, pasos: [], graficos: [] }, respuesta];
        const refrescar = async () => {
            mensajes = mensajes;
            await tick();
            lista?.scrollTo({ top: lista.scrollHeight, behavior: "smooth" });
        };
        await refrescar();
        const proveedor = config.proveedor;
        try {
            if (proveedor === "navegador" && modeloCargado !== config.navegador.modelo) await descargarModelo();
            if (enModoDecision(proveedor)) {
                const e = await obtenerEmbebedor();
                const r = await responderPorDecisiones({
                    pregunta: texto,
                    // Si duda entre tablas pregunta cuál (salvo que ya se haya elegido)
                    ctx: { ...ctx, ...(e ? { embeber: e } : {}), aclarar: !opciones.tablaForzada && !opciones.sinAclarar, tablaForzada: opciones.tablaForzada },
                    decidir: await obtenerDecisor(proveedor),
                    alPaso: (p) => {
                        respuesta.pasos = [...respuesta.pasos, p];
                        refrescar();
                    }
                });
                if (r.grafico) respuesta.graficos = [r.grafico];
                else if (r.filas?.length) {
                    // Sin gráfico (un dato, una lista): los datos en tabla, para verlos, dibujarlos o descargarlos
                    const cols = Object.keys(r.filas[0]);
                    const num = cols.find((k) => typeof r.filas[0][k] === "number");
                    const eje = cols.find((k) => typeof r.filas[0][k] !== "number");
                    respuesta.graficos = [{ tipo: "tabla", x: eje ?? "", y: num ?? "", serie: "", titulo: "", filas: r.filas, sql: r.sql }];
                }
                respuesta.texto = r.texto;
                if (r.aclaracion) respuesta.aclaracion = { ...r.aclaracion, pregunta: texto, elegida: null };
                else if (r.alternativas?.length) respuesta.aclaracion = { opciones: r.alternativas, pregunta: texto, elegida: null, otros: true };
            } else {
            const r = await responder({
                proveedor,
                config: config[proveedor],
                estado: estados[proveedor],
                pregunta: texto,
                ctx,
                lang,
                alPaso: (p) => {
                    respuesta.pasos = [...respuesta.pasos, p];
                    refrescar();
                },
                alGrafico: (g) => {
                    respuesta.graficos = [...respuesta.graficos, g];
                    refrescar();
                },
                alProgreso: (p, txt) => (progresoModelo = { p, texto: txt })
            });
            estados[proveedor] = r.estado;
            respuesta.texto = r.texto;
            }
        } catch (e) {
            respuesta.error = String(e?.message ?? e);
        }
        progresoModelo = null;
        respuesta.enCurso = false;
        ocupado = false;
        await refrescar();
    }

    /** Respuesta a «¿qué datos quieres usar?»: vuelve a preguntar con esa tabla (o sin preguntar) */
    function elegirTabla(m, opcion) {
        if (m.aclaracion.elegida || ocupado) return;
        m.aclaracion.elegida = opcion?.tabla ?? "-";
        mensajes = mensajes;
        enviar(
            m.aclaracion.pregunta,
            opcion
                ? { tablaForzada: opcion.tabla, mostrar: `${t("chat.aclararUsar", lang)}: ${opcion.tema}` }
                : { sinAclarar: true, mostrar: t("chat.aclararNinguna", lang) }
        );
    }

    function nuevaConversacion() {
        mensajes = [];
        estados = {};
    }

    const etiquetaPaso = (p) => {
        const base = t(`chat.paso.${p.herramienta}`, lang);
        if (p.herramienta === "buscar_tablas") return `${base}: «${p.entrada?.texto ?? ""}»`;
        if (p.herramienta === "describir_tabla") return `${base} ${p.entrada?.tabla ?? ""}`;
        if (p.herramienta === "decidir") return `${base}: ${String(p.entrada?.eleccion ?? "").slice(0, 90)}`;
        return base;
    };

    $: ejemplos = [t("chat.ej1", lang), t("chat.ej2", lang), t("chat.ej3", lang)];
</script>

<div class="not-prose my-4 space-y-4">
    <details on:toggle={(e) => e.currentTarget.open && iniciar()}>
        <summary class="w-fit cursor-pointer rounded-md px-2 py-2 text-sm font-semibold text-blue-700 underline decoration-blue-300 underline-offset-4 hover:text-blue-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 dark:text-blue-300 dark:hover:text-blue-100">
            {t("chat.configurar", lang)}
        </summary>
        <fieldset class="mt-2 rounded-lg border border-gray-200 p-3 dark:border-gray-700" on:focusin={iniciar} on:pointerdown={iniciar}>
        <legend class="px-1 text-sm font-semibold">{t("chat.proveedor", lang)}</legend>
        <div class="grid gap-2 sm:grid-cols-2 lg:grid-cols-4" role="radiogroup">
            {#each PROVEEDORES as p}
                <label class="cursor-pointer rounded-md border p-2 text-sm {config.proveedor === p ? 'border-blue-600 bg-blue-50 dark:bg-blue-950/40' : 'border-gray-200 dark:border-gray-700'}">
                    <input type="radio" class="sr-only" bind:group={config.proveedor} value={p} />
                    <span class="font-semibold">{t(`chat.p.${p}`, lang)}</span>
                    <span class="block text-xs text-gray-600 dark:text-gray-400 mt-0.5">{t(`chat.p.${p}.corto`, lang)}</span>
                </label>
            {/each}
        </div>

        <div class="mt-3 text-sm space-y-2">
            <p class="text-xs text-gray-600 dark:text-gray-400">{t(`chat.p.${config.proveedor}.desc`, lang)}</p>
            {#if config.proveedor === "navegador"}
                {#if !hayWebGPU}
                    <p class="text-xs text-amber-700 dark:text-amber-300">{t("chat.sinWebgpu", lang)}</p>
                {:else}
                    <div class="flex flex-wrap items-center gap-2">
                        <label class="flex items-center gap-2">{t("chat.modelo", lang)}
                            <select bind:value={config.navegador.modelo} class="rounded border border-gray-300 dark:border-gray-600 bg-transparent px-2 py-1 text-sm max-w-[16rem]">
                                <option value={DECISOR_NAVEGADOR}>{t("chat.decisorRecomendado", lang)}</option>
                                {#each modelosWebLLM.filter((m) => PREFERIDOS_DECISION.some((r) => r.test(m.id))) as m}
                                    <option value={DECISOR_WEBLLM + m.id}>{m.id} · {t("chat.modoDecision", lang)}{DECISOR_WEBLLM + m.id === DECISOR_PREDETERMINADO ? ` (${t("chat.recomendado", lang)})` : ""}{m.vram ? ` (~${(m.vram / 1024).toFixed(1)} GB)` : ""}</option>
                                {/each}
                                {#if modelosWebLLM.length}
                                    <optgroup label={t("chat.otrosAgente", lang)}>
                                        {#each modelosWebLLM as m}<option value={m.id}>{m.id}{m.vram ? ` (~${(m.vram / 1024).toFixed(1)} GB)` : ""}</option>{/each}
                                    </optgroup>
                                {/if}
                            </select>
                        </label>
                        {#if modeloCargado !== config.navegador.modelo}
                            <button type="button" on:click={descargarModelo} disabled={!!progresoModelo} class="rounded-md bg-gray-800 dark:bg-gray-200 text-white dark:text-gray-900 px-3 py-1 text-sm disabled:opacity-50">{t("chat.cargarModelo", lang)}</button>
                        {:else}
                            <span class="text-xs text-green-700 dark:text-green-400">✓ {t("chat.modeloListo", lang)}</span>
                        {/if}
                    </div>
                {/if}
            {:else if config.proveedor === "local"}
                <div class="grid gap-2 sm:grid-cols-3">
                    <label class="flex flex-col text-xs">{t("chat.url", lang)}<input bind:value={config.local.url} class="rounded border border-gray-300 dark:border-gray-600 bg-transparent px-2 py-1 text-sm" /></label>
                    <label class="flex flex-col text-xs">{t("chat.modelo", lang)}<input bind:value={config.local.modelo} class="rounded border border-gray-300 dark:border-gray-600 bg-transparent px-2 py-1 text-sm" /></label>
                    <label class="flex flex-col text-xs">{t("chat.claveOpcional", lang)}<input type="password" autocomplete="off" bind:value={config.local.clave} class="rounded border border-gray-300 dark:border-gray-600 bg-transparent px-2 py-1 text-sm" /></label>
                </div>
                <label class="flex items-center gap-2 text-xs"><input type="checkbox" bind:checked={config.local.agente} /> {t("chat.modoAgente", lang)}</label>
            {:else if config.proveedor === "otro"}
                <div class="grid gap-2 sm:grid-cols-2">
                    <label class="flex flex-col text-xs">{t("chat.servicio", lang)}
                        <select bind:value={config.otro.servicio} on:change={() => (config.otro.url = PROVEEDORES_API.find((x) => x.id === config.otro.servicio)?.url ?? config.otro.url)}
                            class="rounded border border-gray-300 dark:border-gray-600 bg-transparent px-2 py-1 text-sm">
                            {#each PROVEEDORES_API as s}<option value={s.id}>{s.nombre}</option>{/each}
                        </select>
                    </label>
                    <label class="flex flex-col text-xs">{t("chat.url", lang)}<input bind:value={config.otro.url} class="rounded border border-gray-300 dark:border-gray-600 bg-transparent px-2 py-1 text-sm" /></label>
                    <label class="flex flex-col text-xs">{t("chat.modelo", lang)}<input bind:value={config.otro.modelo} placeholder={t("chat.modeloProveedor", lang)} class="rounded border border-gray-300 dark:border-gray-600 bg-transparent px-2 py-1 text-sm" /></label>
                    <label class="flex flex-col text-xs">{t("chat.clave", lang)}<input type="password" autocomplete="off" bind:value={config.otro.clave} class="rounded border border-gray-300 dark:border-gray-600 bg-transparent px-2 py-1 text-sm" /></label>
                </div>
            {:else}
                <div class="grid gap-2 sm:grid-cols-2">
                    <label class="flex flex-col text-xs">{t("chat.clave", lang)}<input type="password" autocomplete="off" placeholder="sk-ant-…" bind:value={config.anthropic.clave} class="rounded border border-gray-300 dark:border-gray-600 bg-transparent px-2 py-1 text-sm" /></label>
                    <label class="flex flex-col text-xs">{t("chat.modelo", lang)}
                        <select bind:value={config.anthropic.modelo} class="rounded border border-gray-300 dark:border-gray-600 bg-transparent px-2 py-1 text-sm">
                            {#each MODELOS_ANTHROPIC as m}<option value={m.id}>{m.nombre} · {m.precio}</option>{/each}
                        </select>
                    </label>
                </div>
            {/if}
            {#if config.proveedor !== "navegador"}
                <label class="flex items-center gap-2 text-xs"><input type="checkbox" bind:checked={config.recordar} /> {t("chat.recordar", lang)}</label>
            {/if}
            {#if progresoModelo}
                <div class="text-xs" role="status">
                    <div class="h-1.5 w-full rounded bg-gray-200 dark:bg-gray-700 overflow-hidden"><div class="h-full bg-blue-600" style="width: {Math.round(progresoModelo.p * 100)}%"></div></div>
                    <p class="mt-1 text-gray-600 dark:text-gray-400">{t("chat.descargando", lang)} {progresoModelo.texto}</p>
                </div>
            {/if}
        </div>
        </fieldset>
    </details>

    {#if errorCatalogo}
        <p class="rounded-md border border-red-300 bg-red-50 dark:bg-red-950/40 dark:border-red-800 px-3 py-2 text-sm">{t("chat.catalogoError", lang)} ({errorCatalogo})</p>
    {/if}

    <!-- Conversación -->
    <div bind:this={lista} class="space-y-3 max-h-[70vh] overflow-y-auto overflow-x-hidden" aria-live="polite">
        {#if !mensajes.length}
            <div class="text-sm text-gray-600 dark:text-gray-400">
                <p class="mb-2">{t("chat.ejemplos", lang)}</p>
                <div class="flex flex-wrap gap-2">
                    {#each ejemplos as e}
                        <button type="button" on:click={() => enviar(e)} disabled={ocupado || !!errorCatalogo} class="rounded-full border border-gray-300 dark:border-gray-600 px-3 py-1 text-left hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-50">{e}</button>
                    {/each}
                </div>
            </div>
        {/if}
        {#each mensajes as m}
            {#if m.rol === "usuario"}
                <div class="ml-auto w-fit max-w-[85%] rounded-lg bg-blue-600 text-white px-3 py-2 text-sm whitespace-pre-wrap">{m.texto}</div>
            {:else}
                <div class="max-w-full rounded-lg border border-gray-200 dark:border-gray-700 px-3 py-2 text-sm">
                    {#if m.error}
                        <p class="text-red-700 dark:text-red-400">{t("chat.error", lang)} {m.error}</p>
                    {/if}
                    {#each m.graficos as g}<ChatGrafico grafico={g} {lang} />{/each}
                    {#if m.texto}<div class="chat-texto">{@html markdownSeguro(m.texto)}</div>{/if}
                    {#if m.aclaracion?.otros}
                        <div class="mt-2 flex flex-wrap items-center gap-2 text-xs text-gray-600 dark:text-gray-400">
                            <span>{t("chat.otrosDatos", lang)}</span>
                            {#each m.aclaracion.opciones as op}
                                <button type="button" on:click={() => elegirTabla(m, op)} disabled={ocupado || !!m.aclaracion.elegida} title={op.pagina ?? ""}
                                    class="rounded-full border px-2 py-0.5 text-left hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-60 {m.aclaracion.elegida === op.tabla ? 'border-blue-600' : 'border-gray-300 dark:border-gray-600'}">{op.tema}</button>
                            {/each}
                        </div>
                    {:else if m.aclaracion}
                        <p class="mb-2">{t("chat.aclarar", lang)}</p>
                        <div class="flex flex-col gap-2">
                            {#each m.aclaracion.opciones as op}
                                <button type="button" on:click={() => elegirTabla(m, op)} disabled={ocupado || !!m.aclaracion.elegida}
                                    class="rounded-md border px-3 py-2 text-left hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-60 {m.aclaracion.elegida === op.tabla ? 'border-blue-600 bg-blue-50 dark:bg-blue-950' : 'border-gray-300 dark:border-gray-600'}">
                                    <span class="block">{op.tema}</span>
                                    {#if op.pagina}<span class="block text-xs text-gray-500 dark:text-gray-400">{op.pagina}</span>{/if}
                                </button>
                            {/each}
                            <button type="button" on:click={() => elegirTabla(m, null)} disabled={ocupado || !!m.aclaracion.elegida}
                                class="w-fit text-xs text-gray-600 dark:text-gray-400 underline disabled:opacity-60">{t("chat.aclararNinguna", lang)}</button>
                        </div>
                    {/if}
                    {#if m.enCurso}
                        <p class="text-gray-500 dark:text-gray-400 animate-pulse">{m.pasos.length ? etiquetaPaso(m.pasos.at(-1)) : t("chat.pensando", lang)}…</p>
                    {/if}
                    {#if m.pasos.length && !m.enCurso}
                        <details class="mt-2 text-xs text-gray-600 dark:text-gray-400">
                            <summary class="cursor-pointer">{t("chat.comoCalculado", lang)} ({m.pasos.length})</summary>
                            <ol class="mt-1 space-y-1 list-decimal pl-5">
                                {#each m.pasos as p}
                                    <li>{etiquetaPaso(p)}{#if p.entrada?.sql}<pre class="mt-1 whitespace-pre-wrap rounded bg-gray-100 dark:bg-gray-800 p-2 font-mono">{p.entrada.sql}</pre>{/if}</li>
                                {/each}
                            </ol>
                        </details>
                    {/if}
                </div>
            {/if}
        {/each}
    </div>

    <form on:submit|preventDefault={() => enviar()} class="flex flex-col sm:flex-row gap-2 sm:items-end">
        <label class="sr-only" for="chat-pregunta">{t("chat.placeholder", lang)}</label>
        <textarea id="chat-pregunta" rows="2" bind:value={pregunta} placeholder={t("chat.placeholder", lang)} disabled={!!errorCatalogo} on:focus={iniciar}
            on:keydown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); enviar(); } }}
            class="flex-1 rounded-md border border-gray-300 dark:border-gray-600 bg-transparent px-3 py-2 text-sm"></textarea>
        <div class="flex sm:flex-col items-center gap-3 sm:gap-1">
            <button type="submit" disabled={ocupado || !pregunta.trim() || !!errorCatalogo} class="rounded-md bg-blue-600 text-white px-4 py-2 text-sm font-semibold disabled:opacity-50">{t("chat.enviar", lang)}</button>
            {#if mensajes.length}<button type="button" on:click={nuevaConversacion} disabled={ocupado} class="text-xs text-gray-600 dark:text-gray-400 underline">{t("chat.nueva", lang)}</button>{/if}
        </div>
    </form>
    <p class="text-xs text-gray-500 dark:text-gray-400">{t("chat.aviso", lang)}</p>
</div>

<style>
    .chat-texto { overflow-wrap: anywhere; }
    .chat-texto :global(p) { margin: 0.4em 0; }
    .chat-texto :global(ul), .chat-texto :global(ol) { margin: 0.4em 0; padding-left: 1.25em; }
    .chat-texto :global(ul) { list-style: disc; }
    .chat-texto :global(ol) { list-style: decimal; }
    .chat-texto :global(a) { color: rgb(37 99 235); text-decoration: underline; }
    .chat-texto :global(code) { font-family: ui-monospace, monospace; font-size: 0.9em; }
</style>
