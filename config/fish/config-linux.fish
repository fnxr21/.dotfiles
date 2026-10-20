#if status --is-login
set_color red
echo "Hello, Ivan. Welcome to Fight Club."
set_color yellow
echo "don't forget, We don't talk about Fight Club."
set_color normal
#end

alias ls "ls -p --color=auto"

# fish_add_path skips paths that are already there or do not exist
fish_add_path /opt/nvim/bin
