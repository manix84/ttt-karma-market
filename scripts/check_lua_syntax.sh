#!/usr/bin/env bash
set -euo pipefail

if command -v luac5.1 >/dev/null 2>&1; then
  LUAC_BIN="luac5.1"
elif command -v luac >/dev/null 2>&1; then
  LUAC_BIN="luac"
else
  echo "luac or luac5.1 is required for Lua syntax checks." >&2
  exit 1
fi

lua_files=()
while IFS= read -r file; do
  lua_files+=("$file")
done < <(find lua -type f -name '*.lua' | sort)

if [ "${#lua_files[@]}" -eq 0 ]; then
  echo "No Lua files found." >&2
  exit 1
fi

"$LUAC_BIN" -p "${lua_files[@]}"
echo "Lua syntax ok (${#lua_files[@]} files)."
