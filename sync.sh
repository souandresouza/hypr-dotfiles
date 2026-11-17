#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config}"
HYPR_SRC="${HYPR_SRC:-$CONFIG_DIR/hypr}"
SCRIPTS_SRC="${SCRIPTS_SRC:-$CONFIG_DIR/scripts}"

# O cadrocbar pode estar num checkout do projeto ou direto na config instalada,
# com layouts diferentes:
#   ~/Projetos/cadrocbar/{quickshell,scripts}
#   ~/.config/quickshell/{cadrocbar,scripts}
QS_SRC=""
QS_SCRIPTS_SRC=""
for base in "${CADROCBAR_SRC:-$HOME/Projetos/cadrocbar}" "$CONFIG_DIR/quickshell"; do
	if [[ -d "$base/quickshell" ]]; then
		QS_SRC="$base/quickshell"
		QS_SCRIPTS_SRC="$base/scripts"
		break
	elif [[ -d "$base/cadrocbar" ]]; then
		QS_SRC="$base/cadrocbar"
		QS_SCRIPTS_SRC="$base/scripts"
		break
	fi
done

DRY=false
if [[ "${1:-}" == "-n" ]]; then
	DRY=true
fi

rsync_flags=(-a --delete)
[[ "$DRY" == true ]] && rsync_flags+=(-n)

# Só cache local do Python não vai para o repositório.
script_excludes=(
	--exclude "__pycache__/"
)

run() {
	echo "> $*"
	"$@"
}

run rsync "${rsync_flags[@]}" --exclude "scripts/run-scripts.sh" "$HYPR_SRC/" "$REPO_DIR/hypr/"
run rsync "${rsync_flags[@]}" "${script_excludes[@]}" "$SCRIPTS_SRC/" "$REPO_DIR/scripts/"

if [[ -n "$QS_SRC" ]]; then
	run rsync "${rsync_flags[@]}" "$QS_SRC/" "$REPO_DIR/quickshell/"
	run rsync "${rsync_flags[@]}" --exclude "__pycache__/" "$QS_SCRIPTS_SRC/" "$REPO_DIR/quickshell-scripts/"
else
	echo "aviso: cadrocbar não encontrado (defina CADROCBAR_SRC); quickshell não sincronizado" >&2
fi

echo "== git status =="
git -C "$REPO_DIR" status --short | head -40
