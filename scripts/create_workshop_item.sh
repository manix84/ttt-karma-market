#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
GMA_PATH="$DIST_DIR/ttt-karma-market.gma"
ICON_PATH="$ROOT_DIR/workshop/icon.jpg"
WORKSHOP_VDF_PATH="$DIST_DIR/workshop-create.vdf"
WORKSHOP_CONTENT_DIR="$DIST_DIR/workshop-content"

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

vdf_value() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

create_with_steamcmd() {
  local steamcmd_bin
  steamcmd_bin="$(find_tool "${STEAMCMD_BIN:-}" \
    "$(command -v steamcmd 2>/dev/null || true)" \
    "$HOME/Library/Application Support/Steam/steamcmd/steamcmd.sh" \
    "$HOME/.steam/steamcmd/steamcmd.sh")" || {
      echo "Could not find SteamCMD. Install it or set STEAMCMD_BIN explicitly." >&2
      exit 1
    }

  if [ -z "${STEAM_USERNAME:-}" ]; then
    read -r -p "Steam username for SteamCMD upload: " STEAM_USERNAME
  fi

  if [ -z "${STEAM_USERNAME}" ]; then
    echo "Steam username is required for SteamCMD upload." >&2
    exit 1
  fi

  rm -rf "$WORKSHOP_CONTENT_DIR"
  mkdir -p "$WORKSHOP_CONTENT_DIR"
  cp "$GMA_PATH" "$WORKSHOP_CONTENT_DIR/ttt-karma-market.gma"

  cat > "$WORKSHOP_VDF_PATH" <<EOF
"workshopitem"
{
  "appid" "4000"
  "publishedfileid" "0"
  "contentfolder" "$(vdf_value "$WORKSHOP_CONTENT_DIR")"
  "previewfile" "$(vdf_value "$ICON_PATH")"
  "visibility" "2"
  "title" "TTT Karma Market"
  "description" "Visualises Trouble in Terrorist Town karma changes as end-round candlestick charts."
  "changenote" "Initial release."
}
EOF

  echo "Creating Workshop item with SteamCMD. Steam Guard may prompt on first login."
  "$steamcmd_bin" +login "$STEAM_USERNAME" +workshop_build_item "$WORKSHOP_VDF_PATH" +quit

  local item_id
  item_id="$(sed -n 's/.*"publishedfileid"[[:space:]]*"\([0-9][0-9]*\)".*/\1/p' "$WORKSHOP_VDF_PATH" | tail -1)"

  if [ -z "$item_id" ] || [ "$item_id" = "0" ]; then
    echo "SteamCMD completed, but no Workshop item ID was written to $WORKSHOP_VDF_PATH" >&2
    exit 1
  fi

  cat <<EOF

Created Steam Workshop item:
https://steamcommunity.com/sharedfiles/filedetails/?id=$item_id

Add this as the GitHub Actions repository variable:
STEAM_WORKSHOP_ITEM_ID=$item_id

EOF
}

if [ -z "${GMOD_BIN:-}" ]; then
  case "$(uname -s)" in
    Darwin)
      GMOD_BIN="$HOME/Library/Application Support/Steam/steamapps/common/GarrysMod"
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
  "${GMOD_BIN:-}/bin/gmad" \
  "${GMOD_BIN:-}/bin/gmad.exe" \
  "${GMOD_BIN:-}/GarrysMod_Signed.app/Contents/MacOS/gmad" \
  "${GMOD_BIN:-}/GarrysMod_Signed.app/Contents/MacOS/gmad.exe" \
  "${GMOD_BIN:-}/linux64/gmad" \
  "${GMOD_BIN:-}/linux32/gmad" \
  "$(command -v gmad 2>/dev/null || true)")" || {
    echo "Could not find gmad. Set GMOD_BIN or GMAD_BIN explicitly." >&2
    exit 1
  }

GMPUBLISH_BIN="$(find_tool "${GMPUBLISH_BIN:-}" \
  "${GMOD_BIN:-}/gmpublish" \
  "${GMOD_BIN:-}/gmpublish.exe" \
  "${GMOD_BIN:-}/bin/gmpublish" \
  "${GMOD_BIN:-}/bin/gmpublish.exe" \
  "${GMOD_BIN:-}/GarrysMod_Signed.app/Contents/MacOS/gmpublish" \
  "${GMOD_BIN:-}/GarrysMod_Signed.app/Contents/MacOS/gmpublish.exe" \
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
5. Add that number as the GitHub Actions repository variable STEAM_WORKSHOP_ITEM_ID.

If gmpublish fails with "Creation failed! Not logged on", this script will fall
back to SteamCMD and create the item with publishedfileid "0".

EOF

set +e
"$GMPUBLISH_BIN" create -addon "$GMA_PATH" -icon "$ICON_PATH"
publish_exit=$?
set -e

if [ "$publish_exit" -eq 0 ]; then
  exit 0
fi

echo
echo "gmpublish failed. Falling back to SteamCMD Workshop upload."
create_with_steamcmd
