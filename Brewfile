# macOS и Ubuntu: везде Homebrew.
# brew bundle --file=~/.config/dotfiles/Brewfile

# --- Терминальные инструменты ---
brew "git"
brew "gh"
brew "zsh"
brew "neovim"
brew "tmux"
brew "lazygit"
brew "git-delta"      # красивые диффы в lazygit
brew "ripgrep"        # поиск в nvim (telescope/snacks)
brew "fd"
brew "fzf"
brew "tree-sitter-cli"
brew "curl"
brew "wget"
brew "unzip"
brew "zip"            # нужен SDKMAN

# --- Shell и утилиты ---
brew "bat"            # cat с подсветкой (alias cat=bat)
brew "eza"            # ls с иконками (alias ls=eza ...)
brew "yazi"           # файловый менеджер (alias yy=yazi)
brew "ffmpeg"         # yazi: превью видео
brew "poppler"        # yazi: превью PDF
brew "jq"
brew "resvg"          # yazi: превью SVG
brew "imagemagick"    # yazi: превью изображений
brew "sevenzip"       # yazi: архивы
brew "pipx"
brew "htop"
brew "fastfetch"

# --- Языки и компиляторы (нужны Mason-пакетам) ---
brew "node"           # typescript/css/html/json/yaml LSP, prettier, eslint, vtsls
brew "python"         # pyright, pylint, black
brew "rust"           # selene, codelldb, rust extra
brew "lua"
brew "luajit"
brew "luarocks"       # luacheck
brew "cmake"
brew "go"
# Java (jdtls, checkstyle, spring-javaformat) и maven ставятся через SDKMAN, см. install.sh

if OS.mac?
  brew "llvm"         # clang для сборки treesitter-парсеров (рядом с Xcode CLT)
  # Шрифт для иконок (nvim, eza, lazygit, p10k)
  cask "font-jetbrains-mono-nerd-font"
end

if OS.linux?
  brew "gcc"          # C-компилятор для treesitter и сборки формул из исходников
  brew "xclip"        # системный буфер обмена для nvim/tmux (X11)
  # Шрифт на Linux ставится в install.sh (cask'ов в Linuxbrew нет)
end
