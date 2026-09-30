<script>
	import { page } from '$app/stores';
	import { idiomaDeRuta, t as tr } from '../i18n.js';
	$: lang = idiomaDeRuta($page.url.pathname);

	// Botón "Compartir" (X, Instagram, LinkedIn, WhatsApp, Telegram, copiar enlace) para
	// las tarjetas del sitio. Las gráficas de Evidence usan una copia idéntica añadida con
	// patch-package (node_modules/@evidence-dev/core-components/.../ui/CompartirGrafico.svelte).
	export let titulo = undefined;
	/** Texto completo a compartir; si no se da, se usa "titulo · SpainFacts". */
	export let textoCompartir = undefined;
	/** Solo el icono, sin la palabra "Compartir" (para las tarjetas). */
	export let compacto = false;

	let copiado = false;
	let aviso = '';
	let menuAbierto = false;
	let boton;
	// id único para enlazar el botón con su menú (aria-controls)
	const idMenu = `compartir-${Math.random().toString(36).slice(2, 9)}`;

	// Escape cierra el menú y devuelve el foco al botón
	function tecla(e) {
		if (e.key === 'Escape' && menuAbierto) {
			e.stopPropagation();
			menuAbierto = false;
			boton?.focus();
		}
	}
	// Al salir con el tabulador del bloque, el menú se cierra
	function focoFuera(e) {
		if (!e.currentTarget.contains(e.relatedTarget)) menuAbierto = false;
	}

	const texto = () => {
		if (textoCompartir) return textoCompartir;
		const t = (titulo ?? '').toString().trim();
		const pagina = typeof document !== 'undefined' ? document.title : '';
		return t ? `${t} · SpainFacts` : pagina || 'SpainFacts';
	};
	const url = () => (typeof window !== 'undefined' ? window.location.href.split('#')[0] : 'https://spainfacts.org');

	const REDES = [
		{ id: 'x', nombre: 'X', href: () => `https://twitter.com/intent/tweet?text=${encodeURIComponent(texto())}&url=${encodeURIComponent(url())}` },
		// Instagram no tiene enlace para compartir desde la web: ver compartirInstagram()
		{ id: 'instagram', nombre: 'Instagram', especial: true },
		{ id: 'linkedin', nombre: 'LinkedIn', href: () => `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(url())}` },
		{ id: 'whatsapp', nombre: 'WhatsApp', href: () => `https://wa.me/?text=${encodeURIComponent(texto() + ' ' + url())}` },
		{ id: 'telegram', nombre: 'Telegram', href: () => `https://t.me/share/url?url=${encodeURIComponent(url())}&text=${encodeURIComponent(texto())}` }
	];

	function abrir(red) {
		if (red.id === 'instagram') return compartirInstagram();
		window.open(red.href(), '_blank', 'noopener,noreferrer,width=640,height=560');
		menuAbierto = false;
	}

	// En el móvil, el menú nativo de compartir incluye Instagram (historias, mensajes);
	// en el ordenador se copia el enlace y se abre Instagram para pegarlo.
	async function compartirInstagram() {
		menuAbierto = false;
		const movil = typeof navigator !== 'undefined' && /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
		if (movil && navigator.share) {
			try {
				await navigator.share({ title: texto(), text: texto(), url: url() });
				return;
			} catch {
				/* cancelado */
			}
		}
		try {
			await navigator.clipboard.writeText(url());
			aviso = tr('compartir.instagram', lang);
		} catch {
			aviso = tr('compartir.instagram2', lang);
		}
		setTimeout(() => (aviso = ''), 4000);
		window.open('https://www.instagram.com/', '_blank', 'noopener,noreferrer');
	}

	async function copiar() {
		try {
			await navigator.clipboard.writeText(url());
			copiado = true;
			setTimeout(() => (copiado = false), 2000);
		} catch {
			window.prompt(tr('compartir.copiar', lang), url());
		}
		menuAbierto = false;
	}

	async function compartirNativo() {
		if (typeof navigator !== 'undefined' && navigator.share) {
			try {
				await navigator.share({ title: texto(), url: url() });
				return;
			} catch {
				/* cancelado: se abre el menú */
			}
		}
		menuAbierto = !menuAbierto;
	}
</script>

<!-- svelte-ignore a11y-no-static-element-interactions -->
<div class="compartir" on:mouseleave={() => (menuAbierto = false)} on:keydown={tecla} on:focusout={focoFuera}>
	<button
		type="button"
		class="boton-pie"
		class:compacto
		bind:this={boton}
		aria-label={compacto && titulo ? `${tr('compartir', lang)}: ${titulo}` : tr('compartir', lang)}
		title={tr('compartir', lang)}
		aria-expanded={menuAbierto}
		aria-controls={idMenu}
		on:click|stopPropagation={compartirNativo}
	>
		<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"
			><circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" /><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4" /></svg
		>
		{#if !compacto || aviso || copiado}<span aria-hidden="true">{aviso || (copiado ? tr('compartir.copiado', lang) : tr('compartir', lang))}</span>{/if}
	</button>
	<!-- Aviso para lectores de pantalla cuando se copia el enlace -->
	<span class="sr-only" role="status">{aviso || (copiado ? tr('compartir.copiado', lang) : '')}</span>
	{#if menuAbierto}
		<!-- Lista de botones (patrón "disclosure"): se recorre con el tabulador -->
		<div class="menu" id={idMenu} role="group" aria-label={tr('compartir', lang)}>
			{#each REDES as red (red.id)}
				<button type="button" on:click={() => abrir(red)}>{red.nombre}<span class="sr-only"> {tr('compartir.ventana', lang)}</span></button>
			{/each}
			<button type="button" on:click={copiar}>{tr('compartir.copiar', lang)}</button>
		</div>
	{/if}
</div>

<style>
	.compartir {
		position: relative;
	}
	.boton-pie {
		display: flex;
		align-items: center;
		gap: 4px;
		cursor: pointer;
		font-family: var(--ui-font-family);
		font-size: 1em;
		color: var(--base-content);
		background: transparent;
		border: 1px solid var(--base-300);
		border-radius: 999px;
		padding: 2px 9px;
		margin: 0 3px;
		opacity: 0.85;
		transition: all 150ms;
	}
	.boton-pie.compacto {
		padding: 4px;
		border-radius: 6px;
		/* objetivo táctil mínimo de 24 × 24 px (WCAG 2.5.8) */
		min-width: 24px;
		min-height: 24px;
		justify-content: center;
	}
	.boton-pie:focus-visible,
	.menu button:focus-visible {
		outline: 2px solid var(--primary);
		outline-offset: 2px;
		opacity: 1;
	}
	.boton-pie:hover {
		opacity: 1;
		color: var(--primary);
		border-color: var(--primary);
	}
	.boton-pie :global(svg) {
		stroke: currentColor;
	}
	.menu {
		position: absolute;
		right: 0;
		bottom: calc(100% + 6px);
		z-index: 30;
		display: flex;
		flex-direction: column;
		min-width: 150px;
		padding: 4px;
		border: 1px solid var(--base-300);
		border-radius: 8px;
		background: var(--base-100);
		box-shadow: 0 6px 20px rgb(0 0 0 / 0.15);
	}
	.menu button {
		text-align: left;
		min-height: 28px;
		padding: 6px 10px;
		border: none;
		border-radius: 6px;
		background: transparent;
		color: var(--base-content);
		font-family: var(--ui-font-family);
		font-size: 13px;
		cursor: pointer;
	}
	.menu button:hover {
		background: var(--base-200);
		color: var(--primary);
	}
	@media print {
		.compartir {
			display: none;
		}
	}
</style>
