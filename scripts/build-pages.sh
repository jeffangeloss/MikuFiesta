#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
LOCKED_HTML="$ROOT_DIR/index.html"
LOCAL_OPEN_HTML="$ROOT_DIR/private/open/index.html"
LOCAL_ASSETS_DIR="$ROOT_DIR/private/assets"
OPEN_AT_UTC="${OPEN_AT_UTC:-2026-04-17T17:00:00Z}"
FORCE_STATE="${FORCE_STATE:-auto}"

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/index.html" "$DIST_DIR/.nojekyll" "$DIST_DIR/build-state.txt"
rm -rf "$DIST_DIR/assets"

STATE="$(
python3 - "$OPEN_AT_UTC" "$FORCE_STATE" <<'PY'
from datetime import datetime, timezone
import sys

open_at_raw = sys.argv[1]
force_state = sys.argv[2].strip().lower()

if force_state in {"locked", "open"}:
    print(force_state)
    raise SystemExit(0)

if force_state not in {"", "auto"}:
    raise SystemExit(f"Unsupported FORCE_STATE value: {force_state}")

open_at = datetime.fromisoformat(open_at_raw.replace("Z", "+00:00"))
now = datetime.now(timezone.utc)
print("open" if now >= open_at else "locked")
PY
)"

if [[ "$STATE" == "locked" ]]; then
  cp "$LOCKED_HTML" "$DIST_DIR/index.html"
elif [[ -n "${SITE_OPEN_HTML_B64:-}" ]]; then
  python3 - "$DIST_DIR/index.html" <<'PY'
import base64
import os
import sys

output_path = sys.argv[1]
payload = os.environ["SITE_OPEN_HTML_B64"]

with open(output_path, "wb") as fh:
    fh.write(base64.b64decode(payload))
PY
elif [[ -f "$LOCAL_OPEN_HTML" ]]; then
  cp "$LOCAL_OPEN_HTML" "$DIST_DIR/index.html"
else
  echo "The open site is missing. Provide SITE_OPEN_HTML_B64 or create private/open/index.html." >&2
  exit 1
fi

if [[ "$STATE" == "open" && -d "$LOCAL_ASSETS_DIR" ]]; then
  cp -R "$LOCAL_ASSETS_DIR" "$DIST_DIR/assets"
fi

touch "$DIST_DIR/.nojekyll"
printf '%s\n' "$STATE" > "$DIST_DIR/build-state.txt"
echo "Generated Pages artifact in state: $STATE"
