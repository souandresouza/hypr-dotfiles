#!/bin/sh
read_cpu() {
	read _ u n s i w x y z _ < /proc/stat
	total=$((u + n + s + i + w + x + y + z))
	idle=$((i + w))
	printf '%s %s' "$total" "$idle"
}

prev=$(read_cpu)
sleep 0.2
cur=$(read_cpu)
pt=${prev%% *}
pi=${prev##* }
ct=${cur%% *}
ci=${cur##* }
dt=$((ct - pt))
di=$((ci - pi))
cpu=0
[ "$dt" -gt 0 ] && cpu=$(((dt - di) * 100 / dt))

mt=$(awk '/^MemTotal/{print $2}' /proc/meminfo)
ma=$(awk '/^MemAvailable/{print $2}' /proc/meminfo)
mem_pct=0
mem_used_mb=0
mem_total_mb=0
[ "$mt" -gt 0 ] && {
	mem_pct=$(((mt - ma) * 100 / mt))
	mem_used_mb=$(((mt - ma) / 1024))
	mem_total_mb=$((mt / 1024))
}

temp=0
for t in /sys/class/thermal/thermal_zone*/temp; do
	[ -r "$t" ] || continue
	v=$(( $(cat "$t") / 1000 ))
	[ "$v" -gt "$temp" ] && temp=$v
done

gpu=0
for f in /sys/class/drm/card*/device/gpu_busy_percent; do
	[ -r "$f" ] || continue
	gpu=$(cat "$f" 2>/dev/null | tr -dc '0-9')
	[ -n "$gpu" ] && break
done
[ -z "$gpu" ] && gpu=0

printf '{"cpu":%s,"mem_pct":%s,"mem_used_mb":%s,"mem_total_mb":%s,"temp":%s,"gpu":%s}' \
	"$cpu" "$mem_pct" "$mem_used_mb" "$mem_total_mb" "$temp" "$gpu"