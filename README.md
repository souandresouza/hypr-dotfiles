<div align="center">

# Hyprland Dotfiles

![Arch](https://img.shields.io/badge/OS-Arch_Linux-1793d1?style=flat-square&logo=archlinux&logoColor=white)
![Wayland](https://img.shields.io/badge/Protocol-Wayland-ffbc42?style=flat-square&logo=wayland&logoColor=white)

</div>

## Hyprland
> O [Hyprland](https://github.com/hyprwm/Hyprland) é um compositor Wayland independente, altamente personalizável e de organização dinâmica em mosaico, sem sacrificar a estética.

## Instalação

> Requer uma distribuição baseada em **Arch Linux**.

### 1. Clonar o repositório

```bash
git clone https://github.com/souandresouza/hypr-dotfiles ~/hypr-dotfiles
cd ~/hypr-dotfiles
```

### 2. Instalar os pacotes

Os pacotes oficiais e AUR são instalados separadamente.

```bash
# Pacotes oficiais (lista_pacman.txt)
./install_pacman.sh

# Pacotes AUR (lista_aur.txt) - instala o yay automaticamente, se necessário
./install_aur.sh
```

### 3. Copiar as configurações

```bash
./install.sh
```

O `install.sh` verifica e instala as dependências (`git`, `curl`, `yay`), copia todos os diretórios de configuração para `~/.config/`, copia a imagem de perfil do usuário para `~/Documentos/user.png` e define as permissões de execução dos scripts.

### 4. Reiniciar

Efetue logout e entre novamente na sessão do Hyprland.

> 💡 As configurações são instaladas por **cópia**, não por link simbólico. Para modificar, edite diretamente em `~/.config/` ou mantenha uma cópia atualizada deste repositório.

