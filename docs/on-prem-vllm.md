# Crush with On-Premises vLLM (Qwen-Coder) Guide

This guide walks through configuring Crush to work with an on-premises vLLM deployment that serves the Qwen-Coder model via an OpenAI-compatible API (e.g. `https://assist.lab.dev/v1`).

## 1. Launch vLLM with an OpenAI-Compatible Endpoint

Ensure vLLM is running with the OpenAI API server entrypoint and exposed through your ingress (e.g. Envoy):

```bash
python -m vllm.entrypoints.openai.api_server \
  --host 0.0.0.0 --port 8000 \
  --model Qwen2.5-Coder-7B-Instruct \
  --max-model-len 131072 \
  --disable-log-requests
```

Expose the service via your ingress, such as `https://assist.lab.dev/v1`. Many deployments accept any `Authorization: Bearer` token; if yours requires a real token, replace `dummy` in later steps accordingly.

**Sanity check:**

```bash
curl -s https://assist.lab.dev/v1/models \
  -H "Authorization: Bearer dummy" | jq .
```

Record the exact model `id` that you intend to use (e.g. `Qwen2.5-Coder-7B-Instruct`).

## 2. Install Crush

Choose one of the supported installation methods:

```bash
brew install charmbracelet/tap/crush
# or
npm install -g @charmland/crush
# or
go install github.com/charmbracelet/crush@latest
```

## 3. Configure Crush for the Lab vLLM Provider

Copy the reference config from [`configs/crush.lab-vllm.json`](../configs/crush.lab-vllm.json) to `~/.config/crush/crush.json` (or a project-local `.crush.json`) and update the placeholders:

- Replace `QWEN_CODER_MODEL_ID` with the model identifier returned by `GET /v1/models`.
- Adjust `context_window` and `default_max_tokens` if your deployment uses different limits.

For air-gapped environments, keep `"disable_provider_auto_update": true` (or set `CRUSH_DISABLE_PROVIDER_AUTO_UPDATE=1`) to avoid external provider updates.

## 4. Optional Enhancements

### Language Servers and Context Paths

Crush can leverage LSPs and specific project paths for richer context. Example snippet:

```json
{
  "$schema": "https://charm.land/crush.json",
  "lsp": {
    "go": { "command": "gopls" },
    "typescript": { "command": "typescript-language-server", "args": ["--stdio"] },
    "bash": { "command": "bash-language-server", "args": ["start"] }
  },
  "options": {
    "context_paths": [
      "./README.md",
      "./docs",
      "./cmd",
      "./internal"
    ],
    "tui": { "compact_mode": true }
  }
}
```

### Tool Permissions

To allow Crush to run specific tools without prompting each time:

```json
{
  "$schema": "https://charm.land/crush.json",
  "permissions": {
    "allowed_tools": ["view", "ls", "grep", "edit"]
  }
}
```

### Ignore Noisy Paths

Add a `.crushignore` file (an example is provided in [`configs/.crushignore`](../configs/.crushignore) and is copied automatically when you run `scripts/bootstrap-crush-project.sh`) to keep large or irrelevant directories out of context:

```
node_modules/
dist/
vendor/
.env
```

## 5. Running Crush

From your project directory, start Crush:

```bash
crush
```

- Select the `Lab vLLM` provider and the `Qwen Coder (lab)` model.
- Provide tasks such as: "Scan the repo, list top 3 refactors for maintainability; propose diffs, and explain tradeoffs."
- Approve or reject actions (file reads, edits, etc.) as Crush works through the task.
- You can switch models mid-session via the model picker without losing context.

## 6. Troubleshooting Tips

- **401/403 responses**: Ensure `api_key` is set (even to a dummy value) or supply the real token expected by your gateway.
- **Model not found**: Confirm the model `id` in the config matches the value returned by `/v1/models`.
- **TLS / mTLS**: Trust your private CA on the workstation (system keychain or `SSL_CERT_FILE`/`SSL_CERT_DIR`). Avoid disabling verification except for quick tests.
- **Truncated outputs**: Increase `default_max_tokens` and ensure vLLM is launched with an adequate `--max-model-len`.
- **Slow tool calls**: Limit `context_paths` and tune `.crushignore` to avoid indexing large directories.
- **Air-gapped environments**: Keep provider auto-updates disabled to prevent background network calls.

## 7. End-to-End Example

1. List available models:
   ```bash
   curl -s https://assist.lab.dev/v1/models \
     -H "Authorization: Bearer dummy" | jq -r '.data[].id'
   ```
2. Update your Crush config with the desired model id.
3. Launch `crush` in your project and begin collaborating with the agent.

With these steps, Crush will drive the Qwen-Coder model running inside your lab via vLLM, complete with local tools, context, and guardrails tailored to your environment.
