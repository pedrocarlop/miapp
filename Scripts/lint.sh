#!/usr/bin/env bash
set -euo pipefail

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "swiftlint is not installed. Install it with: brew install swiftlint" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

swiftlint lint --config .swiftlint.yml --strict
