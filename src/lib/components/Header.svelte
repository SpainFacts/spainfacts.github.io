<script>
    import { Logo } from "@evidence-dev/core-components";
    import CustomKebabMenu from "./CustomKebabMenu.svelte";
    import { page } from "$app/stores";

    export let data = {};

    let isMenuOpen = false;

    $: pagesManifest = data?.pagesManifest || $page.data?.pagesManifest || {};

    $: {
        console.log("Header data:", data);
        console.log("Header pagesManifest:", pagesManifest);
    }

    $: navLinks = processManifest(pagesManifest);

    function processManifest(manifest) {
        const links = [];

        // Always add Home first
        links.push({ href: "/", label: "Inicio" });

        if (!manifest || !manifest.children) return links;

        // Iterate over children of the root manifest
        Object.entries(manifest.children).forEach(([key, child]) => {
            // Skip if it's not a directory or page we want to show?
            // The key is the folder/file name.
            // child.href should be the full path.

            const href = child.href;
            if (href === "/") return; // Skip home as we added it manually

            let label = child.title || child.frontMatter?.title;

            if (!label) {
                // Fallback to capitalizing the key (folder name)
                label = key.charAt(0).toUpperCase() + key.slice(1);
            }

            links.push({ href, label });
        });

        // Sort links alphabetically or by some other criteria if needed
        // links.sort((a, b) => a.label.localeCompare(b.label));

        return links;
    }

    function toggleMenu() {
        isMenuOpen = !isMenuOpen;
    }
</script>

<header
    class="bg-base-100 border-b border-base-300 sticky top-0 z-50 transition-colors duration-300"
>
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <!-- DEBUG: {JSON.stringify(Object.keys(data || {}))} -->
        <!-- DEBUG PAGE DATA: {JSON.stringify(Object.keys($page.data || {}))} -->
        <div class="flex justify-between h-16">
            <div class="flex">
                <!-- Mobile menu button -->
                <div class="-ml-2 mr-2 flex items-center sm:hidden">
                    <button
                        type="button"
                        class="bg-base-100 inline-flex items-center justify-center p-2 rounded-md text-base-content hover:text-primary hover:bg-base-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
                        aria-controls="mobile-menu"
                        aria-expanded={isMenuOpen}
                        on:click={toggleMenu}
                    >
                        <span class="sr-only">Open main menu</span>
                        {#if isMenuOpen}
                            <svg
                                class="block h-6 w-6"
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                aria-hidden="true"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                        {:else}
                            <svg
                                class="block h-6 w-6"
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                aria-hidden="true"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M4 6h16M4 12h16M4 18h16"
                                />
                            </svg>
                        {/if}
                    </button>
                </div>
                <div class="flex-shrink-0 flex items-center">
                    <Logo logo="/logo16.svg" />
                </div>
                <!-- Desktop Menu -->
                <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
                    {#each navLinks as link}
                        <a
                            href={link.href}
                            class="border-transparent text-base-content hover:border-base-300 hover:text-primary inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors {$page
                                .url.pathname === link.href
                                ? 'border-primary text-primary'
                                : ''}"
                        >
                            {link.label}
                        </a>
                    {/each}
                </div>
            </div>
            <div class="flex items-center">
                <CustomKebabMenu />
            </div>
        </div>
    </div>

    <!-- Mobile menu, show/hide based on menu state -->
    {#if isMenuOpen}
        <div class="sm:hidden" id="mobile-menu">
            <div class="pt-2 pb-3 space-y-1">
                {#each navLinks as link}
                    <a
                        href={link.href}
                        class="border-transparent text-base-content hover:bg-base-200 hover:text-primary block pl-3 pr-4 py-2 border-l-4 text-base font-medium {$page
                            .url.pathname === link.href
                            ? 'border-primary text-primary bg-base-200'
                            : ''}"
                        on:click={() => (isMenuOpen = false)}
                    >
                        {link.label}
                    </a>
                {/each}
            </div>
        </div>
    {/if}
</header>
