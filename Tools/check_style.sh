#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

status=0
swift_files="$(git ls-files | grep -E '\.swift$' || true)"

if [[ -z "$swift_files" ]]; then
  echo "No Swift files found."
  exit 0
fi

while IFS= read -r file; do
  [[ -n "$file" ]] || continue

  if grep -n $'\t' "$file" >/dev/null; then
    echo "Tab character found in $file"
    grep -n $'\t' "$file"
    status=1
  fi

  if grep -n '[[:blank:]]$' "$file" >/dev/null; then
    echo "Trailing whitespace found in $file"
    grep -n '[[:blank:]]$' "$file"
    status=1
  fi
done <<< "$swift_files"

if [[ $status -eq 0 ]]; then
  echo "Style checks passed."
fi

exit $status
