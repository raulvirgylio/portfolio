#!/usr/bin/env bash
# Adiciona fotos ao portfólio.
#
# Uso:
#   bash scripts/adicionar-fotos.sh "E:/FLI 2026/07_FOTOS/Fotos_iPhone" "FLI 2026"
#   bash scripts/adicionar-fotos.sh "E:/Imagens/2026/foto.jpg" "Cobertura"
#
#   1º argumento: uma pasta (pega tudo que for imagem) ou um arquivo só
#   2º argumento: categoria/álbum (vira o filtro na aba Fotos). Opcional.
#
# O que faz:
#   - aceita JPG, JPEG, PNG, WEBP e HEIC (do iPhone — navegador não abre HEIC, converte pra JPG)
#   - gera a versão grande (máx. 1800px) e a miniatura (600px), pra página carregar leve
#   - grava em assets/fotos/ e registra em data/fotos.json sem apagar o que já existe
#   - pula foto que já foi importada antes
#
# Depois é só publicar:  bash scripts/publicar.sh "fotos novas"

set -euo pipefail
cd "$(dirname "$0")/.."
# pwd -W devolve o caminho no formato do Windows (C:/...). O pwd normal do bash devolve
# /c/Users/... , que programas nativos (python, ffmpeg) NÃO conseguem abrir.
RAIZ="$(pwd -W 2>/dev/null || pwd)"

FFMPEG="${LOCALAPPDATA}/hermes/tools/ffmpeg-9.0.1-win32-x64/bin/ffmpeg.exe"
[ -x "$FFMPEG" ] || FFMPEG="ffmpeg"
PY="${LOCALAPPDATA}/hermes/tools/python-3.14.9+20261021-win32-x64/python.exe"
[ -x "$PY" ] || PY="python"
UV="${LOCALAPPDATA}/hermes/tools/uv-0.13.5-win32-x64/uv.exe"
[ -x "$UV" ] || UV="uv"

ORIGEM="${1:-}"
CATEGORIA="${2:-Fotos}"

if [ -z "$ORIGEM" ]; then
  echo "Faltou a pasta ou o arquivo."
  echo 'Exemplo: bash scripts/adicionar-fotos.sh "E:/Imagens/2026" "Cobertura"'
  exit 1
fi

mkdir -p assets/fotos/mini
[ -f data/fotos.json ] || echo "[]" > data/fotos.json

# IMPORTANTE: os temporários ficam DENTRO da pasta do projeto.
# O /tmp do bash (MSYS) não existe para programas nativos do Windows (python, ffmpeg).
LISTA="$RAIZ/.tmp-lista-fotos.txt"
NOVAS="$RAIZ/.tmp-novas-fotos.tsv"
TMPJPG="$RAIZ/.tmp-heic.jpg"
trap 'rm -f "$LISTA" "$NOVAS" "$TMPJPG"' EXIT

if [ -d "$ORIGEM" ]; then
  find "$ORIGEM" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.heic" \) \
    | sort > "$LISTA"
elif [ -f "$ORIGEM" ]; then
  echo "$ORIGEM" > "$LISTA"
else
  echo "Não achei: $ORIGEM"; exit 1
fi

TOTAL=$(wc -l < "$LISTA")
echo "Encontrei $TOTAL imagem(ns). Processando..."
: > "$NOVAS"
N=0; PULADAS=0; FALHAS=0; HEICS=0

while IFS= read -r ARQ; do
  [ -z "$ARQ" ] && continue
  NOME=$(basename "$ARQ"); BASE="${NOME%.*}"; EXT="${NOME##*.}"
  SLUG=$(echo "$BASE" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/-\+/-/g;s/^-//;s/-$//')
  DEST="assets/fotos/${SLUG}.jpg"
  MINI="assets/fotos/mini/${SLUG}.jpg"

  # Já existe o arquivo? Mesmo assim registra — se uma execução anterior foi interrompida
  # antes de gravar o JSON, a foto ficaria no disco e invisível no site.
  # O lado Python deduplica pelo caminho, então registrar de novo é inofensivo.
  if [ -f "$DEST" ]; then
    printf '%s\t%s\t%s\n' "$DEST" "$MINI" "$BASE" >> "$NOVAS"
    PULADAS=$((PULADAS+1)); continue
  fi

  FONTE="$ARQ"
  # HEIC: o ffmpeg não decodifica. Converte com Pillow antes.
  if [ "$(echo "$EXT" | tr '[:upper:]' '[:lower:]')" = "heic" ]; then
    if ! HEIC_IN="$ARQ" HEIC_OUT="$TMPJPG" "$UV" run --quiet --with pillow --with pillow-heif python -c "
import os, pillow_heif
from PIL import Image, ImageOps
pillow_heif.register_heif_opener()
im = Image.open(os.environ['HEIC_IN'])
im = ImageOps.exif_transpose(im)
im.convert('RGB').save(os.environ['HEIC_OUT'], quality=92)
" 2>/dev/null; then
      echo "  ! nao consegui converter: $NOME"; FALHAS=$((FALHAS+1)); continue
    fi
    FONTE="$TMPJPG"; HEICS=$((HEICS+1))
  fi

  if ! "$FFMPEG" -y -loglevel error -i "$FONTE" \
      -vf "scale='min(1800,iw)':-2:flags=lanczos" -q:v 3 "$DEST" 2>/dev/null; then
    echo "  ! falhou: $NOME"; FALHAS=$((FALHAS+1)); rm -f "$TMPJPG"; continue
  fi
  "$FFMPEG" -y -loglevel error -i "$DEST" \
    -vf "scale='min(600,iw)':-2:flags=lanczos" -q:v 4 "$MINI" 2>/dev/null || true
  rm -f "$TMPJPG"

  printf '%s\t%s\t%s\n' "$DEST" "$MINI" "$BASE" >> "$NOVAS"
  N=$((N+1))
  printf "\r  %d/%d" "$N" "$TOTAL"
done < "$LISTA"
echo

CATEGORIA="$CATEGORIA" ARQ_NOVAS=".tmp-novas-fotos.tsv" "$PY" -c "
import json, os
cat = os.environ.get('CATEGORIA', 'Fotos')
with open('data/fotos.json', encoding='utf-8') as fh:
    dados = json.load(fh)
existentes = {d.get('arquivo') for d in dados}
add = 0
with open(os.environ['ARQ_NOVAS'], encoding='utf-8') as fh:
    for linha in fh:
        if not linha.strip():
            continue
        arquivo, mini, legenda = linha.rstrip('\n').split('\t')
        arquivo = arquivo.replace(chr(92), '/'); mini = mini.replace(chr(92), '/')
        if arquivo in existentes:
            continue
        dados.append({'arquivo': arquivo, 'mini': mini, 'legenda': '', 'local': '', 'categoria': cat})
        add += 1
with open('data/fotos.json', 'w', encoding='utf-8') as fh:
    json.dump(dados, fh, ensure_ascii=False, indent=1)
print(f'{add} foto(s) registradas. Total no site: {len(dados)}.')
"

[ "$HEICS" -gt 0 ] && echo "$HEICS eram HEIC do iPhone e foram convertidas."
[ "$PULADAS" -gt 0 ] && echo "$PULADAS ja tinham sido importadas antes (puladas)."
[ "$FALHAS" -gt 0 ] && echo "$FALHAS falharam."
echo
echo "Legendas: abra data/fotos.json e preencha \"legenda\" e \"local\" das que merecerem."
echo "Publicar:  bash scripts/publicar.sh \"fotos novas\""
