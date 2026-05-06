#!/usr/bin/env bash
# Launch llama-server (via custom wrapper with metrics) reading models/active.json.
set -euo pipefail

cd "$(dirname "$0")/.."

PYTHON="${PYTHON:-python}"

MODEL=$($PYTHON -c 'import json; print(json.load(open("models/active.json"))["primary_model"])')
THREADS=$($PYTHON -c 'import json; hw=json.load(open("hardware.json")); print(hw["cpu"].get("cores_physical") or 4)')
GPU_LAYERS="${LAB_N_GPU_LAYERS:-99}"
PARALLEL="${LAB_PARALLEL:-4}"
CTX="${LAB_N_CTX:-2048}"

echo "==> Starting llama-server (wrapper)"
echo "    model     : $MODEL"
echo "    threads   : $THREADS"
echo "    gpu_layers: $GPU_LAYERS"
echo "    parallel  : $PARALLEL"
echo "    ctx       : $CTX"
echo "    listening : http://0.0.0.0:8080"
echo

exec $PYTHON 02-llama-cpp-server/server_with_metrics.py