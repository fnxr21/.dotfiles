#if status is-interactive
# Commands to run in interactive sessions can go here
#end
set fish_greeting ""

# theme
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# aliases
alias ls "ls -p -G"
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"
alias g git
alias c claude
alias claude-yolo "claude --dangerously-skip-permissions"
alias ag="antigravity"
alias python=python3
#nvim
command -qv nvim && alias vim nvim
set -gx EDITOR nvim

function go_19
    asdf set golang 1.19.1
end

function go_24
    asdf set golang 1.24.0
end

function go_26
    asdf set golang 1.26.1
end

# Go
#set -g GOPATH $HOME/go

#set -gx PATH $HOME/.asdf/bin $PATH
#set -gx ASDF_DIR $HOME/.asdf
#source $ASDF_DIR/asdf.fish
# ASDF configuration code
#if test -z $ASDF_DATA_DIR
#    set _asdf_shims "$HOME/.asdf/shims"
#else
#    set _asdf_shims "$ASDF_DATA_DIR/shims"
#end

# Do not use fish_add_path (added in Fish 3.2) because it
# potentially changes the order of items in PATH
#if not contains $_asdf_shims $PATH
#    set -gx --prepend PATH $_asdf_shims
#end
#set --erase _asdf_shims

#if test -s /home/gli/.gvm/scripts/gvm
#    bass source /home/gli/.gvm/scripts/gvm
#end

switch (uname)
    case Darwin
        source (dirname (status --current-filename))/config-osx.fish
    case Linux
        source (dirname (status --current-filename))/config-linux.fish
    case '*'
        source (dirname (status --current-filename))/config-windows.fish
end
