#!/bin/sh
powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/{print $2}' | tr -d ' \r')
connected=$(bluetoothctl devices Connected 2>/dev/null | wc -l)
printf '{"powered":"%s","connected":%s}\n' "$powered" "$connected"