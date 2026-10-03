#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/common.sh"
remove_managed_block

if [[ "$(uname -s)" == "Darwin" ]]; then
  dscacheutil -flushcache
  killall -HUP mDNSResponder 2>/dev/null || true
fi
