#!/bin/bash

# Caminho do arquivo de histórico do wallpaper
WALLPAPER_HISTORY="$HOME/.cache/wallpapers/wallpaper_history.txt"
# Cores geradas pelo ruwall (formato pywal)
COLORS_FILE="$HOME/.cache/wal/colors.css"
# Caminho do arquivo de configuração do hyprlock
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
profile="$HOME/Documentos/user.png"
wallpaper="$HOME/.cache/current_wallpaper.png"
font_family="JetBrainsMono Nerd Font"

# Verifica se o arquivo de histórico existe
if [ ! -f "$WALLPAPER_HISTORY" ]; then
    echo "Erro: Arquivo $WALLPAPER_HISTORY não encontrado!"
    exit 1
fi

# Lê a primeira linha do arquivo (caminho do wallpaper atual)
WALLPAPER_PATH=$(head -n 1 "$WALLPAPER_HISTORY")

# Verifica se o caminho foi lido corretamente
if [ -z "$WALLPAPER_PATH" ]; then
    echo "Erro: Não foi possível ler o caminho do wallpaper do arquivo!"
    exit 1
fi

# Verifica se o arquivo de wallpaper existe
if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "Erro: Arquivo de wallpaper $WALLPAPER_PATH não encontrado!"
    exit 1
fi

extract_color() {
    local key="$1"
    grep -- "--${key}:" "$COLORS_FILE" 2>/dev/null | head -1 | awk -F': ' '{print $2}' | tr -d '; '
}

# Cores padrão
inner_color="#c8c8c8"
border_color="#111111"
accent_color="#30bfee"
accent2_color="#01ee8f"
font_color="#ffffff"

if [ -f "$COLORS_FILE" ]; then
    bg="$(extract_color background)"
    fg="$(extract_color foreground)"
    c0="$(extract_color color0)"
    c1="$(extract_color color1)"
    c4="$(extract_color color4)"
    c6="$(extract_color color6)"
    c15="$(extract_color color15)"

    [ -n "$c0" ] && inner_color="$c0"
    [ -n "$c15" ] && border_color="$c15"
    [ -n "$c4" ] && accent_color="$c4"
    [ -n "$c6" ] && accent2_color="$c6"
    [ -n "$fg" ] && font_color="$fg"
fi

gradient="${accent_color}, ${accent2_color} 45deg"

# Cria o diretório de configuração do hyprlock se não existir
mkdir -p "$(dirname "$HYPRLOCK_CONF")"

# Gera o arquivo hyprlock.conf
cat > "$HYPRLOCK_CONF" << EOF
# ==============================================================================
# Gerado em $(date)
# ==============================================================================
# Configuração gerada automaticamente
# Wallpaper atual: $WALLPAPER_PATH

font_family = $font_family
wallpaper = "$wallpaper"
profile = $profile
inner_color  = $inner_color
border_color = $border_color
gradient = $gradient

general {
    ignore_empty_input = true
    grace = 0
    hide_cursor = true
}

# Background
background {
    monitor =
    path = $wallpaper
    brightness = 0.5
    blur_passes = 2
    blur_size = 7
}

# Profile Picture
image {
    monitor =
    path = $profile
    size = 110
    rounding = 10
    border_size = 4
    border_color = $border_color

    position = 20, -20
    halign = left
    valign = top
    zindex = 1
}

# User Info
label {
    monitor =
    text = cmd[update:1000000] ${XDG_CONFIG_HOME:-$HOME/.config}/scripts/contador_pacotes.sh
    shadow_boost = 0.5
    shadow_passes = 1
    color = $font_color
    font_size = 11
    font_family = $font_family

    position = 170, -35
    halign = left
    valign = top
}

# DATE
label {
    monitor =
    text = cmd[update:60000] LC_TIME=pt_BR.UTF-8 date +"<b> %A, %-d %B %Y </b>"
    color = $font_color
    font_size = 30
    font_family = $font_family
    position = 0, 200
    halign = center
    valign = center
}

# TIME HR
label {
    monitor =
    text = cmd[update:1000] date +"%H:"
    color = $border_color
    shadow_size = 3
    shadow_color = rgb(0,0,0)
    shadow_boost = 1.2
    font_size = 200
    font_family = $font_family
    position = -410, -10
    halign = center
    valign = center
    zindex = 5
}

# TIME MIN
label {
    monitor =
    text = cmd[update:1000] date +"%M:"
    color = $accent_color
    font_size = 200
    font_family = $font_family
    position = 10, -15
    halign = center
    valign = center
    zindex = 5
}

# TIME SEC
label {
    monitor =
    text = cmd[update:1000] date +"%S"
    color = $border_color
    shadow_size = 3
    shadow_color = rgb(0,0,0)
    shadow_boost = 1.2
    font_size = 200
    font_family = $font_family
    position = 400, -6
    halign = center
    valign = center
    zindex = 5
}

# Input Field
input-field {
    monitor =
    size = 200, 50
    outline_thickness = 3
    dots_size = 0.33
    dots_spacing = 0.15
    dots_center = true
    dots_rounding = -1
    outer_color = $gradient
    inner_color = $inner_color
    font_color = $font_color
    fade_on_empty = true
    fade_timeout = 1000
    placeholder_text = <i>Digite a senha...</i>
    hide_input = false
    rounding = -1
    check_color = $accent2_color
    fail_color = rgb(204,34,34)
    fail_text = <i>\$FAIL <b>(\$ATTEMPTS)</b></i>
    fail_transition = 300
    capslock_color = $accent_color
    numlock_color = -1
    bothlock_color = -1
    invert_numlock = false
    swap_font_color = false
    position = 0, -200
    halign = center
    valign = center
}

label { # Status
    monitor =
    text = cmd[update:5000] ${XDG_CONFIG_HOME:-$HOME/.config}/scripts/music-progress.sh
    color = $font_color
    font_size = 14
    font_family = $font_family

    position = 30, 30
    halign = center
    valign = bottom
}
label { # Status
    monitor =
    text = cmd[update:86400] ${XDG_CONFIG_HOME:-$HOME/.config}/scripts/year-progress.sh
    color = $font_color
    font_size = 14
    font_family = $font_family

    position = 500, 30
    halign = center
    valign = bottom
}
label { # Status
    monitor =
    text = cmd[update:300] ${XDG_CONFIG_HOME:-$HOME/.config}/scripts/battery-status.sh
    color = $font_color
    font_size = 14
    font_family = $font_family

    position = -500, 30
    halign = center
    valign = bottom
}
EOF

echo "hyprlock.conf gerado com sucesso!"
echo "Wallpaper: $WALLPAPER_PATH"
echo "Arquivo salvo em: $HYPRLOCK_CONF"
