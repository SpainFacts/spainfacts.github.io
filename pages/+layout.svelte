<script context="module">
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
    export let data;
</script>

<EvidenceDefaultLayout {data} logo="/logo16.svg" builtWithEvidence={false}>
    <slot slot="content" />
</EvidenceDefaultLayout>
