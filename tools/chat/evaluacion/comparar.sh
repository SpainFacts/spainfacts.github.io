#!/usr/bin/env bash
# Compara decisores en modo decisión con las baterías de desarrollo y prueba.
#   bash tools/chat/evaluacion/comparar.sh <carpeta_salida> <modelo1> <modelo2> ... [transformers]
# "transformers" = Gemma 4 E2B con transformers.js (lo que corre en el navegador).
set -u
salida="$1"; shift
mkdir -p "$salida"
tabla="$salida/resumen.tsv"
[ -f "$tabla" ] || printf 'decisor\tdesarrollo\tprueba\tseg_desarrollo\tseg_prueba\tdetalle_prueba\n' > "$tabla"
for m in "$@"; do
	nombre="${m//[:\/]/-}"
	if [ "$m" = "transformers" ]; then motor=(--motor transformers); else motor=(--modelo "$m"); fi
	for c in desarrollo prueba; do
		node tools/chat/evaluacion/evaluar.mjs decision "${motor[@]}" --conjunto "$c" --catalogo build/chat/catalogo.json \
			--embeddings gemma256 --salida "$salida/$nombre-$c.json" > "$salida/$nombre-$c.log" 2>&1
	done
	d=$(tail -1 "$salida/$nombre-desarrollo.log"); p=$(tail -1 "$salida/$nombre-prueba.log")
	printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$m" "$(echo "$d" | grep -oE '^[0-9]+/[0-9]+')" "$(echo "$p" | grep -oE '^[0-9]+/[0-9]+')" \
		"$(echo "$d" | grep -oE '[0-9]+ s ·' | tr -d ' s·')" "$(echo "$p" | grep -oE '[0-9]+ s ·' | tr -d ' s·')" "$(echo "$p" | sed 's/.*s · //')" >> "$tabla"
	echo "$m: desarrollo $(echo "$d" | grep -oE '^[0-9]+/[0-9]+') · prueba $(echo "$p" | grep -oE '^[0-9]+/[0-9]+')"
done
