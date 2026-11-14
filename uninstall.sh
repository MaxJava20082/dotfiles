#!/usr/bin/env bash
# Removal is opt-in. All local files/data are moved into a private backup.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/scripts/common.sh"
DRY=1 APPLY=0 REMOVE_PACKAGES=0 PURGE_DATA=0 PURGE_SDKMAN=0 INCLUDE_SHARED=0
usage() {
  cat <<'HELP'
./uninstall.sh [--profile macos|cachyos|server] [--dry-run | --apply]
               [--packages] [--include-shared] [--purge-data] [--purge-sdkman]
               [--with-shell] [--with-yazi] [--with-dev]
По умолчанию только просмотр. --apply требует ввести DELETE.
Конфиги перемещаются в резервную копию (ссылки — без их содержимого).
--packages удаляет пакеты выбранного профиля, даже установленные вручную ранее.
--include-shared включает Git, curl, языки/компиляторы и общие зависимости.
--purge-data переносит кеши/плагины/историю инструментов в резервную копию.
--purge-sdkman отдельно переносит ~/.sdkman (все его JDK и SDK).
Homebrew/pacman/apt, SSH, проекты и репозиторий не удаляются.
HELP
}
while (( $# )); do
  case "$1" in
    --profile) [[ $# -ge 2 ]] || fail '--profile требует значение'; PROFILE="$2"; shift ;;
    --dry-run) DRY=1; APPLY=0 ;;
    --apply) DRY=0; APPLY=1 ;;
    --packages) REMOVE_PACKAGES=1 ;;
    --include-shared) INCLUDE_SHARED=1 ;;
    --purge-data) PURGE_DATA=1 ;;
    --purge-sdkman) PURGE_SDKMAN=1 ;;
    --with-shell) WITH_SHELL=1 ;;
    --with-yazi) WITH_YAZI=1 ;;
    --with-dev) WITH_DEV=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Неизвестный аргумент: $1" ;;
  esac
  shift
done
(( ! INCLUDE_SHARED || REMOVE_PACKAGES )) || fail '--include-shared требует --packages'
select_profile
load_packages
remove_config() {
  local src="$1" dst="$2" parent
  parent=$(dirname "$dst")
  # Older installers linked entire config directories. Move that link itself,
  # never a file reached through it (which would move the repository source).
  if [[ -L "$parent" && "$(readlink "$parent")" == "$(dirname "$src")" ]]; then
    backup_path "$parent"
  else
    backup_path "$dst"
  fi
}
remove_packages() {
  local pkg selected=() installed=()
  for pkg in "${PACKAGES[@]}"; do
    if (( ! INCLUDE_SHARED )); then
      case "$pkg" in
        git|gh|github-cli|curl|wget|zip|unzip|jq|python*|node*|npm|rust*|cargo|lua*|cmake|go|golang*|llvm|clang|base-devel|build-essential|jdk*|openjdk*|default-jdk|maven|ca-certificates|ffmpeg|poppler*|resvg|imagemagick|sevenzip|7zip|p7zip*) continue ;;
      esac
    fi
    selected+=("$pkg")
  done
  if (( DRY )); then installed=("${selected[@]}"); else
    case "$PROFILE" in macos) load_brew ;; esac
    for pkg in "${selected[@]}"; do
      case "$PROFILE" in
        macos) brew list --formula "$pkg" >/dev/null 2>&1 && installed+=("$pkg") ;;
        cachyos) pacman -Q "$pkg" >/dev/null 2>&1 && installed+=("$pkg") ;;
        server) [[ "$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null || true)" == 'install ok installed' ]] && installed+=("$pkg") ;;
      esac
    done
  fi
  if (( ${#installed[@]} )); then
    case "$PROFILE" in
      macos) run brew uninstall --formula "${installed[@]}" ;;
      cachyos) run sudo pacman -R -- "${installed[@]}" ;;
      server) run sudo apt-get remove --no-auto-remove -- "${installed[@]}" ;;
    esac
  fi
  if [[ "$PROFILE" == macos ]]; then
    if (( DRY )) || brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
      run brew uninstall --cask font-jetbrains-mono-nerd-font
    fi
  fi
}
perform() {
  config_map remove_config
  if (( WITH_SHELL )); then
    local nupath="$CONFIG_HOME/nushell"
    [[ "$PROFILE" != macos || -n "${XDG_CONFIG_HOME:-}" ]] || nupath="$HOME/Library/Application Support/nushell"
    backup_path "$nupath/vendor/autoload/starship.nu"
    backup_path "$nupath/autoload/starship.nu"
  fi
  if (( PURGE_DATA )); then
    local data="${XDG_DATA_HOME:-$HOME/.local/share}" cache="${XDG_CACHE_HOME:-$HOME/.cache}" tool
    for tool in nvim; do
      backup_path "$data/$tool"; backup_path "$cache/$tool"
      backup_path "${XDG_STATE_HOME:-$HOME/.local/state}/$tool"
    done
    backup_path "$HOME/.tmux/plugins"
    backup_path "$HOME/.tmux/resurrect"
    backup_path "$CONFIG_HOME/lazygit/state.yml"
    backup_path "$cache/bat"
    if [[ "$PROFILE" == macos ]]; then
      backup_path "$HOME/Library/Application Support/lazygit/state.yml"
      backup_path "$HOME/Library/Caches/bat"
    fi
    if (( WITH_SHELL )); then
      for tool in "$CONFIG_HOME/nushell" "$HOME/Library/Application Support/nushell"; do
        backup_path "$tool/history.txt"; backup_path "$tool/history.sqlite3"
        backup_path "$tool/history.sqlite3-wal"; backup_path "$tool/history.sqlite3-shm"
      done
    fi
  fi
  if (( PURGE_SDKMAN )); then backup_path "$HOME/.sdkman"; fi
  if (( REMOVE_PACKAGES )); then
    if [[ "$PROFILE" == server ]]; then
      for tool in lazygit fd bat; do backup_path "$HOME/.local/bin/$tool"; done
      if (( WITH_SHELL )); then
        for tool in nu starship eza; do backup_path "$HOME/.local/bin/$tool"; done
      fi
      if (( WITH_YAZI )); then backup_path "$HOME/.local/bin/yazi"; fi
    fi
    remove_packages
  fi
}
echo "Профиль: $PROFILE. Пакеты: $REMOVE_PACKAGES; общие: $INCLUDE_SHARED; данные: $PURGE_DATA; SDKMAN: $PURGE_SDKMAN."
if (( APPLY )); then
  # Show the exact operation set before obtaining the destructive confirmation.
  DRY=1; perform; DRY=0
  echo 'Закрой nvim, Nu, lazygit, htop и сессии tmux перед удалением.'
  printf 'Для применения введи DELETE: '
  read -r answer || fail 'Подтверждение не получено.'
  [[ "$answer" == DELETE ]] || fail 'Отменено.'
fi
perform
