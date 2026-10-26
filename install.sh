#!/usr/bin/env bash
# Установка dotfiles на macOS и Ubuntu. Пакетный менеджер везде Homebrew.
# Безопасно запускать повторно.
# Использование: ./install.sh [--dry-run]
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

run() {
  if (( DRY )); then echo "[dry-run] $*"; else "$@"; fi
}
log() { printf '\n==> %s\n' "$*"; }

case "$(uname -s)" in
  Darwin) OS=mac ;;
  Linux)  OS=linux ;;
  *) echo "Неподдерживаемая ОС: $(uname -s)"; exit 1 ;;
esac

if [[ "$OS" == linux ]] && ! grep -qiE 'ubuntu|debian' /etc/os-release 2>/dev/null; then
  echo "Предупреждение: скрипт проверялся только на Ubuntu/Debian."
fi

# Homebrew может стоять в одном из этих мест
load_brew() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew \
           /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [[ -x "$b" ]]; then
      eval "$("$b" shellenv)"
      return 0
    fi
  done
  return 1
}

link() { # link <источник в репо> <цель>
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "ok: $dst"
    return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    run mv "$dst" "$dst.bak.$(date +%s)"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  echo "link: $dst -> $src"
}

clone() { # clone <url> <каталог>
  [[ -d "$2" ]] && { echo "ok: $2"; return; }
  run git clone --depth=1 "$1" "$2"
}

if [[ "$OS" == mac ]]; then
  log "Xcode Command Line Tools"
  if ! xcode-select -p >/dev/null 2>&1; then
    run xcode-select --install
    echo "Дождись окончания установки CLT и запусти скрипт снова."
    (( DRY )) || exit 0
  fi
else
  log "Зависимости Homebrew для Ubuntu (apt)"
  run sudo apt-get update
  run sudo apt-get install -y build-essential procps curl file git unzip zip locales
fi

log "Homebrew"
if ! load_brew; then
  run env NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew || true
fi

log "Пакеты из Brewfile"
run brew bundle --file="$DOTFILES/Brewfile"

if [[ "$OS" == linux ]]; then
  log "Шрифт JetBrainsMono Nerd Font (Linux)"
  FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  if [[ -d "$FONT_DIR" ]]; then
    echo "ok: $FONT_DIR"
  else
    run mkdir -p "$FONT_DIR"
    run bash -c "curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o /tmp/JetBrainsMono.zip && unzip -oq /tmp/JetBrainsMono.zip -d '$FONT_DIR' && rm /tmp/JetBrainsMono.zip"
    command -v fc-cache >/dev/null 2>&1 && run fc-cache -f
    echo "Если ты работаешь по SSH, шрифт нужно поставить на машину с терминалом."
  fi

  log "zsh как shell по умолчанию"
  BREW_ZSH="$(command -v zsh || true)"
  if [[ -n "$BREW_ZSH" && "${SHELL:-}" != "$BREW_ZSH" ]]; then
    grep -qx "$BREW_ZSH" /etc/shells || run bash -c "echo '$BREW_ZSH' | sudo tee -a /etc/shells >/dev/null"
    run chsh -s "$BREW_ZSH"
  fi
fi

log "Oh My Zsh, powerlevel10k и плагины"
export ZSH="$HOME/.oh-my-zsh"
if [[ ! -d "$ZSH" ]]; then
  run env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone https://github.com/agkozak/zsh-z "$ZSH_CUSTOM/plugins/zsh-z"

log "SDKMAN, Java и Maven (jdtls, checkstyle)"
if [[ ! -d "$HOME/.sdkman" ]]; then
  run bash -c 'curl -s "https://get.sdkman.io?rcupdate=false" | bash'
fi
if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && (( ! DRY )); then
  set +u
  # shellcheck disable=SC1091
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java </dev/null || true
  sdk install maven </dev/null || true
  set -u
fi

log "Symlink'и конфигов"
link "$DOTFILES/zsh/zshrc"       "$HOME/.zshrc"
link "$DOTFILES/zsh/p10k.zsh"    "$HOME/.p10k.zsh"
link "$DOTFILES/tmux/tmux.conf"  "$HOME/.tmux.conf"
for d in nvim lazygit bat; do link "$DOTFILES/$d" "$HOME/.config/$d"; done

log "tmux: TPM и плагины"
clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
(( DRY )) || "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

log "bat: пересборка кэша тем"
run bat cache --build

log "Neovim: плагины и Mason (первый запуск, может занять несколько минут)"
run nvim --headless "+Lazy! sync" +qa
run nvim --headless "+lua require('util.mason_wait').run()" +qa

cat <<MSG

Готово ($OS). Дальше:
  1. Открой терминал заново и выбери шрифт "JetBrainsMono Nerd Font".
  2. Запусти nvim: Mason доустановит недостающие пакеты сам (:Mason, ожидается 23 пакета).
  3. Если prompt выглядит странно: p10k configure
MSG
