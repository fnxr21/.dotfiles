#!/usr/bin/env python3
"""
Claude Code PreToolUse hook: blocks access to secret files.

Second layer of protection in case a `permissions.deny` rule is not applied
(there have been reported bugs), and it also checks Bash commands, which
deny rules for Read() do not cover.

Exit code 2 = block the tool call and show the reason to Claude.
This file never reads or prints any secret content.
"""
import json
import re
import sys

# Filename / path patterns that must never be touched
SENSITIVE = [
    r"(^|[/\\\s'\"=(])\.env($|[.\s'\"/)])",       # .env, .env.local, .env.prod
    r"[^/\\\s]*\.env($|[\s'\"])",               # prod.env
    r"credential-google\.json",
    r"credentials?[^/\\\s]*\.json",
    r"service[-_]?account[^/\\\s]*\.json",
    r"application_default_credentials\.json",
    r"\.config[/\\]gcloud",
    r"\.aws[/\\]",
    r"\.azure[/\\]",
    r"\.ssh[/\\]",
    r"id_rsa|id_ed25519",
    r"\.pem($|[\s'\")])",
    r"\.key($|[\s'\")])",
    r"\.p12($|[\s'\")])",
    r"(^|[/\\\s'\"=(])secrets[/\\]",
]

# Allowed: example/template files with no real values
SAFE = [r"\.env\.example", r"\.env\.sample", r"\.env\.template"]

# Bash commands that dump secrets from memory/env
BAD_COMMANDS = [
    r"(^|[\s;&|])printenv\b",
    r"(^|[\s;&|])env\s*($|[;&|])",
    r"(^|[\s;&|])set\s*($|[;&|])",
    r"print-access-token",
    r"print-identity-token",
    r"secrets\s+versions\s+access",               # gcloud secret manager
    r"echo\s+[\"']?\$\{?[A-Z_]*(KEY|SECRET|TOKEN|PASS|PASSWORD)",
]


def strip_safe(text: str) -> str:
    for p in SAFE:
        text = re.sub(p, "", text, flags=re.IGNORECASE)
    return text


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # not our input; don't break Claude Code

    tool = data.get("tool_name", "")
    tin = data.get("tool_input", {}) or {}

    # Collect every string field that could contain a path or command
    fields = [str(v) for k, v in tin.items()
              if k in ("file_path", "path", "pattern", "glob", "command", "notebook_path")]
    text = strip_safe(" ".join(fields))

    for p in SENSITIVE:
        if re.search(p, text, flags=re.IGNORECASE):
            print(
                f"BLOCKED by security policy: {tool} touches a protected secret file "
                "(.env, credentials, keys, cloud config). Do not read or print it. "
                "Ask the user for a sanitized example (e.g. .env.example) instead.",
                file=sys.stderr,
            )
            sys.exit(2)

    if tool == "Bash":
        for p in BAD_COMMANDS:
            if re.search(p, text, flags=re.IGNORECASE):
                print(
                    "BLOCKED by security policy: this command could print secrets "
                    "or tokens. Use placeholders instead.",
                    file=sys.stderr,
                )
                sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
