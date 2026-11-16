<div align="center">

# Hyprland + MangoWC Dotfiles

![Arch](https://img.shields.io/badge/OS-Arch_Linux-1793d1?style=flat-square&logo=archlinux&logoColor=white)
![Wayland](https://img.shields.io/badge/Protocol-Wayland-ffbc42?style=flat-square&logo=wayland&logoColor=white)

</div>

## Sobre

Dotfiles para **Hyprland** e **MangoWC**, com componentes compartilhados.

- **Comum**: `scripts/`, `quickshell/` (cadrocbar) e `quickshell-scripts/` (temas via **ruwall**, utilitários, launcher/notificações quando aplicável).
- **Hyprland**: `hypr/` (config Lua 0.55+/0.57, binds/regras/scripts exclusivos do Hyprland, `hyprlock`/`hypridle`).
- **MangoWC**: `mango/` (config do MangoWC, binds/regras/tema e scripts exclusivos como `mango/scripts/mango-keys.sh`).
- Theming principal via **ruwall** (cache em `~/.cache/wal/*`), reutilizado pelos perfis e scripts de cores.

## Estrutura

```
hypr-dotfiles/
├── hypr/                  # Configuração do Hyprland (Lua) + scripts exclusivos
│   └── scripts/           #   hypr-colors.sh, hyprkeys.sh, run-scripts.sh
├── mango/                 # Configuração do MangoWC + scripts exclusivos
│   └── scripts/           #   mango-keys.sh
├── quickshell/            # Config do cadrocbar (Bar.qml, Services/, Popouts/...)
├── quickshell-scripts/    # Scripts chamados pelos serviços do quickshell
├── scripts/               # Scripts/utilitários compartilhados (→ ~/.config/scripts)
│   └── colors/            #   temas por app (ruwall/pywal cache), incl. mango-colors.sh
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

O `install.sh` verifica as dependências (`git`, `curl`, `yay`), copia `hypr/`, `mango/`, `scripts/`, `quickshell/` e `quickshell-scripts/` para `~/.config/` e ajusta permissões de execução.

### 4. Reiniciar

Efetue logout e entre novamente na sessão desejada (Hyprland ou MangoWC).

> 💡 As configurações são instaladas por **cópia**, não por link simbólico. Para modificar, edite em `~/.config/` e mantenha este repositório atualizado (ou edite direto aqui).

## Workflow de cores

- `random-wallpaper.sh` aplica o wallpaper (swaybg) e aciona `scripts/run-scripts.sh`, que gera a paleta com **`ruwall`** (`~/.cache/wal/*`) e atualiza os temas dos apps (incluindo `mango-colors.sh` quando aplicável).
- Para o perfil **Hyprland**, `hypr/scripts/hypr-colors.sh` lê `~/.cache/wal/colors.css` e atualiza `hypr/config/colors.lua`, e `scripts/colors/update-hyprlock.sh` pode regenerar o `hyprlock.conf` com base no wallpaper/cores.
- `select-wallpaper.sh` (quando usado) seleciona/aplica wallpaper e regenera paleta com `ruwall`.

> Usa os projetos pessoais **`ruwall`** (geração de paleta) e **`cadrocfile`**/**quickshell** (cadrocbar) como base do fluxo. Scripts exclusivos de compositor ficam em `hypr/scripts/` e `mango/scripts/`.