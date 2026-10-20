# claude-secure: wraps `git` so that `git init` also adds Claude Code secret protection.
# Every other git command passes straight through unchanged.
function git --wraps git --description 'git + claude-secure on init'
    command git $argv
    set -l code $status

    # Only act on a successful `git init`
    if test $code -ne 0; or test (count $argv) -eq 0; or test "$argv[1]" != init
        return $code
    end
    # Skip bare repos and opt-out
    if contains -- --bare $argv; or set -q CLAUDE_SECURE_SKIP
        return $code
    end

    # Find the target folder: first non-option argument after `init`
    set -l target .
    set -l skip_next 0
    for a in $argv[2..-1]
        if test $skip_next -eq 1
            set skip_next 0
            continue
        end
        switch $a
            case --template --separate-git-dir -b --initial-branch --object-format --ref-format --shared
                set skip_next 1   # option that takes a value
            case '-*'
                # other options
            case '*'
                set target $a
                break
        end
    end

    set -l kit $HOME/.config/claude-secure
    if test -x $kit/apply.sh
        $kit/apply.sh $target
    end
    return $code
end
