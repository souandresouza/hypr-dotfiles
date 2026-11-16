#!/usr/bin/env bash
set -eu

# ============================================================================
# FUNÇÕES AUXILIARES
# ============================================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

step_title() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ask_yes_no() {
    local prompt="$1"
    local answer

    while true; do
        read -p "$prompt (y/n): " answer
        case "$answer" in
            y|Y|yes|Yes|YES)
                return 0
                ;;
            n|N|no|No|NO)
                return 1
                ;;
            *)
                echo "Por favor, responda 'y' ou 'n'"
                ;;
        esac
    done
}

# ============================================================================
# BLOCK 1: CHECK AND INSTALL DEPENDENCIES
# ============================================================================
step_title "1 - CHECK AND INSTALL DEPENDENCIES (yay, git, curl)"

# Check if pacman is available
if ! command -v pacman >/dev/null 2>&1; then
    log_error "You're not on an Arch-based distro."
    log_error "Please install the required packages manually."
    exit 1
fi

# Install git and curl if missing
if ! command -v git >/dev/null 2>&1; then
    log_info "Installing git..."
    sudo pacman -S --needed git
fi

if ! command -v curl >/dev/null 2>&1; then
    log_info "Installing curl..."
    sudo pacman -S --needed curl
fi

# Install yay if missing
if command -v yay >/dev/null 2>&1; then
    log_ok "yay is installed."
else
    if ask_yes_no "===> Do you want to install yay now?"; then
        log_info "Cloning yay from AUR..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        cd "$HOME" || exit 1
        rm -rf /tmp/yay
        log_ok "yay has been installed successfully."
    else
        log_warn "You need yay to proceed with package installation automatically."
        exit 1
    fi
fi

# ============================================================================
# BLOCK 2: COPY DOTFILES (Hyprland + Quickshell)
# ============================================================================
step_title "2 - COPY DOTFILES"

DOTFILES="$HOME/hypr-dotfiles"

# Check if dotfiles directory exists
if [[ ! -d "$DOTFILES" ]]; then
    log_warn "Dotfiles directory not found at $DOTFILES"
    if ask_yes_no "===> Clone dotfiles from repository?"; then
        read -p "Enter repository URL (default: https://github.com/souandresouza/hypr-dotfiles): " REPO_URL
        REPO_URL="${REPO_URL:-https://github.com/souandresouza/hypr-dotfiles}"
        git clone "$REPO_URL" "$DOTFILES"
    else
        log_error "Dotfiles required. Exiting."
        exit 1
    fi
fi

# Create config dir
mkdir -p "$HOME/.config"

# Copy configurations
log_info "Copying configurations..."
CONFIG_DIRS=(hypr scripts)

for dir in "${CONFIG_DIRS[@]}"; do
    if [[ -d "$DOTFILES/$dir" ]]; then
        cp -r "$DOTFILES/$dir" "$HOME/.config/"
        log_ok "Copied $dir"
    else
        log_warn "$dir not found in dotfiles"
    fi
done

# Quickshell (cadrocbar bar / toasts / notifications)
log_info "Setting up Quickshell config..."
if [[ -d "$DOTFILES/quickshell" ]]; then
    mkdir -p "$HOME/.config/quickshell"
    cp -r "$DOTFILES/quickshell" "$HOME/.config/quickshell/cadrocbar"
    ln -sfn "cadrocbar" "$HOME/.config/quickshell/default"
    log_ok "Copied quickshell -> ~/.config/quickshell/cadrocbar (default -> cadrocbar)"
else
    log_warn "quickshell not found in dotfiles"
fi

if [[ -d "$DOTFILES/quickshell-scripts" ]]; then
    mkdir -p "$HOME/.config/quickshell"
    cp -r "$DOTFILES/quickshell-scripts" "$HOME/.config/quickshell/scripts"
    log_ok "Copied quickshell-scripts -> ~/.config/quickshell/scripts"
else
    log_warn "quickshell-scripts not found in dotfiles"
fi

# ============================================================================
# BLOCK 3: SET PERMISSIONS
# ============================================================================
step_title "3 - SET PERMISSIONS"

log_info "Setting executable permissions..."

# Scripts
chmod +x "$HOME/.config/scripts"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/scripts/colors"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/hypr/scripts"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/quickshell"/*/scripts/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/quickshell/scripts"/*.py 2>/dev/null || true
chmod +x "$HOME/.config/quickshell/scripts"/*.sh 2>/dev/null || true

log_ok "Permissions set"

log_info "Próximo passo: configurar os pacotes (install_pacman.sh / install_aur.sh)"