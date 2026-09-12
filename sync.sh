#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config}"
HYPR_SRC="${HYPR_SRC:-$CONFIG_DIR/hypr}"
SCRIPTS_SRC="${SCRIPTS_SRC:-$CONFIG_DIR/scripts}"
CADROCBAR_SRC="${CADROCBAR_SRC:-$HOME/Projetos/cadrocbar}"

DRY=false
if [[ "${1:-}" == "-n" ]]; then
	DRY=true
fi

rsync_flags=(-a --delete)
[[ "$DRY" == true ]] && rsync_flags+=(-n)

keep_scripts=(
	battery-status.sh
	battery_tracker.sh
	calendar.sh
	clipboard.sh
	clipboard_toggle.sh
	contador_pacotes.sh
	converter_imagens.sh
	dashboard.sh
	dashboard_toggle.sh
	extract_frames.sh
	hyprpicker.sh
	media-notify.sh
	music-progress.sh
	powermenu.sh
	qr.sh
	random-wallpaper.sh
	screenrecord.sh
	screenshot.sh
	select-wallpaper.sh
	take-screenshot.sh
	wlsunset.sh
	year-progress.sh
)

run() {
	echo "> $*"
	"$@"
}

run rsync "${rsync_flags[@]}" --exclude "scripts/run-scripts.sh" "$HYPR_SRC/" "$REPO_DIR/hypr/"
run rsync "${rsync_flags[@]}" "$CADROCBAR_SRC/quickshell/" "$REPO_DIR/quickshell/"
run rsync "${rsync_flags[@]}" "$CADROCBAR_SRC/scripts/" "$REPO_DIR/quickshell-scripts/"

if [[ "$DRY" == true ]]; then
	echo "> (dry-run) rewrites $REPO_DIR/scripts com o keep-list + colors/update-hyprlock.sh"
else
	rm -rf "$REPO_DIR/scripts"
	mkdir -p "$REPO_DIR/scripts/colors"
	for f in "${keep_scripts[@]}"; do
		cp --preserve=mode,times "$SCRIPTS_SRC/$f" "$REPO_DIR/scripts/"
	done
	cp --preserve=mode,times "$SCRIPTS_SRC/colors/update-hyprlock.sh" "$REPO_DIR/scripts/colors/"
fi

echo "== git status =="
git -C "$REPO_DIR" status --short | head -40