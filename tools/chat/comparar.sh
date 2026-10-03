#!/usr/bin/env bash
# Pasa las dos baterías (ajuste y control) a una lista de modelos de Ollama, en modo
# agente o decisión, y deja una fila por modelo en un TSV.
#
#   bash tools/chat/comparar.sh decision resultados.tsv catalogo.json modelo1 modelo2 ...
#   bash tools/chat/comparar.sh agente   resultados.tsv catalogo.json modelo1 ...
set -u
modo="$1"; salida="$2"; catalogo="$3"; shift 3
script=tools/chat/probar-modelo.mjs
[ "$modo" = "decision" ] && script=tools/chat/probar-decision.mjs
[ -f "$salida" ] || printf 'modo\tmodelo\tajuste\tcontrol\tsegundos_ajuste\tsegundos_control\n' > "$salida"
for m in "$@"; do
	a=$(node "$script" --modelo "$m" --catalogo "$catalogo" 2>&1 | tail -1)
	c=$(node "$script" --modelo "$m" --catalogo "$catalogo" --control 2>&1 | tail -1)
	na=$(echo "$a" | grep -oE '^[0-9]+/10'); nc=$(echo "$c" | grep -oE '^[0-9]+/10')
	sa=$(echo "$a" | grep -oE '[0-9]+ s$' | tr -d ' s'); sc=$(echo "$c" | grep -oE '[0-9]+ s$' | tr -d ' s')
	printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$modo" "$m" "${na:-error}" "${nc:-error}" "${sa:-}" "${sc:-}" >> "$salida"
	echo "$modo $m: ajuste ${na:-error} control ${nc:-error}"
done
