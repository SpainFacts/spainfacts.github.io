<script>
    import { Logo } from "@evidence-dev/core-components";
    import CustomKebabMenu from "./CustomKebabMenu.svelte";
    import { page } from "$app/stores";
    import { idiomaDeRuta, rutaBase, enlace, t } from "../i18n.js";

    export let data = {};

    let isMenuOpen = false;

    // Macro-categories curated for USAFacts structure
    // Rutas en castellano; el prefijo de idioma (/en, /ca...) se añade al pintar
    const enlacesBase = [
        { href: "/territorios", clave: "menu.territorios" },
        { href: "/demografia", clave: "menu.demografia" },
        { href: "/economia", clave: "menu.economia" },
        { href: "/vivienda", clave: "menu.vivienda" },
        { href: "/cuentas-publicas", clave: "menu.cuentas" },
        { href: "/energia-clima", clave: "menu.energia" },
        { href: "/movilidad", clave: "menu.movilidad" },
        { href: "/sociedad", clave: "menu.sociedad" },
        { href: "/medios", clave: "menu.medios" },
        { href: "/transparencia", clave: "menu.transparencia" },
        { href: "/varios", clave: "menu.varios" },
        { href: "/fuentes", clave: "menu.fuentes" },
    ];
    $: lang = idiomaDeRuta($page.url.pathname);
    $: navLinks = enlacesBase.map((l) => ({ ...l, base: l.href, href: enlace(l.href, lang), label: t(l.clave, lang) }));
    $: navLinksMain = navLinks.filter((l) => !["/medios", "/transparencia", "/fuentes"].includes(l.base));
    $: navLinksMore = navLinks.filter((l) => ["/medios", "/transparencia", "/fuentes"].includes(l.base));

    function toggleMenu() {
        isMenuOpen = !isMenuOpen;
    }

    // Escape cierra el menú móvil y devuelve el foco al botón que lo abrió
    let botonMenu;
    function teclaGlobal(e) {
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

<svelte:window on:keydown={teclaGlobal} />

<header
    class="bg-white/95 dark:bg-gray-900/95 backdrop-blur-md border-b border-gray-200 dark:border-gray-800 sticky top-0 z-50 transition-colors duration-200"
>
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
            <div class="flex items-center">
                <!-- Mobile menu button -->
                <div class="-ml-2 mr-2 flex items-center 2xl:hidden">
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
                <a href={enlace("/", lang)} class="flex-shrink-0 flex items-center gap-2.5 group rounded-md" aria-label={t("menu.inicio", lang)}>
                   <!-- <Logo logo="/logo16.svg" /> -->
                    <span class="font-extrabold text-lg tracking-tight text-gray-900 dark:text-white flex items-center gap-1.5">
                        Spain<span class="text-blue-600 dark:text-blue-400">Facts</span>
                    </span>
                </a>

                <!-- Desktop Navigation Menu -->
                <nav class="hidden 2xl:ml-6 2xl:flex 2xl:items-center 2xl:gap-0.5" aria-label={t("menu.principal", lang)}>
                    {#each navLinksMain as link}
                        {@const active = isLinkActive($page.url.pathname, link.base)}
                        <a
                            href={link.href}
                            aria-current={active ? "page" : undefined}
                            class="inline-flex items-center px-2.5 py-2 rounded-lg text-sm font-medium transition-all duration-150 {active
                                ? 'text-blue-600 dark:text-blue-400 bg-blue-50/80 dark:bg-blue-950/50 font-semibold'
                                : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-gray-800/60'}"
                        >
                            {link.label}
                        </a>
                    {/each}
                    <details class="relative">
                        <summary class="cursor-pointer list-none rounded-lg px-2.5 py-2 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-50 hover:text-gray-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 dark:text-gray-300 dark:hover:bg-gray-800/60 dark:hover:text-white">
                            {t("menu.otras", lang)}
                        </summary>
                        <div class="absolute right-0 top-full z-50 mt-2 min-w-52 rounded-xl border border-gray-200 bg-white p-1.5 shadow-lg dark:border-gray-700 dark:bg-gray-900">
                            {#each navLinksMore as link}
                                {@const active = isLinkActive($page.url.pathname, link.base)}
                                <a
                                    href={link.href}
                                    aria-current={active ? "page" : undefined}
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

            <!-- Actions / Kebab Menu -->
            <div class="flex items-center gap-2">
                <CustomKebabMenu />
            </div>
        </div>
    </div>

    <!-- Mobile menu, show/hide based on menu state -->
    {#if isMenuOpen}
        <nav class="2xl:hidden border-t border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 px-4 pt-2 pb-4 space-y-1 shadow-lg" id="mobile-menu" aria-label={t("menu.principal", lang)}>
            {#each navLinks as link}
                {@const active = isLinkActive($page.url.pathname, link.base)}
                <a
                    href={link.href}
                    aria-current={active ? "page" : undefined}
                    class="block px-3 py-2.5 rounded-lg text-base font-medium transition-colors {active
                        ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-950/50 font-semibold'
                        : 'text-gray-700 dark:text-gray-200 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800'}"
                    on:click={() => (isMenuOpen = false)}
                >
                    {link.label}
                </a>
            {/each}
        </nav>
    {/if}
</header>
