# Git Flow + Conventional Commits

How to make branches and write commits in this repo.

---

## 1. Branches

| Branch       | Comes from | Merges into          | What it is for                          |
|--------------|------------|----------------------|-----------------------------------------|
| `main`       | —          | —                    | Stable. What a new laptop installs.     |
| `develop`    | `main`     | `main` (via release) | Daily work lands here first.            |
| `feature/*`  | `develop`  | `develop`            | One new thing (tool, config, function). |
| `release/*`  | `develop`  | `main` + `develop`   | Freeze, test install, then ship.        |
| `hotfix/*`   | `main`     | `main` + `develop`   | Urgent fix for something broken on main.|

Other long-lived branches (for example `linux-ubuntu`) stay as they are.

### Branch names

Lowercase, words joined with `-`:

```
feature/nvim-lsp-go
feature/tmux-linux-clipboard
release/v1.2.0
hotfix/install-stow-path
```

---

## 2. Daily flow

### New feature

```bash
git switch develop
git pull
git switch -c feature/tmux-linux-clipboard

# ...edit, then commit (see section 3)...
git add config/tmux/linux.conf
git commit -m "feat(tmux): copy to system clipboard on linux"

# done: merge back into develop
git switch develop
git merge --no-ff feature/tmux-linux-clipboard
git branch -d feature/tmux-linux-clipboard
git push fn develop
```

### Release (develop → main)

```bash
git switch develop
git switch -c release/v1.2.0
./install.sh --dry-run              # test before shipping
git commit -am "chore(release): v1.2.0"

git switch main
git merge --no-ff release/v1.2.0
git tag -a v1.2.0 -m "v1.2.0"

git switch develop
git merge --no-ff release/v1.2.0
git branch -d release/v1.2.0
git push fn main develop --tags
```

### Hotfix (broken on main)

```bash
git switch main
git switch -c hotfix/install-stow-path
git commit -am "fix(install): use correct stow target dir"

git switch main
git merge --no-ff hotfix/install-stow-path
git tag -a v1.2.1 -m "v1.2.1"

git switch develop
git merge --no-ff hotfix/install-stow-path
git branch -d hotfix/install-stow-path
git push fn main develop --tags
```

> Using the `git-flow` tool? `git flow init -d` uses these same names
> (`main`, `develop`, `feature/`, `release/`, `hotfix/`).

---

## 3. Conventional Commits

Format:

```
<type>(<scope>): <short summary>

<optional body: why, not what>

<optional footer: BREAKING CHANGE: ..., Refs #12>
```

Rules:

- Summary in lowercase, imperative ("add", not "added"), no period, ≤ 72 chars.
- `scope` = the tool or folder you touched: `fish`, `tmux`, `nvim`, `git`, `install`, `vscode`, `htop`, `claude`, `docs`.
- Breaking change: add `!` after the type, or a `BREAKING CHANGE:` footer.

### Types

| Type       | Use when                                        |
|------------|-------------------------------------------------|
| `feat`     | New config, tool, alias, function               |
| `fix`      | Something was broken, now works                 |
| `docs`     | README / docs only                              |
| `style`    | Formatting only, no behaviour change            |
| `refactor` | Restructure, same behaviour                     |
| `perf`     | Faster startup / less work                      |
| `test`     | Test scripts                                    |
| `build`    | Package lists: `Brewfile`, `packages-linux.txt` |
| `ci`       | CI workflows                                    |
| `chore`    | Housekeeping: `.gitignore`, vendored files      |
| `revert`   | Undo an earlier commit                          |

### Examples

```
feat(fish): add claude-secure wrapper for git init
fix(tmux): reload config path on macos
docs: add git flow guide
build: add htop and stow to Brewfile
chore: ignore fish_variables and backup files
refactor(install)!: link home/ with stow instead of cp

BREAKING CHANGE: old copied files in ~ must be removed before install.
```

### Commit template

`home/.gitmessage` is linked to `~/.gitmessage` and set as `commit.template`
in `home/.gitconfig`. Run `git commit` (no `-m`) and the editor opens with the
type list as a reminder. Lines starting with `#` are dropped.

---

## 4. Quick cheatsheet

```bash
git switch -c feature/<name> develop     # start feature
git switch -c release/vX.Y.Z develop     # start release
git switch -c hotfix/<name> main         # start hotfix
git merge --no-ff <branch>               # finish (keep branch history)
git log --oneline --graph --all          # see the flow
```
