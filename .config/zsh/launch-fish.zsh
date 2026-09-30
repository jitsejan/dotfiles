# Hand off from zsh to fish for interactive shells.
#
# Without admin rights `chsh` cannot make fish the login shell: chsh refuses any
# shell that is not listed in /etc/shells, and adding a line there needs sudo.
# Sourcing this from ~/.zshrc gets the same end result in every terminal — iTerm2,
# Terminal.app, VS Code, Ghostty — without touching a system file.
#
# This is sourced late in ~/.zshrc on purpose: zsh's own exports (brew PATH,
# SSL_CERT_FILE, and friends) run first and are inherited by the fish process.

__dotfiles_should_launch_fish() {
  # An explicit opt-out, for getting a plain zsh back to debug the shell setup.
  [[ -n "$DOTFILES_NO_FISH" ]] && return 1

  # Loop guard: if fish ever spawns a zsh that sources this again, stay in zsh.
  [[ -n "$INSIDE_FISH" ]] && return 1

  # Only interactive shells. A non-interactive zsh (scp, rsync, a zsh-shebang
  # script) must stay zsh or it will hang or misparse.
  [[ -o interactive ]] || return 1

  # `zsh -ic 'some command'` is interactive but is here to run one command and
  # exit. ZSH_EXECUTION_STRING holds that command. Exec'ing fish would swallow it
  # and the caller would hang waiting for output that never comes — which breaks
  # editors and tools that probe the shell this way.
  [[ -n "$ZSH_EXECUTION_STRING" ]] && return 1

  # No terminal attached means nobody is going to type at this shell.
  [[ -t 0 ]] || return 1

  command -v fish >/dev/null 2>&1
}

if __dotfiles_should_launch_fish; then
  unfunction __dotfiles_should_launch_fish
  export INSIDE_FISH=1
  exec fish
else
  unfunction __dotfiles_should_launch_fish 2>/dev/null
fi
