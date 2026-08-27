<script>
    export let data = [];
    export let filename = "datos_spainfacts.csv";
    export let label = "Descargar datos (CSV)";

    function downloadCSV() {
        if (!data || data.length === 0) return;

        // Extract headers from the first object
        const headers = Object.keys(data[0]);
        
        // Build CSV rows
        const csvRows = [];
        csvRows.push(headers.join(","));

        for (const row of data) {
            const values = headers.map(header => {
                const val = row[header];
                if (val === null || val === undefined) return '""';
                const escaped = ('' + val).replace(/"/g, '""');
                return `"${escaped}"`;
            });
            csvRows.push(values.join(","));
        }

        const csvString = csvRows.join("\n");
        const blob = new Blob([csvString], { type: "text/csv;charset=utf-8;" });
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.setAttribute("href", url);
        link.setAttribute("download", filename);
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    }
</script>

<button
    type="button"
    on:click={downloadCSV}
    class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-gray-100 hover:bg-gray-200 text-gray-700 dark:bg-gray-800 dark:hover:bg-gray-700 dark:text-gray-200 border border-gray-300 dark:border-gray-700 transition-colors shadow-sm cursor-pointer"
>
    <svg class="w-3.5 h-3.5 text-gray-500 dark:text-gray-400" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" />
    </svg>
    {label}
</button>
