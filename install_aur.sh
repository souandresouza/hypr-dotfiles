#!/bin/bash

set -e

DOTFILES_DIR=~/hypr-dotfiles
AUR_HELPER=yay

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🅰️  Instalando pacotes AUR...${NC}"
echo ""

AUR_LIST="$DOTFILES_DIR/lista_aur.txt"

if [ ! -f "$AUR_LIST" ]; then
    echo -e "${RED}❌ lista_aur.txt não encontrada em $DOTFILES_DIR${NC}"
    exit 1
fi

# Detectar AUR helper
if ! command -v yay &>/dev/null; then
  printf "[!] yay not found\n"
  printf "[+] Installing yay...\n"
  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT
  git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
  (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
else
  printf "[✓] yay already installed\n"
fi

echo -e "${GREEN}Usando AUR helper: $AUR_HELPER${NC}"

# Filtra comentários e linhas vazias
PACKAGES=$(grep -v '^#' "$AUR_LIST" | grep -v '^$')

total=$(echo "$PACKAGES" | wc -l)
echo -e "${YELLOW}$total pacotes AUR a serem instalados:${NC}"
echo "$PACKAGES" | column
echo ""

read -p "Continuar? [s/N]: " confirm
if [[ ! $confirm =~ ^[Ss]$ ]]; then
    echo "Cancelado."
    exit 0
fi

# Instalar
$AUR_HELPER -S --needed $PACKAGES

echo -e "${GREEN}✅ Instalação concluída!${NC}"
