#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bootstrap-crush-project.sh [OPTIONS] [project-path]

Download or update the Crush multi-agent configuration repository under
<project-path>/.crush. When project-path is omitted the current directory is
used, which enables piping curl output straight into bash.

Options:
  -f, --force   Replace an existing .crush directory instead of updating it
  -h, --help    Show this message and exit
USAGE
}

CRUSH_REPO_URL="${CRUSH_REPO_URL:-https://gitlab.example.dev/ai/crush}"

if ! command -v git >/dev/null 2>&1; then
  echo "error: git must be installed to fetch Crush configuration" >&2
  exit 1
fi

FORCE=0
TARGET=""

while getopts ":fh-:" opt; do
  case "$opt" in
    f)
      FORCE=1
      ;;
    h)
      usage
      exit 0
      ;;
    -)
      case "$OPTARG" in
        "")
          break
          ;;
        force)
          FORCE=1
          ;;
        help)
          usage
          exit 0
          ;;
        *)
          echo "error: unknown option: --$OPTARG" >&2
          usage >&2
          exit 1
          ;;
      esac
      ;;
    ?)
      echo "error: unknown option: -$OPTARG" >&2
      usage >&2
      exit 1
      ;;
    :)
      echo "error: option -$OPTARG requires an argument" >&2
      usage >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -gt 1 ]]; then
  echo "error: multiple project paths provided" >&2
  usage >&2
  exit 1
elif [[ $# -eq 1 ]]; then
  TARGET="$1"
fi

if [[ -z "$TARGET" ]]; then
  TARGET="."
fi

if [[ ! -d "$TARGET" ]]; then
  echo "error: project path '$TARGET' does not exist or is not a directory" >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$TARGET" && pwd)"
TARGET_CRUSH_DIR="$PROJECT_ROOT/.crush"
mkdir -p "$PROJECT_ROOT"

ensure_branch() {
  local url="$1"
  local branch

  branch="${CRUSH_REPO_BRANCH:-}"
  if [[ -n "$branch" ]]; then
    printf '%s' "$branch"
    return 0
  fi

  if branch=$(git ls-remote --symref "$url" HEAD 2>/dev/null | awk '/^ref:/ {print $2}' | sed 's#refs/heads/##'); then
    if [[ -n "$branch" ]]; then
      printf '%s' "$branch"
      return 0
    fi
  fi

  printf 'main'
}

DEFAULT_BRANCH="$(ensure_branch "$CRUSH_REPO_URL")"

clone_repo() {
  local dest="$1"
  echo "Cloning $CRUSH_REPO_URL@$DEFAULT_BRANCH into $dest" >&2
  if ! git clone --depth 1 --branch "$DEFAULT_BRANCH" "$CRUSH_REPO_URL" "$dest"; then
    echo "error: failed to clone Crush repository from $CRUSH_REPO_URL" >&2
    exit 1
  fi
}

update_repo() {
  local dest="$1"
  echo "Updating existing Crush checkout in $dest" >&2
  if ! git -C "$dest" remote get-url origin >/dev/null 2>&1; then
    echo "error: $dest exists but is not a git repository (use --force to replace)" >&2
    exit 1
  fi

  local current_remote
  current_remote="$(git -C "$dest" remote get-url origin 2>/dev/null || true)"
  if [[ "$current_remote" != "$CRUSH_REPO_URL" ]]; then
    echo "error: $dest is tracking $current_remote (expected $CRUSH_REPO_URL). Use --force to replace." >&2
    exit 1
  fi

  if ! git -C "$dest" fetch --depth 1 origin "$DEFAULT_BRANCH"; then
    echo "error: failed to fetch updates from $CRUSH_REPO_URL" >&2
    exit 1
  fi

  if ! git -C "$dest" reset --hard "origin/$DEFAULT_BRANCH"; then
    echo "error: failed to reset $dest to origin/$DEFAULT_BRANCH" >&2
    exit 1
  fi
}

if [[ -e "$TARGET_CRUSH_DIR" ]]; then
  if [[ $FORCE -eq 1 ]]; then
    rm -rf "$TARGET_CRUSH_DIR"
    clone_repo "$TARGET_CRUSH_DIR"
  else
    update_repo "$TARGET_CRUSH_DIR"
  fi
else
  clone_repo "$TARGET_CRUSH_DIR"
fi

install_crushignore() {
  local template="$TARGET_CRUSH_DIR/configs/.crushignore"
  local dest="$PROJECT_ROOT/.crushignore"

  if [[ ! -f "$template" ]]; then
    return
  fi

  if [[ -e "$dest" ]]; then
    echo "Existing .crushignore detected at $dest; leaving untouched." >&2
    return
  fi

  if cp "$template" "$dest"; then
    echo "Installed template .crushignore at $dest" >&2
  else
    echo "warning: failed to copy template .crushignore to $dest" >&2
  fi
}

install_crushignore

echo
cat <<'NEXT_STEPS'
Bootstrap complete! Next steps:
  1. Run .crush/scripts/tmux-multi-agent.sh (or the equivalent helper) to start the multi-agent tmux session.
  2. Commit the cloned configuration into your project repository if desired.
NEXT_STEPS

