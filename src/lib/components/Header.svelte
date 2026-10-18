<script>
    import { Logo } from "@evidence-dev/core-components";
    import CustomKebabMenu from "./CustomKebabMenu.svelte";
    import BuscadorGlobal from "./BuscadorGlobal.svelte";
    import { page } from "$app/stores";
    import { idiomaDeRuta, rutaBase, enlace, t } from "../i18n.js";

    export let data = {};

    let isMenuOpen = false;
    let buscadorAbierto = false;

    // Macro-categories curated for USAFacts structure:
    // Temas siempre visibles + sección de Análisis (blog de datos) + herramientas en «Más»
    const enlacesBase = [
        { href: "/territorios", clave: "menu.territorios" },
        { href: "/demografia", clave: "menu.demografia" },
        { href: "/economia", clave: "menu.economia" },
        { href: "/vivienda", clave: "menu.vivienda" },
        { href: "/cuentas-publicas", clave: "menu.cuentas" },
        { href: "/energia-clima", clave: "menu.energia" },
        { href: "/movilidad", clave: "menu.movilidad" },
        { href: "/sociedad", clave: "menu.sociedad" },
        { href: "/analisis", clave: "menu.analisis", esAnalisis: true },
        { href: "/transparencia", clave: "menu.transparencia" },
        { href: "/medios", clave: "menu.medios" },
        { href: "/varios", clave: "menu.varios" },
        { href: "/chat", clave: "menu.chat" },
        { href: "/fuentes", clave: "menu.fuentes" },
    ];
    $: lang = idiomaDeRuta($page.url.pathname);
    $: navLinks = enlacesBase.map((l) => ({ ...l, base: l.href, href: enlace(l.href, lang), label: t(l.clave, lang) }));
    $: navLinksMain = navLinks.filter((l) => !["/transparencia", "/medios", "/varios", "/chat", "/fuentes"].includes(l.base));
    $: navLinksMore = navLinks.filter((l) => ["/transparencia", "/medios", "/varios", "/chat", "/fuentes"].includes(l.base));

    function toggleMenu() {
        isMenuOpen = !isMenuOpen;
    }

    // «Más» es un <details>: el navegador no lo cierra al navegar (SvelteKit no recarga
    // la página) ni al pulsar fuera, y se quedaba abierto tapando el contenido
    let menuMas;
    $: $page.url.pathname, menuMas && (menuMas.open = false);
    function clicGlobal(e) {
        if (menuMas?.open && !menuMas.contains(e.target)) menuMas.open = false;
    }

    // Escape cierra el menú móvil y devuelve el foco al botón que lo abrió
    let botonMenu;
    function teclaGlobal(e) {
        if (e.key === "Escape" && menuMas?.open) menuMas.open = false;
        if (e.key === "Escape" && isMenuOpen) {
            isMenuOpen = false;
            botonMenu?.focus();
        }
    }

    // Se compara sin el prefijo de idioma
    function isLinkActive(pathname, href) {
        const ruta = rutaBase(pathname);
        if (href === "/") {
            return ruta === "/";
        }
        return ruta.startsWith(href);
    }
</script>

<svelte:window on:keydown={teclaGlobal} on:click={clicGlobal} />

<header
    class="bg-white/95 dark:bg-gray-900/95 backdrop-blur-md border-b border-gray-200 dark:border-gray-800 sticky top-0 z-50 transition-colors duration-200"
>
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
            <div class="flex items-center min-w-0">
                <!-- Mobile menu button -->
                <div class="-ml-2 mr-2 flex items-center xl:hidden">
                    <button
                        type="button"
                        class="inline-flex items-center justify-center p-2 rounded-lg text-gray-600 hover:text-gray-900 hover:bg-gray-100 dark:text-gray-300 dark:hover:text-white dark:hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        aria-controls="mobile-menu"
                        aria-expanded={isMenuOpen}
                        bind:this={botonMenu}
                        on:click={toggleMenu}
                    >
                        <span class="sr-only">{isMenuOpen ? t("menu.cerrar", lang) : t("menu.abrir", lang)}</span>
                        {#if isMenuOpen}
                            <svg class="block h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true" focusable="false">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                        {:else}
                            <svg class="block h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true" focusable="false">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                            </svg>
                        {/if}
                    </button>
                </div>

                <!-- Brand Logo & Name -->
                <a href={enlace("/", lang)} class="flex-shrink-0 flex items-center gap-2 group rounded-md" aria-label={t("menu.inicio", lang)}>
                    <span class="font-extrabold text-lg tracking-tight text-gray-900 dark:text-white flex items-center gap-1">
                        Spain<span class="text-blue-600 dark:text-blue-400">Facts</span>
                    </span>
                </a>

                <!-- Desktop Navigation Menu (visible from xl: 1280px+) -->
                <nav class="hidden xl:ml-4 xl:flex xl:items-center xl:gap-0.5" aria-label={t("menu.principal", lang)}>
                    {#each navLinksMain as link}
                        {@const active = isLinkActive($page.url.pathname, link.base)}
                        <a
                            href={link.href}
                            aria-current={active ? "page" : undefined}
                            class="inline-flex items-center gap-1 px-2 py-1.5 rounded-lg text-[13px] font-medium whitespace-nowrap transition-all duration-150 {active
                                ? 'text-blue-600 dark:text-blue-400 bg-blue-50/80 dark:bg-blue-950/50 font-semibold'
                                : link.esAnalisis
                                  ? 'text-indigo-700 dark:text-indigo-300 bg-indigo-50/70 dark:bg-indigo-950/40 hover:bg-indigo-100/80 dark:hover:bg-indigo-900/50 font-semibold'
                                  : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-gray-800/60'}"
                        >
                            {#if link.esAnalisis}
                                <span class="h-1.5 w-1.5 rounded-full bg-indigo-500" aria-hidden="true"></span>
                            {/if}
                            {link.label}
                        </a>
                    {/each}
                    <details class="relative" bind:this={menuMas}>
                        <summary class="cursor-pointer list-none rounded-lg px-2 py-1.5 text-[13px] font-medium whitespace-nowrap text-gray-600 transition-colors hover:bg-gray-50 hover:text-gray-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 dark:text-gray-300 dark:hover:bg-gray-800/60 dark:hover:text-white">
                            {t("menu.otras", lang)} ▾
                        </summary>
                        <div class="absolute right-0 top-full z-50 mt-2 min-w-56 rounded-xl border border-gray-200 bg-white p-1.5 shadow-lg dark:border-gray-700 dark:bg-gray-900">
                            {#each navLinksMore as link}
                                {@const active = isLinkActive($page.url.pathname, link.base)}
                                <a
                                    href={link.href}
                                    aria-current={active ? "page" : undefined}
                                    on:click={() => (menuMas.open = false)}
                                    class="block rounded-lg px-3 py-2 text-sm font-medium {active
                                        ? 'bg-blue-50 text-blue-700 dark:bg-blue-950/50 dark:text-blue-300'
                                        : 'text-gray-700 hover:bg-gray-50 dark:text-gray-200 dark:hover:bg-gray-800'}"
                                >
                                    {link.label}
                                </a>
                            {/each}
                        </div>
                    </details>
                </nav>
            </div>

            <!-- Actions: Global Search (⌘K) + Kebab Menu -->
            <div class="flex items-center gap-1.5 sm:gap-2">
                <button
                    type="button"
                    on:click={() => (buscadorAbierto = true)}
                    aria-label={t("menu.buscar", lang)}
                    class="inline-flex items-center gap-2 rounded-xl border border-gray-200 bg-gray-50/90 px-2.5 py-1.5 text-xs font-medium text-gray-600 transition-colors hover:border-blue-400 hover:bg-white hover:text-gray-900 dark:border-gray-700 dark:bg-gray-800/80 dark:text-gray-300 dark:hover:border-blue-500 dark:hover:text-white"
                >
                    <svg class="h-4 w-4 text-gray-500 dark:text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
                    </svg>
                    <span class="hidden sm:inline">{t("menu.buscar", lang)}</span>
                    <kbd class="hidden md:inline-block rounded border border-gray-300 bg-white px-1.5 py-0.5 text-[10px] font-semibold text-gray-500 dark:border-gray-600 dark:bg-gray-900 dark:text-gray-400">
                        ⌘K
                    </kbd>
                </button>
                <CustomKebabMenu />
            </div>
        </div>
    </div>

    <!-- Mobile menu, show/hide based on menu state -->
    {#if isMenuOpen}
        <nav class="xl:hidden border-t border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 px-4 pt-2 pb-4 space-y-1 shadow-lg" id="mobile-menu" aria-label={t("menu.principal", lang)}>
            {#each navLinks as link}
                {@const active = isLinkActive($page.url.pathname, link.base)}
                <a
                    href={link.href}
                    aria-current={active ? "page" : undefined}
                    class="flex items-center justify-between px-3 py-2.5 rounded-lg text-base font-medium transition-colors {active
                        ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-950/50 font-semibold'
                        : 'text-gray-700 dark:text-gray-200 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800'}"
                    on:click={() => (isMenuOpen = false)}
                >
                    <span>{link.label}</span>
                    {#if link.esAnalisis}
                        <span class="rounded-full bg-indigo-100 dark:bg-indigo-950 px-2 py-0.5 text-xs font-semibold text-indigo-700 dark:text-indigo-300">Blog</span>
                    {/if}
                </a>
            {/each}
        </nav>
    {/if}
</header>

<BuscadorGlobal bind:abierto={buscadorAbierto} />
