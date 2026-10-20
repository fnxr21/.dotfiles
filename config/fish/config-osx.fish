# Homebrew (Apple Silicon: /opt/homebrew, Intel: /usr/local)
for brew in /opt/homebrew/bin/brew /usr/local/bin/brew
    if test -x $brew
        $brew shellenv | source
        break
    end
end

alias ls "ls -p -G"
