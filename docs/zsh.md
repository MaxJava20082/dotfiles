# zsh, bat, yazi

## zsh

Конфиг: `zsh/zshrc` (symlink на `~/.zshrc`), prompt: `zsh/p10k.zsh` (`~/.p10k.zsh`).

- Oh My Zsh + тема powerlevel10k. Перенастройка prompt: `p10k configure`.
- Плагины: `git`, `docker`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `z` (в custom стоит `zsh-z`: `z <часть пути>` прыгает в частые директории).
- Алиасы: `ls` -> `eza --long --all --tree --level=1 --icons=always`, `cat` -> `bat`, `yy` -> `yazi`.
- SDKMAN (Java, Maven) и pipx (`~/.local/bin`) подключены в конце файла.

## bat

`brew install bat`. Конфиг в `bat/` (`~/.config/bat`), свои темы кладутся в `bat/themes/*.tmTheme`, после чего `bat cache --build`.
Полезно: `bat файл`, `bat -p` (без рамок), `bat --list-themes`, тему задаёт `BAT_THEME` или `--theme=` в `~/.config/bat/config`.

## yazi

`brew install yazi` (для превью ещё `ffmpeg poppler jq resvg imagemagick sevenzip`, всё есть в Brewfile). Запуск: `yy` (или `yazi`).

| Клавиши | Действие |
|---|---|
| `h` `j` `k` `l` | навигация (выход в родителя / вход) |
| `space` | выделить файл |
| `y` / `x` / `p` | копировать / вырезать / вставить |
| `d` | в корзину, `D` удалить насовсем |
| `a` | создать файл (имя с `/` на конце создаёт папку) |
| `r` | переименовать |
| `/` | поиск |
| `z` | fzf-переход |
| `~` | справка по клавишам |
| `q` | выйти |

Конфигурация yazi (`~/.config/yazi`) пока не создана, используются значения по умолчанию.
