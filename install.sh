#!/usr/bin/env bash
# Dotfiles installer for macOS (arm64 / Homebrew) and Linux.
#
# Usage: ./install.sh [--packages] [--no-plugins] [--dry-run]
#   --packages    also install tools (brew bundle on macOS, apt on Linux; apt needs sudo)
#   --no-plugins  do not download fish plugins (fisher update)
#   --dry-run     only print what would happen; change nothing
#
# Safe to run many times:
#   - a link that is already correct is skipped
#   - any other file in the way is MOVED to ~/dotfiles-backup/<date>/ (never deleted)
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
OS="$(uname -s)"
PACKAGES=0 PLUGINS=1 DRY=0

for arg in "$@"; do
  case "$arg" in
    --packages) PACKAGES=1 ;;
    --no-plugins) PLUGINS=0 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
run()  { if [ "$DRY" -eq 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }

# ---------------------------------------------------------------- 1. packages
install_packages() {
  case "$OS" in
    Darwin)
      if ! command -v brew >/dev/null; then
        for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
          [ -x "$b" ] && eval "$("$b" shellenv)" && break
        done
      fi
      command -v brew >/dev/null || { warn "Homebrew not found. Install it first (see README)."; exit 1; }
      run brew bundle --file "$DOT/Brewfile"
      ;;
    Linux)
      command -v apt-get >/dev/null || { warn "apt not found; install packages from packages-linux.txt by hand."; return; }
      mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$DOT/packages-linux.txt")
      run sudo apt-get update
      run sudo apt-get install -y "${pkgs[@]}"
      ;;
  esac
}

# ---------------------------------------------------------------- 2. links
# Move $dst to the backup folder, unless it is already a link to $src.
backup_if_needed() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local rel="${dst#"$HOME"/}"
    say "backup: ~/$rel -> ${BACKUP/#$HOME/~}/$rel"
    run mkdir -p "$(dirname "$BACKUP/$rel")"
    run mv "$dst" "$BACKUP/$rel"
  fi
}

# Link every file of a stow package into $target (one link per file).
stow_pkg() {
  local pkg="$1" target="$2" src
  while IFS= read -r -d '' src; do
    backup_if_needed "$src" "$target/${src#"$DOT/$pkg/"}"
  done < <(find "$DOT/$pkg" \( -type f -o -type l \) ! -name .gitignore -print0)
  run mkdir -p "$target"
  if [ "$DRY" -eq 1 ]; then
    # conflicts here are normal: the real run moves those files to the backup first
    stow --no-folding -n -v -d "$DOT" -t "$target" -R "$pkg" || true
  else
    stow --no-folding -d "$DOT" -t "$target" -R "$pkg"
  fi
}

link_file() {
  local src="$1" dst="$2"
  backup_if_needed "$src" "$dst"
  if [ ! -L "$dst" ]; then
    run mkdir -p "$(dirname "$dst")"
    run ln -s "$src" "$dst"
  fi
}

link_all() {
  command -v stow >/dev/null || { warn "GNU stow is missing. Run with --packages, or install stow."; exit 1; }
  say "linking config/ -> ~/.config"
  stow_pkg config "$HOME/.config"
  say "linking home/ -> ~"
  stow_pkg home "$HOME"

  say "linking VS Code Insiders settings"
  case "$OS" in
    Darwin) link_file "$DOT/vscode/settings.json" "$HOME/Library/Application Support/Code - Insiders/User/settings.json" ;;
    Linux)  link_file "$DOT/vscode/settings.json" "$HOME/.config/Code - Insiders/User/settings.json" ;;
  esac
}

# ---------------------------------------------------------------- 3. git
setup_git() {
  local local_cfg="$HOME/.gitconfig.local"
  if [ ! -e "$local_cfg" ]; then
    # Take name/email from the backed-up old ~/.gitconfig if there is one.
    local old="$BACKUP/.gitconfig" name="" email=""
    if [ -f "$old" ]; then
      name="$(git config -f "$old" --get user.name || true)"
      email="$(git config -f "$old" --get user.email || true)"
    fi
    if [ -n "$name" ] && [ -n "$email" ]; then
      say "creating ~/.gitconfig.local (name/email from your old ~/.gitconfig)"
      run git config -f "$local_cfg" user.name "$name"
      run git config -f "$local_cfg" user.email "$email"
    else
      say "creating ~/.gitconfig.local from example -> EDIT IT: add your name and email"
      run cp "$DOT/gitconfig.local.example" "$local_cfg"
    fi
  fi

  if command -v git-secrets >/dev/null; then
    if [ ! -d "$HOME/.git-templates/git-secrets/hooks" ]; then
      say "installing git-secrets hooks template"
      run git secrets --install "$HOME/.git-templates/git-secrets"
    fi
  else
    warn "git-secrets not installed: new repos will not get the secret hooks"
  fi
}

# ---------------------------------------------------------------- 4. fish plugins
setup_fish() {
  if ! command -v fish >/dev/null; then warn "fish not installed; skipping plugins"; return; fi
  if [ "$PLUGINS" -eq 0 ]; then say "skipping fish plugins (--no-plugins)"; return; fi
  # Uses the pinned vendor/fisher.fish (no curl | sh). Plugins are downloaded from GitHub.
  say "installing fish plugins from fish_plugins (downloads from GitHub)"
  run fish -c "source '$DOT/vendor/fisher.fish'; fisher update"
}

# ---------------------------------------------------------------- main
say "dotfiles: $DOT   OS: $OS   HOME: $HOME"
[ "$DRY" -eq 1 ] && say "DRY RUN: nothing will change"
[ "$PACKAGES" -eq 1 ] && install_packages
link_all
setup_git
setup_fish

if [ -d "$BACKUP" ]; then say "old files saved in: ${BACKUP/#$HOME/~}"; fi
say "done. Next: open a new terminal. Optional: 'tide configure', 'chsh -s \$(command -v fish)'"
