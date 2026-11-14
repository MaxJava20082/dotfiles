#!/usr/bin/env bash
# Shared lifecycle functions, compatible with macOS Bash 3.2.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DRY=0 PROFILE= CONFIGS_ONLY=0 WITH_SHELL=0 WITH_YAZI=0 WITH_DEV=0
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
BACKUP=
fail() { echo "Ошибка: $*" >&2; exit 1; }
run() {
  if (( DRY )); then printf '[dry-run]'; printf ' %q' "$@"; printf '\n'; else "$@"; fi
}
select_profile() {
  local kernel id
  kernel=$(uname -s)
  id=
  if [[ "$kernel" == Linux ]]; then
    id=$(. /etc/os-release; printf '%s' "$ID")
  fi
  if [[ -z "$PROFILE" ]]; then
    case "$kernel:$id" in
      Darwin:*) PROFILE=macos ;;
      Linux:cachyos) PROFILE=cachyos ;;
      Linux:ubuntu|Linux:debian) PROFILE=server ;;
      *) fail 'Укажи поддерживаемую ОС: macOS, CachyOS, Ubuntu/Debian Server.' ;;
    esac
  fi
  case "$PROFILE" in macos|cachyos|server) ;; *) fail "Неизвестный профиль: $PROFILE" ;; esac
  if (( ! DRY )); then
    case "$PROFILE:$kernel:$id" in
      macos:Darwin:*|cachyos:Linux:cachyos|server:Linux:ubuntu|server:Linux:debian) ;;
      *) fail "Профиль $PROFILE не соответствует ОС $kernel/$id (просмотр: --dry-run)." ;;
    esac
  fi
  if [[ "$PROFILE" != server ]]; then WITH_SHELL=1; WITH_YAZI=1; WITH_DEV=1; fi
}
backup_path() {
  local path="$1" slot physical_parent
  [[ -e "$path" || -L "$path" ]] || return 0
  physical_parent=$(cd "$(dirname "$path")" && pwd -P)
  case "$physical_parent/" in
    "$ROOT/"*) fail "Отказ перемещать файл внутри репозитория через родительскую ссылку: $path" ;;
  esac
  if (( DRY )); then echo "[dry-run] backup: $path"; return; fi
  if [[ -z "$BACKUP" ]]; then
    mkdir -p "$STATE_HOME/backups"
    BACKUP=$(mktemp -d "$STATE_HOME/backups/$(date +%Y%m%d-%H%M%S).XXXXXX")
    chmod 700 "$BACKUP"
    echo "Резервная копия: $BACKUP"
  fi
  slot="$BACKUP/$(find "$BACKUP" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
  printf '%s\t%s\n' "$slot" "$path" >> "$BACKUP/manifest.tsv"
  mv "$path" "$slot"
}
link_config() {
  local src="$1" dst="$2"
  if [[ "$src" -ef "$dst" ]]; then return; fi
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then return; fi
  backup_path "$dst"
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
}
# One authoritative mapping for install and uninstall. Directories containing
# histories are not linked wholesale; individual editable files are linked.
config_map() {
  local nupath="$CONFIG_HOME/nushell" lazygitpath="$CONFIG_HOME/lazygit"
  if [[ "$PROFILE" == macos && -z "${XDG_CONFIG_HOME:-}" ]]; then
    nupath="$HOME/Library/Application Support/nushell"
    lazygitpath="$HOME/Library/Application Support/lazygit"
  fi
  if [[ "$PROFILE" == server ]]; then
    "$1" "$ROOT/profiles/server/nvim" "$CONFIG_HOME/nvim"
    "$1" "$ROOT/profiles/server/tmux.conf" "$HOME/.tmux.conf"
    "$1" "$ROOT/profiles/server/lazygit.yml" "$lazygitpath/config.yml"
  else
    "$1" "$ROOT/nvim" "$CONFIG_HOME/nvim"
    "$1" "$ROOT/tmux/tmux.conf" "$HOME/.tmux.conf"
    "$1" "$ROOT/lazygit/config.yml" "$lazygitpath/config.yml"
  fi
  "$1" "$ROOT/git/gitconfig" "$HOME/.gitconfig"
  "$1" "$ROOT/bat" "$CONFIG_HOME/bat"
  "$1" "$ROOT/htop/htoprc" "$CONFIG_HOME/htop/htoprc"
  if (( WITH_SHELL )); then
    "$1" "$ROOT/zsh/zshrc" "$HOME/.zshrc"
    "$1" "$ROOT/starship/starship.toml" "$CONFIG_HOME/starship.toml"
    "$1" "$ROOT/nushell/env.nu" "$nupath/env.nu"
    "$1" "$ROOT/nushell/config.nu" "$nupath/config.nu"
  fi
}
package_list() {
  case "$PROFILE" in
    macos) sed -n 's/^brew "\([^"]*\)".*/\1/p' "$ROOT/Brewfile" ;;
    cachyos) cat "$ROOT/packages/cachyos.txt" ;;
    server)
      cat "$ROOT/packages/server.txt"
      (( ! WITH_DEV )) || cat "$ROOT/packages/server-dev.txt"
      (( ! WITH_SHELL )) || echo zsh
      (( ! WITH_YAZI )) || printf '%s\n' ffmpeg poppler-utils imagemagick p7zip-full
      ;;
  esac
  return 0
}
load_packages() {
  PACKAGES=()
  while IFS= read -r pkg; do [[ -z "$pkg" || "$pkg" == \#* ]] || PACKAGES+=("$pkg"); done < <(package_list)
}
load_brew() {
  if command -v brew >/dev/null 2>&1; then return; fi
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$b" ]]; then eval "$("$b" shellenv)"; return; fi
  done
  fail 'Сначала установи Homebrew: https://brew.sh'
}
