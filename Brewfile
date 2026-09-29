# Brewfile — the source of truth for installed software.
#
# This file is Ruby, which lets one Brewfile serve two machines. On a Mac where
# the user is a local admin everything below is installed. On a Mac without admin
# rights, bootstrap.sh exports HOMEBREW_DOTFILES_NO_ADMIN=1 and the handful of
# entries that genuinely require sudo are swapped for user-installable equivalents.
#
# The variable must carry the HOMEBREW_ prefix: `brew` sanitizes its subprocess
# environment and drops anything not prefixed that way, so a plain
# DOTFILES_NO_ADMIN would silently arrive here as nil and the branch below would
# quietly take the admin path.
#
# An entry belongs in the no-admin exclusion list only if it CANNOT install without
# sudo — in practice that means casks whose artifact is a `.pkg` installer, plus
# Docker Desktop, which installs a privileged helper on first launch. Casks that
# ship a plain `.app` install fine into ~/Applications and stay in the common list.
no_admin = ENV["HOMEBREW_DOTFILES_NO_ADMIN"] == "1"

# Install a cask unless the app is already present outside Homebrew's control.
# A managed Mac (the same Mac that has no admin rights) gets Chrome, Edge and
# friends pushed into /Applications by IT. Without this guard `brew bundle`
# happily installs a second copy into ~/Applications, which then shadows the
# managed one in Spotlight and drifts out of date separately.
def cask_unless_present(token, app_name)
  dirs = [File.expand_path("~/Applications"), "/Applications"]
  if dirs.any? { |d| File.directory?(File.join(d, app_name)) }
    puts "Skipping cask #{token} - #{app_name} is already installed outside Homebrew"
  else
    cask token
  end
end

# Taps
tap "microsoft/mssql-release", "https://github.com/Microsoft/homebrew-mssql-release"
tap "hashicorp/tap"   # terraform — see the Core Development Tools note below

# Shell & Terminal
brew "fish"
brew "starship"
cask "ghostty"
cask "iterm2"

# Core Development Tools
brew "act"
brew "awscli"
brew "dockutil"
brew "duckdb"
brew "gh"
brew "git"
brew "git-filter-repo"
brew "pipx"
brew "libpq"        # psql + client libs only — no local server is ever run
# HashiCorp relicensed Terraform to the BUSL, so homebrew-core dropped the
# formula. `brew "terraform"` now resolves to nothing and `brew bundle` skips it
# silently — it must be tap-qualified or it is never installed.
brew "hashicorp/tap/terraform"
brew "terragrunt"
brew "uv"
brew "tmux"
cask "gcloud-cli"   # user-space install script, no sudo needed

# Node runtime.
# homebrew-core's `node` bottle is stamped for /opt/homebrew, so in a user prefix
# Homebrew builds node from source — and node's build pulls in LLVM, which also
# has no relocatable bottle. That cascade is a multi-hour compile. fnm has a
# `:any_skip_relocation` bottle and fetches upstream's prebuilt Node binaries, so
# it installs in seconds. scripts/install_node.sh drives it before `brew bundle`
# reaches the npm entries below.
if no_admin
  brew "fnm"           # Node version manager; provides node + npm
else
  brew "node"
end

# Container runtime.
# Docker Desktop installs a privileged helper the first time it launches, which
# needs an admin password. colima gives the same `docker` CLI on a user-owned
# Lima VM and needs no admin at all.
if no_admin
  brew "colima"          # Docker-compatible container runtime in a user VM
  brew "docker"          # docker CLI only (the daemon comes from colima)
  brew "docker-compose"
else
  cask "docker-desktop"
end

# opencode — same reason as node: the formula has no relocatable bottle and its
# build needs LLVM. Upstream also ships it on npm as a prebuilt package, which is
# what the no-admin branch uses instead.
unless no_admin
  brew "opencode"      # AI coding agent for the terminal
end

# Command Line Utilities
brew "bat"          # cat replacement
brew "btop"         # resource monitor
brew "cmatrix"      # terminal matrix animation
brew "eza"          # ls replacement
brew "fd"           # find replacement
brew "fzf"          # fuzzy finder
brew "glow"         # markdown renderer
brew "jq"           # JSON processor
brew "qpdf"         # PDF transform & inspect
brew "ripgrep"      # grep replacement
brew "shellcheck"   # lint scripts/*.sh (matches CI)
brew "tree"         # directory tree display
brew "zoxide"       # cd replacement

# Development Applications
cask "fork"
cask "visual-studio-code"

# Productivity & Utilities
cask "rectangle"            # window management
cask "obsidian"             # note taking
cask "beyond-compare"       # file comparison and management
cask "shadow"               # AI notetaker (taperlabs) — not in Homebrew's cask repo,
                            # tracked here as a marker; install manually from shadow.app
cask "libreoffice"          # office suite

# Browsers — usually pre-installed by IT on a managed Mac, so only install a
# copy if one isn't already there.
cask_unless_present "google-chrome", "Google Chrome.app"
cask_unless_present "microsoft-edge", "Microsoft Edge.app"

# AI Tools
cask "chatgpt"
cask "claude"

# Database Drivers
brew "unixodbc"                                             # ODBC 3 connectivity for UNIX
brew "microsoft/mssql-release/msodbcsql18", trusted: true   # MS SQL Server ODBC driver

# Document Processing
brew "pandoc"

# Fonts
cask "font-jetbrains-mono-nerd-font"

# --- Admin-only entries ----------------------------------------------------
# Each of these ships a .pkg installer (or a privileged helper) and cannot be
# installed without a sudo password, so they are skipped on a no-admin machine.
# bootstrap.sh prints them as manual steps instead of failing.
unless no_admin
  cask "zoom"                   # video calls (pkg installer)
  cask "mactex"                 # LaTeX distribution (pkg installer)
  cask "windows-app"            # Microsoft VDI client (pkg installer)
  cask "intune-company-portal"  # client device management (pkg installer)
end

# VS Code Extensions
vscode "atlassian.atlascode"
vscode "hashicorp.terraform"
vscode "jebbs.plantuml"
vscode "monokai.theme-monokai-pro-vscode"
vscode "ms-python.debugpy"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-python.vscode-python-envs"
vscode "ms-toolsai.jupyter"
vscode "ms-toolsai.jupyter-keymap"
vscode "ms-toolsai.jupyter-renderers"
vscode "ms-toolsai.vscode-jupyter-cell-tags"
vscode "ms-toolsai.vscode-jupyter-slideshow"
vscode "mechatroner.rainbow-csv"
vscode "ms-vscode.makefile-tools"
vscode "openai.chatgpt"
vscode "redhat.vscode-yaml"
vscode "vstirbu.vscode-mermaid-preview"

# npm Global Packages
#
# `brew bundle` resolves an `npm` entry by installing the *Homebrew* node
# formula, regardless of a node already being on PATH. On a user prefix that
# formula has no relocatable bottle and its build pulls in LLVM — the exact
# multi-hour compile the fnm swap above exists to avoid. So on a no-admin
# machine the npm globals are installed by scripts/install_apps.sh using fnm's
# node instead, and are listed here only for the admin path.
unless no_admin
  npm "@anthropic-ai/claude-code"
  npm "@mermaid-js/mermaid-cli"
  npm "pptxgenjs"
end
