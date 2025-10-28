#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

session="crush-lab"
tmux new-session -d -s "$session" -n architect "crush --config .crush/architect.crush.json"
tmux split-window -h "crush --config .crush/engineer.crush.json"
tmux select-pane -t 0
tmux split-window -v "crush --config .crush/tester.crush.json"
tmux select-pane -t 1
tmux split-window -v "crush --config .crush/doc.crush.json"
tmux select-pane -t 2
tmux split-window -v "crush --config .crush/critic.crush.json"
tmux select-layout tiled
tmux set -g mouse on
tmux attach -t "$session"
