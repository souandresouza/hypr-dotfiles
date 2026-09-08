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

# ============================================================================
# BLOCK 3: Copiar para diretórios
# ============================================================================
DOTFILES="$HOME/hypr-dotfiles"

cp -r "$DOTFILES/cava" ~/.config
cp -r "$DOTFILES/fastfetch" ~/.config
cp -r "$DOTFILES/fuzzel" ~/.config
cp -r "$DOTFILES/hypr" ~/.config
cp -r "$DOTFILES/kitty" ~/.config
cp -r "$DOTFILES/music-tui" ~/.config
cp -r "$DOTFILES/scripts" ~/.config
cp -r "$DOTFILES/swaync" ~/.config
cp -r "$DOTFILES/wallpapers" ~/.config
cp -r "$DOTFILES/waybar" ~/.config
cp -r "$DOTFILES/zathura" ~/.config

chmod +x $HOME/.config/scripts/*.sh
chmod +x $HOME/.config/scripts/colors/*.sh
chmod +x $HOME/.config/hypr/scripts/*.sh
chmod +x $HOME/.config/waybar/scripts/*.sh
chmod +x $HOME/.config/waybar/scripts/*.py
chmod +x $HOME/hypr-dotfiles/install-hyprland-essentials.sh
