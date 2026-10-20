# Git Flow + Conventional Commits

How to make branches and write commits. These rules apply to every repo on this
machine (git hooks from `~/.git-templates`, see section 4).

---

## 1. Rules

1. **Never push to `main`.** Not from the terminal, VS Code, scripts or Claude.
   `main` only changes through a **pull request**.
2. Daily work goes to `dev` through `feature/*` branches.
3. Code moves up the layers: `dev` → `stg` → `beta` (optional) → `main` (PR).
4. Commits follow Conventional Commits. No emoji or icons.

---

## 2. Branches

| Branch      | Layer                  | Comes from | Goes to                     |
|-------------|------------------------|------------|-----------------------------|
| `main`      | production             | —          | — (PR only)                 |
| `beta`      | prod-like testing (optional) | `stg` | `main` via PR             |
| `stg`       | staging deploy         | `dev`      | `beta`, or `main` via PR    |
| `dev`       | development            | `main`     | `stg`                       |
| `feature/*` | one feature / new function | `dev`  | `dev`                       |
| `hotfix/*`  | urgent fix for prod    | `main`     | `main` via PR, then `dev`   |

```
feature/*  ──►  dev  ──►  stg  ──►  beta (optional)  ──PR──►  main
                 ▲                                              │
                 └──────────────  hotfix/*  ◄────────────────────┘
```

### Branch names

Lowercase, words joined with `-`:

```
feature/nvim-lsp-go
feature/install-linux-packages
hotfix/install-stow-path
```

---

## 3. Daily flow

### New feature or function

```bash
git switch dev && git pull
git switch -c feature/tmux-linux-clipboard

# ...edit and commit (section 5)...

git switch dev
git merge --no-ff feature/tmux-linux-clipboard
git branch -d feature/tmux-linux-clipboard
git push origin dev
```

### Deploy to staging

```bash
git switch stg && git pull
git merge --no-ff dev
git push origin stg
```

### Prod-like testing (optional)

```bash
git switch beta && git pull
git merge --no-ff stg
git push origin beta
```

### Release to production

Open a pull request on GitHub: **`beta` → `main`** (or **`stg` → `main`** when
you skip beta). Merge it there. Then tag:

```bash
git switch main && git pull
git tag -a v1.2.0 -m "v1.2.0"
git push origin v1.2.0
```

### Hotfix (broken in production)

```bash
git switch main && git pull
git switch -c hotfix/install-stow-path
git commit -am "fix(install): use correct stow target dir"
git push -u origin hotfix/install-stow-path
# open a PR: hotfix/install-stow-path -> main, merge it

# bring the fix back down so it is not lost
git switch dev && git pull
git merge --no-ff hotfix/install-stow-path
git push origin dev
git branch -d hotfix/install-stow-path
```

---

## 4. What enforces this

| Where | What | Bypass |
|-------|------|--------|
| `pre-push` hook | blocks any push to `main`/`master` (a first push that creates `main` on an empty remote is allowed) | `--no-verify` (emergency only) |
| `commit-msg` hook | blocks non-conventional messages, subjects over 72 chars, emoji | `--no-verify` |
| GitHub branch protection on `main` | requires a PR; blocks even `--no-verify` | repo admin |

Hooks are local. **Turn on branch protection** so the rule holds from
everywhere: GitHub → repo → Settings → Branches → Add rule → `main` →
"Require a pull request before merging".

Old repos (made before these hooks): run `claude-secure` (own repo) or
`claude-secure --local` (someone else's) inside them.

---

## 5. Commits

Format:

```
<type>(<scope>): <summary>

- <change one>
- <change two>
```

Rules:

- Summary: lowercase, imperative ("add", not "added"), no period, ≤ 72 chars.
- Short and clear. Say what changed; skip what the diff already shows.
- **Small change:** subject line only.
- **Many changes:** subject line, blank line, then one bullet per change.
- No emoji, no icons, no ticket noise.
- `scope` = the tool or area you touched: `fish`, `tmux`, `nvim`, `git`,
  `install`, `vscode`, `claude`, `docs` ...
- Breaking change: `!` after the type, plus a `BREAKING CHANGE:` line.

### Types

| Type       | Use when                                   |
|------------|--------------------------------------------|
| `feat`     | new feature, config, tool, function        |
| `fix`      | something was broken, now works            |
| `docs`     | docs only                                  |
| `style`    | formatting only, no behaviour change       |
| `refactor` | restructure, same behaviour                |
| `perf`     | faster / lighter                           |
| `test`     | tests                                      |
| `build`    | dependencies, package lists                |
| `ci`       | CI workflows                               |
| `chore`    | housekeeping                               |
| `revert`   | undo an earlier commit                     |

### Examples

Small:

```
fix(tmux): reload config path on macos
docs: add git flow guide
```

Many changes:

```
feat(git): enforce branch and commit rules

- block direct pushes to main with a pre-push hook
- check conventional commit format in commit-msg
- add dev, stg and beta branch guide
```

Breaking:

```
refactor(install)!: link home/ with stow instead of cp

BREAKING CHANGE: remove old copied files in ~ before running install.
```

### Commit template

`git commit` (no `-m`) opens the editor with `~/.gitmessage` as a reminder.
Lines starting with `#` are dropped.

---

## 6. Cheatsheet

```bash
git switch -c feature/<name> dev       # start feature
git switch -c hotfix/<name> main       # start hotfix
git merge --no-ff <branch>             # merge, keep branch history
git log --oneline --graph --all        # see the flow
```
