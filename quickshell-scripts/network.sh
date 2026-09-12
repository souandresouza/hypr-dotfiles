#!/bin/sh
wifi_radio=$(LANG=C nmcli -t -f WIFI radio 2>/dev/null | tr -d '\r')
wifi_enabled=no
[ "$wifi_radio" = "enabled" ] && wifi_enabled=yes

info=$(LANG=C nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | sed -n 's/^yes:/\0/p' | head -1)
if [ -n "$info" ]; then
	ssid=$(printf '%s' "$info" | cut -d: -f2 | tr -d '\r\n')
	signal=$(printf '%s' "$info" | cut -d: -f3 | tr -d '\r\n' | tr -dc '0-9')
	ssid_esc=$(printf '%s' "$ssid" | sed 's/\\/\\\\/g; s/"/\\"/g')
	printf '{"state":"wifi","ssid":"%s","signal":%s,"wifi_enabled":"%s"}\n' "$ssid_esc" "$signal" "$wifi_enabled"
else
	if LANG=C nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | grep -q ':ethernet:connected'; then
		printf '{"state":"ethernet","ssid":"","signal":100,"wifi_enabled":"%s"}\n' "$wifi_enabled"
	else
		printf '{"state":"off","ssid":"","signal":0,"wifi_enabled":"%s"}\n' "$wifi_enabled"
	fi
fi