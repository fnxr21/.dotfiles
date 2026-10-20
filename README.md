# Dotfiles

My core setup: **fish** shell, **nvim** editor, **tmux**, **ghostty** terminal, git, htop, VS Code Insiders settings.
Works on **macOS (Apple Silicon)** and **Linux (Ubuntu)**.

One repo, one script: `git clone` → `./install.sh` → done.

---

## Contents

1. [New laptop: quick start](#1-new-laptop-quick-start)
2. [What is inside](#2-what-is-inside)
3. [How install.sh works](#3-how-installsh-works)
4. [How to use: shell, aliases, functions](#4-how-to-use-shell-aliases-functions)
5. [Settings: tmux, nvim, ghostty, git](#5-settings-tmux-nvim-ghostty-git)
6. [Daily work: add, update, remove](#6-daily-work-add-update-remove)
7. [Security rules](#7-security-rules)
8. [Test the install safely](#8-test-the-install-safely)
9. [Troubleshooting](#9-troubleshooting)

Git branches and commit messages: see [GIT-FLOW.md](GIT-FLOW.md).

---

## 1. New laptop: quick start

### macOS (M1 / M2 / M3)

```bash
# 1. Homebrew (installs to /opt/homebrew)
#    Get the command from https://brew.sh and run it.
# 2. Clone
git clone git@github.com:fnxr21/.dotfiles.git ~/dotfiles
cd ~/dotfiles
# 3. Look first (changes nothing)
./install.sh --dry-run
# 4. Install tools + links + fish plugins
./install.sh --packages
# 5. Your git name/email (file is NOT in git)
nvim ~/.gitconfig.local
# 6. Make fish the default shell
echo "$(command -v fish)" | sudo tee -a /etc/shells
chsh -s "$(command -v fish)"
# 7. Open a new terminal (Ghostty), then set the prompt look once:
tide configure
```

### Linux (Ubuntu / Debian)

```bash
sudo apt install -y git stow
git clone git@github.com:fnxr21/.dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run
./install.sh --packages        # apt install, asks for sudo
nvim ~/.gitconfig.local
chsh -s "$(command -v fish)"
tide configure
```

Some tools are **not in apt**. Install them by hand on Linux:

| tool | why | how |
|---|---|---|
| neovim ≥ 0.10 | LazyVim needs a new version | download from github.com/neovim/neovim/releases, unpack to `/opt/nvim` (fish adds `/opt/nvim/bin` to PATH) |
| ghostty | terminal | see ghostty.org/docs/install |
| asdf | Go versions (`go_19`, `go_24` …) | see asdf-vm.com |
| lazygit | tmux `prefix + g` | github.com/jesseduffield/lazygit releases |
| gitleaks | secret scan | github.com/gitleaks/gitleaks releases |
| PlemolJP Console NF | ghostty font | github.com/yuru7/PlemolJP releases → `~/.local/share/fonts` |
| VS Code Insiders | editor | code.visualstudio.com/insiders |

> On Ubuntu, `fd` is called `fdfind`. Fix: `ln -s (command -v fdfind) ~/.local/bin/fd`

---

## 2. What is inside

```
~/dotfiles/
├── install.sh              one script for macOS + Linux
├── Brewfile                macOS packages  (brew bundle)
├── packages-linux.txt      Linux packages  (apt)
├── gitconfig.local.example template for ~/.gitconfig.local
├── .gitignore              blocks secrets and machine state
├── .gitleaks.toml          secret scanner config
├── vendor/fisher.fish      pinned fisher (plugin manager)
├── config/_doc/            my notes (tmux, AI tools)
├── config/      ──▶ linked into ~/.config/
│   ├── fish/               shell
│   ├── nvim/               editor (LazyVim)
│   ├── tmux/               terminal multiplexer
│   ├── ghostty/            terminal
│   ├── htop/               process viewer
│   ├── enchant/            my spell-check word list
│   ├── git-secrets/        global.gitignore + secret patterns
│   └── claude-secure/      Claude Code secret protection kit
├── home/        ──▶ linked into ~/
│   ├── .gitconfig          shared git settings
│   └── .claude/settings.json
└── vscode/settings.json ──▶ VS Code Insiders "User" folder
```

| folder | links to | what it is |
|---|---|---|
| `config/fish` | `~/.config/fish` | `config.fish` (all OS), `config-osx.fish`, `config-linux.fish`, `fish_plugins`, my functions |
| `config/nvim` | `~/.config/nvim` | LazyVim. `lazy-lock.json` pins plugin versions |
| `config/tmux` | `~/.config/tmux` | `tmux.conf` + `macos.conf` / `linux.conf` + statusline + utility |
| `config/ghostty` | `~/.config/ghostty` | theme, font, opacity |
| `config/htop` | `~/.config/htop` | htop layout |
| `config/enchant` | `~/.config/enchant` | personal dictionary (Linux apps) |
| `config/git-secrets` | `~/.config/git-secrets` | `global.gitignore` (used by git `core.excludesFile`) and `patterns` |
| `config/claude-secure` | `~/.config/claude-secure` | `apply.sh` + templates (see §4) |
| `home/.gitconfig` | `~/.gitconfig` | shared git settings. Includes `~/.gitconfig.local` |
| `home/.claude/settings.json` | `~/.claude/settings.json` | Claude Code user settings |
| `vscode/settings.json` | macOS: `~/Library/Application Support/Code - Insiders/User/` · Linux: `~/.config/Code - Insiders/User/` | VS Code settings |

**Not in this repo (on purpose):** logins, sessions, caches, `fish_variables`, `~/.ssh`, cloud configs (gcloud …),
Linux desktop state (dconf, gnome, monitors …), `go/env`, API keys.

---

## 3. How install.sh works

```bash
./install.sh                 # links + git setup + fish plugins
./install.sh --dry-run       # only print, change nothing
./install.sh --packages      # also install tools (brew / apt)
./install.sh --no-plugins    # no download of fish plugins
./install.sh --help
```

Steps:

1. **Packages** (only with `--packages`): `brew bundle` on macOS, `apt-get install` on Linux.
2. **Backup**: if a real file is in the way, it is **moved** to `~/dotfiles-backup/<date-time>/`. Nothing is deleted.
3. **Links**: GNU Stow links **each file** (`--no-folding`) from `config/` → `~/.config` and `home/` → `~`.
   VS Code settings are linked to the right folder for the OS.
4. **Git**: creates `~/.gitconfig.local` (takes name/email from your old `~/.gitconfig` if it can).
   Installs git-secrets hooks into `~/.git-templates/git-secrets`, plus the claude-secure `pre-commit` and `post-checkout` hooks (new repos get them on `git init` **and** `git clone`, from any terminal).
5. **Fish plugins**: loads `vendor/fisher.fish` and runs `fisher update` → installs everything in `fish_plugins`.
   This is the **only step that downloads code** (from GitHub).

**Safe to run twice:** correct links are skipped; no new backup is made when nothing changes.

**Undo:**
```bash
cd ~/dotfiles
stow -D -t ~/.config config
stow -D -t ~ home
# then copy your files back from ~/dotfiles-backup/<date-time>/
```

---

## 4. How to use: shell, aliases, functions

### Fish plugins (`config/fish/fish_plugins`)

| plugin | what it gives you |
|---|---|
| `jorgebucaran/fisher` | plugin manager: `fisher list`, `fisher update`, `fisher install <user/repo>` |
| `ilancosman/tide@v6` | the prompt. Change the look: `tide configure` |
| `patrickf1/fzf.fish` | fuzzy search keys (below) |
| `jethrokuan/z` | jump to folders: `z proj` goes to your most used folder matching "proj" |
| `jorgebucaran/nvm.fish` | Node versions: `nvm install lts`, `nvm use 20` |
| `edc/bass` | run bash scripts in fish: `bass source script.sh` |

**fzf.fish keys:**

| key | search |
|---|---|
| `Ctrl+R` | command history |
| `Ctrl+Alt+F` | files in this folder |
| `Ctrl+Alt+L` | git log |
| `Ctrl+Alt+S` | git status |
| `Ctrl+Alt+P` | processes |
| `Ctrl+V` | shell variables |

### Aliases (`config.fish`)

| alias | runs |
|---|---|
| `g` | `git` |
| `c` | `claude` |
| `ag` | `antigravity` |
| `vim` | `nvim` (if installed) |
| `python` | `python3` |
| `ls` | `ls -p` with colors (macOS `-G`, Linux `--color=auto`) |
| `la` / `ll` / `lla` | all / long / long + all |

`EDITOR` is `nvim`.

### Go versions (asdf)

`go_19`, `go_21`, `go_24`, `go_26` → `asdf set golang <version>` in the current folder.
Default version is in `config/fish/.tool-versions`.

### My functions (`config/fish/functions/`)

| function | what it does |
|---|---|
| `make` | runs `make`; if a line has JSON, it prints it pretty with `jq`. Note: it hides make's exit code |
| `git` | normal `git`, but after `git init` it also runs `claude-secure` on the new repo. Skip once: `CLAUDE_SECURE_SKIP=1 git init` |
| `claude-secure [dir]` | adds Claude Code secret protection to a project: `.claude/hooks/protect_secrets.py`, `.claude/settings.json` (merged), `CLAUDE.md` (appended), `.gitignore` lines, git hooks (pre-commit + git-secrets). Safe to run again |
| `claude-secure --local [dir]` | same, for **someone else's** project: writes `.claude/settings.local.json`, `.claude/CLAUDE.md` and `.git/info/exclude` instead, so `git status` stays clean. Runs by itself after `git clone` |
| `fish_mode_prompt` | empty: hides the vi-mode label |

### OS-specific fish settings

`config.fish` ends with:

```fish
switch (uname)
    case Darwin
        source .../config-osx.fish     # Homebrew shellenv (/opt/homebrew), ls -G
    case Linux
        source .../config-linux.fish   # greeting, ls --color, /opt/nvim/bin in PATH
end
```

Put Mac-only things in `config-osx.fish`, Linux-only things in `config-linux.fish`.

---

## 5. Settings: tmux, nvim, ghostty, git

### tmux

Prefix is **`Ctrl+t`** (not `Ctrl+b`).

| keys | action |
|---|---|
| `prefix` `\|` | split left / right |
| `prefix` `-` | split top / bottom |
| `prefix` `h` `j` `k` `l` | move between panes |
| `prefix` `Ctrl+h/j/k/l` | resize pane (5 cells) |
| `prefix` `e` | close all other panes |
| `prefix` `r` | reload config |
| `prefix` `o` | open current folder (Finder / file manager) |
| `prefix` `g` | lazygit popup |
| `Ctrl+Shift+←/→` | move window left / right |

Copy mode uses vi keys. Files: `tmux.conf` (main), `statusline.conf` (colors/status bar),
`utility.conf` (lazygit), `macos.conf` / `linux.conf` (per OS). More notes: `config/_doc/tmux/tmux.md`.

### nvim

LazyVim starter. First start installs plugins (needs internet).
- Your options: `lua/config/options.lua` · keymaps: `lua/config/keymaps.lua` · plugins: `lua/plugins/*.lua`
- `lazy-lock.json` pins plugin versions. Update: `:Lazy update`, then commit the new lock file.
- Health check: `:checkhealth`
- Needs: `git`, `ripgrep`, `fd`, a C compiler, `lazygit` (optional).

### ghostty

`config/ghostty/config.ghostty`: theme "Solarized Dark - Patched" (in `themes/`), font
**PlemolJP Console NF**, opacity 0.9, blur. `macos-option-as-alt = left` (macOS only, ignored on Linux).
Reload: `Cmd+Shift+,` (macOS) / `Ctrl+Shift+,` (Linux).

### git

- `home/.gitconfig`: shared settings (pull, bitbucket SSH url, git-secrets rules, hooks template, global ignore).
  At the end: `[include] path = ~/.gitconfig.local`.
- `~/.gitconfig.local`: **your name and email**. Not in git. Template: `gitconfig.local.example`.
- `core.excludesFile` = `~/.config/git-secrets/global.gitignore` → ignored in **every** repo.
- `init.templateDir` = `~/.git-templates/git-secrets` → every new repo gets these hooks (any terminal, VS Code, scripts):

  | hook | when | does |
  |---|---|---|
  | `pre-commit` | every commit | blocks secret file names, runs git-secrets, runs gitleaks (if installed). If the repo has no `.claude/` protection yet, adds it |
  | `commit-msg` | every commit | Conventional Commits format, subject <= 72 chars, no emoji; then git-secrets on the message |
  | `prepare-commit-msg` | every commit | git-secrets on the message |
  | `pre-push` | every push | blocks pushes to `main`/`master` (use a PR). See [GIT-FLOW.md](GIT-FLOW.md) |
  | `post-checkout` | right after `git clone` | runs `claude-secure --local` (skips tool folders like `~/.local`, `~/.cache`, Homebrew). Skip once: `CLAUDE_SECURE_SKIP=1 git clone ...` |

  Old repos (made before this): run `claude-secure` (own repo) or `claude-secure --local` (someone else's) inside them.
- Guide: `config/git-secrets/readme_first_step.md`

### VS Code Insiders

Only `settings.json` is shared. Extensions are not.
**WakaTime API key is NOT in this file.** Put it in `~/.wakatime.cfg`:

```ini
[settings]
api_key = YOUR_WAKATIME_API_KEY
```

### Claude Code

`home/.claude/settings.json` = user settings. Install Claude Code: see `config/_doc/ai/claude-code.md`.
9router (optional): `config/_doc/ai/9router.md`.

---

## 6. Daily work: add, update, remove

Files in `~/.config` are **links** to this repo. Edit them normally; the change is already in the repo.

```bash
cd ~/dotfiles
git status
git diff
gitleaks git . --redact -v && gitleaks dir . --redact -v   # secret scan
git add -A && git commit -m "fish: add alias"
git push
```

**Add a new config** (example: `~/.config/lazygit/config.yml`):

```bash
mkdir -p ~/dotfiles/config/lazygit
mv ~/.config/lazygit/config.yml ~/dotfiles/config/lazygit/
cd ~/dotfiles && ./install.sh --no-plugins     # creates the link
```

**Update on another machine:**

```bash
cd ~/dotfiles && git pull && ./install.sh
```

**Add a fish plugin:** `fisher install user/repo` (it also updates `fish_plugins`), then commit.

**Stop linking one file:** `rm ~/.config/x/file` (removes only the link), then copy the file back from the repo.

---

## 7. Security rules

- **Never commit** `.env`, keys (`*.pem`, `*.key`, `id_*`), `*credential*.json`, tokens, `auth.json`, `hosts.yml`.
  `.gitignore` blocks most of them, but **always check `git status` before commit**.
- Secrets go into env vars, `~/.gitconfig.local`, `~/.wakatime.cfg`, or a secret manager. Not into this repo.
- **Scan before push:**
  ```bash
  gitleaks git . --redact -v      # all git history
  gitleaks dir . --redact -v      # current files
  git secrets --scan
  ```
  `.gitleaks.toml` only allows the **fake** example keys in `config/git-secrets/readme_first_step.md`.
- **If a secret was committed:** deleting it is **not enough** (it stays in git history).
  1. **Rotate** the key at the provider (make a new one, turn off the old one).
  2. Then clean history (e.g. `git filter-repo`) and force-push. Only after step 1.
- Check if the GitHub repo is public or private: GitHub → repo → Settings → "Danger Zone" / visibility.

---

## 8. Test the install safely

Use a **fake HOME**, so your real files are not touched:

```bash
cd ~/dotfiles
T=$(mktemp -d)
HOME=$T ./install.sh --dry-run --no-plugins     # 1. only print
HOME=$T ./install.sh --no-plugins               # 2. real run, in the fake home
find $T -maxdepth 3 -type l -printf '%p -> %l\n' | head -30   # 3. see links
HOME=$T ./install.sh --no-plugins               # 4. run again: nothing new should happen
HOME=$T fish -c 'echo fish OK'                  # 5. config loads?
rm -rf "$T"                                     # 6. clean up the fake home
```

Test a backup: put a file in the way first (`mkdir -p $T/.config/tmux; echo old > $T/.config/tmux/tmux.conf`),
run the script, and check that `$T/dotfiles-backup/<date>/.config/tmux/tmux.conf` exists.

---

## 9. Troubleshooting

| problem | fix |
|---|---|
| `stow: WARNING! stowing ... would cause conflicts` | a real file is there. `./install.sh` moves it to the backup first. Running `stow` by hand? Move the file yourself |
| prompt looks plain | `fisher update`, then `tide configure` |
| `fd` not found on Ubuntu | `ln -s (command -v fdfind) ~/.local/bin/fd` |
| nvim errors on start | neovim too old (need ≥ 0.10): `nvim --version` |
| tmux clipboard on macOS | `brew install reattach-to-user-namespace` |
| git says "please tell me who you are" | fill in `~/.gitconfig.local` |
| htop changed the link into a normal file | htop rewrites its file on exit. Copy it back to `config/htop/htoprc` and run `./install.sh` |
