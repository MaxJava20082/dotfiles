# Nushell, Starship, zsh, bat, yazi

## Nushell + Starship

Конфиги: `nushell/env.nu`, `nushell/config.nu`, `starship/starship.toml`.
На macOS Nu читает `~/Library/Application Support/nushell`; при XDG_CONFIG_HOME — `$XDG_CONFIG_HOME/nushell`.
Starship загружается из `autoload/starship.nu`; после обновления Starship пересоздай файл командой `starship init nu | save -f ($nu.default-config-dir | path join autoload/starship.nu)`.

- Prompt: цветные сегменты пути, Git, окружения и времени; ввод на второй строке.
- `ls`, `open`, `cat` — встроенные команды Nu; `ll`/`lt` — eza, `c` — bat, `lg` — lazygit.
- `yy` — Yazi с переходом в выбранную папку после выхода.
- На macOS `o` открывает файл системным приложением.
- SDKMAN candidates добавляются в PATH; Java получает JAVA_HOME.
- `sdk` запускает SDKMAN в bash; после смены версии перезапусти Nu.
- История SQLite, нечувствительное к регистру fuzzy-дополнение, редактирование Emacs.
- Для программ с POSIX-синтаксисом используй `bash -c` или `zsh -c`.

## Запасной zsh

`zsh/zshrc` сохраняет Oh My Zsh и SDKMAN, prompt использует Starship.
Для запуска Nushell в терминале укажи команду `nu --login`.
Системная login shell не меняется: это сохраняет совместимость SSH и скриптов.

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

## Профили

На сервере shell ставится только с `--with-shell`; по умолчанию остаётся текущая оболочка.
Starship использует XDG_CONFIG_HOME, если он задан. Новые JDK/Maven ставятся нативным
пакетным менеджером, существующий SDKMAN сохраняется.
