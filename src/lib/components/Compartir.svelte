<script>
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
			aviso = 'Enlace copiado: pégalo en Instagram';
		} catch {
			aviso = 'Copia el enlace de la página para pegarlo en Instagram';
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
			window.prompt('Copia el enlace:', url());
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

<div class="compartir" on:mouseleave={() => (menuAbierto = false)}>
	<button type="button" class="boton-pie" class:compacto aria-label="Compartir" title="Compartir" aria-haspopup="true" aria-expanded={menuAbierto} on:click|stopPropagation={compartirNativo}>
		<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
			><circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" /><path d="M8.6 13.5l6.8 4M15.4 6.5l-6.8 4" /></svg
		>
		{#if !compacto || aviso || copiado}<span>{aviso || (copiado ? 'Enlace copiado' : 'Compartir')}</span>{/if}
	</button>
	{#if menuAbierto}
		<div class="menu" role="menu">
			{#each REDES as red (red.id)}
				<button type="button" role="menuitem" on:click={() => abrir(red)}>{red.nombre}</button>
			{/each}
			<button type="button" role="menuitem" on:click={copiar}>Copiar enlace</button>
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
