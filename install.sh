#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/scripts/common.sh"
usage() {
  cat <<'HELP'
./install.sh [--profile macos|cachyos|server] [--dry-run] [--configs-only]
             [--with-shell] [--with-yazi] [--with-dev]
Профиль определяется по ОС. Серверные опции: Nushell/Starship/zsh/eza,
Yazi с превью, языковые инструменты. --configs-only не ставит пакеты/плагины.
HELP
}
while (( $# )); do
  case "$1" in
    --profile) [[ $# -ge 2 ]] || fail '--profile требует значение'; PROFILE="$2"; shift ;;
    --dry-run) DRY=1 ;;
    --configs-only) CONFIGS_ONLY=1 ;;
    --with-shell) WITH_SHELL=1 ;;
    --with-yazi) WITH_YAZI=1 ;;
    --with-dev) WITH_DEV=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Неизвестный аргумент: $1" ;;
  esac
  shift
done
select_profile
load_packages
echo "Профиль: $PROFILE"
if (( ! CONFIGS_ONLY )); then
  case "$PROFILE" in
    macos)
      if (( ! DRY )); then
        xcode-select -p >/dev/null 2>&1 || fail 'Установи Xcode CLT: xcode-select --install, затем повтори запуск.'
        load_brew
      fi
      run brew bundle --file="$ROOT/Brewfile"
      ;;
    cachyos) run sudo pacman -Syu --needed -- "${PACKAGES[@]}" ;;
    server)
      run sudo apt-get update
      run sudo apt-get install -y --no-install-recommends -- "${PACKAGES[@]}"
      # Ubuntu/Debian name these binaries fdfind and batcat.
      link_config /usr/bin/fdfind "$HOME/.local/bin/fd"
      link_config /usr/bin/batcat "$HOME/.local/bin/bat"
      backup_path "$HOME/.local/bin/lazygit"
      run python3 "$ROOT/scripts/release_binary.py" lazygit "$HOME/.local/bin"
      if (( WITH_SHELL )); then
        for tool in nu starship eza; do backup_path "$HOME/.local/bin/$tool"; run python3 "$ROOT/scripts/release_binary.py" "$tool" "$HOME/.local/bin"; done
      fi
      if (( WITH_YAZI )); then backup_path "$HOME/.local/bin/yazi"; run python3 "$ROOT/scripts/release_binary.py" yazi "$HOME/.local/bin"; fi
      ;;
  esac
fi
config_map link_config
if (( ! CONFIGS_ONLY )); then
  export PATH="$HOME/.local/bin:$PATH"
  if (( WITH_SHELL )); then
    # Generate Starship in the user autoload directory reported by Nushell.
    nupath="$CONFIG_HOME/nushell"
    [[ "$PROFILE" != macos || -n "${XDG_CONFIG_HOME:-}" ]] || nupath="$HOME/Library/Application Support/nushell"
    run mkdir -p "$nupath/autoload"
    backup_path "$nupath/autoload/starship.nu"
    if (( DRY )); then
      echo "[dry-run] starship init nu > $nupath/autoload/starship.nu"
    else
      starship init nu > "$nupath/autoload/starship.nu"
    fi
  fi
  run bat cache --build
  if [[ "$PROFILE" != server ]]; then
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
      run git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    fi
    run "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    run nvim --headless '+Lazy! sync' +qa
    run nvim --headless "+lua require('util.mason_wait').run()" +qa
  fi
fi
printf '\nГотово: %s. Shell не изменён. PATH для сервера: export PATH="$HOME/.local/bin:$PATH"\n' "$PROFILE"
