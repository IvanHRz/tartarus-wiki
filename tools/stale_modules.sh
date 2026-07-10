#!/usr/bin/env bash
# Módulos cuya página quedó atrás del código. Alimenta el paso 1 del lint.
set -euo pipefail
cd "$(dirname "$0")/.."
for f in wiki/modulos/*.md; do
  [[ -e "$f" ]] || { echo "(sin páginas de módulo)"; exit 0; }
  ref=$(grep -m1 '^commit_ref:' "$f" | awk '{print $2}')
  [[ -z "$ref" || "$ref" == "HEAD" ]] && { echo "⚠  $f — sin commit_ref fijo"; continue; }
  n=$(git -C "${REPO:-raw/repo}" log --oneline "$ref"..HEAD 2>/dev/null | wc -l | tr -d ' ')
  [[ "$n" -gt 0 ]] && echo "⚠  $f — $n commits detrás de HEAD (ref: $ref)" || echo "✓  $f"
done
