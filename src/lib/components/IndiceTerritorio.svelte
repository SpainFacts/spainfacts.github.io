<script>
    import { tick } from 'svelte';
    import { page } from '$app/stores';
    import { idiomaDeRuta, t } from '../i18n.js';

    let headings = [];
    let currentPath = '';
    $: lang = idiomaDeRuta($page.url.pathname);
    $: if (typeof document !== 'undefined' && $page.url.pathname !== currentPath) cargarIndice($page.url.pathname);

    async function cargarIndice(path) {
        currentPath = path;
        headings = [];
        if (!/^\/(?:en\/|ca\/|gl\/|eu\/)?territorios\/[^/]+(?:\/[^/]+)?\/?$/.test(path)) return;
        await tick();
        if (path !== $page.url.pathname) return;
        const article = document.getElementById('evidence-main-article');
        headings = Array.from(article?.querySelectorAll('h2[id]') ?? [])
            .map((heading) => ({ id: heading.id, title: heading.textContent?.trim() ?? '' }))
            .filter((heading) => heading.id && heading.title);
    }
</script>

{#if headings.length >= 6}
    <nav class="my-5 rounded-lg border border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-700 dark:bg-gray-900" aria-label={t('territorio.indice.aria', lang)}>
        <details>
            <summary class="cursor-pointer font-medium text-gray-800 dark:text-gray-100">{t('territorio.indice.titulo', lang)}</summary>
            <ol class="mt-3 flex flex-wrap gap-x-5 gap-y-2 pl-5 text-sm">
                {#each headings as heading (heading.id)}
                    <li><a class="text-blue-700 underline dark:text-blue-300" href="#{heading.id}">{heading.title}</a></li>
                {/each}
            </ol>
        </details>
    </nav>
{/if}
