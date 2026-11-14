# Environment shared by interactive and command-mode Nushell.
let brew_prefix = ([/opt/homebrew /usr/local] | where {|p| $p | path join bin/brew | path exists } | first 1)
if ($brew_prefix | is-not-empty) {
    $env.HOMEBREW_PREFIX = ($brew_prefix | first)
    $env.PATH = ($env.PATH | prepend [($env.HOMEBREW_PREFIX | path join bin) ($env.HOMEBREW_PREFIX | path join sbin)])
}
$env.PATH = ($env.PATH | prepend [($env.HOME | path join .local/bin) ($env.HOME | path join .cargo/bin)] | uniq)
$env.SDKMAN_DIR = ($env.HOME | path join .sdkman)
for candidate in [java maven gradle kotlin scala] {
    let current = ($env.SDKMAN_DIR | path join candidates $candidate current)
    if ($current | path exists) {
        $env.PATH = ($env.PATH | prepend ($current | path join bin) | uniq)
        if $candidate == java { $env.JAVA_HOME = $current }
    }
}
$env.STARSHIP_CONFIG = (($env.XDG_CONFIG_HOME? | default ($env.HOME | path join .config)) | path join starship.toml)
$env.EDITOR = 'nvim'
$env.VISUAL = 'nvim'

# Homebrew JDK is keg-only; SDKMAN candidates above take precedence.
if ("JAVA_HOME" not-in $env) and ("HOMEBREW_PREFIX" in $env) {
    let jdk = ($env.HOMEBREW_PREFIX | path join opt/openjdk@21/libexec/openjdk.jdk/Contents/Home)
    if ($jdk | path exists) {
        $env.JAVA_HOME = $jdk
        $env.PATH = ($env.PATH | prepend ($jdk | path join bin))
    }
}
