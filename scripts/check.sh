#!/usr/bin/env bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOSTS_SOURCE="$ROOT_DIR/hosts"

python3 - "$HOSTS_SOURCE" <<'PY'
import ipaddress
import sys

path = sys.argv[1]
seen = {}
errors = []
for number, raw in enumerate(open(path, encoding="utf-8"), 1):
    line = raw.split("#", 1)[0].strip()
    if not line:
        continue
    fields = line.split()
    if len(fields) < 2:
        errors.append(f"line {number}: expected an address and at least one hostname")
        continue
    try:
        ipaddress.ip_address(fields[0])
    except ValueError:
        errors.append(f"line {number}: invalid IP address: {fields[0]}")
        continue
    for hostname in fields[1:]:
        if hostname.startswith("*.") or "*" in hostname:
            errors.append(f"line {number}: hosts files do not support wildcards: {hostname}")
        if hostname in seen:
            errors.append(f"line {number}: duplicate hostname {hostname} (first on line {seen[hostname]})")
        else:
            seen[hostname] = number

if errors:
    print("Invalid hosts file:", file=sys.stderr)
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)

print(f"OK: {len(seen)} unique hostnames")
PY
