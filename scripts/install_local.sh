#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-symlink}"
ADDONS_DIR="${2:-}"
ADDON_NAME="${ADDON_NAME:-ttt-karma-market}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "$ADDONS_DIR" ]; then
  case "$(uname -s)" in
    Darwin)
      ADDONS_DIR="$HOME/Library/Application Support/Steam/steamapps/common/GarrysMod/garrysmod/addons"
      ;;
    Linux)
      ADDONS_DIR="$HOME/.steam/steam/steamapps/common/GarrysMod/garrysmod/addons"
      ;;
    *)
      echo "Could not infer Garry's Mod addons directory for this OS." >&2
      echo "Usage: scripts/install_local.sh [symlink|copy] /path/to/GarrysMod/garrysmod/addons" >&2
      exit 1
      ;;
  esac
fi

TARGET="$ADDONS_DIR/$ADDON_NAME"

if [ "$MODE" != "symlink" ] && [ "$MODE" != "copy" ]; then
  echo "Unknown mode: $MODE" >&2
  echo "Usage: scripts/install_local.sh [symlink|copy] /path/to/GarrysMod/garrysmod/addons" >&2
  exit 1
fi

if [ ! -d "$ADDONS_DIR" ]; then
  echo "Addons directory does not exist: $ADDONS_DIR" >&2
  echo "Create it or pass the correct path explicitly." >&2
  exit 1
fi

bash "$ROOT_DIR/scripts/check_all.sh"

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  if [ "$TARGET" != "$ROOT_DIR" ] && [ "$(readlink "$TARGET" 2>/dev/null || true)" != "$ROOT_DIR" ]; then
    echo "Target already exists and is not this project: $TARGET" >&2
    echo "Remove it manually first if you want to replace it." >&2
    exit 1
  fi
fi

if [ "$MODE" = "symlink" ]; then
  ln -sfn "$ROOT_DIR" "$TARGET"
  echo "Installed local symlink: $TARGET -> $ROOT_DIR"
else
  rm -rf "$TARGET"
  mkdir -p "$TARGET"
  tar \
    --exclude '.git' \
    --exclude 'dist' \
    --exclude '*.gma' \
    -cf - -C "$ROOT_DIR" . | tar -xf - -C "$TARGET"
  echo "Installed local copy: $TARGET"
fi

echo "Restart Garry's Mod or change map before testing."
