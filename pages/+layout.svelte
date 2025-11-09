<script context="module">
    export const formatNumber = (num, decimales = 2) => {
        return new Intl.NumberFormat('es-ES', {
            minimumFractionDigits: decimales,
            maximumFractionDigits: decimales
        }).format(num);
    };
    
    export const formatCurrency = (num) => {
        return new Intl.NumberFormat('es-ES', {
            style: 'currency',
            currency: 'EUR'
        }).format(num);
    };
    
    // Formatear números grandes con abreviatura (M para millones, m para miles)
    export const formatCompact = (num, decimales = 1) => {
        if (Math.abs(num) >= 1e6) {
            return formatNumber(num / 1e6, decimales) + ' M';
        } else if (Math.abs(num) >= 1e3) {
            return formatNumber(num / 1e3, decimales) + ' m';
        }
        return formatNumber(num, decimales);
    };
    
    // Formatear específicamente en millones
    export const formatMillions = (num, decimales = 2) => {
        return formatNumber(num / 1e6, decimales) + ' M';
    };
    
    // Formatear específicamente en miles
    export const formatThousands = (num, decimales = 1) => {
        return formatNumber(num / 1e3, decimales) + ' m';
    };
</script>

<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import { EvidenceDefaultLayout } from '@evidence-dev/core-components';
	export let data;
</script>

<EvidenceDefaultLayout {data} logo="/logo16.svg" builtWithEvidence={false}>
	<slot slot="content" />
</EvidenceDefaultLayout>
