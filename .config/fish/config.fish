set -gx PATH /opt/homebrew/bin $PATH

# Aliases
alias cat="bat"
alias cd="z"
alias ls="eza -alh"         # if you use eza (recommended over `ls`)
alias grep="rg"
alias find="fd"
alias tree="eza --tree"
alias ..="cd .."
alias ...="cd ../.."
alias please="sudo"

# Set prompt
starship init fish | source

# zoxide init
if type -q zoxide
    zoxide init fish | source
end

function __auto_dotenv --on-variable PWD
    if test -f .env
        dotenv .env
    end
end
