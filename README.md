# Crush On-Premise vLLM Setup

This repository provides reference configuration files and documentation for running [Crush](https://github.com/charmbracelet/crush) against an on-premises [vLLM](https://github.com/vllm-project/vllm) deployment.

## Quickstart: run the multi-agent workspace

You can go from a blank repository to a fully running Crush workspace with two commands:

```bash
# 1. Bootstrap the shared configs into the current project
curl -fsSL https://gitlab.example.dev/ai/crush/-/raw/main/scripts/bootstrap-crush-project.sh | bash

# 2. Launch every agent inside a tmux session
.crush/configs/multi-agent/tmux-multi-agent.sh
```

The bootstrap script clones or updates the Crush configuration repo into `.crush/`. Rerun it whenever you need fresh configs, add `--force` (`... | bash -s -- --force`) to replace the directory entirely, or set `CRUSH_REPO_URL`/`CRUSH_REPO_BRANCH` to target an internal mirror.

The tmux helper creates (or reattaches to) a `crush-multi-agent` session and opens panes for the Architect, Engineer, Tester, Documenter, and Critic roles. Make sure `tmux` is installed locally; rerunning the script simply drops you back into the existing session.

## Optional: tmuxinator workspace

For a richer workspace that opens every agent plus dedicated panes for the Crush log stream and a master shell, install [tmuxinator](https://github.com/tmuxinator/tmuxinator) and launch the provided configuration:

```bash
dnf install -y ruby
gem install tmuxinator
```

Then start the project-scoped tmuxinator workspace from your repository root:

```bash
tmuxinator start -p .crush/configs/multi-agent/crush-multi-agent.yml
```

The layout mirrors the tmux helper while automatically tailing `./.crush/logs/crush.log` (created on demand) and leaving a master pane open for editing, git operations, or other coordination tasks.

When you are ready to dive deeper into the workspace layout or customise roles, continue with the detailed guides below.

## Guides

- [On-premise vLLM walkthrough](docs/on-prem-vllm.md)
- [Multi-agent Crush workspace](docs/multi-agent-setup.md)
