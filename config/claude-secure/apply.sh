#!/usr/bin/env bash
# claude-secure: add Claude Code secret protection to a project.
# Usage: apply.sh [--local] [project-dir]     (default: current folder)
#   default  : your own project. Writes .claude/settings.json, CLAUDE.md, .gitignore
#              (meant to be committed).
#   --local  : someone else's project (used after `git clone`). Never touches tracked
#              files: writes .claude/settings.local.json, .claude/CLAUDE.md and
#              .git/info/exclude, so nothing shows up in `git status`.
# Safe to run many times. It never overwrites your files: it merges or appends.
# It never opens .env, credential or key files.
set -euo pipefail

LOCAL=0
if [ "${1:-}" = "--local" ]; then LOCAL=1; shift; fi

KIT="${CLAUDE_SECURE_HOME:-$HOME/.config/claude-secure}"
T="$KIT/templates"
DIR="$(cd "${1:-.}" && pwd)"
MARK="<!-- claude-secure -->"

[ -d "$T" ] || { echo "claude-secure: templates not found in $T" >&2; exit 1; }
cd "$DIR"
changed=()
gitdir=$(git rev-parse --git-dir 2>/dev/null || true)

tracked() { [ -n "$gitdir" ] && git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; }

# 1) .claude/hooks/protect_secrets.py  (leave it alone if the project tracks its own)
mkdir -p .claude/hooks
if ! tracked .claude/hooks/protect_secrets.py \
   && ! cmp -s "$T/hooks/protect_secrets.py" .claude/hooks/protect_secrets.py 2>/dev/null; then
  cp "$T/hooks/protect_secrets.py" .claude/hooks/protect_secrets.py
  chmod +x .claude/hooks/protect_secrets.py
  changed+=(".claude/hooks/protect_secrets.py")
fi

# 2) settings  (merge, never overwrite)
settings=.claude/settings.json
if [ $LOCAL -eq 1 ]; then
  settings=.claude/settings.local.json
  # project already ships the protection: nothing to add
  grep -qs "protect_secrets.py" .claude/settings.json && settings=""
fi
if [ -n "$settings" ]; then
if python3 - "$T/settings.json" "$settings" <<'PY'
import json, os, sys
src, dst = sys.argv[1], sys.argv[2]
new = json.load(open(src))
if os.path.exists(dst):
    try:
        cur = json.load(open(dst))
    except Exception:
        print(f"claude-secure: {dst} is not valid JSON, left unchanged", file=sys.stderr)
        sys.exit(1)
else:
    cur = {}
before = json.dumps(cur, sort_keys=True)

perm = cur.setdefault("permissions", {})
for key in ("deny", "ask"):
    lst = perm.setdefault(key, [])
    for rule in new["permissions"].get(key, []):
        if rule not in lst:
            lst.append(rule)

env = cur.setdefault("env", {})
for k, v in new.get("env", {}).items():
    env.setdefault(k, v)

hooks = cur.setdefault("hooks", {}).setdefault("PreToolUse", [])
present = {h.get("command") for g in hooks for h in g.get("hooks", [])}
for g in new["hooks"]["PreToolUse"]:
    if not any(h["command"] in present for h in g["hooks"]):
        hooks.append(g)

if json.dumps(cur, sort_keys=True) != before:
    json.dump(cur, open(dst, "w"), indent=2)
    open(dst, "a").write("\n")
    sys.exit(0)
sys.exit(3)   # nothing changed
PY
then changed+=("$settings")
else rc=$?; [ $rc -eq 3 ] || exit $rc
fi
fi

# 3) rules for Claude  (append once, keeps your own text)
rules=CLAUDE.md
if [ $LOCAL -eq 1 ]; then
  rules=.claude/CLAUDE.md
  # project already has the rules, or tracks its own .claude/CLAUDE.md
  { grep -qsF "$MARK" CLAUDE.md || tracked .claude/CLAUDE.md; } && rules=""
fi
if [ -n "$rules" ] && ! grep -qsF "$MARK" "$rules"; then
  { [ -s "$rules" ] && printf '\n'; echo "$MARK"; cat "$T/CLAUDE.md"; } >> "$rules"
  changed+=("$rules")
fi

# 4) ignore list  (add only missing lines)
#    own project: .gitignore (committed)   --local: .git/info/exclude (never committed)
ignore=.gitignore
extra=()
if [ $LOCAL -eq 1 ]; then
  [ -n "$gitdir" ] || { echo "claude-secure: --local needs a git repo" >&2; exit 1; }
  ignore=$(git rev-parse --git-path info/exclude)
  mkdir -p "$(dirname "$ignore")"
  extra=(".claude/hooks/protect_secrets.py" ".claude/settings.local.json" ".claude/CLAUDE.md" ".claude/secure-allow")
fi
touch "$ignore"
added=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if ! grep -qxF -- "$line" "$ignore"; then
    [ $added -eq 0 ] && { [ -s "$ignore" ] && [ -n "$(tail -c1 "$ignore")" ] && echo >> "$ignore"; }
    echo "$line" >> "$ignore"; added=1
  fi
done < <(cat "$T/gitignore-additions.txt"; printf '%s\n' "${extra[@]+"${extra[@]}"}")
[ $added -eq 1 ] && changed+=("$ignore")

# 5) git hooks: pre-commit + commit-msg (both also run git-secrets), pre-push (no
#    direct push to main). Replaces a plain one-line git-secrets hook.
if [ -n "$gitdir" ]; then
  hooks_dir="$(git rev-parse --git-path hooks)"
  mkdir -p "$hooks_dir"
  for h in pre-commit commit-msg pre-push; do
    hp="$hooks_dir/$h"
    if [ ! -e "$hp" ] || { ! grep -q "claude-secure" "$hp" && grep -q "git secrets --" "$hp" && [ "$(grep -cv '^#' "$hp")" -le 1 ]; }; then
      cp "$T/$h" "$hp"; chmod +x "$hp"
      changed+=("git $h hook")
    elif ! grep -q "claude-secure" "$hp"; then
      echo "claude-secure: a $h hook already exists; not replaced. See $T/$h" >&2
    fi
  done
  # git-secrets prepare-commit-msg hook, if missing (same as a fresh `git init` gets)
  hp="$hooks_dir/prepare-commit-msg"
  if [ ! -e "$hp" ] && command -v git-secrets >/dev/null 2>&1; then
    printf '#!/usr/bin/env bash\ngit secrets --prepare_commit_msg_hook -- "$@"\n' > "$hp"; chmod +x "$hp"
    changed+=("git prepare-commit-msg hook")
  fi
  # Warn about secret files that git ALREADY tracks (.gitignore can't help those)
  tracked_secrets=$(git ls-files 2>/dev/null | grep -E -i '(^|/)\.env($|\.)|credential[^/]*\.json$|\.(pem|key|p12)$' | grep -E -v -i '\.env\.(example|sample|template)$' || true)
  if [ -n "$tracked_secrets" ]; then
    echo "claude-secure WARNING: git already tracks these secret-looking files:" >&2
    echo "$tracked_secrets" | sed 's/^/  - /' >&2
    echo "  Untrack with: git rm --cached <file>   (and rotate the secret if it was pushed)" >&2
  fi
fi

mode=""; [ $LOCAL -eq 1 ] && mode=" (local)"
if [ ${#changed[@]} -gt 0 ]; then
  echo "🔒 claude-secure$mode: protected $(basename "$DIR") → ${changed[*]}"
else
  echo "🔒 claude-secure$mode: $(basename "$DIR") already protected"
fi
