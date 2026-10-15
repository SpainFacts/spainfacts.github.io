#!/bin/bash
# Tras el LoRA: exportar a ONNX y medir (validacion6 y baterías viejas, con clasificador)
D=/c/Users/jota/Documents/GitHub/spainfacts.github.io/.claude/worktrees/distracted-dirac-68763f/tools/chat/entrenamiento
until grep -q "reserva después" $D/runs/decider08-lora/registro.txt; do sleep 60; done
cd $D
HF_HOME=/c/Users/jota/.cache/huggingface CUDA_VISIBLE_DEVICES= /c/Users/jota/venvs/rocm/Scripts/python.exe -u exportar-onnx.py --referencia /c/Users/jota/venvs/onnx-qwen --modelo Mapika/decider-0.8b --lora runs/decider08-lora/lora --salida /c/Users/jota/venvs/onnx-decider/decider-08-lora > runs/exportar-lora.log 2>&1
bash $D/exp/medir.sh v6-lora-clas onnx:C:/Users/jota/venvs/onnx-decider/decider-08-lora v6
bash $D/exp/medir.sh viejas-lora-clas onnx:C:/Users/jota/venvs/onnx-decider/decider-08-lora viejas
echo hecho > $D/runs/tras-entrenar.hecho
