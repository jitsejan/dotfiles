# --- Homebrew ---------------------------------------------------------------
# The prefix is not hardcoded: an admin install lives in /opt/homebrew, but a
# machine without admin rights keeps Homebrew in a user-owned directory. Take
# the first prefix that actually exists.
# Keep this list identical to brew_prefix() in scripts/lib/common.sh.
for brew_prefix in $HOME/homebrew $HOME/.brew $HOME/Documents/.brew /opt/homebrew /usr/local
    if test -x $brew_prefix/bin/brew
        fish_add_path -gP $brew_prefix/bin $brew_prefix/sbin
        break
    end
end
set -e brew_prefix

fish_add_path -gP $HOME/.local/bin

# libpq is keg-only (Homebrew won't link it into the prefix's bin), so psql and
# pg_dump need their directory added explicitly or they look uninstalled.
if type -q brew
    set -l libpq_bin (brew --prefix)/opt/libpq/bin
    test -d $libpq_bin && fish_add_path -gP $libpq_bin
end

# TinyTeX is the LaTeX for this machine (MacTeX's .pkg needs admin). It installs
# into $HOME and registers nothing on PATH by itself — its own installer would
# write /etc/paths.d, which needs sudo — so add it here instead. Without this
# pandoc's PDF output and any bare `pdflatex` call find no engine at all.
set -l tinytex_bin $HOME/Library/TinyTeX/bin/universal-darwin
test -d $tinytex_bin && fish_add_path -gP $tinytex_bin

# --- Corporate TLS interception ---------------------------------------------
# The office network (Cloudflare Gateway) re-signs TLS. The macOS keychain trusts
# the gateway root but Python's bundled certifi does not, so requests/dbt/dlt fail
# with "self-signed certificate in certificate chain". Point them at the exported
# keychain roots when that bundle is present.
# Regenerate after a new corporate root is pushed:
#   security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain > ~/.config/certs/aria-ca.pem
#   security find-certificate -a -p /Library/Keychains/System.keychain >> ~/.config/certs/aria-ca.pem
# Each runtime ships its own trust store and needs pointing at the keychain
# export separately: SSL_CERT_FILE/REQUESTS_CA_BUNDLE for Python, and
# NODE_EXTRA_CA_CERTS for Node — without the latter, `code --install-extension`
# and `npm install` fail with "self signed certificate in certificate chain".
if test -f $HOME/.config/certs/aria-ca.pem
    set -gx SSL_CERT_FILE $HOME/.config/certs/aria-ca.pem
    set -gx REQUESTS_CA_BUNDLE $SSL_CERT_FILE
    set -gx NODE_EXTRA_CA_CERTS $SSL_CERT_FILE
end

# --- Aliases ----------------------------------------------------------------
# Each modern replacement is only aliased if it is actually installed, so a
# partially provisioned machine still gets a working `cat`, `ls` and `grep`.
type -q bat && alias cat="bat"
type -q eza && alias ls="eza -alh"
type -q rg && alias grep="rg"
type -q fd && alias find="fd"

alias ..="cd .."
alias ...="cd ../.."
alias please="sudo"

# --- Node -------------------------------------------------------------------
# On a machine without admin rights node comes from fnm rather than Homebrew
# (the brew bottle isn't relocatable and building it drags in LLVM), so the
# shell needs fnm's shims on PATH. --use-on-cd picks up a directory's
# .node-version / .nvmrc automatically.
if type -q fnm
    fnm env --use-on-cd --shell fish | source
end

# --- Prompt -----------------------------------------------------------------
if type -q starship
    starship init fish | source
end

if type -q zoxide
    zoxide init fish | source
    alias cd="z"
end

# fzf init — Ctrl-R (history), Ctrl-T (file finder), Alt-C (cd)
if type -q fzf
    fzf --fish | source
end

function __auto_dotenv --on-variable PWD
    if test -f .env
        dotenv .env
    end
end
