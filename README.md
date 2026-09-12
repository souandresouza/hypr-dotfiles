<div align="center">

# Hyprland + Quickshell Dotfiles

![Arch](https://img.shields.io/badge/OS-Arch_Linux-1793d1?style=flat-square&logo=archlinux&logoColor=white)
![Wayland](https://img.shields.io/badge/Protocol-Wayland-ffbc42?style=flat-square&logo=wayland&logoColor=white)

</div>

## Sobre

Dotfiles focados em **Hyprland** + **Quickshell (cadrocbar)**.

- Barra, launcher, centro e toasts de notificação feitos em **Quickshell/cadrocbar**;
- Theming via **python-pywal** (`~/.cache/wal/colors.css` → `hypr/config/colors.lua`, `hyprlock.conf`);
- **mako**, **waybar** e **matugen** não fazem parte desta configuração.

## Estrutura

```
hypr-dotfiles/
├── hypr/                  # Configuração do Hyprland (lua) + scripts
│   └── scripts/           #   hypr-colors.sh, hyprkeys.sh, run-scripts.sh
├── quickshell/            # Config do cadrocbar (Bar.qml, Services/, Popouts/...)
├── quickshell-scripts/    # Scripts chamados pelos serviços do quickshell
├── scripts/               # Utilitários usados pelos binds/autostart (→ ~/.config/scripts)
├── install.sh             # Copia as configs para ~/.config/
└── lista_{pacman,aur}.txt # Pacotes
```

Em `~/.config/` o quickshell fica organizado assim (o `install.sh` faz isso):

```
~/.config/quickshell/
├── cadrocbar/   # ← conteúdo de quickshell/
├── default/     # → symlink para cadrocbar
└── scripts/     # ← conteúdo de quickshell-scripts/
```

> Os serviços do quickshell resolvem scripts via `shellDir/../scripts`, então o layout acima é necessário para o Theme.binDir funcionar.

## Instalação

> Requer uma distribuição baseada em **Arch Linux**.

### 1. Clonar o repositório

```bash
git clone https://github.com/souandresouza/hypr-dotfiles ~/hypr-dotfiles
cd ~/hypr-dotfiles
```

### 2. Instalar os pacotes

```bash
# Pacotes oficiais (inclui quickshell)
./install_pacman.sh

# Pacotes AUR (quickshell deps extras, pywal etc.)
./install_aur.sh
```

### 3. Copiar as configurações

```bash
./install.sh
```

O `install.sh` verifica as dependências (`git`, `curl`, `yay`), copia `hypr/`, `scripts/`, `quickshell/` e `quickshell-scripts/` para `~/.config/` e ajusta permissões de execução.

### 4. Reiniciar

Efetue logout e entre novamente na sessão do Hyprland.

> 💡 As configurações são instaladas por **cópia**, não por link simbólico. Para modificar, edite em `~/.config/` e mantenha este repositório atualizado (ou edite direto aqui).

## Workflow de cores

1. `random-wallpaper.sh` (SUPER+H) roda `wal -i <imagem>` e aplica via `swaybg`;
2. `hypr-colors.sh` gera `hypr/config/colors.lua` (bordas do Hyprland);
3. `update-hyprlock.sh` regera `hyprlock.conf` com o wallpaper atual.