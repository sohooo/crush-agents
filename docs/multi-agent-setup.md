# Multi-agent Crush Workspace

This guide shows how to run a local, role-focused Crush workspace that mirrors a multi-agent software team. Each agent gets its own Crush configuration and tmux pane so that you can iterate on design, implementation, testing, documentation, and review in parallel.

## Roles and configuration files

The `configs/multi-agent` directory contains one Crush configuration per role:

| Role | Config file | Responsibilities |
| --- | --- | --- |
| 🧭 Architect | `architect.crush.json` | Provides the system-level view, plans refactors, and keeps the architecture cohesive. |
| 🧑‍💻 Engineer | `engineer.crush.json` | Implements the plan, edits code, and keeps changes small and testable. |
| 🧪 Tester | `tester.crush.json` | Designs automated tests, exercises edge cases, and reports regressions. |
| 🧾 Documenter | `documenter.crush.json` | Maintains READMEs, docstrings, and change notes in lockstep with code. |
| 🛡️ Critic | `critic.crush.json` | Reviews diffs for security and performance risks and suggests mitigations. |

Each file defines:

- A dedicated `session_name` so panes are easy to identify.
- The shared Lab vLLM provider, pre-configured with the Qwen Coder model.
- Role-specific `initial_prompt` text and curated `context_paths`.

Feel free to adjust context paths to match your repository layout.

## Launching the tmux workspace

If you want to reuse these configs in another repository, run the bootstrap helper directly from your target project:

```bash
curl -fsSL https://gitlab.example.dev/ai/crush/-/raw/main/scripts/bootstrap-crush-project.sh | bash
```

The script clones or updates `https://gitlab.example.dev/ai/crush` into `<project>/.crush`. Pass `--force` to replace the directory entirely, or set `CRUSH_REPO_URL=<your-mirror>`/`CRUSH_REPO_BRANCH=<branch>` to pull from a different source.

Once the configs live alongside your code, use the helper script to spawn all agents at once:

```bash
.crush/configs/multi-agent/tmux-multi-agent.sh
```

If you are working directly from this repository, the script also lives under `configs/multi-agent/tmux-multi-agent.sh`.

The script will:

1. Create (or attach to) the `crush-multi-agent` tmux session.
2. Launch the Architect pane first, then split the window for the Engineer and Tester.
3. Add panes for the Documenter and Critic, arranging everything with a tiled layout.
4. Attach your terminal to the session so you can start collaborating immediately.

If the session already exists, re-running the script simply re-attaches to it. Ensure `tmux` is installed locally before launching.

## Coordinating the agents

A simple loop keeps everyone in sync:

1. The Architect publishes design notes (for example under `docs/agent-messages/`).
2. The Engineer applies the plan, commits changes, and summarizes the work.
3. The Tester adds coverage and runs `go test -v ./...`.
4. The Documenter updates READMEs and guides.
5. The Critic inspects the latest diff (`git diff HEAD~1`) and flags risks.

Because every agent shares the same git repository, committing frequently lets each pane pick up the latest work without manual copy/paste.

## Customising further

- Add more roles by duplicating a config file and editing the prompt and context.
- Attach shared MCP servers to expose external tools or ticketing systems.
- Swap the tmux layout or replace it with background Crush sessions in separate terminal tabs.

This setup offers a lightweight yet powerful way to simulate a complete product team with Crush.
