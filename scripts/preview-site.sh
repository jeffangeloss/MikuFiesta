#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="${1:-open}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-4173}"

case "$STATE" in
  open|locked)
    ;;
  *)
    echo "Usage: $0 [open|locked]" >&2
    exit 1
    ;;
esac

FORCE_STATE="$STATE" "$ROOT_DIR/scripts/build-pages.sh" >/dev/null

echo "Previewing '$STATE' site at http://$HOST:$PORT"
echo "This server is bound to $HOST only, so it stays local to your machine."
echo "Press Ctrl+C to stop."

cd "$ROOT_DIR/dist"
exec python3 -m http.server "$PORT" --bind "$HOST"
