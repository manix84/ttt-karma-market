#!/usr/bin/env python3
"""Repository-local checks for the Garry's Mod addon package surface."""

from __future__ import annotations

import fnmatch
import json
import struct
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = {
    "addon.json",
    "CONTRIBUTING.md",
    "PRIVACY.md",
    "SECURITY.md",
    "SUPPORT.md",
    "VERSION",
    "WHATSNEW.md",
    "lua/autorun/ttt_karma_market.lua",
    "lua/ttt_karma_market/sh_config.lua",
    "lua/ttt_karma_market/sh_types.lua",
    "lua/ttt_karma_market/sv_karma_market.lua",
    "lua/ttt_karma_market/sv_admin.lua",
    "lua/ttt_karma_market/cl_karma_market.lua",
    "lua/ttt_karma_market/cl_chart.lua",
    "lua/ttt_karma_market/cl_ui.lua",
    "lua/ttt_karma_market/cl_admin.lua",
    "materials/icon64/ttt_karma_market.png",
    "workshop/icon.jpg",
}

REQUIRED_IGNORES = {
    ".github/*",
    "scripts/*",
    "tests/*",
    "workshop/*",
    "dist/*",
    "README.md",
    "CONTRIBUTING.md",
    "LICENSE.md",
    "PRIVACY.md",
    "SECURITY.md",
    "SUPPORT.md",
    "VERSION",
    "WHATSNEW.md",
    ".githooks/*",
    ".tools/*",
    "*.gma",
    "*.DS_Store",
}

PACKAGE_EXTENSIONS = {
    ".json",
    ".lua",
    ".png",
    ".jpg",
    ".jpeg",
    ".vtf",
    ".vmt",
    ".wav",
    ".mp3",
    ".ogg",
    ".mdl",
    ".phy",
    ".vvd",
    ".dx80.vtx",
    ".dx90.vtx",
    ".sw.vtx",
}

FORBIDDEN_PATTERNS = (
    "*.html",
    "*.htm",
    "*.js",
    "*.css",
    "*.psd",
    "*.pdn",
    "*.exe",
    "*.dll",
    "*.so",
    "*.dylib",
)

FORBIDDEN_LUA_SNIPPETS = (
    "DHTML",
    "vgui.Create(\"DHTML\"",
    "vgui.Create('DHTML'",
    "http.Fetch",
    "HTTP(",
    "require(",
)


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def load_addon_json() -> dict:
    try:
        return json.loads((ROOT / "addon.json").read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"addon.json is invalid JSON: {exc}")


def is_ignored(path: str, ignore_patterns: list[str]) -> bool:
    return any(fnmatch.fnmatchcase(path, pattern) for pattern in ignore_patterns)


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        fail(f"{rel(path)} is not a PNG file")

    return struct.unpack(">II", data[16:24])


def jpeg_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if not data.startswith(b"\xff\xd8"):
        fail(f"{rel(path)} is not a JPEG file")

    index = 2
    while index < len(data):
        while index < len(data) and data[index] == 0xFF:
            index += 1

        marker = data[index]
        index += 1

        if marker in {0xD8, 0xD9}:
            continue

        length = struct.unpack(">H", data[index:index + 2])[0]
        segment = data[index + 2:index + length]

        if marker in range(0xC0, 0xC4):
            height, width = struct.unpack(">HH", segment[1:5])
            return width, height

        index += length

    fail(f"Could not read JPEG dimensions for {rel(path)}")


def all_files() -> list[Path]:
    return sorted(
        path
        for path in ROOT.rglob("*")
        if path.is_file() and ".git" not in path.parts
    )


def check_metadata(addon: dict) -> list[str]:
    errors: list[str] = []

    if addon.get("title") != "TTT Karma Market":
        errors.append("addon.json title must be 'TTT Karma Market'")

    if addon.get("type") != "tool":
        errors.append("addon.json type must be 'tool'")

    tags = addon.get("tags")
    if not isinstance(tags, list) or not tags:
        errors.append("addon.json tags must be a non-empty list")

    ignore = addon.get("ignore")
    if not isinstance(ignore, list):
        errors.append("addon.json ignore must be a list")
    else:
        missing = sorted(REQUIRED_IGNORES.difference(ignore))
        if missing:
            errors.append("addon.json ignore is missing: " + ", ".join(missing))

    return errors


def check_required_files() -> list[str]:
    return [
        f"missing required file: {path}"
        for path in sorted(REQUIRED_FILES)
        if not (ROOT / path).is_file()
    ]


def check_package_surface(ignore: list[str]) -> list[str]:
    errors: list[str] = []
    package_files: list[str] = []

    for path in all_files():
        name = rel(path)

        if is_ignored(name, ignore):
            continue

        package_files.append(name)

        for pattern in FORBIDDEN_PATTERNS:
            if fnmatch.fnmatchcase(name, pattern):
                errors.append(f"forbidden file would be packaged: {name}")

        if path.suffix.lower() not in PACKAGE_EXTENSIONS:
            errors.append(f"unexpected package file extension: {name}")

    if "addon.json" not in package_files:
        errors.append("addon.json would not be packaged")

    return errors


def check_images() -> list[str]:
    errors: list[str] = []
    icon64 = ROOT / "materials/icon64/ttt_karma_market.png"
    workshop_icon = ROOT / "workshop/icon.jpg"

    if png_size(icon64) != (64, 64):
        errors.append("materials/icon64/ttt_karma_market.png must be 64x64")

    if jpeg_size(workshop_icon) != (512, 512):
        errors.append("workshop/icon.jpg must be 512x512")

    return errors


def check_lua_policy() -> list[str]:
    errors: list[str] = []

    for path in sorted((ROOT / "lua").rglob("*.lua")):
        text = path.read_text(encoding="utf-8")
        name = rel(path)

        for snippet in FORBIDDEN_LUA_SNIPPETS:
            if snippet in text:
                errors.append(f"forbidden Lua snippet in {name}: {snippet}")

        if "\t" in text:
            errors.append(f"tab indentation found in {name}; use spaces")

        for lineno, line in enumerate(text.splitlines(), start=1):
            if line.rstrip() != line:
                errors.append(f"trailing whitespace in {name}:{lineno}")

    return errors


def main() -> int:
    addon = load_addon_json()
    errors: list[str] = []

    errors.extend(check_metadata(addon))
    errors.extend(check_required_files())
    errors.extend(check_package_surface(addon.get("ignore", [])))
    errors.extend(check_images())
    errors.extend(check_lua_policy())

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)

        return 1

    print("Addon checks ok.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
