# Claude Code

## How to Install

Install Claude Code using the official installer:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

After installation, check the version:

```bash
claude --version
```

## How to Run

Go to your project directory:

```bash
cd /path/to/your/project
```

Start Claude Code:

```bash
claude
```

## How to Login

Run:

```bash
claude
```

If you are not authenticated, Claude Code will ask you to log in.

Follow the authentication steps shown in the terminal/browser.

## How to Exit

Exit Claude Code with:

```text
/exit
```

Or:

```text
Ctrl+C
```

## Configuration

Claude Code configuration:

```text
~/.claude/
```

Project-specific instructions:

```text
CLAUDE.md
```

Example:

```text
my-project/
├── CLAUDE.md
├── src/
└── ...
```

## Useful Commands

Check version:

```bash
claude --version
```

Show help:

```bash
claude --help
```

Continue the previous session:

```bash
claude --continue
```

Resume a previous session:

```bash
claude --resume
```

## Security

Before using Claude Code with a project, review the official security documentation:

https://code.claude.com/docs/en/security

The security documentation covers topics such as:

* Permissions
* Tool access
* File and directory access
* Command execution
* Authentication
* Data handling
* Security best practices

**Official documentation:**

https://code.claude.com/docs/en/security

