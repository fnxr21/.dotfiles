# tmux

tmux is a terminal multiplexer.

It allows you to keep multiple terminals inside one terminal session, split terminals into panes, create multiple windows, and keep processes running even after closing your terminal.

## Basic Concept

```text
tmux
└── Session
    ├── Window
    │   ├── Pane
    │   └── Pane
    │
    └── Window
        ├── Pane
        └── Pane
```

### Session

A session is the main container.

```bash
tmux new -s dev
```

Create a session named `dev`.

### Window

A window is like a tab inside a session.

```text
Session: dev

Window 0: code
Window 1: logs
Window 2: database
```

### Pane

A pane is a split terminal inside a window.

```text
+-------------------+-------------------+
|                   |                   |
|       Pane 0      |       Pane 1      |
|                   |                   |
+-------------------+-------------------+
```

---

# Prefix

tmux commands normally start with the tmux prefix.

Default:

```text
Ctrl+b
```

If you configure your own prefix, use that instead.

Example:

```tmux
set -g prefix C-a
unbind C-b
bind C-a send-prefix
```

Then:

```text
Ctrl+a + command
```

For example:

```text
Ctrl+a d
```

detaches from the session.

---

# Session

## Create a session

```bash
tmux new -s dev
```

Create a session called `dev`.

## List sessions

```bash
tmux ls
```

or:

```bash
tmux list-sessions
```

## Attach to a session

```bash
tmux attach -t dev
```

Short version:

```bash
tmux a -t dev
```

## Create or attach automatically

```bash
tmux new -A -s dev
```

If `dev` exists:

```text
attach
```

If it doesn't exist:

```text
create
```

This is very useful for daily development.

---

# Detach

Detach from tmux without killing the processes.

```text
Prefix + d
```

Example:

```text
Ctrl+a d
```

The session keeps running.

You can close your terminal and later run:

```bash
tmux attach -t dev
```

Your processes will still be there.

---

# Kill Session

## Kill current session

Inside tmux:

```text
Prefix + :
```

Then:

```text
kill-session
```

## Kill a specific session

From outside tmux:

```bash
tmux kill-session -t dev
```

## Kill all tmux sessions

```bash
tmux kill-server
```

> Be careful. This kills every tmux session and all processes running inside them.

---

# Windows

## Create a new window

```text
Prefix + c
```

Example:

```text
Ctrl+a c
```

## Next window

```text
Prefix + n
```

## Previous window

```text
Prefix + p
```

## Go directly to a window

```text
Prefix + 0
Prefix + 1
Prefix + 2
```

For example:

```text
Prefix + 2
```

goes to window `2`.

## Rename window

```text
Prefix + ,
```

Example:

```text
code
logs
database
server
```

---

# Panes

Panes allow you to split one window into multiple terminals.

## Horizontal split

If configured:

```text
Prefix + |
```

Result:

```text
+-------------------+-------------------+
|                   |                   |
|       Pane 0      |       Pane 1      |
|                   |                   |
+-------------------+-------------------+
```

## Vertical split

If configured:

```text
Prefix + -
```

Result:

```text
+---------------------------------------+
|                Pane 0                 |
+---------------------------------------+
|                Pane 1                 |
+---------------------------------------+
```

---

# Navigate Panes

With vim-style navigation:

```text
Prefix + h    left
Prefix + j    down
Prefix + k    up
Prefix + l    right
```

Example:

```text
Prefix + h
```

moves to the pane on the left.

If you configure `bind -n`, the prefix is not required.

Example:

```tmux
bind -n C-h select-pane -L
bind -n C-j select-pane -D
bind -n C-k select-pane -U
bind -n C-l select-pane -R
```

Then:

```text
Ctrl+h
Ctrl+j
Ctrl+k
Ctrl+l
```

can move between panes directly.

---

# Resize Panes

Example configuration:

```tmux
bind -r C-k resize-pane -U 5
bind -r C-j resize-pane -D 5
bind -r C-h resize-pane -L 5
bind -r C-l resize-pane -R 5
```

Then:

```text
Prefix + Ctrl+k    resize up
Prefix + Ctrl+j    resize down
Prefix + Ctrl+h    resize left
Prefix + Ctrl+l    resize right
```

---

# Zoom Pane

Sometimes one pane needs the entire screen.

```text
Prefix + z
```

Example:

```text
Normal:

+-------------------+-------------------+
|                   |                   |
|      terminal     |       logs        |
|                   |                   |
+-------------------+-------------------+

Zoom:

+---------------------------------------+
|                                       |
|                 logs                  |
|                                       |
|                                       |
+---------------------------------------+
```

Press:

```text
Prefix + z
```

again to return to the normal layout.

---

# Kill Pane

Inside the pane:

```bash
exit
```

Or use tmux:

```text
Prefix + x
```

Then confirm.

If you configured:

```tmux
bind -r e kill-pane -a
```

then:

```text
Prefix + e
```

can be used according to your configuration.

---

# Copy Mode

Copy mode is useful for reading logs and copying text.

Enter copy mode:

```text
Prefix + [
```

If using vi mode:

```tmux
set-window-option -g mode-keys vi
```

you can use vim-like navigation.

## Search

Inside copy mode:

```text
/
```

Type:

```text
error
```

Press:

```text
Enter
```

Next result:

```text
n
```

Previous result:

```text
N
```

## Select text

Enter copy mode:

```text
Prefix + [
```

Move the cursor to the beginning.

Press:

```text
Space
```

Move the cursor to select text.

Press:

```text
Enter
```

to copy.

## Paste

```text
Prefix + ]
```

---

# Reload Configuration

If your config is:

```text
~/.config/tmux/tmux.conf
```

you can reload it with:

```bash
tmux source-file ~/.config/tmux/tmux.conf
```

Or configure:

```tmux
bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
```

Then:

```text
Prefix + r
```

reloads the configuration.

---

# Useful Commands

## List sessions

```bash
tmux ls
```

## Create session

```bash
tmux new -s dev
```

## Attach

```bash
tmux attach -t dev
```

## Create or attach

```bash
tmux new -A -s dev
```

## Rename session

```bash
tmux rename-session -t dev backend
```

## Kill session

```bash
tmux kill-session -t dev
```

## Kill all sessions

```bash
tmux kill-server
```

---

# Daily Development Workflow

A simple workflow:

```bash
tmux new -A -s dev
```

Create multiple windows:

```text
Window 0 → code
Window 1 → server
Window 2 → logs
Window 3 → database
```

Example:

```text
dev
├── 0: code
│   ├── nvim
│   └── terminal
│
├── 1: server
│   └── make run
│
├── 2: logs
│   └── kubectl logs
│
└── 3: database
    └── mongosh / psql
```

Detach:

```text
Prefix + d
```

Later:

```bash
tmux attach -t dev
```

Everything is still running.

---

# Project Session

For a project, you can create a dedicated session:

```bash
tmux new -s backend
```

Then:

```text
Window 0 → code
Window 1 → server
Window 2 → logs
```

This keeps your development environment organized.

---

# Automatic Project Layout

You can create a script:

```bash
mkdir -p ~/.config/tmux/scripts
```

Example:

```bash
nvim ~/.config/tmux/scripts/backend.sh
```

```bash
#!/usr/bin/env bash

SESSION="backend"
PROJECT="$HOME/dev/backend"

tmux has-session -t "$SESSION" 2>/dev/null

if [ $? != 0 ]; then
    tmux new-session -d -s "$SESSION" -c "$PROJECT" -n code

    tmux split-window -h -t "$SESSION:0" -c "$PROJECT"

    tmux select-pane -t "$SESSION:0.0"
    tmux send-keys "nvim ." C-m

    tmux select-pane -t "$SESSION:0.1"
    tmux send-keys "make run" C-m

    tmux new-window -t "$SESSION" -n logs -c "$PROJECT"
fi

tmux attach-session -t "$SESSION"
```

Make it executable:

```bash
chmod +x ~/.config/tmux/scripts/backend.sh
```

Run:

```bash
~/.config/tmux/scripts/backend.sh
```

Now your project environment can be created automatically.

---

# Useful Mental Model

Think about tmux like this:

```text
Terminal
   │
   └── tmux
       │
       └── Session
           │
           ├── Window
           │   ├── Pane
           │   └── Pane
           │
           ├── Window
           │   └── Pane
           │
           └── Window
               ├── Pane
               └── Pane
```

The important difference:

```text
Terminal closed
      ↓
tmux session still running
      ↓
processes still running
```

---

# Practice

The best way to learn tmux is to practice without looking at the commands.

## Practice 1 — Create a Session

Create a session called:

```text
practice
```

Goal:

```text
practice
└── Window 0
```

Then:

1. Detach from it.
2. List sessions.
3. Attach to it again.

Commands you should discover:

```bash
tmux new -s ...
tmux ls
tmux attach -t ...
```

---

## Practice 2 — Windows

Inside `practice`:

Create 3 windows.

Make them:

```text
0: code
1: server
2: logs
```

Practice:

- Move to next window.
- Move to previous window.
- Jump directly to window `2`.
- Rename window `1`.

---

## Practice 3 — Panes

In window `code`:

Create this layout:

```text
+-------------------+-------------------+
|                   |                   |
|       Pane 0      |       Pane 1      |
|                   |                   |
+-------------------+-------------------+
```

Then split Pane 0 vertically:

```text
+-------------------+-------------------+
|                   |                   |
|       Pane 0      |       Pane 1      |
+-------------------+-------------------+
|                   |                   |
|       Pane 2      |                   |
+-------------------+-------------------+
```

Practice moving between:

```text
h
j
k
l
```

---

## Practice 4 — Zoom

Create at least 3 panes.

Then:

1. Zoom one pane.
2. Work inside it.
3. Unzoom.
4. Move to another pane.
5. Zoom it.

Goal: become comfortable with:

```text
Prefix + z
```

---

## Practice 5 — Kill Things

Create:

```text
practice
├── Window 0
├── Window 1
└── Window 2
```

Then:

1. Kill one pane.
2. Kill one window.
3. Kill the entire session.
4. Recreate the session.

Important command:

```bash
tmux kill-session -t practice
```

---

## Practice 6 — Detach / Reattach

Run something that keeps running:

```bash
sleep 300
```

Detach from tmux.

Close your terminal.

Open a new terminal.

Attach again:

```bash
tmux attach -t practice
```

Verify that the process is still running.

This is one of the most important reasons to use tmux.

---

## Practice 7 — Logs

Run:

```bash
ping 8.8.8.8
```

Let it produce lots of output.

Enter copy mode:

```text
Prefix + [
```

Practice:

- Scroll up.
- Scroll down.
- Search for `time=`.
- Go to the next result.
- Select some text.
- Copy it.
- Paste it into another pane.

---

## Practice 8 — Real Development Layout

Create:

```text
dev
├── code
│   ├── editor
│   └── terminal
│
├── server
│   └── application
│
└── logs
    └── logs
```

Pretend you are working on a real project.

Run:

```text
code     → nvim
terminal → git / commands
server   → make run
logs     → tail / kubectl logs
```

Detach.

Open another terminal.

Attach again.

Everything should still be there.

---

# Final Challenge

Without looking at this README:

## Goal

Create a tmux session:

```text
backend
```

With:

```text
backend
├── code
│   ├── editor
│   └── terminal
│
├── server
│   └── application
│
└── logs
    └── logs
```

Then:

1. Start your editor.
2. Start your application.
3. Generate some logs.
4. Navigate between panes using `h/j/k/l`.
5. Zoom the application pane.
6. Search logs using copy mode.
7. Detach.
8. Close the terminal.
9. Open a new terminal.
10. Reattach to `backend`.
11. Kill the session when finished.

If you can do this without checking the README, you have the core tmux workflow down.
