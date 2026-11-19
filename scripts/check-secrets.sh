#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# check-secrets.sh — fails if a secret-like value or a personal absolute path
# is found in the tracked tree. Runs locally and in CI.
#
# Usage: ./scripts/check-secrets.sh
# ---------------------------------------------------------------------------
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

status=0
patterns=(
  'sk-[A-Za-z0-9_-]{16,}'
  'sk_[A-Za-z0-9_-]{16,}'
  'ghp_[A-Za-z0-9]{20,}'
  'gho_[A-Za-z0-9]{20,}'
  'ghs_[A-Za-z0-9]{20,}'
  'github_pat_[A-Za-z0-9_]{20,}'
  'AKIA[0-9A-Z]{16}'
  'AIza[0-9A-Za-z_-]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
  '(api[_-]?key|secret|token|password)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{16,}["'"'"']'
  '/(home|Users)/[A-Za-z0-9._-]+/'
)

for pattern in "${patterns[@]}"; do
  matches="$(grep -RInE --exclude-dir=.git --exclude='check-secrets.sh' -- "$pattern" . || true)"
  if [ -n "$matches" ]; then
    printf '%s\n' "$matches"
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  printf '\033[32mOK\033[0m no secret-like values or personal absolute paths found\n'
else
  printf '\033[31mFAIL\033[0m remove the values above before committing\n'
fi

exit "$status"
