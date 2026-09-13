<script context="module">
    import { setFormatLocale } from "@evidence-dev/component-utilities/localeFormatting";
    setFormatLocale("es-ES");
    import {
        formatNumber,
        formatCurrency,
        formatCompact,
        formatMillions,
        formatThousands,
    } from "../../../../src/lib/utils.js";
    export {
        formatNumber,
        formatCurrency,
        formatCompact,
        formatMillions,
        formatThousands,
    };
</script>

<script>
    import "@evidence-dev/tailwind/fonts.css";
    import "../app.css";
    import { EvidenceDefaultLayout } from "@evidence-dev/core-components";
    import Header from "../../../../src/lib/components/Header.svelte";
    export let data;
</script>

<Header {data} />

<EvidenceDefaultLayout
    {data}
    logo="/logo16.svg"
    builtWithEvidence={false}
    hideSidebar={true}
    hideHeader={true}
>
    <slot slot="content" />
</EvidenceDefaultLayout>
