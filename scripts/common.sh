#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOSTS_SOURCE="$ROOT_DIR/hosts"
HOSTS_FILE="${HOSTS_FILE:-/etc/hosts}"
BEGIN_MARKER='# BEGIN etc_hosts managed block'
END_MARKER='# END etc_hosts managed block'

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "Run this command with sudo: sudo $0" >&2
    exit 1
  fi
}

make_temp_file() {
  local dir
  dir="$(dirname "$HOSTS_FILE")"
  mktemp "$dir/.etc_hosts.XXXXXX"
}

strip_managed_block() {
  local input="$1"
  local output="$2"
  awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
    $0 == begin { if (inside) bad=1; inside=1; next }
    $0 == end   { if (!inside) bad=1; inside=0; next }
    !inside { print }
    END { if (inside || bad) exit 1 }
  ' "$input" > "$output"
}

backup_and_replace() {
  local candidate="$1"
  local backup
  backup="${HOSTS_FILE}.backup.$(date +%Y%m%d-%H%M%S)"
  if [[ -e "$HOSTS_FILE" ]]; then
    cp -p "$HOSTS_FILE" "$backup"
    local mode
    if mode="$(stat -f '%Lp' "$HOSTS_FILE" 2>/dev/null)"; then
      chmod "$mode" "$candidate"
    elif mode="$(stat -c '%a' "$HOSTS_FILE" 2>/dev/null)"; then
      chmod "$mode" "$candidate"
    fi
  fi
  mv -f "$candidate" "$HOSTS_FILE"
  echo "Updated $HOSTS_FILE (backup: $backup)"
}

remove_managed_block() {
  require_root
  if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Hosts file not found: $HOSTS_FILE" >&2
    exit 1
  fi
  if ! grep -Fqx "$BEGIN_MARKER" "$HOSTS_FILE"; then
    echo "No etc_hosts managed block found in $HOSTS_FILE"
    return 0
  fi
  local tmp
  tmp="$(make_temp_file)"
  if ! strip_managed_block "$HOSTS_FILE" "$tmp"; then
    rm -f "$tmp"
    echo "Managed markers are malformed; leaving $HOSTS_FILE unchanged" >&2
    exit 1
  fi
  backup_and_replace "$tmp"
}
