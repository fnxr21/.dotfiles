# claude-secure: protect an existing project manually.
# Usage: claude-secure            (current folder)
#        claude-secure ~/work/app
function claude-secure --description 'Add Claude Code secret protection to a project'
    $HOME/.config/claude-secure/apply.sh $argv
end
