#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: check-vllm.sh [OPTIONS]

Validate connectivity and configuration for a vLLM deployment defined in a
Crush configuration file.

Options:
  -c, --config PATH     Path to crush.json (default: ~/.config/crush/crush.json)
  -p, --provider NAME   Provider key to inspect (default: lab-vllm)
  -h, --help            Show this message and exit
USAGE
}

CONFIG_PATH="${HOME}/.config/crush/crush.json"
PROVIDER_KEY="lab-vllm"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--config)
      if [[ $# -lt 2 ]]; then
        echo "error: --config requires a value" >&2
        exit 1
      fi
      CONFIG_PATH="$2"
      shift 2
      ;;
    -p|--provider)
      if [[ $# -lt 2 ]]; then
        echo "error: --provider requires a value" >&2
        exit 1
      fi
      PROVIDER_KEY="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

for cmd in curl jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
done

if [[ ! -f "$CONFIG_PATH" ]]; then
  echo "error: configuration file not found: $CONFIG_PATH" >&2
  exit 1
fi

status_info() {
  echo "-- $*"
}

status_ok() {
  echo "✔ $*"
}

status_warn() {
  echo "⚠ $*" >&2
}

status_fail() {
  echo "✖ $*" >&2
}

failures=0

status_info "Checking provider '$PROVIDER_KEY' in $CONFIG_PATH"

if ! jq -e ".providers | has(\"$PROVIDER_KEY\")" "$CONFIG_PATH" >/dev/null 2>&1; then
  status_fail "Provider '$PROVIDER_KEY' not found in configuration"
  exit 1
fi

base_url=$(jq -r ".providers[\"$PROVIDER_KEY\"].base_url // empty" "$CONFIG_PATH")
api_key=$(jq -r ".providers[\"$PROVIDER_KEY\"].api_key // empty" "$CONFIG_PATH")

if [[ -z "$base_url" ]]; then
  status_fail "base_url is missing for provider '$PROVIDER_KEY'"
  exit 1
fi

if [[ -z "$api_key" ]]; then
  status_warn "api_key is empty; continuing without Authorization header"
fi

mapfile -t model_rows < <(jq -r ".providers[\"$PROVIDER_KEY\"].models[]? | [.id, (.context_window // 0), (.default_max_tokens // 0)] | @tsv" "$CONFIG_PATH") || true

if [[ ${#model_rows[@]} -eq 0 ]]; then
  status_fail "No models defined for provider '$PROVIDER_KEY'"
  exit 1
fi

config_models=()
declare -A context_windows
declare -A max_tokens

for row in "${model_rows[@]}"; do
  IFS=$'\t' read -r model_id context_window default_max_tokens <<<"$row"
  config_models+=("$model_id")
  context_windows["$model_id"]="$context_window"
  max_tokens["$model_id"]="$default_max_tokens"

  if [[ -z "$model_id" ]]; then
    status_fail "A model entry is missing an id"
    failures=1
  elif [[ "$model_id" == *"MODEL_ID"* ]]; then
    status_fail "Model id '$model_id' still contains a placeholder"
    failures=1
  fi

  if [[ "$context_window" -le 0 ]]; then
    status_fail "Model '$model_id' has a non-positive context_window: $context_window"
    failures=1
  fi

  if [[ "$default_max_tokens" -le 0 ]]; then
    status_fail "Model '$model_id' has a non-positive default_max_tokens: $default_max_tokens"
    failures=1
  elif [[ "$default_max_tokens" -gt "$context_window" ]]; then
    status_fail "Model '$model_id' default_max_tokens ($default_max_tokens) exceeds context_window ($context_window)"
    failures=1
  fi
done

if [[ $failures -ne 0 ]]; then
  exit 1
fi

models_endpoint="${base_url%/}/models"
status_info "Querying $models_endpoint"

curl_args=("--silent" "--show-error" "--fail" "--max-time" "10" "--connect-timeout" "5")
if [[ -n "$api_key" ]]; then
  curl_args+=("-H" "Authorization: Bearer $api_key")
fi

response=""
if ! response=$(curl "${curl_args[@]}" "$models_endpoint"); then
  status_fail "Failed to reach $models_endpoint"
  exit 1
fi

if ! echo "$response" | jq . >/dev/null 2>&1; then
  status_fail "Response from $models_endpoint is not valid JSON"
  exit 1
fi

available_models=$(echo "$response" | jq -r '.data[]?.id')

if [[ -z "$available_models" ]]; then
  status_warn "No models returned by /models endpoint"
fi

missing_models=()
for model_id in "${config_models[@]}"; do
  if ! grep -Fxq "$model_id" <<<"$available_models"; then
    missing_models+=("$model_id")
  fi
done

if [[ ${#missing_models[@]} -gt 0 ]]; then
  status_fail "Models not found remotely: ${missing_models[*]}"
  exit 1
fi

for model_id in "${config_models[@]}"; do
  status_ok "Model '$model_id' validated (context_window=${context_windows[$model_id]}, default_max_tokens=${max_tokens[$model_id]})"
done

status_ok "Successfully connected to $models_endpoint and validated configuration"
