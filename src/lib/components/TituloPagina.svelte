<!--
    Título y descripción de páginas cuyo nombre sale de una consulta (fichas de territorio).
    Evidence ya mete en cada página su propio <svelte:head> con <title>{frontmatter.title}</title>
    (o "Evidence" si no hay title), y una página no admite un segundo <svelte:head>.
    Este componente lleva el suyo: Svelte solo conserva un <title> (el último que se renderiza,
    también al prerenderizar), así que este sustituye al de Evidence. Las páginas que lo usan no
    llevan `description` en el frontmatter para no duplicar la meta description.

    <TituloPagina nombre="Sevilla" dentro="Andalucía" descripcion="Ficha de la provincia: ..." />
      -> <title>Sevilla (Andalucía) · SpainFacts</title>
      -> <meta name="description" content="Sevilla (Andalucía). Ficha de la provincia: ...">
-->
<script>
    export let nombre = '';
    /** Territorio que lo contiene (se omite si coincide con el nombre: Cantabria, Ceuta...) */
    export let dentro = '';
    /** Descripción genérica de la página; se antepone el nombre */
    export let descripcion = '';

    $: completo = nombre && dentro && dentro !== nombre ? `${nombre} (${dentro})` : nombre;
</script>

<svelte:head>
    {#if completo}
        <title>{completo} · SpainFacts</title>
        <meta property="og:title" content="{completo} · SpainFacts" />
        <meta name="twitter:title" content="{completo} · SpainFacts" />
        {#if descripcion}
            <meta name="description" content="{completo}. {descripcion}" />
            <meta property="og:description" content="{completo}. {descripcion}" />
            <meta name="twitter:description" content="{completo}. {descripcion}" />
        {/if}
    {/if}
</svelte:head>
