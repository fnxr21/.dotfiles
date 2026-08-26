# Git Secrets Setup Guide — Ubuntu + Fish

This guide explains how to install and configure [`git-secrets`](https://github.com/awslabs/git-secrets) on Ubuntu using the Fish shell.

The setup provides:

* AWS credential detection
* Custom secret detection
* Google service-account credential detection
* Database password detection
* API key / client secret / access token detection
* Private key detection
* URL detection
* Automatic Git hooks for new repositories
* Manual setup for existing repositories
* Secret scanning before commit
* Secret scanning in Git history

> **Important:** All examples in this guide use fake credentials. Never use real credentials for testing.

---

## 1. Prerequisites

Install Git and Make:

```fish
sudo apt update
sudo apt install -y git make
```

Verify:

```fish
git --version
make --version
```

---

# 2. Clone git-secrets

We keep the `git-secrets` source under `~/.config`.

Create the directory:

```fish
mkdir -p ~/.config
cd ~/.config
```

Clone the repository:

```fish
git clone https://github.com/awslabs/git-secrets.git
```

The source will be located at:

```text
~/.config/git-secrets/
```

---

# 3. Install git-secrets

Go into the cloned repository:

```fish
cd ~/.config/git-secrets
```

Install it into the user's local binary directory:

```fish
make install PREFIX=$HOME/.local
```

This installs:

```text
~/.local/bin/git-secrets
```

---

# 4. Add git-secrets to Fish PATH

Run this directly from the Fish terminal:

```fish
fish_add_path ~/.local/bin
```

You do not need to manually edit `~/.config/fish/config.fish`.

Verify:

```fish
which git-secrets
```

Expected:

```text
/home/<username>/.local/bin/git-secrets
```

Verify the command:

```fish
git secrets --help
```

---

# 5. Configure AWS Secret Detection

Register the built-in AWS patterns globally:

```fish
git secrets --register-aws --global
```

Check the configuration:

```fish
git secrets --list --global
```

You should see AWS-related patterns such as:

```text
secrets.providers git secrets --aws-provider
secrets.patterns ...
secrets.allowed ...
```

The AWS configuration detects common AWS credentials such as:

* AWS Access Key IDs
* AWS Secret Access Keys
* AWS Account IDs
* Other AWS credential patterns supported by `git-secrets`

---

# 6. Create Custom Secret Rules

AWS detection is not enough for every application.

Projects may contain:

* Database passwords
* API keys
* Client secrets
* Access tokens
* Private keys
* Internal credentials
* Company-specific credential formats

Create a custom pattern file:

```fish
mkdir -p ~/.config/git-secrets
touch ~/.config/git-secrets/custom-patterns
```

Open it:

```fish
nano ~/.config/git-secrets/custom-patterns
```

Example:

```text
password[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
passwd[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
api[_-]?key[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
client[_-]?secret[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
access[_-]?token[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
private[_-]?key[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----
```

## Load the custom rules

`git-secrets` does not automatically read the `custom-patterns` file.

Load the rules into the global Git configuration:

```fish
while read -l pattern
    test -n "$pattern"; or continue
    string match -qr '^#' -- "$pattern"; and continue
    git secrets --add --global "$pattern"
end < ~/.config/git-secrets/custom-patterns
```

Verify:

```fish
git secrets --list --global
```

The output should contain both:

* AWS patterns
* Custom patterns

---

# 7. Google Service Account Credential Detection

Google service-account JSON files can contain sensitive private keys.

Example fake credential:

```json
{
  "type": "service_account",
  "project_id": "test-project",
  "private_key_id": "fake-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\nFAKE_TEST_KEY_DO_NOT_USE\n-----END PRIVATE KEY-----\n",
  "client_email": "test-service-account@test-project.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
```

Add a private-key pattern:

```fish
git secrets --add --global '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'
```

Optionally detect Google service-account files:

```fish
git secrets --add --global '"type"[[:space:]]*:[[:space:]]*"service_account"'
```

Verify:

```fish
git secrets --list --global
```

---

# 8. URL / Link Detection

For this environment, URLs are considered prohibited content.

The following should be blocked:

```text
http://example.com
https://example.com
https://api.example.com
http://service.gli.svc
```

Add the protocol rules:

```fish
git secrets --add --global 'http://'
git secrets --add --global 'https://'
```

If the policy also requires blocking specific domain suffixes:

```fish
git secrets --add --global '\.com'
git secrets --add --global '\.gli'
git secrets --add --global '\.id'
git secrets --add --global '\.svc'
```

This means content containing these patterns will be rejected.

> **Important:** Blocking `.com`, `.id`, `.gli`, or `.svc` is intentionally broad. It can block legitimate text or configuration. Only use these rules if the project policy explicitly requires it.

---

# 9. Company-Specific Credential Files

Some credential files should never be committed, regardless of their contents.

Examples:

```text
gli-dev-storage.json
gli-dev-secret.json
```

For files that must never be committed, use Git's global excludes file in addition to `git-secrets`.

Create:

```fish
mkdir -p ~/.config/git-secrets
touch ~/.config/git-secrets/global.gitignore
```

Add:

```text
gli-dev-storage.json
gli-dev-secret.json
.env
*.pem
*.key
```

Configure Git:

```fish
git config --global core.excludesFile ~/.config/git-secrets/global.gitignore
```

Verify:

```fish
git config --global --get core.excludesFile
```

Expected:

```text
/home/<username>/.config/git-secrets/global.gitignore
```

### Why use both?

`gitignore` prevents files from being accidentally staged.

`git-secrets` scans content that is staged.

Using both provides defense in depth:

```text
Credential file
      │
      ▼
Global Git ignore
      │
      ▼
Not accidentally staged
      │
      ▼
git-secrets
      │
      ▼
Content scanned
      │
      ▼
ALLOW / BLOCK
```

---

# 10. Automatically Install Hooks for New Repositories

Create a Git template:

```fish
mkdir -p ~/.git-templates/git-secrets
```

Install the hooks:

```fish
git secrets --install ~/.git-templates/git-secrets
```

You should see:

```text
✓ Installed commit-msg hook
✓ Installed pre-commit hook
✓ Installed prepare-commit-msg hook
```

Configure Git to use this template:

```fish
git config --global init.templateDir ~/.git-templates/git-secrets
```

Verify:

```fish
git config --global --get init.templateDir
```

Expected:

```text
/home/<username>/.git-templates/git-secrets
```

---

# 11. Test New Repository Hook Installation

Create a test repository:

```fish
mkdir -p ~/dev/git-secrets-test
cd ~/dev/git-secrets-test
git init
```

Check the hooks:

```fish
ls -la .git/hooks/
```

Expected:

```text
commit-msg
pre-commit
prepare-commit-msg
```

This confirms that new repositories automatically receive the `git-secrets` hooks.

---

# 12. Test AWS Credential Detection

Create a fake AWS credential:

```fish
echo 'AWS_ACCESS_KEY_ID=AKIA1234567890123456' > aws-test.txt
```

Scan:

```fish
git secrets --scan
```

Expected:

```text
aws-test.txt:1:AWS_ACCESS_KEY_ID=AKIA1234567890123456

[ERROR] Matched one or more prohibited patterns
```

The secret is detected.

---

# 13. Test Database Password Detection

Create:

```fish
echo 'DB_PASSWORD=my-super-secret-password' > db-test.txt
```

Scan:

```fish
git secrets --scan
```

If the password rule is registered, it should be detected.

Check your active rules if necessary:

```fish
git secrets --list --global
```

---

# 14. Test Google Credential Detection

Create a fake Google credential file:

```fish
cat > google-credential-test.json <<'EOF'
{
  "type": "service_account",
  "project_id": "test-project",
  "private_key_id": "fake-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\nFAKE_TEST_KEY_DO_NOT_USE\n-----END PRIVATE KEY-----\n",
  "client_email": "test-service-account@test-project.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
EOF
```

Scan:

```fish
git secrets --scan google-credential-test.json
```

The private-key or service-account pattern should be detected.

---

# 15. Test URL Detection

Test HTTPS:

```fish
echo 'https://google.com' > url-test.txt
```

Scan:

```fish
git secrets --scan url-test.txt
```

Expected:

```text
url-test.txt:1:https://google.com

[ERROR] Matched one or more prohibited patterns
```

Test HTTP:

```fish
echo 'http://example.com' > http-test.txt
git secrets --scan http-test.txt
```

Expected:

```text
[ERROR] Matched one or more prohibited patterns
```

Test an internal service:

```fish
echo 'http://my-service.namespace.svc' > svc-test.txt
git secrets --scan svc-test.txt
```

Expected:

```text
[ERROR] Matched one or more prohibited patterns
```

---

# 16. Test a Clean File

Create:

```fish
echo 'hello world' > normal.txt
```

Scan:

```fish
git secrets --scan normal.txt
```

There should be no secret detection error.

This confirms that normal content can still pass.

---

# 17. Test the Actual Git Commit Hook

This is the most important test.

Stage a fake AWS credential:

```fish
git add aws-test.txt
```

Try to commit:

```fish
git commit -m "test aws credential"
```

The commit should be blocked.

Expected:

```text
[ERROR] Matched one or more prohibited patterns
```

This confirms that the `pre-commit` hook is working.

---

# 18. Test a Clean Commit

Remove the secret from staging:

```fish
git restore --staged aws-test.txt
```

Stage the clean file:

```fish
git add normal.txt
```

Commit:

```fish
git commit -m "test clean file"
```

This commit should succeed.

---

# 19. Test Git History Scanning

`git-secrets` can scan existing Git history.

Run:

```fish
git secrets --scan-history
```

This is useful for finding secrets that may already exist in previous commits.

For testing only, a fake secret can be committed using:

```fish
git commit --no-verify -m "test bypass"
```

Then scan history:

```fish
git secrets --scan-history
```

The fake secret should be detected.

> Never use `--no-verify` to bypass protection for a real secret.

---

# 20. Existing Repositories

The Git template applies to repositories initialized after the template was configured.

Existing repositories need the hook installed once.

Go into the repository:

```fish
cd ~/path/to/existing-project
```

Run:

```fish
git secrets --install
```

Check:

```fish
ls -la .git/hooks/
```

You should see:

```text
commit-msg
pre-commit
prepare-commit-msg
```

You do NOT need to reinstall the `git-secrets` program.

---

# 21. Verify the Complete Configuration

Check where `git-secrets` is installed:

```fish
which git-secrets
```

Check global rules:

```fish
git secrets --list --global
```

Check Git template:

```fish
git config --global --get init.templateDir
```

Check global Git ignore:

```fish
git config --global --get core.excludesFile
```

Check Git configuration:

```fish
git config --global --list | grep -E 'secrets|template|excludes'
```

---

# 22. Recommended Directory Structure

The final setup looks like:

```text
/home/<username>/
│
├── .config/
│   └── git-secrets/
│       ├── git-secrets/       # cloned source
│       ├── custom-patterns    # custom secret patterns
│       └── global.gitignore   # globally ignored credential files
│
├── .local/
│   └── bin/
│       └── git-secrets        # installed executable
│
├── .git-templates/
│   └── git-secrets/
│       └── hooks/
│           ├── commit-msg
│           ├── pre-commit
│           └── prepare-commit-msg
│
└── .gitconfig                 # global Git configuration
```

---

# 23. Configuration Flow

The complete protection flow is:

```text
                  Developer
                      │
                      │ git add
                      ▼
             ┌─────────────────┐
             │ Global gitignore│
             │                 │
             │ .env            │
             │ *.pem           │
             │ *.key           │
             │ credential JSON │
             └────────┬────────┘
                      │
                      ▼
                Git staging
                      │
                      │ git commit
                      ▼
             ┌─────────────────┐
             │   pre-commit    │
             │      hook       │
             └────────┬────────┘
                      │
                      ▼
             ┌─────────────────┐
             │   git-secrets   │
             ├─────────────────┤
             │ AWS credentials │
             │ DB passwords    │
             │ API keys        │
             │ Client secrets  │
             │ Access tokens   │
             │ Private keys    │
             │ URLs            │
             │ Custom patterns │
             └────────┬────────┘
                      │
                ┌─────┴─────┐
                │           │
             MATCH       NO MATCH
                │           │
                ▼           ▼
             BLOCK         ALLOW
```

---

# 24. Useful Commands

### Show global rules

```fish
git secrets --list --global
```

### Scan current repository

```fish
git secrets --scan
```

### Scan a specific file

```fish
git secrets --scan path/to/file
```

### Scan Git history

```fish
git secrets --scan-history
```

### Install hooks in an existing repository

```fish
git secrets --install
```

### Register AWS rules

```fish
git secrets --register-aws --global
```

### Show Git template

```fish
git config --global --get init.templateDir
```

### Show global ignore file

```fish
git config --global --get core.excludesFile
```

---

# 25. Updating git-secrets

Because the source repository is located under:

```text
~/.config/git-secrets/
```

update it with:

```fish
cd ~/.config/git-secrets
git pull
```

Then reinstall:

```fish
make install PREFIX=$HOME/.local
```

Verify:

```fish
which git-secrets
git secrets --help
```

---

# 26. Important Security Notes

## Never use real credentials for testing

Use fake values such as:

```text
AKIA1234567890123456
```

or:

```text
FAKE_TEST_KEY_DO_NOT_USE
```

## git-secrets does not replace secret management

`git-secrets` is a prevention and detection tool.

It does not replace:

* Secret managers
* Environment variables
* Workload identity
* IAM policies
* Credential rotation
* Access control
* Repository security

## If a real credential is committed

Do not assume deleting the file is enough.

Immediately:

1. Revoke or rotate the credential.
2. Check where it may have been exposed.
3. Remove it from Git history if appropriate.
4. Investigate whether the credential was used.

Git history can preserve secrets even after the file is deleted.

---

# 27. Final Checklist

Before considering the setup complete:

* [ ] `git-secrets` installed
* [ ] `git-secrets` available in Fish PATH
* [ ] AWS rules registered globally
* [ ] Custom secret rules registered globally
* [ ] Google private-key detection tested
* [ ] Database password detection tested
* [ ] API key detection tested
* [ ] Access-token detection tested
* [ ] Private-key detection tested
* [ ] HTTP detection tested
* [ ] HTTPS detection tested
* [ ] `.com` detection tested if required by policy
* [ ] `.id` detection tested if required by policy
* [ ] `.gli` detection tested if required by policy
* [ ] `.svc` detection tested if required by policy
* [ ] Credential filenames added to global Git ignore
* [ ] Git template configured
* [ ] New repository automatically receives hooks
* [ ] Existing repositories have hooks installed
* [ ] Secret commit is blocked
* [ ] Clean commit succeeds
* [ ] Git history scanning tested

---

# 28. Expected Final Behavior

With this configuration:

```text
AWS credential                 → ❌ BLOCK
Database password              → ❌ BLOCK
API key                        → ❌ BLOCK
Client secret                  → ❌ BLOCK
Access token                   → ❌ BLOCK
Private key                    → ❌ BLOCK
Google service-account key     → ❌ BLOCK
http://...                     → ❌ BLOCK
https://...                    → ❌ BLOCK
.com                           → ❌ BLOCK (if enabled)
.id                            → ❌ BLOCK (if enabled)
.gli                           → ❌ BLOCK (if enabled)
.svc                           → ❌ BLOCK (if enabled)

Normal source code             → ✅ ALLOW
Normal text                    → ✅ ALLOW
Clean commit                   → ✅ ALLOW
```

The goal is simple:

> **Make the safe path automatic and make accidental credential commits difficult.**


Note:

how to remove the hooks from repo:

```
cd ~/dev/lab/your-repo 

rm -f .git/hooks/pre-commit
rm -f .git/hooks/commit-msg
rm -f .git/hooks/prepare-commit-msg
```

