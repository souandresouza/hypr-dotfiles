<div align="center">

# Hyprland + Quickshell Dotfiles

![Arch](https://img.shields.io/badge/OS-Arch_Linux-1793d1?style=flat-square&logo=archlinux&logoColor=white)
![Wayland](https://img.shields.io/badge/Protocol-Wayland-ffbc42?style=flat-square&logo=wayland&logoColor=white)

</div>

## Sobre

Dotfiles **exclusivos do Hyprland**, com **Quickshell ([cadrocbar](https://github.com/souandresouza/cadrocbar))** e theming via **[ruwall](https://github.com/souandresouza/ruwall)**.

- Configuração do Hyprland em Lua (`hypr/`, compatível com 0.55+/0.57), `hyprlock` e `hypridle`.
- Barra, launcher, popups e notificações em **Quickshell/[cadrocbar](https://github.com/souandresouza/cadrocbar)** (`quickshell/` + `quickshell-scripts/`).
- Scripts/utilitários e pipeline de cores em `scripts/`, usando os projetos pessoais [ruwall](https://github.com/souandresouza/ruwall) e [cadrocfile](https://github.com/souandresouza/cadrocfile) quando aplicável.
- Para **MangoWC**, use o repositório [cadrocspace](https://github.com/souandresouza/cadrocspace).

## Estrutura

```
hypr-dotfiles/
├── hypr/                  # Configuração do Hyprland (Lua) + scripts exclusivos
│   └── scripts/           #   hypr-colors.sh, hyprkeys.sh, run-scripts.sh
├── quickshell/            # Config do cadrocbar (Bar.qml, Services/, Popouts/...)
├── quickshell-scripts/    # Scripts chamados pelos serviços do quickshell
├── scripts/               # Scripts/utilitários do ambiente Hyprland (→ ~/.config/scripts)
│   └── colors/            #   temas por app a partir do cache do ruwall
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

# Pacotes AUR (quickshell deps extras, ruwall etc.)
./install_aur.sh
```

### 3. Copiar as configurações

```bash
./install.sh
```

O `install.sh` verifica as dependências (`git`, `curl`, `yay`), copia `hypr/`, `scripts/`, `quickshell/` e `quickshell-scripts/` para `~/.config/` e ajusta permissões de execução.

### 4. Reiniciar

Efetue logout e entre novamente na sessão do Hyprland.

> 💡 As configurações são instaladas por **cópia**, não por link simbólico. Para modificar, edite em `~/.config/` e rode `./sync.sh` para espelhar `hypr/`, `scripts/`, `quickshell/` e `quickshell-scripts/` no repositório. Use `./sync.sh -n` para simular.

## Workflow de cores

- `random-wallpaper.sh` aplica o wallpaper (swaybg) e aciona `scripts/run-scripts.sh`, que gera a paleta com **[`ruwall`](https://github.com/souandresouza/ruwall)** (`~/.cache/wal/*`) e atualiza os temas dos apps.
- Para o **Hyprland**, `hypr/scripts/hypr-colors.sh` lê `~/.cache/wal/colors.css` e atualiza `hypr/config/colors.lua`. O `scripts/run-scripts.sh` também regenera o `hyprlock.conf` via `scripts/colors/update-hyprlock.sh` (texto sempre branco).
- `select-wallpaper.sh` seleciona/aplica o wallpaper e chama o mesmo `run-scripts.sh`, mantendo paleta e temas em sincronia.

> Usa os projetos pessoais **[`ruwall`](https://github.com/souandresouza/ruwall)** (geração de paleta) e **[`cadrocfile`](https://github.com/souandresouza/cadrocfile)**/**quickshell** ([cadrocbar](https://github.com/souandresouza/cadrocbar)) como base do fluxo. Scripts exclusivos do Hyprland ficam em `hypr/scripts/`.