#!/bin/bash
# Lanza una medida de evaluar-decisor.mjs con el catálogo y el clasificador propios.
#   bash medir.sh <nombre> <decisor> <baterias: v6|viejas> [sin-clas]
W=/c/Users/jota/Documents/GitHub/spainfacts.github.io/.claude/worktrees/distracted-dirac-68763f
R=$W/tools/chat/entrenamiento/resultados
E2=tools/chat/evaluacion
if [ "$3" = v6 ]; then B=$W/tools/chat/evaluacion/preguntas-validacion6.json; else B=$E2/preguntas-desarrollo.json,$E2/preguntas-prueba.json,$E2/preguntas-validacion2.json,$E2/preguntas-validacion3.json,$E2/preguntas-validacion4.json,$E2/preguntas-validacion5.json; fi
CLAS="--clasificador $W/tools/chat/entrenamiento/clasificador.json"
[ "$4" = sin-clas ] && CLAS=""
cd /c/Users/jota/Documents/GitHub/spainfacts.github.io
node $W/tools/chat/entrenamiento/evaluar-decisor.mjs --catalogo $W/tools/chat/entrenamiento/datos/catalogo.json --dtype '{"embed_tokens":"fp16","decoder_model_merged":"q4"}' $CLAS --decisor "$2" --bateria "$B" --salida $R/$1.json > $R/$1.log 2>&1
