<script>
    import { Logo } from "@evidence-dev/core-components";
    import CustomKebabMenu from "./CustomKebabMenu.svelte";
    import { page } from "$app/stores";

    export let data = {};

    let isMenuOpen = false;

    // Macro-categories curated for USAFacts structure
    const navLinks = [
        { href: "/", label: "Inicio" },
        { href: "/demografia", label: "Demografía" },
        { href: "/economia", label: "Economía" },
        { href: "/cuentas-publicas", label: "Cuentas Públicas" },
        { href: "/energia-clima", label: "Energía & Clima" },
        { href: "/indicadores", label: "Indicadores" },
        { href: "/observatorios", label: "Observatorios" },
        { href: "/fuentes", label: "Fuentes" },
    ];

    function toggleMenu() {
        isMenuOpen = !isMenuOpen;
    }

    function isLinkActive(pathname, href) {
        if (href === "/") {
            return pathname === "/";
        }
        return pathname.startsWith(href);
    }
</script>

<header
    class="bg-white/95 dark:bg-gray-900/95 backdrop-blur-md border-b border-gray-200 dark:border-gray-800 sticky top-0 z-50 transition-colors duration-200"
>
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
            <div class="flex items-center">
                <!-- Mobile menu button -->
                <div class="-ml-2 mr-2 flex items-center lg:hidden">
                    <button
                        type="button"
                        class="inline-flex items-center justify-center p-2 rounded-lg text-gray-600 hover:text-gray-900 hover:bg-gray-100 dark:text-gray-300 dark:hover:text-white dark:hover:bg-gray-800 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        aria-controls="mobile-menu"
                        aria-expanded={isMenuOpen}
                        on:click={toggleMenu}
                    >
                        <span class="sr-only">Abrir menú principal</span>
                        {#if isMenuOpen}
                            <svg class="block h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                        {:else}
                            <svg class="block h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                            </svg>
                        {/if}
                    </button>
                </div>

                <!-- Brand Logo & Name -->
                <a href="/" class="flex-shrink-0 flex items-center gap-2.5 group">
                    <Logo logo="/logo16.svg" />
                    <span class="font-extrabold text-lg tracking-tight text-gray-900 dark:text-white flex items-center gap-1.5">
                        Spain<span class="text-blue-600 dark:text-blue-400">Facts</span>
                        <span class="hidden sm:inline-block text-[10px] uppercase font-bold tracking-wider px-1.5 py-0.5 rounded bg-blue-100 text-blue-700 dark:bg-blue-900/50 dark:text-blue-300 border border-blue-200 dark:border-blue-800">
                            Datos Oficiales
                        </span>
                    </span>
                </a>

                <!-- Desktop Navigation Menu -->
                <nav class="hidden lg:ml-8 lg:flex lg:space-x-1" aria-label="Navegación principal">
                    {#each navLinks as link}
                        {@const active = isLinkActive($page.url.pathname, link.href)}
                        <a
                            href={link.href}
                            class="inline-flex items-center px-3 py-2 rounded-lg text-sm font-medium transition-all duration-150 {active
                                ? 'text-blue-600 dark:text-blue-400 bg-blue-50/80 dark:bg-blue-950/50 font-semibold'
                                : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-gray-800/60'}"
                        >
                            {link.label}
                        </a>
                    {/each}
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
        <div class="lg:hidden border-t border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900 px-4 pt-2 pb-4 space-y-1 shadow-lg" id="mobile-menu">
            {#each navLinks as link}
                {@const active = isLinkActive($page.url.pathname, link.href)}
                <a
                    href={link.href}
                    class="block px-3 py-2.5 rounded-lg text-base font-medium transition-colors {active
                        ? 'text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-950/50 font-semibold'
                        : 'text-gray-700 dark:text-gray-200 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-800'}"
                    on:click={() => (isMenuOpen = false)}
                >
                    {link.label}
                </a>
            {/each}
        </div>
    {/if}
</header>
