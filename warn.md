# warn.md: нюансы и что нужно знать

## Перед первым запуском install.sh

- **Поддерживаются macOS (Apple Silicon и Intel) и Ubuntu/Debian.** Пакеты везде через Homebrew. На других дистрибутивах скрипт предупредит, но `apt`-шаг не сработает.
- **Ubuntu: нужен `sudo`.** Он используется для `apt-get install` зависимостей Homebrew и для `chsh`/`/etc/shells`. Homebrew ставится в `/home/linuxbrew/.linuxbrew`. Не запускай скрипт от root: Homebrew это запрещает.
- **Сначала `./install.sh --dry-run`.** Он ничего не меняет и показывает все шаги.
- **macOS: Xcode Command Line Tools.** Если их нет, скрипт запускает `xcode-select --install` и завершается. Дождись окончания установки в окне macOS и запусти скрипт снова.
- **Первый запуск долгий.** `brew bundle` (llvm, rust, ffmpeg и другое), SDKMAN и Mason занимают от 10 до 30 минут и несколько гигабайт.
- **Нужен интернет** на всех шагах, включая первый запуск nvim.

## Что скрипт делает с твоими файлами

- `~/.zshrc`, `~/.p10k.zsh`, `~/.tmux.conf` и `~/.config/{nvim,lazygit,bat}` заменяются symlink'ами на файлы из репозитория.
- Существующие файлы не удаляются, а переименовываются в `*.bak.<unix-время>`. Если откатываешься, верни их вручную (`rm ~/.zshrc && mv ~/.zshrc.bak.<время> ~/.zshrc`).
- Из-за symlink'ов правка `~/.zshrc` или `~/.tmux.conf` меняет файл в репозитории. Не забывай коммитить.
- На этой машине `~/.zshrc`, `~/.p10k.zsh` и `~/.tmux.conf` пока обычные файлы, а копии лежат в репо. Правки в `~` и в репо расходятся, пока не запущен `install.sh`.

## Публичный репозиторий

- Репозиторий публичный: всё в нём видно всем. Перед пушем проверь `git ls-files` и `git diff` на токены, ключи, пароли и внутренние адреса.
- `zsh/p10k.zsh` (около 90 КБ) генерируется `p10k configure`. Это не секрет, но объёмный файл.
- Папки `~/.config/anthropic`, `github-copilot`, `configstore` лежат вне репозитория и в него не попадают. Не копируй их в `dotfiles`: там могут быть токены.
- `lazygit/state.yml` в `.gitignore`: там история и пути к локальным проектам.
- Не коммить `*.bak.*`, они могут содержать старые секреты. Папка с ними лежит в `~`, не в репозитории, но проверь перед `git add -A`.

## Neovim и Mason

- **Автоустановка:** при первом запуске nvim Mason ставит 23 пакета из `nvim/lua/plugins/lsp.lua`. Первый запуск может выглядеть зависшим, смотри прогресс в `:Mason`.
- **Пакеты требуют языковых рантаймов:** node (TS/JS/CSS/HTML/JSON/YAML LSP, prettier, eslint), python (pyright, pylint, black), rust (selene), luarocks (luacheck), JDK (jdtls, checkstyle). Без них установка конкретного пакета падает. Смотри `:MasonLog`.
- **Java и Python extras не подключены.** `jdtls`, `pyright`, `black` и `pylint` установятся, но LSP для Java и Python не настроен. Подключение описано в `docs/neovim.md`.
- **Конфиг `lsp.lua` написан под старые имена серверов** (`tsserver`, `lspconfig.util.root_pattern`). В новых версиях LazyVim и nvim-lspconfig это может давать предупреждения. TS-сервером по факту работает `vtsls` из extra. При ошибках смотри `:checkhealth lsp`.
- **`lazy-lock.json` в репозитории.** Это зафиксированные версии плагинов. `:Lazy update` их меняет, после проверки коммить новый lock. Если после обновления что-то сломалось: `:Lazy restore`.
- **Автопроверка обновлений включена** (`checker.enabled = true`), nvim периодически сам лезет в сеть.
- `dev.path = "~/.ghq/github.com"` в `lazy.lua`: путь для локальной разработки плагинов, на новой машине папки не будет, это не ошибка.
- Headless-установка Mason (`util/mason_wait.lua`) ждёт до 10 минут. Если интернет медленный, запусти ещё раз.

## tmux

- **Префикс `Ctrl+a`**, а не `Ctrl+b`. Это важно для любых инструкций из интернета.
- Плагины ставятся клавишами `prefix` `I`. `install.sh` делает это сам через `tpm/bin/install_plugins`, но если TPM не успел, нажми вручную.
- **Автосохранение сессий выключено** (`@continuum-save-interval '0'`). Сохраняй руками: `prefix` `Ctrl+s`. Без этого после перезагрузки восстановится только последнее ручное сохранение (или ничего).
- Автовосстановление при старте включено: при запуске tmux поднимется последнее сохранение.
- `Ctrl+h/j/k/l` для перехода между панелями и окнами nvim работает только при наличии `vim-tmux-navigator` и в tmux, и в nvim. Проверь, что плагин есть в обоих местах.
- `default-terminal "screen-256color"`: для true color в некоторых терминалах нужно `tmux-256color` и `terminal-overrides`. Если цвета выглядят блекло, смотри этот параметр.
- `set -g mouse on` и отсутствие сброса выделения при отпускании мыши: чтобы скопировать текст в системный буфер, может понадобиться `Option`/`Shift` или настройка `pbcopy` в copy-mode.

## lazygit

- Нужен `git-delta` (`delta`) и Nerd Font. Без `delta` панель диффа покажет ошибку.
- `<leader>lg` в nvim работает через плагин `lazygit.nvim` и требует установленный `lazygit` в PATH.
- Список клавиш в `docs/lazygit.md` частично сверен с `lazygit -c`, остальное написано по памяти. Если что-то не срабатывает, нажми `?` в самом lazygit.

## zsh, bat, yazi

- `ls` переопределён в `eza --long --all --tree --level=1 ...`. На каждый вызов выводится предупреждение `eza: Option --tree is useless given --all --all`. Это безвредно, но шумно: убрать `--all` или `--tree` в алиасе.
- `cat` это алиас на `bat`. В скриптах, где `cat` нужен «чистый», используй `command cat` или `\cat`.
- Плагин `z` в списке OMZ у тебя фактически `zsh-z` из `custom/plugins`. `install.sh` клонирует его, без него плагин не загрузится.
- `bat/themes` пуста (только `.gitkeep`). Свои темы положи туда и выполни `bat cache --build`.
- Конфига yazi нет (`~/.config/yazi` не существует), работает с настройками по умолчанию. Превью зависят от `ffmpeg`, `poppler`, `jq`, `resvg`, `imagemagick`, `sevenzip`, они есть в Brewfile.
- SDKMAN-блок в `.zshrc` должен оставаться в самом конце файла. Не добавляй ничего после него.
- Powerlevel10k без Nerd Font выглядит сломанным. Выбери `JetBrainsMono Nerd Font` в терминале (iTerm2: Profiles, Text, Font).

## Различия macOS и Ubuntu

- **Brewfile с условиями:** `llvm` и cask шрифта только на macOS; `gcc` и `xclip` только на Linux. Casks в Linuxbrew не существуют, поэтому шрифт на Ubuntu скачивается скриптом в `~/.local/share/fonts`.
- **Шрифт при SSH:** отрисовывает иконки терминал на твоей локальной машине. Ставить шрифт на удалённый сервер бессмысленно.
- **Линукс-бинарники из Homebrew** собираются/ставятся в `/home/linuxbrew/.linuxbrew`. Часть формул (например `llvm`, `ffmpeg`) на слабой машине собирается долго, если нет готовых bottle.
- **Буфер обмена:** на macOS работает `pbcopy`. На Ubuntu нужен `xclip` (X11) или `wl-clipboard` (Wayland). Без них копирование из nvim и tmux в систему не работает. На headless-сервере буфера нет вообще.
- **Homebrew в PATH:** блок в начале `zsh/zshrc` ищет brew во всех типичных местах. В `~/.zprofile` на macOS строка `brew shellenv` может остаться, дублирование безвредно.
- **`chsh` на Ubuntu** запросит пароль. Новый shell подхватится после перелогина.
- **Docker:** плагин `docker` в OMZ лишь даёт алиасы и автодополнение. Сам Docker (Desktop или Engine) в Brewfile не ставится.
- **Не проверено на реальной Ubuntu.** Скрипт и Brewfile написаны по документации Homebrew и проверены только `--dry-run` на macOS. Первый запуск на чистой Ubuntu лучше делать в VM или контейнере.

## Java

- Java и Maven ставятся через SDKMAN, а не brew. `install.sh` вызывает `sdk install java` и `sdk install maven` в неинтерактивном режиме и берёт версию по умолчанию. Если нужна конкретная (например 21), поставь её сам: `sdk install java 21.x.y-tem`.
- Mason-пакеты `jdtls` и `checkstyle` ищут `java` в PATH. Если нестандартный JDK, проверь `java -version` в том же терминале, из которого запускаешь nvim.

## Проверка после установки

```sh
brew bundle check --file=~/.config/dotfiles/Brewfile   # все пакеты на месте
ls ~/.local/share/nvim/mason/packages | wc -l          # 23
tmux source-file ~/.tmux.conf                          # без ошибок
lazygit --version && bat --version && yazi --version
```

## Что не покрыто

- Нет других ОС и дистрибутивов (Fedora, Arch, Windows/WSL не проверялись).
- Нет конфигов iTerm2, Raycast, htop, qBittorrent и прочего из `~/.config`: в репозиторий они не входят.
- Нет автоматических тестов установки на чистой системе. `install.sh` проверялся только через `--dry-run` на macOS, где всё уже установлено. На Ubuntu не запускался.
