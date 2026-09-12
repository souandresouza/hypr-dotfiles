#!/usr/bin/env bash
set -euo pipefail

CMD="${1:-info}"

active_line=$(nmcli -t -f NAME,DEVICE,TYPE con show --active 2>/dev/null \
	| grep ':802-11-wireless$' | head -1 || true)

if [[ -z "$active_line" ]]; then
	if [[ "${CMD}" == "info" ]]; then
		jq -nc --arg ssid "" --arg conn "" --arg dev "" --arg ip "" --arg gateway "" \
			--arg band "" --arg psk "" \
			'{ssid:$ssid,conn:$conn,device:$dev,ip:$ip,gateway:$gateway,band:$band,psk:$psk}'
	elif [[ "${CMD}" == "qr" ]]; then
		echo "no-wifi"
	fi
	exit 0
fi

conn=$(cut -d: -f1 <<<"$active_line")
dev=$(cut -d: -f2 <<<"$active_line")

get_psk() {
	nmcli dev wifi show-password 2>/dev/null | sed -n 's/^\(Senha\|Password\)[[:space:]]*:[[:space:]]*//p' | head -1 || true
}

band_of() {
	local freq="$1"
	if (( freq >= 2400 && freq <= 2484 )); then
		echo "2.4GHz"
	elif (( freq >= 4900 && freq <= 5885 )); then
		echo "5GHz"
	elif (( freq >= 5900 )); then
		echo "6GHz"
	fi
}

band_of_chan() {
	local chan="$1"
	if (( chan >= 1 && chan <= 13 )); then
		echo "2.4GHz"
	elif (( chan >= 34 && chan <= 177 )); then
		echo "5GHz"
	fi
}

qr_escape() {
	printf '%s' "$1" | sed 's/\([\\;,:"'"'"']\)/\\\1/g'
}

case "$CMD" in
	info)
		ssid=$(nmcli -g 802-11-wireless.ssid connection show "$conn" 2>/dev/null | head -1)
		ip=$(nmcli -g IP4.ADDRESS dev show "$dev" 2>/dev/null | head -1)
		gateway=$(nmcli -g IP4.GATEWAY dev show "$dev" 2>/dev/null | head -1)
		psk=$(get_psk)
		band=""
		if command -v iw >/dev/null 2>&1; then
			freq=$(iw dev "$dev" link 2>/dev/null | sed -n 's/.*freq: \([0-9]*\).*/\1/p' | head -1)
			if [[ -n "$freq" ]]; then
				band=$(band_of "$freq")
			fi
		else
			chan=$(nmcli -t -f IN-USE,CHAN dev wifi 2>/dev/null | sed -n 's/^\*://p' | head -1)
			if [[ -n "$chan" ]]; then
				band=$(band_of_chan "$chan")
			fi
		fi
		jq -nc --arg ssid "${ssid:-}" --arg conn "$conn" --arg dev "$dev" --arg ip "${ip:-}" \
			--arg gateway "${gateway:-}" --arg band "${band:-}" --arg psk "${psk:-}" \
			'{ssid:$ssid,conn:$conn,device:$dev,ip:$ip,gateway:$gateway,band:$band,psk:$psk}'
		;;
	qr)
		ssid=$(nmcli -g 802-11-wireless.ssid connection show "$conn" 2>/dev/null | head -1)
		psk=$(get_psk)
		if [[ -z "$ssid" ]]; then
			echo "no-wifi"
			exit 0
		fi
		payload="WIFI:T:WPA;S:$(qr_escape "$ssid");P:$(qr_escape "$psk");;"
		out="/tmp/cadrocbar-wifi-qr.png"
		qrencode -o "$out" -s 8 -m 2 "$payload" 2>/dev/null || {
			echo "no-qr"
			exit 1
		}
		echo "$out"
		;;
	band)
		val="${2:-auto}"
		if [[ "$val" == "auto" ]]; then
			nmcli con modify "$conn" wifi.band "" 2>/dev/null || true
		else
			nmcli con modify "$conn" wifi.band "$val" 2>/dev/null || true
		fi
		nmcli con up "$conn" >/dev/null 2>&1 || true
		;;
	*)
		exit 1
		;;
esac