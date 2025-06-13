# Aliases
alias cat="bat"
alias cd="z"
alias ls="eza -alh"         # if you use eza (recommended over `ls`)
alias grep="rg"
alias find="fd"
alias ..="cd .."
alias ...="cd ../.."
alias please="sudo"

# Set prompt
starship init fish | source

# zoxide init
if type -q zoxide
    zoxide init fish | source
end