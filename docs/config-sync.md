# Сверка с локальным компьютером

Проверено 2026-11-14. Сверка относится к этому Mac; конфиги удалённого сервера
не читались. Пользовательские изменения в Git сохранены, коммиты не создавались.

| Конфиг | Активное расположение | Результат |
|---|---|---|
| Neovim | ~/.config/nvim | Уже ссылка на nvim/ |
| bat | ~/.config/bat | Уже ссылка на bat/, дополнительных тем нет |
| lazygit | ~/.config/lazygit и ~/Library/Application Support/lazygit/config.yml | Конфиги совпали; state.yml исключён |
| tmux | ~/.tmux.conf | Совпадает |
| Starship | ~/.config/starship.toml | Совпадает |
| Nushell | ~/.config/nushell и ~/Library/Application Support/nushell | env.nu/config.nu совпали в обоих каталогах |
| zsh | ~/.zshrc | Взята текущая копия; абсолютный путь ~/.local/bin сделан переносимым; добавлено обнаружение Homebrew/JDK |
| htop | ~/.config/htop/htoprc | Скопирован в htop/htoprc |
| Git | ~/.gitconfig | Скопированы name/email в git/gitconfig |

У yazi, eza, fastfetch, fzf, ripgrep отдельных конфигов в стандартных каталогах
не найдено. Также отсутствуют ~/.curlrc, ~/.wgetrc, ~/.npmrc, ~/.cargo/config.toml,
~/.m2/settings.xml, ~/.config/go/env, ~/.config/pip/pip.conf, ~/.config/gh/config.yml.
У остальных утилит Brewfile собственных конфигов в репозитории нет; системные
настройки ОС, авторизация gh, кеши компиляторов и установленные SDK не копируются.
Глобальные нестандартные пути конфигов или переменные из других сессий не обследованы.

Адаптации после копирования: XDG_CONFIG_HOME для Starship, Homebrew JDK для Nu/zsh,
переносимая команда открытия файлов Nu, /bin/bash вместо отсутствующего fish в Neovim.
Серверные настройки находятся отдельно в profiles/server и не меняют рабочий профиль.
