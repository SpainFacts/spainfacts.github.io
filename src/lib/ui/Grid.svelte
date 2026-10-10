<script context="module">
    export const evidenceInclude = true;
</script>

<script>
    export let columns = 2;
    columns = parseInt(columns);
    $: tabletColumns = Math.min(columns, 3);

    export let gapWidth = 10;
</script>

<div class="grid" style="--grid-columns: {columns}; --tablet-columns: {tabletColumns}; column-gap: {gapWidth}px;">
    <slot></slot>
</div>

<style>
    .grid {
        display: grid;
        grid-template-columns: repeat(var(--grid-columns), minmax(0, 1fr));
    }

    @media screen and (max-width: 1100px) {
        .grid {
            grid-template-columns: repeat(var(--tablet-columns), minmax(0, 1fr));
        }
    }

    @media screen and (max-width: 640px) {
        .grid {
            grid-template-columns: minmax(0, 1fr);
        }
    }
</style>