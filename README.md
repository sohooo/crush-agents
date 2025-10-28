# Crush On-Premise vLLM Setup

This repository provides reference configuration files and documentation for running [Crush](https://github.com/charmbracelet/crush) against an on-premises [vLLM](https://github.com/vllm-project/vllm) deployment.

## Guides

- [On-premise vLLM walkthrough](docs/on-prem-vllm.md)
- [Multi-agent Crush workspace](docs/multi-agent-setup.md)

## Bootstrap another project quickly

From any repository that should host the Crush multi-agent configs, run:

```bash
curl -fsSL https://gitlab.example.dev/ai/crush/-/raw/main/scripts/bootstrap-crush-project.sh | bash
```

Re-run the same command at any time to update the `.crush` directory in place. Use `--force` (for example `... | bash -s -- --force`) to replace the directory entirely, and override the source via `CRUSH_REPO_URL`/`CRUSH_REPO_BRANCH` when mirroring the configs internally.
