#!/usr/bin/env bash
# Publica as mudanças no ar (GitHub Pages).
#
# Uso:
#   bash scripts/publicar.sh
#   bash scripts/publicar.sh "troquei a foto e marquei mais videos"
#
# Em ~1 minuto depois do push o site atualiza em
# https://raulvirgylio.github.io/portfolio/

set -euo pipefail
cd "$(dirname "$0")/.."

MSG="${1:-atualiza portfolio}"

if [ -z "$(git status --porcelain)" ]; then
  echo "Nada mudou — não há o que publicar."
  exit 0
fi

echo "--- vai subir isto: ---"
git status --short
echo

git add -A
git commit -q -m "$MSG"
git push -q origin main

echo "Publicado. Em ~1 minuto: https://raulvirgylio.github.io/portfolio/"
echo "Se não atualizar, force o recarregamento com Ctrl+F5."
