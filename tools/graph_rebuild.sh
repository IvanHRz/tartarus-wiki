#!/usr/bin/env bash
# Reconstruye el grafo del repo. 100% LOCAL: Tree-sitter + Leiden, cero llamadas a un LLM.
#   --semantic  añade extracción semántica de prosa (SÍ llama al modelo configurado)
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="$(cd .raw/repo && pwd -P)"
OUT="$PWD/.graph"

command -v graphify >/dev/null || { echo "falta graphify: pip install graphifyy"; exit 1; }

if [[ "${1:-}" == "--semantic" ]]; then
  echo "⚠  extracción semántica: envía descripciones de docs al LLM configurado"
  graphify extract "$REPO" --out "$OUT"
else
  graphify extract "$REPO" --code-only --no-cluster --out "$OUT"
  graphify cluster-only "$OUT" --no-label --no-viz
fi

echo
echo "→ $OUT/graphify-out/GRAPH_REPORT.md"
graphify benchmark "$OUT/graphify-out/graph.json" 2>/dev/null | grep -i reduction || true
