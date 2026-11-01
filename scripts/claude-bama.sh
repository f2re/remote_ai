#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

git submodule update --init --recursive

if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code CLI was not found in PATH." >&2
  exit 127
fi

exec claude --plugin-dir "$ROOT/vendor/bama" "$@"
