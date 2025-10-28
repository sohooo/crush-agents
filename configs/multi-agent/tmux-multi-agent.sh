#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="crush-multi-agent"
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${CONFIG_DIR}/../.." && pwd)"

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux is required to launch the multi-agent workspace" >&2
  exit 1
fi

if tmux has-session -t "${SESSION_NAME}" 2>/dev/null; then
  echo "Attaching to existing tmux session '${SESSION_NAME}'" >&2
  tmux attach -t "${SESSION_NAME}"
  exit 0
fi

cd "${REPO_ROOT}"

tmux new-session -d -s "${SESSION_NAME}" -n architect "crush --config ${CONFIG_DIR}/architect.crush.json"
tmux split-window -h "crush --config ${CONFIG_DIR}/engineer.crush.json"
tmux split-window -v "crush --config ${CONFIG_DIR}/tester.crush.json"
tmux select-pane -t 0

tmux split-window -v "crush --config ${CONFIG_DIR}/documenter.crush.json"
tmux select-pane -t 3

tmux split-window -v "crush --config ${CONFIG_DIR}/critic.crush.json"
tmux select-layout tiled
tmux select-pane -t 0

tmux attach-session -t "${SESSION_NAME}"
