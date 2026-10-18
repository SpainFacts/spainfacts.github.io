<script>
    import { page } from "$app/stores";
    import { IDIOMAS, idiomaDeRuta, rutaEnIdioma, enlace, t } from "../i18n.js";

    $: lang = idiomaDeRuta($page.url.pathname);

    const temasPrincipales = [
        { href: "/territorios", clave: "menu.territorios" },
        { href: "/demografia", clave: "menu.demografia" },
        { href: "/economia", clave: "menu.economia" },
        { href: "/vivienda", clave: "menu.vivienda" },
        { href: "/cuentas-publicas", clave: "menu.cuentas" },
        { href: "/energia-clima", clave: "menu.energia" },
        { href: "/movilidad", clave: "menu.movilidad" },
        { href: "/sociedad", clave: "menu.sociedad" },
        { href: "/transparencia", clave: "menu.transparencia" },
        { href: "/medios", clave: "menu.medios" }
    ];

    const enlacesHerramientas = [
        { href: "/analisis", clave: "menu.analisis" },
        { href: "/chat", clave: "menu.chat" },
        { href: "/territorios/municipios", texto: { es: "Buscador de municipios (+8.100)", en: "Municipality finder (8,100+)", ca: "Cercador de municipis (+8.100)", gl: "Buscador de concellos (+8.100)", eu: "Udalerrien bilatzailea (+8.100)" } },
        { href: "/varios/indicadores", texto: { es: "Catálogo de indicadores", en: "Indicator catalogue", ca: "Catàleg d’indicadors", gl: "Catálogo de indicadores", eu: "Adierazleen katalogoa" } },
        { href: "/varios/mapas", texto: { es: "Explorador de mapas", en: "Map explorer", ca: "Explorador de mapes", gl: "Explorador de mapas", eu: "Mapen arakatzailea" } },
        { href: "/varios/espana-en-europa", texto: { es: "España en Europa", en: "Spain in Europe", ca: "Espanya a Europa", gl: "España en Europa", eu: "Espainia Europan" } }
    ];

    const enlacesTransparencia = [
        { href: "/fuentes", clave: "menu.fuentes" },
        { href: "/varios/datos-abiertos", texto: { es: "Datos abiertos en España", en: "Open data in Spain", ca: "Dades obertes a Espanya", gl: "Datos abertos en España", eu: "Datu irekiak Espainian" } },
        { href: "/varios/inspiracion-internacional", texto: { es: "Inspiración internacional (USAFacts)", en: "International inspiration (USAFacts)", ca: "Inspiració internacional (USAFacts)", gl: "Inspiración internacional (USAFacts)", eu: "Nazioarteko inspirazioa (USAFacts)" } }
    ];
</script>

<footer class="mt-16 border-t border-gray-200 bg-slate-50/80 text-gray-600 dark:border-gray-800 dark:bg-gray-900/80 dark:text-gray-400 print:hidden">
    <div class="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
        <div class="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-5">
            <!-- Marca y misión -->
            <div class="lg:col-span-2">
                <a href={enlace("/", lang)} class="inline-flex items-center gap-1 font-extrabold text-xl tracking-tight text-gray-900 dark:text-white no-underline">
                    Spain<span class="text-blue-600 dark:text-blue-400">Facts</span>
                </a>
                <p class="mt-3 max-w-md text-sm leading-relaxed text-gray-600 dark:text-gray-400">
                    {t("footer.mision", lang)}
                </p>
                <!-- Selector rápido de idioma en el pie -->
                <div class="mt-5 flex flex-wrap items-center gap-1.5" aria-label={t("menu.idioma", lang)}>
                    {#each Object.entries(IDIOMAS) as [cod, info]}
                        <a
                            href={rutaEnIdioma($page.url.pathname, cod)}
                            class="rounded-md px-2 py-1 text-xs font-medium no-underline transition-colors {cod === lang
                                ? 'bg-blue-600 text-white'
                                : 'bg-gray-200/70 text-gray-700 hover:bg-gray-300 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700'}"
                        >
                            {info.nombre}
                        </a>
                    {/each}
                </div>
            </div>

            <!-- Columna 1: Temas siempre visibles -->
            <div>
                <h2 class="text-xs font-bold uppercase tracking-wider text-gray-900 dark:text-white">
                    {t("footer.temas", lang)}
                </h2>
                <ul class="mt-3 space-y-2 text-sm list-none p-0">
                    {#each temasPrincipales as item}
                        <li>
                            <a href={enlace(item.href, lang)} class="text-gray-600 hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400 no-underline">
                                {t(item.clave, lang)}
                            </a>
                        </li>
                    {/each}
                </ul>
            </div>

            <!-- Columna 2: Análisis y herramientas -->
            <div>
                <h2 class="text-xs font-bold uppercase tracking-wider text-gray-900 dark:text-white">
                    {t("footer.analisisHerramientas", lang)}
                </h2>
                <ul class="mt-3 space-y-2 text-sm list-none p-0">
                    {#each enlacesHerramientas as item}
                        <li>
                            <a href={enlace(item.href, lang)} class="text-gray-600 hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400 no-underline">
                                {item.clave ? t(item.clave, lang) : item.texto[lang] ?? item.texto.es}
                            </a>
                        </li>
                    {/each}
                </ul>
            </div>

            <!-- Columna 3: Rigor y código abierto -->
            <div>
                <h2 class="text-xs font-bold uppercase tracking-wider text-gray-900 dark:text-white">
                    {t("footer.transparenciaMetodo", lang)}
                </h2>
                <ul class="mt-3 space-y-2 text-sm list-none p-0">
                    {#each enlacesTransparencia as item}
                        <li>
                            <a href={enlace(item.href, lang)} class="text-gray-600 hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400 no-underline">
                                {item.clave ? t(item.clave, lang) : item.texto[lang] ?? item.texto.es}
                            </a>
                        </li>
                    {/each}
                    <li>
                        <a
                            href="https://github.com/spainfacts/spainfacts.github.io"
                            target="_blank"
                            rel="noopener noreferrer"
                            class="inline-flex items-center gap-1 text-gray-600 hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400 no-underline"
                        >
                            GitHub (Open Source) ↗
                        </a>
                    </li>
                </ul>
            </div>
        </div>

        <div class="mt-10 border-t border-gray-200 pt-6 text-xs text-gray-500 dark:border-gray-800 dark:text-gray-500 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
            <p>{t("footer.licencia", lang)}</p>
            <p class="font-medium">SpainFacts.org</p>
        </div>
    </div>
</footer>
