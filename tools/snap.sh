#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-/tmp/RemoteAI-shots}"

rm -rf "$OUT"
mkdir -p "$OUT"

cd "$ROOT"
REMOTE_AI_SNAPSHOT_DIR="$OUT" swift test --filter ReleaseSnapshotTests

count="$(find "$OUT" -type f -name '*.png' | wc -l | tr -d ' ')"
if [[ "$count" -lt 16 ]]; then
  echo "Expected at least 16 PNG snapshots, found $count" >&2
  exit 1
fi

find "$OUT" -type f -name '*.png' -print | sort
echo "SNAPSHOT done $OUT"
