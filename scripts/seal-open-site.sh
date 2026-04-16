#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_OPEN_HTML="$ROOT_DIR/private/open/index.html"
LOCAL_ASSETS_DIR="$ROOT_DIR/private/assets"
PASSPHRASE_FILE="${OPEN_SITE_PASSPHRASE_FILE:-$ROOT_DIR/private/.open-site-passphrase}"
SEALED_OUTPUT="$ROOT_DIR/secure/open-site.tar.enc"
TEMP_DIRS=()

cleanup() {
  local entry

  if ((${#TEMP_DIRS[@]})); then
    for entry in "${TEMP_DIRS[@]}"; do
      [[ -n "$entry" && -e "$entry" ]] && rm -rf "$entry"
    done
  fi

  return 0
}

trap cleanup EXIT

if [[ ! -f "$LOCAL_OPEN_HTML" ]]; then
  echo "Missing $LOCAL_OPEN_HTML" >&2
  exit 1
fi

if [[ ! -d "$LOCAL_ASSETS_DIR" ]]; then
  echo "Missing $LOCAL_ASSETS_DIR" >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/secure" "$(dirname "$PASSPHRASE_FILE")"

if [[ ! -f "$PASSPHRASE_FILE" ]]; then
  openssl rand -base64 48 | tr -d '\n' > "$PASSPHRASE_FILE"
  chmod 600 "$PASSPHRASE_FILE"
  echo "Created local passphrase file at $PASSPHRASE_FILE"
fi

PAYLOAD_DIR="$(mktemp -d)"
TEMP_DIRS+=("$PAYLOAD_DIR")

mkdir -p "$PAYLOAD_DIR/assets"
cp "$LOCAL_OPEN_HTML" "$PAYLOAD_DIR/index.html"
cp -R "$LOCAL_ASSETS_DIR"/. "$PAYLOAD_DIR/assets/"

tar -C "$PAYLOAD_DIR" -cf - . | openssl enc -aes-256-cbc -pbkdf2 -salt -pass "file:$PASSPHRASE_FILE" -out "$SEALED_OUTPUT"

echo "Created sealed launch bundle at $SEALED_OUTPUT"
echo "Reuse passphrase from $PASSPHRASE_FILE when syncing the GitHub secret OPEN_SITE_PASSPHRASE."
