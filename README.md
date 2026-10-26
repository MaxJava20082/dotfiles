# dotfiles

Терминальная сборка для **macOS** и **Ubuntu**: Neovim (LazyVim), tmux, lazygit, zsh (Oh My Zsh + powerlevel10k), bat, yazi. Все пакеты ставятся через **Homebrew** (на Ubuntu это Linuxbrew), `apt` нужен только для зависимостей самого Homebrew.

```
nvim/      конфиг Neovim (LazyVim), lazy-lock.json
tmux/      tmux.conf -> ~/.tmux.conf
lazygit/   config.yml
zsh/       zshrc -> ~/.zshrc, p10k.zsh -> ~/.p10k.zsh
bat/       темы bat
docs/      документация: tmux, lazygit, neovim, zsh/bat/yazi
Brewfile   все brew-пакеты, языки и компиляторы (с ветками OS.mac? / OS.linux?)
install.sh автоустановка (macOS и Ubuntu)
```

## Быстрый старт

```sh
git clone https://github.com/<user>/dotfiles ~/.config/dotfiles
cd ~/.config/dotfiles
./install.sh            # ./install.sh --dry-run покажет шаги без изменений
```

Скрипт идемпотентный: существующие файлы переименовываются в `*.bak.<timestamp>`, а не затираются.

`install.sh` сам создаёт symlink'и: `~/.config/{nvim,lazygit,bat}`, `~/.zshrc`, `~/.p10k.zsh`, `~/.tmux.conf`. Репозиторий можно клонировать и в другое место, например `~/dotfiles`.

## Что делает install.sh

Скрипт сам определяет ОС (`uname`).

| Шаг | macOS | Ubuntu |
|---|---|---|
| Базовые зависимости | Xcode Command Line Tools | `apt`: build-essential, procps, curl, file, git, unzip, zip |
| Homebrew | `/opt/homebrew` или `/usr/local` | `/home/linuxbrew/.linuxbrew` |
| Пакеты | `brew bundle` (+ llvm, шрифт-cask) | `brew bundle` (+ gcc, xclip) |
| Шрифт | cask `font-jetbrains-mono-nerd-font` | скачивается в `~/.local/share/fonts` |
| Shell | zsh уже есть | brew-zsh прописывается в `/etc/shells`, `chsh` |

Дальше одинаково на обеих ОС:

1. Oh My Zsh, powerlevel10k, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-z`.
2. SDKMAN, Java и Maven.
3. Symlink'и `~/.zshrc`, `~/.p10k.zsh`, `~/.tmux.conf`, `~/.config/{nvim,lazygit,bat}`.
4. TPM и tmux-плагины.
5. `bat cache --build`.
6. Neovim: `Lazy sync` и установка всех Mason-пакетов.

## Ручная установка

macOS:

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Ubuntu:

```sh
sudo apt-get update && sudo apt-get install -y build-essential procps curl file git unzip zip
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

Дальше на обеих ОС: `brew bundle --file=~/.config/dotfiles/Brewfile`, затем шаги 1-6 выше. После этого в терминале выбери шрифт **JetBrainsMono Nerd Font**.

### Языки и зачем они нужны

| Что | Через | Зачем |
|---|---|---|
| node | brew | TS/JS/CSS/HTML/JSON/YAML LSP, prettier, eslint, vtsls |
| python | brew | pyright, pylint, black |
| rust | brew | selene, codelldb |
| lua, luarocks | brew | luacheck |
| gcc (Ubuntu) / llvm + Xcode CLT (macOS), cmake | brew / xcode-select | сборка treesitter-парсеров |
| go | brew | Go-инструменты |
| java, maven | SDKMAN | jdtls, checkstyle, spring-javaformat |

## Документация

- [tmux](docs/tmux.md)
- [lazygit](docs/lazygit.md)
- [Neovim и Mason](docs/neovim.md)
- [zsh, bat, yazi](docs/zsh.md)

## Проблемы

- Квадратики вместо иконок: не выбран Nerd Font в терминале (при SSH шрифт ставится на локальной машине).
- Ubuntu: `brew: command not found` в новом shell: проверь блок Homebrew в начале `~/.zshrc`.
- Ubuntu: нет буфера обмена в nvim/tmux: нужен `xclip` (есть в Brewfile) и X11/Wayland-сессия.
- Mason не поставил пакет: `:Mason`, `:MasonLog`; чаще всего не хватает node/python/JDK.
- Плагины tmux не подтянулись: `prefix` `I` (prefix = `Ctrl+a`).
- Тема bat не видна: `bat cache --build`.
