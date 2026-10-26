#!/usr/bin/env bash
# Установка dotfiles на чистый macOS. Безопасно запускать повторно.
# Использование: ./install.sh [--dry-run]
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

run() {
  if (( DRY )); then echo "[dry-run] $*"; else "$@"; fi
}
log() { printf '\n==> %s\n' "$*"; }

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

log "Xcode Command Line Tools (C-компилятор для treesitter)"
if ! xcode-select -p >/dev/null 2>&1; then
  run xcode-select --install
  echo "Дождись окончания установки CLT и запусти скрипт снова."
  (( DRY )) || exit 0
fi

log "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
fi

log "Пакеты из Brewfile"
run brew bundle --file="$DOTFILES/Brewfile"

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
  run bash -c 'curl -s "https://get.sdkman.io" | bash'
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
# nvim, lazygit, bat уже лежат в ~/.config; если репо склонирован в другое место, линкуем:
if [[ "$DOTFILES" != "$HOME/.config" ]]; then
  for d in nvim lazygit bat; do link "$DOTFILES/$d" "$HOME/.config/$d"; done
fi

log "tmux: TPM и плагины"
clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
(( DRY )) || "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true

log "bat: пересборка кэша тем"
run bat cache --build

log "Neovim: плагины и Mason (первый запуск, может занять несколько минут)"
run nvim --headless "+Lazy! sync" +qa
run nvim --headless "+lua require('util.mason_wait').run()" +qa

cat <<MSG

Готово. Дальше:
  1. Открой терминал заново и выбери шрифт "JetBrainsMono Nerd Font".
  2. Запусти nvim: Mason доустановит недостающие пакеты сам (:Mason, ожидается 23 пакета).
  3. Если prompt выглядит странно: p10k configure
MSG
