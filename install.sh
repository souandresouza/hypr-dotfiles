#!/usr/bin/env bash
set -u

# ============================================================================
# CORES E FUNÇÕES AUXILIARES
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error(){ echo -e "${RED}✗${NC} $1"; }
log_info() { echo -e "${BLUE}➜${NC} $1"; }
step_title() { echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"; }

ask_yes_no() {
    local prompt="$1"
    local answer
    while true; do
        read -p "$prompt (s/N) " -n 1 -r answer
        echo
        if [[ $answer =~ ^[Ss]$ ]]; then
            return 0
        elif [[ $answer =~ ^[Nn]$ ]] || [[ -z $answer ]]; then
            return 1
        else
            echo -e "${YELLOW}Resposta inválida. Digite 's' ou 'n'.${NC}"
        fi
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
        log_info "Cloning yay-bin from AUR..."
        git clone https://aur.archlinux.org/yay-bin.git /tmp/yay
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
# BLOCK 2: INSTALL HYPRLAND ESSENTIALS
# ============================================================================
step_title "2 - INSTALL HYPRLAND ESSENTIALS"

log_info "Detecting available network manager..."

# Detect network manager
NETWORK_PACKAGES=()
NETWORK_SERVICE=""
if command -v NetworkManager >/dev/null 2>&1; then
    NETWORK_PACKAGES=(networkmanager network-manager-applet)
    NETWORK_SERVICE="NetworkManager"
    log_ok "NetworkManager detected"
elif command -v iwd >/dev/null 2>&1; then
    NETWORK_PACKAGES=(iwd)
    NETWORK_SERVICE="iwd"
    log_ok "iwd detected"
else
    log_info "No network manager detected. Installing NetworkManager..."
    NETWORK_PACKAGES=(networkmanager network-manager-applet)
    NETWORK_SERVICE="NetworkManager"
fi

# Essential packages (official repos)
ESSENTIALS=(
    hyprland
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    wayland-protocols
    xorg-xwayland
    xdg-desktop-portal-hyprland
    seatd
    polkit-kde-agent
    pipewire
    pipewire-pulse
    wireplumber
    waybar
    fuzzel
    swaybg
    swaync
    wl-clip-persist
    xsettingsd
    brightnessctl
    bluez
    blueman
    ttf-jetbrains-mono-nerd
    pavucontrol
    cava
    fastfetch
    kitty
    zathura
    zathura-pdf-mupdf
    mpv
    yt-dlp
    btop
    nano
    tree
    wget
    unzip
    unrar
    jq
    python-pywal
    sddm
)

# AUR packages
AUR_PACKAGES=(
    wal-telegram-git
)

# Merge packages
PACKAGES=("${ESSENTIALS[@]}" "${NETWORK_PACKAGES[@]}")

log_info "Packages to install from official repos:"
printf "  %s\n" "${PACKAGES[@]}"
echo ""
log_info "Packages to install from AUR:"
printf "  %s\n" "${AUR_PACKAGES[@]}"
echo ""

if ask_yes_no "===> Proceed with installation?"; then
    # Install official packages
    log_info "Installing packages from official repos..."
    sudo pacman -S --needed "${PACKAGES[@]}"
    log_ok "Official packages installed successfully."

    # Install AUR packages
    log_info "Installing packages from AUR..."
    yay -S --needed "${AUR_PACKAGES[@]}"
    log_ok "AUR packages installed successfully."
else
    log_warn "Package installation skipped."
fi

# ============================================================================
# BLOCK 3: ENABLE SERVICES
# ============================================================================
step_title "3 - ENABLE SERVICES"

# Network
if [[ -n "$NETWORK_SERVICE" ]]; then
    sudo systemctl enable --now "$NETWORK_SERVICE" 2>/dev/null
    log_ok "$NETWORK_SERVICE enabled"
fi

# Bluetooth
if pacman -Q bluez >/dev/null 2>&1; then
    sudo systemctl enable --now bluetooth 2>/dev/null
    log_ok "Bluetooth enabled"
fi

# Seatd
if pacman -Q seatd >/dev/null 2>&1; then
    sudo systemctl enable --now seatd 2>/dev/null
    sudo usermod -aG seat "$USER" 2>/dev/null
    log_ok "Seatd enabled and user added to 'seat' group"
fi

# PipeWire (user services)
if pacman -Q pipewire >/dev/null 2>&1; then
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null
    log_ok "PipeWire/WirePlumber enabled for user"
fi

# SDDM
if pacman -Q sddm >/dev/null 2>&1; then
    sudo systemctl enable sddm 2>/dev/null
    log_ok "SDDM enabled (will start on next boot)"
fi

# ============================================================================
# BLOCK 4: CONFIGURE SDDM (sem autologin + NumLock)
# ============================================================================
step_title "4 - CONFIGURE SDDM"

if pacman -Q sddm >/dev/null 2>&1; then
    log_info "Configuring SDDM..."

    # Create SDDM config directory
    sudo mkdir -p /etc/sddm.conf.d

    # Create SDDM config (sem autologin, com NumLock ativo)
    sudo tee /etc/sddm.conf.d/hyprland.conf > /dev/null <<EOF
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
Numlock=on

[Theme]
Current=breeze

[Users]
MaximumUid=65000
MinimumUid=1000

[Autologin]
# Autologin desabilitado
Session=
User=
EOF

    log_ok "SDDM configured with NumLock ON (autologin disabled)"

    # Create hyprland desktop entry if not exists
    if [[ ! -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
        log_info "Creating Hyprland desktop entry for SDDM..."
        sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
        log_ok "Hyprland desktop entry created"
    fi
else
    log_warn "SDDM not installed. Skipping configuration."
fi

# ============================================================================
# BLOCK 5: COPY DOTFILES
# ============================================================================
step_title "5 - COPY DOTFILES"

DOTFILES="$HOME/hypr-dotfiles"

# Check if dotfiles directory exists
if [[ ! -d "$DOTFILES" ]]; then
    log_warn "Dotfiles directory not found at $DOTFILES"
    if ask_yes_no "===> Clone dotfiles from repository?"; then
        read -p "Enter repository URL (default: https://github.com/youruser/hypr-dotfiles): " REPO_URL
        REPO_URL="${REPO_URL:-https://github.com/youruser/hypr-dotfiles}"
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
CONFIG_DIRS=(cava fastfetch fuzzel hypr kitty music-tui scripts swaync wallpapers waybar zathura)

for dir in "${CONFIG_DIRS[@]}"; do
    if [[ -d "$DOTFILES/$dir" ]]; then
        cp -r "$DOTFILES/$dir" "$HOME/.config/"
        log_ok "Copied $dir"
    else
        log_warn "$dir not found in dotfiles"
    fi
done

# ============================================================================
# BLOCK 6: SET PERMISSIONS
# ============================================================================
step_title "6 - SET PERMISSIONS"

log_info "Setting executable permissions..."

# Scripts
chmod +x "$HOME/.config/scripts"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/scripts/colors"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/hypr/scripts"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/waybar/scripts"/*.sh 2>/dev/null || true
chmod +x "$HOME/.config/waybar/scripts"/*.py 2>/dev/null || true
chmod +x "$DOTFILES/install-hyprland-essentials.sh" 2>/dev/null || true

log_ok "Permissions set"

# ============================================================================
# BLOCK 7: OPTIONAL PACKAGES
# ============================================================================
step_title "7 - OPTIONAL PACKAGES"

if ask_yes_no "===> Install optional packages (browsers, file manager, etc.)?"; then
    echo ""
    echo "1) Browsers (Firefox + LibreWolf)"
    echo "2) Terminals (Alacritty + Kitty)"
    echo "3) Utilities (Thunar, MPV, VLC, GIMP)"
    echo "4) SDDM Themes (sddm-archlinux-theme-git from AUR)"
    echo "5) All of the above"
    echo "6) None"
    read -p "Choose an option (1-6): " OPTION

    case $OPTION in
        1)
            sudo pacman -S --needed firefox librewolf
            log_ok "Browsers installed"
            ;;
        2)
            sudo pacman -S --needed alacritty kitty
            log_ok "Terminals installed"
            ;;
        3)
            sudo pacman -S --needed thunar thunar-archive-plugin tumbler mpv vlc gimp
            log_ok "Utilities installed"
            ;;
        4)
            yay -S --needed sddm-archlinux-theme-git
            log_ok "SDDM themes installed"
            log_info "To change theme: edit /etc/sddm.conf.d/hyprland.conf and set Theme=archlinux-sddm-theme"
            ;;
        5)
            sudo pacman -S --needed firefox librewolf alacritty kitty thunar thunar-archive-plugin tumbler mpv vlc gimp
            yay -S --needed sddm-archlinux-theme-git
            log_ok "All optional packages installed"
            log_info "To change SDDM theme: edit /etc/sddm.conf.d/hyprland.conf and set Theme=archlinux-sddm-theme"
            ;;
        6)
            log_info "No optional packages installed"
            ;;
        *)
            log_warn "Invalid option. Skipping optional packages."
            ;;
    esac
fi

# ============================================================================
# BLOCK 8: WAL SETUP (pywal)
# ============================================================================
step_title "8 - WAL SETUP"

if command -v wal >/dev/null 2>&1; then
    log_info "pywal detected. Generating initial color scheme..."

    # Check if wallpapers directory exists
    if [[ -d "$HOME/.config/wallpapers" ]]; then
        # Get first wallpaper
        WALLPAPER=$(find "$HOME/.config/wallpapers" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | head -n 1)
        if [[ -n "$WALLPAPER" ]]; then
            wal -i "$WALLPAPER" -n
            log_ok "Color scheme generated from $WALLPAPER"
        else
            log_warn "No wallpapers found in ~/.config/wallpapers"
        fi
    else
        log_warn "Wallpapers directory not found"
    fi
else
    log_warn "pywal not installed. Skipping color generation."
fi

# ============================================================================
# FINALIZATION
# ============================================================================
step_title "INSTALLATION COMPLETE!"

log_ok "Hyprland with all essentials has been installed!"
log_info "Configuration files copied to ~/.config/"
log_info "User '$USER' added to 'seat' group (requires logout/login)"
log_info "pywal installed and ready to use"
log_info "SDDM configured with NumLock ON (autologin disabled)"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Hyprland installation completed successfully${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}NEXT STEPS:${NC}"
echo "  1. ${YELLOW}Reboot your system${NC} - SDDM will start automatically"
echo "  2. ${YELLOW}Login${NC} with your user and password"
echo "  3. ${YELLOW}Select Hyprland${NC} session and login"
echo ""
echo -e "${BLUE}SDDM INFO:${NC}"
echo "  - Config file: /etc/sddm.conf.d/hyprland.conf"
echo "  - NumLock is ${GREEN}ON${NC} by default"
echo "  - Autologin is ${YELLOW}disabled${NC}"
echo "  - To change theme: Install sddm-archlinux-theme-git and edit config"
echo ""
echo -e "${BLUE}PYWAL INFO:${NC}"
echo "  - Run 'wal -i /path/to/wallpaper' to generate new colors"
echo "  - Telegram already has wal-telegram-git integration"
echo ""
echo -e "${YELLOW}Enjoy your new Hyprland setup! 🚀${NC}"
