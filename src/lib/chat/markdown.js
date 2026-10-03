// Markdown mínimo y seguro para las respuestas del modelo: el texto se escapa entero y
// solo se reconstruyen negritas, cursivas, código, enlaces (https o rutas de la web),
// listas y párrafos. Nunca se inserta HTML que venga del modelo.

const escapar = (s) =>
	s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');

function enLinea(s) {
	return escapar(s)
		.replace(/`([^`]+)`/g, '<code>$1</code>')
		.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
		.replace(/(^|[\s(])\*([^*\s][^*]*)\*/g, '$1<em>$2</em>')
		.replace(/\[([^\]]+)\]\(((?:https:\/\/|\/)[^\s)]+)\)/g, (_, texto, url) => {
			const externo = url.startsWith('https://') && !url.startsWith('https://spainfacts.org');
			return `<a href="${url}"${externo ? ' target="_blank" rel="noopener noreferrer"' : ''}>${texto}</a>`;
		})
		.replace(/(^|\s)(https:\/\/spainfacts\.org\/[^\s<)]*)/g, '$1<a href="$2">$2</a>');
}

export function markdownSeguro(texto) {
	const bloques = String(texto ?? '').trim().split(/\n{2,}/);
	return bloques
		.map((b) => {
			const lineas = b.split('\n');
			if (lineas.every((l) => /^\s*([-*•]|\d+\.)\s+/.test(l))) {
				const ordenada = /^\s*\d+\./.test(lineas[0]);
				const items = lineas.map((l) => `<li>${enLinea(l.replace(/^\s*([-*•]|\d+\.)\s+/, ''))}</li>`).join('');
				return ordenada ? `<ol>${items}</ol>` : `<ul>${items}</ul>`;
			}
			const titulo = b.match(/^#{1,4}\s+(.*)$/);
			if (titulo && lineas.length === 1) return `<p><strong>${enLinea(titulo[1])}</strong></p>`;
			return `<p>${lineas.map(enLinea).join('<br>')}</p>`;
		})
		.join('');
}
