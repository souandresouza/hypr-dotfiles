#!/bin/bash
# media-notify.sh -- notifica quando a mídia muda (playerctl)

command -v playerctl >/dev/null 2>&1 || exit 0
command -v notify-send >/dev/null 2>&1 || exit 0

meta_atual=""

while true; do
    meta=$(playerctl metadata --format "{{playerName}}|{{artist}}|{{title}}" 2>/dev/null || true)

    if [[ -n "$meta" && "$meta" != "$meta_atual" ]]; then
        player="${meta%%|*}"
        rest="${meta#*|}"
        artist="${rest%%|*}"
        title="${rest#*|}"

        if [[ -n "$artist" && "$artist" != "$title" ]]; then
            text="$artist — $title"
        else
            text="$title"
        fi

        notify-send -i audio "Agora tocando" "$text" -h string:x-canonical-private-synchronous:media
        meta_atual="$meta"
    fi

    sleep 3
done