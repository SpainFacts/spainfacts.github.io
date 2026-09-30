<script>
    import { page } from "$app/stores";
    import { idiomaDeRuta, t } from "../i18n.js";
    $: lang = idiomaDeRuta($page.url.pathname);
    import Button from "./ui/button/button.svelte";
    import * as DropdownMenu from "./ui/dropdown-menu";
    import { Icon } from "@steeze-ui/svelte-icon";
    // addBasePath is used for routing, we can try to import it or mock it if it fails.
    // Trying direct import first.
    import { addBasePath } from "@evidence-dev/sdk/utils/svelte";
    import {
        Settings,
        _3dCubeSphere,
        Link,
        Dots,
        Table,
        Prompt,
        Sun,
        Moon,
    } from "@steeze-ui/tabler-icons";
    import { showQueries } from "@evidence-dev/component-utilities/stores";
    import { getThemeStores } from "../themes/themes.js";
    import { dev } from "$app/environment";

    const beforeprint = new Event("export-beforeprint");
    const afterprint = new Event("export-afterprint");
    function print() {
        window.dispatchEvent(beforeprint);
        setTimeout(() => window.print(), 0);
        setTimeout(() => window.dispatchEvent(afterprint), 0);
    }

    const {
        selectedAppearance,
        activeAppearance,
        cycleAppearance,
        themesConfig,
    } = getThemeStores();

    export let neverShowQueries = false;

    $: themeLabel = t(`tema.${$selectedAppearance}`, lang);
    $: themeIcon = $activeAppearance === "light" ? Sun : Moon;
</script>

<DropdownMenu.Root>
    <DropdownMenu.Trigger asChild let:builder>
        <Button
            builders={[builder]}
            variant="ghost"
            size="sm"
            class="px-1"
            aria-label={t("opc.mas", lang)}
        >
            <Icon src={Dots} class="h-6 w-6" aria-hidden="true" />
        </Button>
    </DropdownMenu.Trigger>
    <DropdownMenu.Content class="w-52 text-xs">
        <DropdownMenu.Group>
            <DropdownMenu.Item on:click={print}>
                {t("opc.imprimir", lang)}
                <DropdownMenu.Shortcut>⌘P</DropdownMenu.Shortcut>
            </DropdownMenu.Item>
            {#if dev || !neverShowQueries}
                <DropdownMenu.Item
                    on:click={(e) => {
                        e.preventDefault();
                        showQueries.update((val) => !val);
                    }}
                >
                    {$showQueries ? t("opc.ocultar", lang) : t("opc.mostrar", lang)}
                </DropdownMenu.Item>
            {/if}

            {#if $themesConfig.appearance.switcher}
                <DropdownMenu.Item
                    on:click={(e) => {
                        e.preventDefault();
                        cycleAppearance();
                    }}
                >
                    {t("opc.apariencia", lang)}
                    <DropdownMenu.Shortcut
                        class="tracking-normal flex flex-row items-center"
                    >
                        <span class="text-xs leading-none">{themeLabel}</span>
                        <Icon src={themeIcon} class="h-4 w-4 ml-1" aria-hidden="true" />
                    </DropdownMenu.Shortcut>
                </DropdownMenu.Item>
            {/if}
        </DropdownMenu.Group>
        {#if dev}
            <DropdownMenu.Separator />
            <DropdownMenu.Group>
                <DropdownMenu.Item href={addBasePath("/settings")} el="a">
                    Settings
                    <DropdownMenu.Shortcut
                        ><Icon
                            src={Settings}
                            class="w-4 h-4"
                        /></DropdownMenu.Shortcut
                    >
                </DropdownMenu.Item>
                <DropdownMenu.Item
                    href={addBasePath("/settings/#deploy")}
                    el="a"
                >
                    Deploy
                    <DropdownMenu.Shortcut
                        ><Icon
                            src={_3dCubeSphere}
                            class="h-4 w-4"
                        /></DropdownMenu.Shortcut
                    >
                </DropdownMenu.Item>
                <DropdownMenu.Item href={addBasePath("/explore/schema")} el="a">
                    Schema Viewer
                    <DropdownMenu.Shortcut>
                        <Icon src={Table} class="h-4 w-4" />
                    </DropdownMenu.Shortcut>
                </DropdownMenu.Item>
                <DropdownMenu.Item
                    href={addBasePath("/explore/console")}
                    el="a"
                >
                    SQL Console
                    <DropdownMenu.Shortcut>
                        <Icon src={Prompt} class="h-4 w-4" />
                    </DropdownMenu.Shortcut>
                </DropdownMenu.Item>
                <DropdownMenu.Item
                    href={addBasePath("https://docs.evidence.dev")}
                    target="_blank"
                    rel="noreferrer"
                    el="a"
                >
                    Documentation
                    <DropdownMenu.Shortcut
                        ><Icon
                            src={Link}
                            class="h-4 w-4"
                        /></DropdownMenu.Shortcut
                    >
                </DropdownMenu.Item>
            </DropdownMenu.Group>
        {/if}
    </DropdownMenu.Content>
</DropdownMenu.Root>
