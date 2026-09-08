#!/bin/sh

COLORS_FILE="$HOME/.cache/wal/colors.css"
SWAYNC_FILE="$HOME/.config/swaync/style.css"

if [ ! -f "$COLORS_FILE" ]; then
    echo "ERRO: Arquivo $COLORS_FILE não encontrado!"
    exit 1
fi

# Extrair cores do formato Pywal/CSS (--color0: #xxx;)
extract_color() {
    grep "\-\-color$1:" "$COLORS_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '; '
}

# Extrair cores 0-15
color0=$(extract_color 0)
color1=$(extract_color 1)
color2=$(extract_color 2)
color3=$(extract_color 3)
color4=$(extract_color 4)
color5=$(extract_color 5)
color6=$(extract_color 6)
color7=$(extract_color 7)
color8=$(extract_color 8)
color9=$(extract_color 9)
color10=$(extract_color 10)
color11=$(extract_color 11)
color12=$(extract_color 12)
color13=$(extract_color 13)
color14=$(extract_color 14)
color15=$(extract_color 15)

# DEBUG
echo "foreground = [$foreground]"
echo "background = [$background]"
echo "cursor = [$cursor]"
for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    eval "echo \"color$i = [\$color$i]\""
done

# Verificar se as cores foram extraídas
if [ -z "$color0" ]; then
    echo "ERRO: Nenhuma cor extraída."
    exit 1
fi

mkdir -p "$(dirname "$SWAYNC_FILE")"
rm -f "$SWAYNC_FILE"

# Gerar arquivo no formato Waybar (sem aspas)
cat > "$SWAYNC_FILE" << EOF
* {
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 12px;
    font-weight: bold;
}

.notification-row {
    outline: none;
    margin: 5px;
}

.notification {
    background: $color0;
    border: 1px solid $color7;
    border-radius: 10px;
    padding: 10px;
    box-shadow: 0 0 5px $color0;
}

.notification-content .summary {
    color: $color7;
    font-size: 14px;
    font-weight: bold;
    text-shadow: 0 0 2px $color0;
}

.notification-content .body {
    color: $color7;
    font-size: 14px;
}

.notification-content .time {
    color: $color13;
}

.notification-action {
    color: $color0;
    background: $color7;
    border-radius: 5px;
}

/* --- CONTROL CENTER --- */
.control-center {
    background: $color0;
    border-radius: 15px;
    box-shadow: 0 0 10px $color0;
    margin: 3px;
}

.widget-title {
    color: $color7;
    font-weight: bold;
    font-size: 12px;
}

.widget-label {
    color: $color7;
}

.widget-buttons-grid > flowbox > flowboxchild > button {
    background: $color7;
    border-radius: 10px;
    margin: 3px;
    border: 1px solid $color7;
}

.widget-buttons-grid > flowbox > flowboxchild > button:hover {
    background: $color7;
    color: $color7;
}

.widget-dnd {
    color: $color7;
}

.widget-dnd > switch {
    background: $color7;
    border-radius: 10px;
    border: 1px solid $color7;
}

.widget-dnd > switch:checked {
    background: $color7;
}
EOF

if pgrep -x "swaync" > /dev/null; then
    # Se waybar estiver rodando, mata ela (esconde)
    pkill swaync
else
    # Se não, inicia ela (exibe)
    swaync &
fi
