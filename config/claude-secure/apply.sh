#!/usr/bin/env bash
# claude-secure: add Claude Code secret protection to a project.
# Usage: apply.sh [project-dir]     (default: current folder)
# Safe to run many times. It never overwrites your files: it merges or appends.
# It never opens .env, credential or key files.
set -euo pipefail

KIT="${CLAUDE_SECURE_HOME:-$HOME/.config/claude-secure}"
T="$KIT/templates"
DIR="$(cd "${1:-.}" && pwd)"
MARK="<!-- claude-secure -->"

[ -d "$T" ] || { echo "claude-secure: templates not found in $T" >&2; exit 1; }
cd "$DIR"
changed=()

# 1) .claude/hooks/protect_secrets.py
mkdir -p .claude/hooks
if ! cmp -s "$T/hooks/protect_secrets.py" .claude/hooks/protect_secrets.py 2>/dev/null; then
  cp "$T/hooks/protect_secrets.py" .claude/hooks/protect_secrets.py
  chmod +x .claude/hooks/protect_secrets.py
  changed+=(".claude/hooks/protect_secrets.py")
fi

# 2) .claude/settings.json  (merge, never overwrite)
if python3 - "$T/settings.json" .claude/settings.json <<'PY'
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
then changed+=(".claude/settings.json")
else rc=$?; [ $rc -eq 3 ] || exit $rc
fi

# 3) CLAUDE.md  (append once, keeps your own text)
if ! grep -qF "$MARK" CLAUDE.md 2>/dev/null; then
  { [ -s CLAUDE.md ] && printf '\n'; echo "$MARK"; cat "$T/CLAUDE.md"; } >> CLAUDE.md
  changed+=("CLAUDE.md")
fi

# 4) .gitignore  (add only missing lines)
touch .gitignore
added=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if ! grep -qxF -- "$line" .gitignore; then
    [ $added -eq 0 ] && { [ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ] && echo >> .gitignore; }
    echo "$line" >> .gitignore; added=1
  fi
done < "$T/gitignore-additions.txt"
[ $added -eq 1 ] && changed+=(".gitignore")

# 5) git pre-commit hook (only if this is a git repo and no hook exists yet)
if gitdir=$(git rev-parse --git-dir 2>/dev/null); then
  hook="$gitdir/hooks/pre-commit"
  if [ ! -e "$hook" ]; then
    mkdir -p "$gitdir/hooks"; cp "$T/pre-commit" "$hook"; chmod +x "$hook"
    changed+=("git pre-commit hook")
  elif ! grep -q "claude-secure" "$hook"; then
    echo "claude-secure: a pre-commit hook already exists; not replaced. See $T/pre-commit" >&2
  fi
  # Warn about secret files that git ALREADY tracks (.gitignore can't help those)
  tracked=$(git ls-files 2>/dev/null | grep -E -i '(^|/)\.env($|\.)|credential[^/]*\.json$|\.(pem|key|p12)$' | grep -E -v -i '\.env\.(example|sample|template)$' || true)
  if [ -n "$tracked" ]; then
    echo "claude-secure WARNING: git already tracks these secret-looking files:" >&2
    echo "$tracked" | sed 's/^/  - /' >&2
    echo "  Untrack with: git rm --cached <file>   (and rotate the secret if it was pushed)" >&2
  fi
fi

if [ ${#changed[@]} -gt 0 ]; then
  echo "🔒 claude-secure: protected $(basename "$DIR") → ${changed[*]}"
else
  echo "🔒 claude-secure: $(basename "$DIR") already protected"
fi
