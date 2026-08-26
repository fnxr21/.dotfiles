###
nano ~/.config/git-secrets/patterns


### Put your rules inside, for example:
```
password[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
api[_-]?key[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
client[_-]?secret[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
access[_-]?token[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
private[_-]?key[[:space:]]*[:=][[:space:]]*["']?[^"'[:space:]]+
```


### Load the rules globally

```bash
while read -l pattern
    test -n "$pattern"; or continue
    git secrets --add --global "$pattern"
end < ~/.config/git-secrets/patterns
```



### Now check:

```
git secrets --list --global
```


### for global .gitignore
```
git config --global core.excludesFile ~/.config/git-secrets/global.gitignore
```

### create file

```
touch ~/.config/git-secrets/global.gitignore
```

example
```
gli-dev-storage.json
gli-dev-secret.json
.env
*.pem
*.key
```


```
.gitignore/global excludes
        ↓
Don't accidentally git add credentials

git-secrets
        ↓
Catch secrets that somehow get staged
```


```
~/.config/git-secrets/
├── patterns     ← YOU EDIT THIS
└── ...                 ← git-secrets source

~/.local/bin/
└── git-secrets         ← executable

~/.gitconfig            ← active global rules

~/.git-templates/
└── git-secrets/
    └── hooks/
        ├── commit-msg
        ├── pre-commit
        └── prepare-commit-msg
```