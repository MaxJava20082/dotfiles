# dotfiles

Моя терминальная сборка для macOS (Apple Silicon): Neovim (LazyVim), tmux, lazygit, zsh (Oh My Zsh + powerlevel10k), bat, yazi.

```
nvim/      конфиг Neovim (LazyVim), lazy-lock.json
tmux/      tmux.conf -> ~/.tmux.conf
lazygit/   config.yml
zsh/       zshrc -> ~/.zshrc, p10k.zsh -> ~/.p10k.zsh
bat/       темы bat
docs/      документация: tmux, lazygit, neovim, zsh/bat/yazi
Brewfile   все brew-пакеты, языки и компиляторы
install.sh автоустановка
```

## Быстрый старт

```sh
git clone https://github.com/<user>/dotfiles ~/.config
cd ~/.config
./install.sh            # ./install.sh --dry-run покажет шаги без изменений
```

Скрипт идемпотентный: существующие файлы переименовываются в `*.bak.<timestamp>`, а не затираются.

Если `~/.config` уже существует и не пуст, клонируй в другое место (например, `~/dotfiles`): `install.sh` сам создаст symlink'и в `~/.config`.

## Что делает install.sh

1. Xcode Command Line Tools (C-компилятор для treesitter).
2. Homebrew и `brew bundle` по `Brewfile`.
3. Oh My Zsh, powerlevel10k, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-z`.
4. SDKMAN, Java и Maven.
5. Symlink'и `~/.zshrc`, `~/.p10k.zsh`, `~/.tmux.conf`.
6. TPM и tmux-плагины.
7. `bat cache --build`.
8. Neovim: `Lazy sync` и установка всех Mason-пакетов.

## Ручная установка

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle --file=~/.config/Brewfile
```

Дальше шаги 3-8 выше. После этого в терминале выбери шрифт **JetBrainsMono Nerd Font**.

### Языки и зачем они нужны

| Что | Через | Зачем |
|---|---|---|
| node | brew | TS/JS/CSS/HTML/JSON/YAML LSP, prettier, eslint, vtsls |
| python | brew | pyright, pylint, black |
| rust | brew | selene, codelldb |
| lua, luarocks | brew | luacheck |
| llvm, cmake, Xcode CLT | brew / xcode-select | сборка treesitter-парсеров |
| go | brew | Go-инструменты |
| java, maven | SDKMAN | jdtls, checkstyle, spring-javaformat |

## Документация

- [tmux](docs/tmux.md)
- [lazygit](docs/lazygit.md)
- [Neovim и Mason](docs/neovim.md)
- [zsh, bat, yazi](docs/zsh.md)

## Проблемы

- Квадратики вместо иконок: не выбран Nerd Font в терминале.
- Mason не поставил пакет: `:Mason`, `:MasonLog`; чаще всего не хватает node/python/JDK.
- Плагины tmux не подтянулись: `prefix` `I` (prefix = `Ctrl+a`).
- Тема bat не видна: `bat cache --build`.
