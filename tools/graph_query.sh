#!/usr/bin/env bash
# BFS sobre el grafo. Sin LLM. Uso: bash tools/graph_query.sh "cómo funciona X" [budget]
set -euo pipefail
cd "$(dirname "$0")/.."
graphify query "$1" --budget "${2:-2000}" --graph .graph/graphify-out/graph.json
