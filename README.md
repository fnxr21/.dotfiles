# Dotfiles

Personal Linux configuration files and development environment setup.

## Requirements

* Ubuntu / Linux
* Git
* Fish shell
* Git Secrets
* asdf
* Claude Code

## Repository Structure

```text
dotfiles/
├── .config/
│   ├── fish/
│   ├── git-secrets/
│   └── ...
├── README.md
└── ...
```

## Clone

Clone the repository:

```bash
git clone <repository-url> ~/dotfiles
```

Go to the dotfiles directory:

```bash
cd ~/dotfiles
```

## Configuration

Configuration files are stored under:

```text
~/.config/
```

For example:

```text
~/.config/
├── fish/
├── git-secrets/
└── ...
```

Create the `.config` directory if it does not exist:

```bash
mkdir -p ~/.config
```

Then copy or link the required configuration files.

## Git Secrets

Git Secrets is configured to help prevent accidentally committing credentials and sensitive files.

Example protected files:

```text
.env
*.pem
*.key
gli-dev-storage.json
gli-dev-secret.json
```

Before committing changes, check:

```bash
git secrets --scan
```

## Claude Code

Claude Code configuration can be stored in:

```text
~/.claude/
```

Install Claude Code:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Check the installation:

```bash
claude --version
```

Run Claude Code:

```bash
claude
```

Security documentation:

https://code.claude.com/docs/en/security

## 9Router

9Router is optional and is **not required for Claude Code**.

Install:

```bash
npm install -g 9router
```

Run:

```bash
9router
```

Dashboard:

```text
http://localhost:20128/dashboard
```

To find the process:

```bash
sudo ss -ltnp 'sport = :20128'
```

Example:

```text
LISTEN  0  511  0.0.0.0:20128  0.0.0.0:*  users:(("next-server (v1",pid=151938,fd=21))
```

Kill the process:

```bash
kill 151938
```

**Note:** Avoid connecting your main Claude account to third-party routers unless you understand the authentication and security implications.

## Security

**Never commit credentials or secrets to this repository.**

Do not store:

```text
.env
*.pem
*.key
passwords
API keys
access tokens
private keys
cloud credentials
```

Use environment variables or a secure secret manager for sensitive information.

Before pushing:

```bash
git status
git secrets --scan
```

## Update

Pull the latest configuration:

```bash
cd ~/dotfiles
git pull
```

After changing configuration, restart the relevant application or shell.

## Backup

This repository is intended to keep personal configuration reproducible across machines.

Before making major changes:

```bash
git status
git add .
git commit -m "backup: update dotfiles"
```

