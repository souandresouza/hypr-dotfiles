#!/usr/bin/env bash
set -euo pipefail

# ========= CONFIG =========
BASE_DIR="$HOME/Imagens/Screenshots"

DATE=$(date +%d-%m-%Y)
TIMESTAMP=$(date +%d%m%Y_%H%M%S)

DIR="$BASE_DIR/$DATE"

# Modelos do tesseract baixados fora do pacman ficam aqui; se os pacotes
# tesseract-data-* estiverem instalados, o script prefere /usr/share/tessdata.
TESSDATA_USER="$HOME/.local/share/tesseract/tessdata"

# ========= DETECT COMPOSITOR =========
detect_compositor() {
  if command -v hyprctl >/dev/null 2>&1 && hyprctl version >/dev/null 2>&1; then
    echo "hyprland"
  else
    echo "unknown"
  fi
}

COMPOSITOR=$(detect_compositor)

# ========= GET ACTIVE WINDOW GEOMETRY =========
# `hyprctl activewindow -j` devolve "at" e "size" da janela focada.
get_window_geom() {
  case "$COMPOSITOR" in
    hyprland)
      hyprctl activewindow -j 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
if not isinstance(d, dict) or not d or d.get("mapped") is False:
    sys.exit(1)
at = d.get("at") or [0, 0]
size = d.get("size") or [0, 0]
w, h = int(size[0]), int(size[1])
if w <= 0 or h <= 0:
    sys.exit(1)
print("%d,%d %dx%d" % (int(at[0]), int(at[1]), w, h))
' 2>/dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

# ========= HELP =========
usage() {
  echo "Uso: screenshot [all|monitor|region|window|ocr|qr]"
  exit 1
}

# ========= HELPERS =========
# Captura para arquivo e define MODE/FILE. A pasta do dia só é criada quando
# existe uma imagem para salvar (OCR/QR não criam pasta vazia).
capture() {
  local mode="$1"
  shift

  MODE="$mode"
  FILE="$DIR/screenshot_${MODE}_${TIMESTAMP}.png"
  mkdir -p "$DIR"
  grim "$@" "$FILE"
}

notify_error() {
  notify-send -u critical "$1" "${2:-}"
}

# Idiomas disponíveis em um diretório de dados do tesseract, na ordem de
# preferência deste script (português + inglês).
ocr_langs() {
  local dir="$1"
  local lang available_lang
  local -a available=() chosen=()

  mapfile -t available < <(tesseract --list-langs --tessdata-dir "$dir" 2>/dev/null | tail -n +2)
  for lang in por eng; do
    for available_lang in "${available[@]}"; do
      if [[ "$available_lang" == "$lang" ]]; then
        chosen+=("$lang")
        break
      fi
    done
  done

  ((${#chosen[@]})) || return 1
  (IFS=+; printf '%s' "${chosen[*]}")
}

# ========= MODES =========
case "${1:-}" in
  all)
    capture all
    ;;

  monitor)
    MONITOR=$(slurp -o -f "%o") || exit 0
    [[ -n "$MONITOR" ]] || exit 0
    capture "$MONITOR" -o "$MONITOR"
    ;;

  region)
    GEOM=$(slurp) || exit 0
    [[ -n "$GEOM" ]] || exit 0
    capture region -g "$GEOM"
    ;;

  window)
    GEOM=$(get_window_geom || true)

    if [[ -z "${GEOM:-}" ]]; then
      notify-send "Screenshot" "Erro ao obter janela ($COMPOSITOR)"
      exit 1
    fi

    capture window -g "$GEOM"
    ;;

  ocr)
    MODE="ocr"
    GEOM=$(slurp) || exit 0
    [[ -n "$GEOM" ]] || exit 0

    command -v tesseract >/dev/null || {
      notify_error "OCR" "tesseract não encontrado (instale tesseract)"
      exit 1
    }

    LANGS="${OCR_LANGS:-}"
    TESSDATA_ARGS=()
    if [[ -z "$LANGS" ]]; then
      if LANGS=$(ocr_langs /usr/share/tessdata); then
        :
      elif LANGS=$(ocr_langs "$TESSDATA_USER"); then
        TESSDATA_ARGS=(--tessdata-dir "$TESSDATA_USER")
      else
        notify_error "OCR" "Sem modelos do tesseract (instale tesseract-data-por e tesseract-data-eng)"
        exit 1
      fi
    fi

    RESULT=$(grim -g "$GEOM" - | tesseract stdin stdout \
      --oem 1 --psm 6 -l "$LANGS" "${TESSDATA_ARGS[@]}" \
      -c preserve_interword_spaces=1 2>/dev/null) || true

    # Remove só espaços nas pontas; quebras de linha internas são preservadas.
    RESULT="${RESULT#"${RESULT%%[![:space:]]*}"}"
    RESULT="${RESULT%"${RESULT##*[![:space:]]}"}"

    [[ -n "$RESULT" ]] || {
      notify_error "OCR" "Nenhum texto encontrado na região"
      exit 1
    }

    printf '%s' "$RESULT" | wl-copy
    notify-send "OCR" "Texto copiado para a área de transferência"
    exit 0
    ;;

  qr)
    MODE="qr"
    GEOM=$(slurp) || exit 0
    [[ -n "$GEOM" ]] || exit 0

    command -v zbarimg >/dev/null || {
      notify_error "QR" "zbarimg não encontrado (instale zbar)"
      exit 1
    }

    RESULT=$(grim -g "$GEOM" - | zbarimg -q --raw -Sdisable -Sqrcode.enable - 2>/dev/null) || true

    [[ -n "$RESULT" ]] || {
      notify_error "QR" "Nenhum QR code encontrado na região"
      exit 1
    }

    # QR pode carregar segredo (otpauth://, tokens): não exibe o conteúdo e
    # marca a cópia como sensível.
    printf '%s' "$RESULT" | wl-copy --sensitive
    notify-send "QR" "Conteúdo copiado para a área de transferência"
    exit 0
    ;;

  *)
    usage
    ;;
esac

# ========= COPY =========
wl-copy < "$FILE"

# ========= FEEDBACK (notificação com miniatura) =========
# Passa o caminho absoluto em -i para a notificação exibir a prévia.
FILENAME=$(basename "$FILE")
notify-send -i "$FILE" "Screenshot Capturada" "$MODE • $FILENAME"
echo "Salvo em: $FILE"
