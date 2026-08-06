#!/usr/bin/env bash
# Commits del repo desde la última entrada de bitácora en log.md.
# Uso: bash tools/git_digest.sh [ref_inicial]
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="${REPO:-.raw/repo}"

LAST="${1:-}"
if [[ -z "$LAST" ]]; then
  # busca el último commit_ref citado en una entrada de bitacora/release
  LAST=$(grep -oE '`[0-9a-f]{7,40}`' log.md 2>/dev/null | tr -d '`' | tail -1 || true)
fi

if [[ -z "$LAST" ]]; then
  echo "### Sin ref previa — mostrando últimos 30 commits"
  git -C "$REPO" log --oneline -30
else
  echo "### Commits desde $LAST"
  git -C "$REPO" log --oneline "$LAST"..HEAD
  echo
  echo "### Archivos tocados"
  git -C "$REPO" diff --stat "$LAST"..HEAD | tail -30
fi
echo
echo "### HEAD"
git -C "$REPO" log -1 --format='%h %ad %s' --date=short
