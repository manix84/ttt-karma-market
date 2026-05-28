#!/usr/bin/env bash
set -euo pipefail

mkdir -p dist

if command -v gmad >/dev/null 2>&1; then
  gmad create -folder . -out dist/ttt-karma-market.gma
  echo "gmad build ok: dist/ttt-karma-market.gma"
else
  echo "gmad not found; running package-surface dry run instead."
  python3 scripts/check_addon.py
fi
