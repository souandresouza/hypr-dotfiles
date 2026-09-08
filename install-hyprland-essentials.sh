#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Instalação Essencial para Hyprland ===${NC}"

# 1. Pacotes essenciais (sempre instalar)
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
)

# 2. Detecta gerenciador de rede disponível
if command -v NetworkManager &> /dev/null; then
    NETWORK_PACKAGES=(networkmanager network-manager-applet)
    NETWORK_SERVICE="NetworkManager"
    echo -e "${GREEN}✓ NetworkManager detectado${NC}"
elif command -v iwd &> /dev/null; then
    NETWORK_PACKAGES=(iwd)
    NETWORK_SERVICE="iwd"
    echo -e "${GREEN}✓ iwd detectado${NC}"
else
    echo -e "${YELLOW}⚠ Nenhum gerenciador de rede detectado. Instalando NetworkManager...${NC}"
    NETWORK_PACKAGES=(networkmanager network-manager-applet)
    NETWORK_SERVICE="NetworkManager"
fi

# 3. Junta tudo
PACKAGES=("${ESSENTIALS[@]}" "${NETWORK_PACKAGES[@]}")

# 4. Mostra o que será instalado
echo -e "\n${YELLOW}Pacotes a serem instalados:${NC}"
printf "  %s\n" "${PACKAGES[@]}"
echo ""

# 5. Pergunta se deseja continuar
read -p "Deseja continuar com a instalação? (s/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}Instalação cancelada.${NC}"
    exit 1
fi

# 6. Instala os pacotes
echo -e "\n${GREEN}Instalando pacotes...${NC}"
sudo pacman -S --needed "${PACKAGES[@]}"

# 7. Habilita serviços
echo -e "\n${GREEN}Habilitando serviços...${NC}"

# Network
if [[ -n "$NETWORK_SERVICE" ]]; then
    sudo systemctl enable --now "$NETWORK_SERVICE"
    echo -e "${GREEN}✓ $NETWORK_SERVICE ativado${NC}"
fi

# Bluetooth
if pacman -Q bluez &> /dev/null; then
    sudo systemctl enable --now bluetooth
    echo -e "${GREEN}✓ Bluetooth ativado${NC}"
fi

# Seatd
if pacman -Q seatd &> /dev/null; then
    sudo systemctl enable --now seatd
    sudo usermod -aG seat "$USER"
    echo -e "${GREEN}✓ Seatd ativado e usuário adicionado ao grupo 'seat'${NC}"
fi

# PipeWire (user service)
if pacman -Q pipewire &> /dev/null; then
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null
    echo -e "${GREEN}✓ PipeWire/WirePlumber ativado para o usuário${NC}"
fi

# 8. Pergunta por pacotes opcionais
echo -e "\n${YELLOW}Deseja instalar pacotes opcionais?${NC}"
echo "1) Navegadores (Firefox + LibreWolf)"
echo "2) Terminais (Alacritty + Kitty)"
echo "3) Utilitários (Thunar, MPV, VLC, GIMP)"
echo "4) Todos os acima"
echo "5) Nenhum"
read -p "Escolha uma opção (1-5): " OPTION

case $OPTION in
    1)
        sudo pacman -S --needed firefox librewolf
        ;;
    2)
        sudo pacman -S --needed alacritty kitty
        ;;
    3)
        sudo pacman -S --needed thunar thunar-archive-plugin tumbler mpv vlc gimp
        ;;
    4)
        sudo pacman -S --needed firefox librewolf alacritty kitty thunar thunar-archive-plugin tumbler mpv vlc gimp
        ;;
    5)
        echo -e "${GREEN}Nenhum pacote opcional instalado.${NC}"
        ;;
    *)
        echo -e "${RED}Opção inválida. Nenhum pacote opcional instalado.${NC}"
        ;;
esac

# 9. Finaliza
echo -e "\n${GREEN}=== Instalação concluída! ===${NC}"
echo -e "${YELLOW}Recomendação: Reinicie o sistema para aplicar todas as configurações.${NC}"
echo -e "${YELLOW}Depois faça login e inicie o Hyprland com o comando 'Hyprland' (ou via SDDM se instalado).${NC}"