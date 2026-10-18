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
        { href: "/medios", clave: "menu.medios" },
        { href: "/varios", clave: "menu.varios" }
    ];

    const enlacesExploracion = [
        { href: "/varios/ciudades", texto: { es: "Ciudades de España y Europa", en: "Spanish & European cities", ca: "Ciutats d’Espanya i d’Europa", gl: "Cidades de España e de Europa", eu: "Espainiako eta Europako hiriak" } },
        { href: "/varios/espana-en-el-mundo", texto: { es: "España en el mundo", en: "Spain in the world", ca: "Espanya al món", gl: "España no mundo", eu: "Espainia munduan" } },
        { href: "/varios/espana-en-europa", texto: { es: "España en Europa", en: "Spain in Europe", ca: "Espanya a Europa", gl: "España en Europa", eu: "Espainia Europan" } },
        { href: "/territorios/municipios", texto: { es: "Buscador de municipios (+8.100)", en: "Municipality finder (8,100+)", ca: "Cercador de municipis (+8.100)", gl: "Buscador de concellos (+8.100)", eu: "Udalerrien bilatzailea (+8.100)" } },
        { href: "/varios/mapas", texto: { es: "Explorador de mapas", en: "Map explorer", ca: "Explorador de mapes", gl: "Explorador de mapas", eu: "Mapen arakatzailea" } },
        { href: "/varios/indicadores", texto: { es: "Catálogo de indicadores", en: "Indicator catalogue", ca: "Catàleg d’indicadors", gl: "Catálogo de indicadores", eu: "Adierazleen katalogoa" } },
        { href: "/varios/diputados-caseros", texto: { es: "¿Cuántos diputados son caseros?", en: "Landlord MPs in Congress", ca: "Quants diputats són propietaris?", gl: "Cantos deputados son caseiros?", eu: "Zenbat diputatu dira errentatzaileak?" } },
        { href: "/varios/observatorios", texto: { es: "Observatorios públicos", en: "Public observatories", ca: "Observatoris públics", gl: "Observatorios públicos", eu: "Behatoki publikoak" } }
    ];

    const enlacesAnalisis = [
        { href: "/analisis", texto: { es: "Todos los reportajes", en: "All data deep-dives", ca: "Tots els reportatges", gl: "Todas as reportaxes", eu: "Erreportaje guztiak" } },
        { href: "/analisis/brecha-vivienda-salarios", texto: { es: "Brecha vivienda y salarios", en: "Housing & wages gap", ca: "Bretxa habitatge i salaris", gl: "Fenda vivenda e salarios", eu: "Etxebizitzaren eta soldaten arrakala" } },
        { href: "/analisis/revolucion-renovable", texto: { es: "La revolución renovable", en: "The renewable revolution", ca: "La revolució renovable", gl: "A revolución renovable", eu: "Iraultza berriztagarria" } },
        { href: "/movilidad/flotas-e-impuestos", texto: { es: "Paraísos fiscales de flotas", en: "Fleet tax havens", ca: "Paradisos fiscals de flotes", gl: "Paraísos fiscais de frotas", eu: "Floten zerga-paradisuak" } },
        { href: "/sociedad/publico-privado", texto: { es: "Público y privado en servicios", en: "Public & private services", ca: "Públic i privat en serveis", gl: "Público e privado en servizos", eu: "Publikoa eta pribatua zerbitzuetan" } },
        { href: "/medios/dinero-publico", texto: { es: "Publicidad en medios", en: "Media public funding", ca: "Publicitat en mitjans", gl: "Publicidade en medios", eu: "Publizitatea hedabideetan" } },
        { href: "/chat", clave: "menu.chat" }
    ];

    const enlacesTransparencia = [
        { href: "/transparencia", texto: { es: "Portal de Transparencia →", en: "Transparency Portal →", ca: "Portal de Transparència →", gl: "Portal de Transparencia →", eu: "Gardentasun Ataria →" } },
        { href: "/transparencia/contratacion", texto: { es: "Contratación pública (OIReScon)", en: "Public procurement (OIReScon)", ca: "Contractació pública (OIReScon)", gl: "Contratación pública (OIReScon)", eu: "Kontratazio publikoa (OIReScon)" } },
        { href: "/transparencia/subvenciones", texto: { es: "Subvenciones públicas (BDNS)", en: "Public subsidies (BDNS)", ca: "Subvencions públiques (BDNS)", gl: "Subvencións públicas (BDNS)", eu: "Diru-laguntza publikoak (BDNS)" } },
        { href: "/transparencia/consejo-transparencia", texto: { es: "Reclamaciones de acceso (CTBG)", en: "FOI claims (CTBG)", ca: "Reclamacions d'accés (CTBG)", gl: "Reclamacións de acceso (CTBG)", eu: "Informazio-erreklamazioak (CTBG)" } },
        { href: "/transparencia/decretos-ley", texto: { es: "Decretos-ley desde 1977", en: "Decree-laws since 1977", ca: "Decrets llei des del 1977", gl: "Decretos-lei desde 1977", eu: "Lege-dekretuak 1977tik" } },
        { href: "/transparencia/cuentas-municipales", texto: { es: "Rendición de cuentas municipal", en: "Municipal accounts compliance", ca: "Rendició de comptes municipal", gl: "Rendición de contas municipal", eu: "Udalen kontu-ematea" } },
        { href: "/transparencia/indultos", texto: { es: "Indultos concedidos desde 1996", en: "Pardons granted since 1996", ca: "Indults concedits des del 1996", gl: "Indultos concedidos desde 1996", eu: "Emandako indultuak 1996tik" } },
        { href: "/transparencia/comparacion-internacional", texto: { es: "España en gobernanza global", en: "Spain in governance indices", ca: "Espanya en governança global", gl: "España en gobernanza global", eu: "Espainia gobernantza globalean" } }
    ];

    const enlacesMetodo = [
        { href: "/fuentes", texto: { es: "Catálogo de fuentes y método →", en: "Sources & methodology catalogue →", ca: "Catàleg de fonts i metodologia →", gl: "Catálogo de fontes e metodoloxía →", eu: "Iturrien katalogoa eta metodologia →" } },
        { href: "/varios/datos-abiertos", texto: { es: "Datos abiertos en España", en: "Open data in Spain", ca: "Dades obertes a Espanya", gl: "Datos abertos en España", eu: "Datu irekiak Espainian" } },
        { href: "/varios/inspiracion-internacional", texto: { es: "Inspiración en USAFacts", en: "Inspiration from USAFacts", ca: "Inspiració en USAFacts", gl: "Inspiración en USAFacts", eu: "USAFactsen inspirazioa" } }
    ];
</script>

<footer class="mt-20 border-t border-gray-200 bg-slate-50/80 text-gray-600 dark:border-gray-800 dark:bg-gray-900/80 dark:text-gray-400 print:hidden">
    <div class="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
        <!-- Bloque superior: Identidad y Selector de idioma -->
        <div class="mb-10 pb-8 border-b border-gray-200 dark:border-gray-800 flex flex-col md:flex-row md:items-center md:justify-between gap-6">
            <div>
                <a href={enlace("/", lang)} class="inline-flex items-center gap-1 font-extrabold text-2xl tracking-tight text-gray-900 dark:text-white no-underline">
                    Spain<span class="text-blue-600 dark:text-blue-400">Facts</span>
                </a>
                <p class="mt-2 max-w-xl text-sm leading-relaxed text-gray-600 dark:text-gray-400">
                    {t("footer.mision", lang)}
                </p>
            </div>
            <div class="flex flex-wrap items-center gap-1.5" aria-label={t("menu.idioma", lang)}>
                {#each Object.entries(IDIOMAS) as [cod, info]}
                    <a
                        href={rutaEnIdioma($page.url.pathname, cod)}
                        class="rounded-md px-2.5 py-1 text-xs font-semibold no-underline transition-colors {cod === lang
                            ? 'bg-blue-600 text-white shadow-sm'
                            : 'bg-gray-200/80 text-gray-700 hover:bg-gray-300 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700'}"
                    >
                        {info.nombre}
                    </a>
                {/each}
            </div>
        </div>

        <!-- Columnas del mapa web -->
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-8">
            <!-- Columna 1: Temas principales -->
            <div>
                <h2 class="text-xs font-bold uppercase tracking-wider text-gray-900 dark:text-white">
                    <a href={enlace("/", lang)} class="text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 no-underline">
                        {t("footer.temas", lang)}
                    </a>
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

            <!-- Columna 2: Exploración y ciudades -->
            <div>
                <h2 class="text-xs font-bold uppercase tracking-wider text-gray-900 dark:text-white">
                    <a href={enlace("/varios", lang)} class="text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 no-underline">
                        {t("footer.explorar", lang)}
                    </a>
                </h2>
                <ul class="mt-3 space-y-2 text-sm list-none p-0">
                    {#each enlacesExploracion as item}
                        <li>
                            <a href={enlace(item.href, lang)} class="text-gray-600 hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400 no-underline">
                                {item.clave ? t(item.clave, lang) : item.texto[lang] ?? item.texto.es}
                            </a>
                        </li>
                    {/each}
                </ul>
            </div>

            <!-- Columna 3: Análisis y reportajes -->
            <div>
                <h2 class="text-xs font-bold uppercase tracking-wider text-gray-900 dark:text-white">
                    <a href={enlace("/analisis", lang)} class="text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 no-underline">
                        {t("footer.analisis", lang)}
                    </a>
                </h2>
                <ul class="mt-3 space-y-2 text-sm list-none p-0">
                    {#each enlacesAnalisis as item}
                        <li>
                            <a href={enlace(item.href, lang)} class="text-gray-600 hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400 no-underline">
                                {item.clave ? t(item.clave, lang) : item.texto[lang] ?? item.texto.es}
                            </a>
                        </li>
                    {/each}
                </ul>
            </div>

            <!-- Columna 4: Transparencia (enlace directo en el título y lista) -->
            <div>
                <h2 class="text-xs font-bold uppercase tracking-wider text-gray-900 dark:text-white">
                    <a href={enlace("/transparencia", lang)} class="text-blue-600 dark:text-blue-400 hover:underline">
                        {t("footer.transparencia", lang)} →
                    </a>
                </h2>
                <ul class="mt-3 space-y-2 text-sm list-none p-0">
                    {#each enlacesTransparencia as item}
                        <li>
                            <a href={enlace(item.href, lang)} class="text-gray-600 hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400 no-underline">
                                {item.clave ? t(item.clave, lang) : item.texto[lang] ?? item.texto.es}
                            </a>
                        </li>
                    {/each}
                </ul>
            </div>

            <!-- Columna 5: Método y datos abiertos (enlace directo en el título y lista) -->
            <div>
                <h2 class="text-xs font-bold uppercase tracking-wider text-gray-900 dark:text-white">
                    <a href={enlace("/fuentes", lang)} class="text-blue-600 dark:text-blue-400 hover:underline">
                        {t("footer.metodo", lang)} →
                    </a>
                </h2>
                <ul class="mt-3 space-y-2 text-sm list-none p-0">
                    {#each enlacesMetodo as item}
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
                            class="inline-flex items-center gap-1 text-gray-600 hover:text-blue-600 dark:text-gray-400 dark:hover:text-blue-400 no-underline font-medium"
                        >
                            GitHub (Open Source) ↗
                        </a>
                    </li>
                </ul>
            </div>
        </div>

        <div class="mt-12 border-t border-gray-200 pt-6 text-xs text-gray-500 dark:border-gray-800 dark:text-gray-500 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
            <p>{t("footer.licencia", lang)}</p>
            <p class="font-medium">SpainFacts.org · Inspirado en USAFacts</p>
        </div>
    </div>
</footer>
