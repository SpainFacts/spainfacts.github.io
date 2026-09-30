<script>
    import { slide, fade } from "svelte/transition";
    import { page } from "$app/stores";
    import { idiomaDeRuta, t, tf } from "../i18n.js";
    $: lang = idiomaDeRuta($page.url.pathname);

    export let data = [];
    export let columns = [];
    export let title = undefined;
    export let rows = 10;
    export let downloadable = true;
    export let searchable = true;

    let currentPage = 1;
    let searchTerm = "";
    let sortColumn = null;
    let sortDirection = "asc";
    let isHovered = false;
    let showSearch = false;

    // Filtrado
    $: filteredData = data.filter((row) => {
        if (!searchTerm) return true;
        const term = searchTerm.toLowerCase();
        return columns.some((col) => {
            const val = row[col.accessor];
            return String(val).toLowerCase().includes(term);
        });
    });

    // Ordenación
    $: sortedData = [...filteredData].sort((a, b) => {
        if (!sortColumn) return 0;
        const valA = a[sortColumn];
        const valB = b[sortColumn];

        if (valA < valB) return sortDirection === "asc" ? -1 : 1;
        if (valA > valB) return sortDirection === "asc" ? 1 : -1;
        return 0;
    });

    // Paginación
    $: totalPages = Math.ceil(sortedData.length / rows);
    $: paginatedData = sortedData.slice(
        (currentPage - 1) * rows,
        currentPage * rows,
    );

    $: if (searchTerm) currentPage = 1;

    function handleSort(columnAccessor) {
        if (sortColumn === columnAccessor) {
            sortDirection = sortDirection === "asc" ? "desc" : "asc";
        } else {
            sortColumn = columnAccessor;
            sortDirection = "asc";
        }
    }

    function downloadCSV() {
        const headers = columns.map((c) => c.title).join(",");
        const rowsCSV = sortedData
            .map((row) => {
                return columns
                    .map((col) => {
                        let val = row[col.accessor];
                        if (typeof val === "string") {
                            val = val.replace(/"/g, '""');
                            if (val.includes(",")) val = `"${val}"`;
                        }
                        return val;
                    })
                    .join(",");
            })
            .join("\n");

        const csvContent = `${headers}\n${rowsCSV}`;
        const blob = new Blob([csvContent], {
            type: "text/csv;charset=utf-8;",
        });
        const link = document.createElement("a");
        const url = URL.createObjectURL(blob);
        link.setAttribute("href", url);
        link.setAttribute("download", `${title || "data"}.csv`);
        link.style.visibility = "hidden";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    function nextPage() {
        if (currentPage < totalPages) currentPage++;
    }

    function prevPage() {
        if (currentPage > 1) currentPage--;
    }
</script>

<div
    class="w-full my-4 font-sans text-sm group relative"
    on:mouseenter={() => (isHovered = true)}
    on:mouseleave={() => (isHovered = false)}
>
    {#if title}
        <h3
            class="text-base font-semibold text-gray-900 dark:text-gray-100 mb-2"
        >
            {title}
        </h3>
    {/if}

    <div
        class="overflow-x-auto w-full border-b border-gray-200 dark:border-gray-700"
    >
        <table class="w-full text-left border-collapse">
            {#if title}<caption class="sr-only">{title}</caption>{/if}
            <thead>
                <tr class="border-b border-gray-200 dark:border-gray-700">
                    {#each columns as col}
                        <th
                            scope="col"
                            aria-sort={sortColumn === col.accessor ? (sortDirection === "asc" ? "ascending" : "descending") : undefined}
                            class="py-1 px-2 font-semibold text-xs text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200 select-none whitespace-nowrap {col.align ===
                            'right'
                                ? 'text-right'
                                : 'text-left'}"
                        >
                            <!-- Botón para poder ordenar también con el teclado -->
                            <button
                                type="button"
                                class="inline-flex min-h-6 items-center gap-1 cursor-pointer font-semibold"
                                on:click={() => handleSort(col.accessor)}
                            >
                                {col.title}
                                {#if sortColumn === col.accessor}
                                    <span class="text-[10px] text-gray-500 dark:text-gray-400" aria-hidden="true">
                                        {#if sortDirection === "asc"}▲{:else}▼{/if}
                                    </span>
                                {/if}
                            </button>
                        </th>
                    {/each}
                </tr>
            </thead>
            <tbody class="text-sm">
                {#each paginatedData as row}
                    <tr
                        class="border-b border-gray-100 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors"
                    >
                        {#each columns as col}
                            <td
                                class="py-1 px-2 text-gray-700 dark:text-gray-300 whitespace-nowrap {col.align ===
                                'right'
                                    ? 'text-right'
                                    : 'text-left'} font-variant-numeric tabular-nums"
                            >
                                {#if col.fmt}
                                    {@html col.fmt(row[col.accessor])}
                                {:else}
                                    {row[col.accessor]}
                                {/if}
                            </td>
                        {/each}
                    </tr>
                {/each}
                {#if paginatedData.length === 0}
                    <tr>
                        <td
                            colspan={columns.length}
                            class="py-4 text-center text-gray-500 text-xs"
                        >
                            {t("tabla.sinDatos", lang)}
                        </td>
                    </tr>
                {/if}
            </tbody>
        </table>
    </div>

    <!-- Footer Controls (Pagination & Actions) -->
    <div class="flex justify-between items-center py-1 mt-1 min-h-[28px]">
        <!-- Pagination -->
        <div class="flex items-center gap-2 text-xs text-gray-500 dark:text-gray-400">
            {#if totalPages > 1}
                <button
                    type="button"
                    aria-label={t("tabla.anterior", lang)}
                    class="min-h-6 min-w-6 hover:text-gray-900 dark:hover:text-gray-300 disabled:opacity-30 disabled:cursor-not-allowed"
                    on:click={prevPage}
                    disabled={currentPage === 1}
                >
                    <span aria-hidden="true">←</span>
                </button>
                <span>
                    <span class="sr-only">{t("tabla.pagina", lang)}</span> {currentPage} / {totalPages}
                </span>
                <button
                    type="button"
                    aria-label={t("tabla.siguiente", lang)}
                    class="min-h-6 min-w-6 hover:text-gray-900 dark:hover:text-gray-300 disabled:opacity-30 disabled:cursor-not-allowed"
                    on:click={nextPage}
                    disabled={currentPage === totalPages}
                >
                    <span aria-hidden="true">→</span>
                </button>
            {/if}
            <span class="ml-2" role="status">{tf("tabla.filas", lang, { n: sortedData.length })}</span>
        </div>

        <!-- Actions (Search & Download) - Visible on Hover (y al llegar con el teclado) -->
        <div
            class="flex items-center gap-2 transition-opacity duration-200 focus-within:opacity-100 {isHovered ||
            showSearch ||
            searchTerm
                ? 'opacity-100'
                : 'opacity-0'}"
        >
            {#if showSearch || searchTerm}
                <div
                    class="relative"
                    transition:slide={{ axis: "x", duration: 200 }}
                >
                    <input
                        type="search"
                        placeholder={t("tabla.buscarPh", lang)}
                        aria-label={title ? `${t("tabla.buscarEn", lang)} ${title}` : t("tabla.buscarEn", lang)}
                        bind:value={searchTerm}
                        class="px-2 py-0.5 text-xs border rounded border-gray-300 dark:border-gray-600 bg-transparent focus:outline-none focus:border-blue-500 w-32"
                        autoFocus
                    />
                    <button
                        type="button"
                        aria-label={t("tabla.borrar", lang)}
                        class="absolute right-1 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                        on:click={() => {
                            searchTerm = "";
                            showSearch = false;
                        }}
                    >
                        <span aria-hidden="true">×</span>
                    </button>
                </div>
            {/if}

            {#if !showSearch && !searchTerm && searchable}
                <button
                    type="button"
                    on:click={() => (showSearch = true)}
                    class="p-1 min-h-6 min-w-6 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
                    title={t("tabla.buscar", lang)}
                    aria-label={t("tabla.buscarEn", lang)}
                >
                    <svg
                        aria-hidden="true"
                        focusable="false"
                        xmlns="http://www.w3.org/2000/svg"
                        width="14"
                        height="14"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        ><circle cx="11" cy="11" r="8"></circle><line
                            x1="21"
                            y1="21"
                            x2="16.65"
                            y2="16.65"
                        ></line></svg
                    >
                </button>
            {/if}

            {#if downloadable}
                <button
                    type="button"
                    on:click={downloadCSV}
                    class="p-1 min-h-6 min-w-6 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
                    title={t("tabla.csv", lang)}
                    aria-label={t("tabla.csvAria", lang)}
                >
                    <svg
                        aria-hidden="true"
                        focusable="false"
                        xmlns="http://www.w3.org/2000/svg"
                        width="14"
                        height="14"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        ><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"
                        ></path><polyline points="7 10 12 15 17 10"
                        ></polyline><line x1="12" y1="15" x2="12" y2="3"
                        ></line></svg
                    >
                </button>
            {/if}
        </div>
    </div>
</div>
