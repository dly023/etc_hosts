#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
require_root

if [[ ! -r "$HOSTS_SOURCE" ]]; then
  echo "Cannot read $HOSTS_SOURCE" >&2
  exit 1
fi
"$ROOT_DIR/scripts/check.sh"

tmp="$(make_temp_file)"
if [[ -f "$HOSTS_FILE" ]]; then
  if ! strip_managed_block "$HOSTS_FILE" "$tmp"; then
    rm -f "$tmp"
    echo "Managed markers are malformed; leaving $HOSTS_FILE unchanged" >&2
    exit 1
  fi
else
  : > "$tmp"
fi

{
  printf '\n%s\n' "$BEGIN_MARKER"
  cat "$HOSTS_SOURCE"
  printf '%s\n' "$END_MARKER"
} >> "$tmp"

backup_and_replace "$tmp"

if [[ "$(uname -s)" == "Darwin" ]]; then
  dscacheutil -flushcache
  killall -HUP mDNSResponder 2>/dev/null || true
fi
