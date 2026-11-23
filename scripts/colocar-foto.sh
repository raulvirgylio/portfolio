#!/usr/bin/env bash
# Coloca uma foto sua no site, já cortada em 4:5 e no tamanho certo.
#
# Uso:
#   bash scripts/colocar-foto.sh "E:/FLI 2026/07_FOTOS/Fotos_iPhone/IMG_1234.JPG"
#
# Corta pelo centro, redimensiona pra 900x1125 e salva em assets/raulzito.jpg.
# Se o corte central cortar sua cabeça, abra o arquivo original, enquadre à mão
# e salve direto como assets/raulzito.jpg — o script é só conveniência.

set -euo pipefail

FFMPEG="${LOCALAPPDATA}/hermes/tools/ffmpeg-9.0.1-win32-x64/bin/ffmpeg.exe"
[ -x "$FFMPEG" ] || FFMPEG="ffmpeg"

ORIGEM="${1:-}"
if [ -z "$ORIGEM" ]; then
  echo "Faltou o caminho da foto."
  echo 'Exemplo: bash scripts/colocar-foto.sh "E:/Imagens/minha-foto.jpg"'
  exit 1
fi
[ -f "$ORIGEM" ] || { echo "Não achei o arquivo: $ORIGEM"; exit 1; }

DESTINO="$(cd "$(dirname "$0")/.." && pwd)/assets/raulzito.jpg"
mkdir -p "$(dirname "$DESTINO")"

# crop central 4:5 -> escala 900x1125 -> jpg de boa qualidade
"$FFMPEG" -y -loglevel error -i "$ORIGEM" \
  -vf "crop='min(iw,ih*4/5)':'min(ih,iw*5/4)',scale=900:1125:flags=lanczos" \
  -q:v 3 "$DESTINO"

echo "Pronto: $DESTINO"
echo "Recarregue o site com Ctrl+F5."
