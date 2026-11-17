#!/bin/bash

# Script: ~/.config/scripts/music-progress.sh

# Get player status and metadata
status=$(playerctl status 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null | head -c 30)
title=$(playerctl metadata title 2>/dev/null | head -c 30)

# Fallback para metadata alternativa
if [[ -z "$artist" && -z "$title" ]]; then
    artist=$(playerctl metadata xesam:artist 2>/dev/null | head -c 30)
    title=$(playerctl metadata xesam:title 2>/dev/null | head -c 30)
fi

# Primeira linha: Artista e Título
if [[ -n "$artist" && -n "$title" ]]; then
    echo "$artist - $title"
elif [[ -n "$title" ]]; then
    echo "$title"
elif [[ -n "$artist" ]]; then
    echo "$artist"
elif [[ "$status" =~ ^(Playing|Paused)$ ]]; then
    echo "Playing"
fi

# Segunda linha: Progresso
if [[ "$status" =~ ^(Playing|Paused)$ ]]; then
    position=$(playerctl position 2>/dev/null)
    duration=$(playerctl metadata mpris:length 2>/dev/null)
    
    # Streams/rádios reportam duração desconhecida como INT64_MAX; nesse caso
    # mostramos só o tempo tocado em vez de um valor absurdo.
    if [[ -n "$duration" && $duration -ge 86400000000 ]]; then
        duration=""
    fi

    if [[ -n "$position" && -n "$duration" && $duration -gt 0 ]]; then
        # Usa awk para cálculos mais precisos
        read -r percentage pos_min pos_sec dur_min dur_sec <<< $(awk -v pos="$position" -v dur="$duration" '
        BEGIN {
            dur_sec = dur / 1000000
            pct = (pos / dur_sec) * 100
            if (pct > 100) pct = 100
            if (pct < 0) pct = 0
            
            pos_min = int(pos / 60)
            pos_sec = int(pos % 60)
            dur_min = int(dur_sec / 60)
            dur_sec = int(dur_sec % 60)
            
            printf "%d %02d %02d %02d %02d", pct, pos_min, pos_sec, dur_min, dur_sec
        }')
        
        # Cria barra de progresso
        width=15
        filled=$(( (percentage * width) / 100 ))
        
        bar="["
        for ((i=0; i<width; i++)); do
            if [ $i -lt $filled ]; then
                bar="${bar}━"
            elif [ $i -eq $filled ] && [ $filled -gt 0 ] && [ $filled -lt $width ]; then
                bar="${bar}▶"
            else
                bar="${bar}─"
            fi
        done
        bar="${bar}]"
        
        # Exibe progresso
        if [[ "$status" == "Paused" ]]; then
            echo "$bar ${pos_min}:${pos_sec} / ${dur_min}:${dur_sec} ⏸️"
        else
            echo "$bar ${pos_min}:${pos_sec} / ${dur_min}:${dur_sec}"
        fi
    else
        if [[ -n "$position" ]]; then
            pos_min=$(awk -v pos="$position" 'BEGIN { printf "%d", pos / 60 }')
            pos_sec=$(awk -v pos="$position" 'BEGIN { printf "%02d", pos % 60 }')
            if [[ "$status" == "Paused" ]]; then
                echo "⏸️ ${pos_min}:${pos_sec} / --:--"
            else
                echo "▶ ${pos_min}:${pos_sec} / --:--"
            fi
        else
            [[ "$status" == "Paused" ]] && echo "[PAUSED]" || echo "[PLAYING]"
        fi
    fi
elif [[ "$status" == "Stopped" ]]; then
    echo "[STOPPED]"
fi
