# dotfiles

Личные настройки терминального окружения и три профиля установки:

| Профиль | ОС | Пакеты | Настройки |
|---|---|---|---|
| `macos` | macOS | Homebrew, `Brewfile` | LazyVim, tmux + TPM, lazygit + delta, Nushell/Starship, zsh, bat, htop, Git |
| `cachyos` | CachyOS | pacman, `packages/cachyos.txt` | То же рабочее окружение |
| `server` | Ubuntu/Debian | apt + официальные GitHub Releases | Минимальный Neovim без плагинов, tmux без TPM, lazygit без delta/иконок, bat, htop, Git |

Ubuntu/Debian поддерживаются только как серверный профиль. Homebrew на Linux не нужен.
Все пакеты CachyOS берутся из официальных репозиториев; AUR сейчас не требуется.

## Установка

Клонируй репозиторий в любую постоянную папку, затем:

```sh
./install.sh --dry-run                  # автоопределение ОС, только просмотр
./install.sh                            # установить профиль этой ОС
./install.sh --configs-only              # только ссылки, без пакетов и плагинов
```

Явный выбор: `--profile macos`, `--profile cachyos`, `--profile server`.
Применение чужого профиля блокируется; `--dry-run` разрешает посмотреть любой.
Не запускай установщик через sudo: sudo вызывается только для системных пакетов Linux.
На macOS сначала установи [Homebrew](https://brew.sh) и Xcode Command Line Tools.
На Linux нужны Bash и sudo; Python 3 установится с серверными пакетами.
CachyOS выполняет полное `pacman -Syu`, чтобы избежать частичного обновления системы.

Существующие конфиги перемещаются в закрытый каталог
`${XDG_STATE_HOME:-~/.local/state}/dotfiles/backups/<дата>.<суффикс>`.
`manifest.tsv` содержит соответствие резервной копии и исходного пути.
Уже правильные ссылки остаются на месте. Данные не записываются при `--dry-run`,
сетевые загрузки и пакетные менеджеры при этом не вызываются.

## Сервер Ubuntu/Debian

```sh
./install.sh --profile server --dry-run
./install.sh --profile server
# Опциональные компоненты:
./install.sh --profile server --with-shell --with-yazi --with-dev --dry-run
```

Базовые инструменты: Git, tmux, Neovim, lazygit, ripgrep, fd, fzf, bat, curl,
wget, unzip, zip, jq, htop. Python 3 и CA certificates нужны установщику.
`fd-find`/`bat` из apt получают локальные ссылки `~/.local/bin/fd`/`bat`.
Добавь `export PATH="$HOME/.local/bin:$PATH"` в свой shell или войди заново,
если ~/.profile уже добавляет этот каталог.

- `--with-shell`: zsh, Nushell, Starship и eza. Текущая login shell не меняется;
  запускай `nu` вручную. Старый Oh My Zsh используется, если уже существует.
- `--with-yazi`: yazi и превью через ffmpeg, poppler, ImageMagick и 7zip.
  Графического рабочего стола и шрифтов на сервере не требуется.
- `--with-dev`: компиляторы, Node/npm, Python venv/pipx, Rust/Cargo, Lua,
  Go, Java и Maven. Серверный Neovim остаётся минимальным, LSP не ставятся.

lazygit и опциональные Nu/Starship/eza/yazi берутся из официальных GitHub Releases
в `~/.local/bin` (Linux x86_64/ARM64). Проверяется SHA256 из GitHub API;
без контрольной суммы или при несовпадении установка прекращается.
Скачивается последний релиз, поэтому нужна совместимая с ним glibc.
API имеет лимит запросов без авторизации. Старые Ubuntu/Debian могут потребовать
обновления ОС для запуска последних бинарников; реальные Linux-установки здесь не проверены.

SSH, firewall и системные службы установщик не меняет. Nerd Font выбирается
на локальном компьютере с SSH-клиентом. Для базового серверного профиля иконки выключены.

## Удаление и переустановка на той же ОС

```sh
./uninstall.sh --profile macos                         # только просмотр
./uninstall.sh --profile macos --packages               # просмотр удаления утилит
./uninstall.sh --profile macos --packages --apply       # запросит DELETE
# Более полная очистка, сначала просмотреть:
./uninstall.sh --profile macos --packages --include-shared --purge-data --purge-sdkman
```

Для CachyOS используй `--profile cachyos`, для Ubuntu/Debian — `--profile server`.
Перед применением закрой инструменты и сессии tmux. Для серверных опций укажи те же
`--with-shell`, `--with-yazi`, `--with-dev`, что использовались при установке.

По умолчанию переносит только конфиги. `--packages` удаляет утилиты выбранного
профиля, включая те, что были установлены до dotfiles. Это сброс выбранного набора,
а не откат только последней установки. `--include-shared` дополнительно включает
Git, curl, языки, компиляторы и другие общие зависимости — полный список виден
в предварительном просмотре. macOS удаляет brew-пакеты, системные /usr/bin остаются.
Пакетный менеджер может отказать из-за зависимых пакетов: принудительное удаление,
`autoremove`, удаление баз данных пакетных менеджеров не используются.

`--purge-data` переносит кеши Neovim/bat, плагины tmux, сохранения сессий,
историю lazygit и (с `--with-shell`) историю Nushell в резервную копию.
`--purge-sdkman` отдельно переносит весь ~/.sdkman, включая все его Java/SDK.
Резервные копии остаются даже при полной очистке, удаляй их вручную после проверки.
История zsh/bash, учётные данные GitHub, проекты, SSH и сам репозиторий сохраняются.
После удаления запускай `./install.sh` с тем же профилем и опциями.

## Что синхронизировано с компьютера

[Отчёт сравнения](docs/config-sync.md). Помимо исходных папок добавлены `htop/`
и `git/`. Автор коммитов в `git/gitconfig` — личные name/email владельца.
Перед использованием другим человеком измени их.
На macOS учитываются стандартные пути `~/Library/Application Support/{nushell,lazygit}`;
при заданном XDG_CONFIG_HOME используется он. Starship читает `$XDG_CONFIG_HOME/starship.toml`.

Java/Maven при новой установке берутся из Homebrew/pacman/apt. Существующий SDKMAN
остаётся доступен в zsh/Nu. Neovim использует `/bin/bash` для внешних команд;
раньше был жёстко задан fish, которого нет в списке установки.

## Документация и проверки

- [Neovim](docs/neovim.md), [tmux](docs/tmux.md), [lazygit](docs/lazygit.md), [shell](docs/zsh.md)
- [Ограничения](warn.md)

```sh
python3 -m unittest discover -s tests -v
bash -n install.sh uninstall.sh scripts/common.sh
zsh -n zsh/zshrc
```

Тесты работают с временным HOME. Настоящие пакеты не ставятся и не удаляются.
