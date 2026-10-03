#!/usr/bin/env python3
"""Refresh the IPv4 snapshot in the repository hosts file via Google DoH."""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen
import json
import os
import sys

ROOT = Path(__file__).resolve().parents[1]
HOSTS = ROOT / "hosts"
ENDPOINT = os.environ.get("DOH_ENDPOINT", "https://dns.google/resolve")


def parse_hosts(path):
    header = []
    names = []
    body_started = False
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            if not body_started:
                header.append(line)
            continue
        body_started = True
        fields = stripped.split()
        if len(fields) < 2:
            raise ValueError(f"Malformed hosts line: {line}")
        names.extend(fields[1:])
    return header, sorted(set(names))


def resolve(name):
    url = ENDPOINT + "?" + urlencode({"name": name, "type": "A"})
    request = Request(url, headers={"accept": "application/dns-json"})
    with urlopen(request, timeout=15) as response:
        payload = json.load(response)
    addresses = list(dict.fromkeys(
        row["data"] for row in payload.get("Answer", []) if row.get("type") == 1
    ))
    if not addresses:
        raise ValueError(f"No IPv4 A record returned for {name}")
    return name, addresses[0]


def main():
    header, names = parse_hosts(HOSTS)
    with ThreadPoolExecutor(max_workers=6) as pool:
        resolved = dict(pool.map(resolve, names))
    lines = header + [f"{resolved[name]} {name}" for name in names]
    temporary = HOSTS.with_suffix(".tmp")
    temporary.write_text("\n".join(lines) + "\n", encoding="utf-8")
    temporary.replace(HOSTS)
    print(f"Updated {len(names)} hostnames in {HOSTS}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"refresh failed: {error}", file=sys.stderr)
        sys.exit(1)
