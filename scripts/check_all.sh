#!/usr/bin/env bash
set -euo pipefail

python3 scripts/check_addon.py
bash scripts/check_lua_syntax.sh
bash scripts/dry_run_build.sh
node scripts/generate-release-notes.mjs
