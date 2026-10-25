<!-- Patrón de rayado para «sin datos» en los mapas. Cada mapa incluye uno (todos iguales, mismo id):
     un SVG de tamaño cero, no display:none, porque los patrones de un SVG oculto no se pintan -->
<script>
    import { RAYADO } from '../escalaMapa.js';
</script>

<svg width="0" height="0" style="position:absolute" aria-hidden="true" focusable="false">
    <defs>
        <pattern id={RAYADO} width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
            <rect width="6" height="6" class="fill-gray-100 dark:fill-gray-800" />
            <line x1="0" y1="0" x2="0" y2="6" class="stroke-gray-400 dark:stroke-gray-500" stroke-width="2" />
        </pattern>
    </defs>
</svg>
