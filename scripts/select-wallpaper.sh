#!/bin/bash
# ~/.config/scripts/select-wallpaper.sh
# Seletor de wallpaper para as imagens de ~/.config/wallpapers
# Usa fuzzel (fallback: rofi) para escolha, aplica com swaybg e
# mantém o histórico/cache consistente com random-wallpaper.sh.
#
# Uso:
#   select-wallpaper.sh            escolhe e aplica o wallpaper
#   select-wallpaper.sh --grid     abre a grade de miniaturas em imv

set -euo pipefail

source "$HOME/.config/scripts/random-wallpaper.sh"

CONFIG_DIR="$HOME/.config"
WALLPAPER_DIR="$CONFIG_DIR/wallpapers"
CACHE_DIR="$HOME/.cache/wallpapers"
CURRENT_WALLPAPER="$HOME/.cache/current_wallpaper.png"

# Gera uma grade de miniaturas de todos os wallpapers
preview_grid() {
    local out="$CACHE_DIR/preview.png"
    local imgs=()

    while IFS= read -r f; do
        [[ -n "$f" ]] && imgs+=("$f")
    done < <(list_available_wallpapers)

    if [[ ${#imgs[@]} -eq 0 ]]; then
        echo "Nenhum wallpaper encontrado em $WALLPAPER_DIR" >&2
        return 1
    fi

    if command -v montage &>/dev/null; then
        montage -label '%t' -thumbnail '240x>' -background '#0f1115' \
            -fill '#e0e2e4' -pointsize 18 -geometry '+8+8' \
            "${imgs[@]}" "$out"
        echo "$out"
    fi
}

# Abre a grade de miniaturas no imv
show_grid() {
    local grid
    grid=$(preview_grid)
    if [[ -n "$grid" ]] && command -v imv &>/dev/null; then
        imv "$grid" &
        return 0
    fi
    echo "montage ou imv não disponíveis" >&2
    return 1
}

# Escolhe o wallpaper via launcher e imprime o caminho escolhido
pick_wallpaper() {
    local all
    all=$(list_available_wallpapers || true)

    if [[ -z "$all" ]]; then
        echo "Nenhum wallpaper encontrado em $WALLPAPER_DIR" >&2
        return 1
    fi

    local selected=""
    if command -v fuzzel &>/dev/null; then
        selected=$(printf '%s\n' "$all" | fuzzel --dmenu --prompt "Wallpaper: " --only-match 2>/dev/null || true)
    elif command -v rofi &>/dev/null; then
        selected=$(printf '%s\n' "$all" | rofi -dmenu -i -p "Wallpaper: " 2>/dev/null || true)
    else
        echo "Nenhum launcher (fuzzel/rofi) disponível" >&2
        return 1
    fi

    if [[ -n "$selected" ]]; then
        echo "$selected"
        return 0
    fi
    return 1
}

main() {
    local show_preview=false

    if [[ "${1:-}" == "--grid" ]]; then
        show_preview=true
    fi

    ensure_directories

    if $show_preview; then
        show_grid
    fi

    local chosen
    if chosen=$(pick_wallpaper); then
        echo "Aplicando: $chosen" >&2

        apply_wallpaper "$chosen"
        update_history "$chosen"
        cp "$chosen" "$CURRENT_WALLPAPER" 2>/dev/null || true

        # Regenera o tema de cores baseado no wallpaper
        wal -i "$chosen" >/dev/null 2>&1 || true

        notify-send "Wallpaper" "$(basename "$chosen")" -i "$chosen" 2>/dev/null || true
    else
        echo "Nenhum wallpaper selecionado" >&2
        exit 1
    fi
}

# Executa somente quando chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi