#!/bin/bash
# Comparación de decisores con y sin clasificador sobre las 6 baterías viejas + validacion6
# (270 preguntas), con el catálogo de build/chat y los parquets limpios de la integración.
#   bash tools/chat/entrenamiento/comparar.sh gpu   -> Ollama (Ministral, Gemma) y decider con LoRA en servir.py
#   bash tools/chat/entrenamiento/comparar.sh cpu   -> motor del navegador (ONNX en Node): decider con LoRA y Gemma
R=C:/Users/jota/Documents/GitHub/spainfacts.github.io
cd $R
export SPAINFACTS_PARQUETS=data/parquets-integracion
E=tools/chat/evaluacion
B=$E/preguntas-desarrollo.json,$E/preguntas-prueba.json,$E/preguntas-validacion2.json,$E/preguntas-validacion3.json,$E/preguntas-validacion4.json,$E/preguntas-validacion5.json,$E/preguntas-validacion6.json
D=tools/chat/entrenamiento
OUT=$D/resultados/comparacion
mkdir -p $OUT
CLAS="--clasificador $D/clasificador.json"
medir() { # nombre decisor [opciones...]
	local n=$1 dec=$2; shift 2
	[ -f $OUT/$n.json ] && return
	node $D/evaluar-decisor.mjs --decisor "$dec" --bateria $B --salida $OUT/$n.json "$@" > $OUT/$n.log 2>&1
}
if [ "$1" = gpu ]; then
	medir ministral ollama:ministral-3:3b
	medir ministral-clas ollama:ministral-3:3b $CLAS
	medir gemma ollama:gemma4:e2b
	medir gemma-clas ollama:gemma4:e2b $CLAS
	# decider-0.8b + LoRA en bf16 (servidor local en la gráfica)
	HF_HOME=C:/Users/jota/.cache/huggingface C:/Users/jota/venvs/rocm/Scripts/python.exe -u $D/servir.py --modelo Mapika/decider-0.8b --lora $D/runs/decider08-lora/lora --puerto 8767 > $OUT/servir.log 2>&1 &
	SERV=$!
	until curl -s -m 5 -X POST localhost:8767/decidir -H "Content-Type: application/json" -d '{"prompt":"x Answer: (","n":2}' | grep -q probs; do sleep 10; done
	medir decider-lora-clas http://127.0.0.1:8767 $CLAS
	medir decider-lora http://127.0.0.1:8767
	kill $SERV
else
	DT='{"embed_tokens":"fp16","decoder_model_merged":"q4"}'
	medir onnx-decider-lora-clas onnx:C:/Users/jota/venvs/onnx-decider/decider-08-lora --dtype "$DT" $CLAS
	medir onnx-gemma-clas onnx:onnx-community/gemma-4-E2B-it-ONNX --dtype q4 $CLAS
	medir onnx-gemma onnx:onnx-community/gemma-4-E2B-it-ONNX --dtype q4
fi
echo hecho > $OUT/$1.hecho
