#!/usr/bin/env bash
set -u

# ============================================================================
# BLOCK 1: CHECK AND INSTALL DEPENDENCIES
# ============================================================================
step_title "1 - CHECK AND INSTALL DEPENDENCIES (yay, git, curl)"

# Check if pacman is available (Arch Linux or Arch-based distros)
if command -v pacman >/dev/null 2>&1; then
    if command -v yay >/dev/null 2>&1; then
        log_ok "yay is installed."
    else
        if ask_yes_no "===> Do you want to install yay now?"; then
            git clone https://aur.archlinux.org/yay-bin.git /tmp/yay
            (cd /tmp/yay && makepkg -si --noconfirm)
            cd "$HOME" || exit 1
            rm -rf /tmp/yay
            log_ok "yay has been installed successfully."
        else
            log_warn "You need yay to proceed with package installation automatically."
        fi
    fi
else
    log_error "You're not on an Arch-based distro."
    log_error "Please install the required packages manually."
fi

# ============================================================================
# BLOCK 2: Criar diretórios necessários
# ============================================================================

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/cava"
mkdir -p "$HOME/.config/fastfetch"
mkdir -p "$HOME/.config/fuzzel"
mkdir -p "$HOME/.config/hypr"
mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.config/music-tui"
mkdir -p "$HOME/.config/scripts"
mkdir -p "$HOME/.config/swaync"
mkdir -p "$HOME/.config/wallpapers"
mkdir -p "$HOME/.config/waybar"
mkdir -p "$HOME/.config/zathura"

log_ok "Todos diretórios necessários criados."

chmod +x $HOME/hypr-dotfiles/install-hyprland-essentials.sh
