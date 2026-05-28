#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
GMA_PATH="$DIST_DIR/ttt-karma-market.gma"
ICON_PATH="$ROOT_DIR/workshop/icon.jpg"

find_tool() {
  local env_value="$1"
  shift

  if [ -n "$env_value" ]; then
    if [ -x "$env_value" ]; then
      printf '%s\n' "$env_value"
      return 0
    fi

    echo "Configured tool is not executable: $env_value" >&2
    return 1
  fi

  for candidate in "$@"; do
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

if [ -z "${GMOD_BIN:-}" ]; then
  case "$(uname -s)" in
    Darwin)
      GMOD_BIN="$HOME/Library/Application Support/Steam/steamapps/common/GarrysMod/bin"
      ;;
    Linux)
      GMOD_BIN="$HOME/.steam/steam/steamapps/common/GarrysMod/bin"
      ;;
    *)
      GMOD_BIN=""
      ;;
  esac
fi

GMAD_BIN="$(find_tool "${GMAD_BIN:-}" \
  "${GMOD_BIN:-}/gmad" \
  "${GMOD_BIN:-}/gmad.exe" \
  "${GMOD_BIN:-}/linux64/gmad" \
  "${GMOD_BIN:-}/linux32/gmad" \
  "$(command -v gmad 2>/dev/null || true)")" || {
    echo "Could not find gmad. Set GMOD_BIN or GMAD_BIN explicitly." >&2
    exit 1
  }

GMPUBLISH_BIN="$(find_tool "${GMPUBLISH_BIN:-}" \
  "${GMOD_BIN:-}/gmpublish" \
  "${GMOD_BIN:-}/gmpublish.exe" \
  "${GMOD_BIN:-}/linux64/gmpublish" \
  "${GMOD_BIN:-}/linux32/gmpublish" \
  "$(command -v gmpublish 2>/dev/null || true)")" || {
    echo "Could not find gmpublish. Set GMOD_BIN or GMPUBLISH_BIN explicitly." >&2
    exit 1
  }

mkdir -p "$DIST_DIR"

bash "$ROOT_DIR/scripts/check_all.sh"

"$GMAD_BIN" create -folder "$ROOT_DIR" -out "$GMA_PATH"

cat <<EOF

About to create a NEW Steam Workshop item.

This should normally be run once. After it succeeds:
1. Open your Garry's Mod Workshop page.
2. Go to Your Files > Files You've Posted.
3. Open the new item.
4. Copy the numeric id from the URL:
   https://steamcommunity.com/sharedfiles/filedetails/?id=<THIS_NUMBER>
5. Add that number as the GitHub Actions secret STEAM_WORKSHOP_ID.

EOF

"$GMPUBLISH_BIN" create -addon "$GMA_PATH" -icon "$ICON_PATH"
