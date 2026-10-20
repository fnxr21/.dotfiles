# Git rules (all projects)

## Branches
- Never push to `main` or `master`. `main` changes only through a pull request.
- Layers: `feature/*` -> `dev` -> `stg` (staging) -> `beta` (optional prod-like testing) -> `main` (PR).
- Urgent prod fix: `hotfix/*` from `main`, PR into `main`, then merge into `dev`.
- New work starts on `feature/<name>` from `dev`. Names: lowercase, words joined with `-`.

## Commits
- Conventional Commits: `<type>(<scope>): <summary>`, lowercase, imperative, no period, <= 72 chars.
- Types: feat fix docs style refactor perf test build ci chore revert.
- Short and clear. Small change: subject only. Many changes: blank line, then one `- ` bullet per change.
- No emoji or icons. No Co-Authored-By, Claude-Session or "Generated with" lines.
