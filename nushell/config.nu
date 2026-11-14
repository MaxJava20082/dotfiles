# Nushell keeps ls/open/cat as structured-data commands.
$env.config.show_banner = false
$env.config.edit_mode = 'emacs'
$env.config.buffer_editor = 'nvim'
$env.config.history.file_format = 'sqlite'
$env.config.history.max_size = 100000
$env.config.history.sync_on_enter = true
$env.config.history.ignore_space_prefixed = true
$env.config.completions.case_sensitive = false
$env.config.completions.algorithm = 'fuzzy'
$env.config.table.mode = 'rounded'
$env.config.cursor_shape.emacs = 'line'
alias ll = eza --long --all --icons=auto --git
alias lt = eza --tree --level=2 --icons=auto
alias c = bat
alias lg = lazygit
alias g = git
alias gs = git status --short --branch
alias gd = git diff
alias gl = git log --oneline --graph --decorate -20
alias .. = cd ..
# SDKMAN is a bash function. Use `sdk <args>` for management, then restart Nu.
def --wrapped sdk [...args: string] {
    ^bash -c 'source "$HOME/.sdkman/bin/sdkman-init.sh"; sdk "$@"' sdk ...$args
}
# Yazi returns the last directory through a temporary file.
def --env --wrapped yy [...args: string] {
    let tmp = (mktemp -t yazi-cwd.XXXXXX)
    ^yazi ...$args --cwd-file $tmp
    let cwd = (open --raw $tmp | str trim)
    rm $tmp
    if ($cwd | is-not-empty) and ($cwd | path exists) { cd $cwd }
}
# macOS: `open` remains Nu's file reader; `o` launches Finder/default apps.
def o [target: string] {
    if $nu.os-info.name == macos { ^/usr/bin/open $target } else { ^xdg-open $target }
}
