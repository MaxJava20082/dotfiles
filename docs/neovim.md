# Neovim

Конфиг: LazyVim, `nvim/`. Плагины фиксируются в `nvim/lazy-lock.json`.

## Автоустановка инструментов

Список в `nvim/lua/plugins/lsp.lua` (`mason.nvim` -> `ensure_installed`). При первом запуске nvim Mason ставит всё сам. Проверка: `:Mason` -> Installed (23).

| Пакет | Назначение | Требует |
|---|---|---|
| `lua-language-server`, `stylua`, `selene`, `luacheck` | Lua: LSP, форматтер, линтеры | luarocks (luacheck), rust (selene) |
| `typescript-language-server`, `vtsls`, `eslint-lsp`, `prettier` | TS/JS | node |
| `css-lsp`, `html-lsp`, `json-lsp`, `yaml-language-server`, `tailwindcss-language-server` | web/конфиги | node |
| `pyright`, `pylint`, `black`, `blackd-client` | Python | python |
| `jdtls`, `checkstyle`, `spring-javaformat` | Java | JDK (SDKMAN) |
| `codelldb` | отладчик для Rust/C/C++ | - |
| `shellcheck`, `shfmt` | shell | - |

Подключённые extras (`nvim/lua/config/lazy.lua`): eslint, prettier, typescript, json, rust, tailwind, mini-hipatterns.
Java и Python extras не подключены: инструменты ставятся, но LSP для этих языков не настроен. Подключить: добавить `{ import = "lazyvim.plugins.extras.lang.java" }` / `lang.python`.

## Обновление и диагностика

| Команда | Действие |
|---|---|
| `:Lazy sync` | установить/обновить плагины |
| `:Mason` | менеджер LSP/форматтеров |
| `:checkhealth` | диагностика |
| `:LazyExtras` | включение extras |

Headless-установка (так делает `install.sh`):

```sh
nvim --headless "+Lazy! sync" +qa
nvim --headless "+lua require('util.mason_wait').run()" +qa
```
