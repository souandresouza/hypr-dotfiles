#!/bin/sh
case "${1:-get}" in
	get)
		out=$(brightnessctl -m 2>/dev/null)
		if [ -n "$out" ]; then
			cur=$(printf '%s' "$out" | cut -d, -f3 | tr -dc '0-9')
			max=$(printf '%s' "$out" | cut -d, -f5 | tr -dc '0-9')
			pct=$(printf '%s' "$out" | cut -d, -f4 | tr -dc '0-9')
			printf '{"cur":%s,"max":%s,"pct":%s}\n' "$cur" "$max" "$pct"
		else
			printf '{"cur":0,"max":0,"pct":0}\n'
		fi
		;;
	set)
		brightnessctl set "${2}" >/dev/null 2>&1
		;;
esac