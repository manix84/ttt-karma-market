# 📈 TTT Karma Market

TTT Karma Market is a self-contained Trouble in Terrorist Town addon that
visualises per-player karma movement as an end-round candlestick chart.

## ✨ Features

- Tracks karma snapshots during each TTT round.
- Builds OHLC candlestick data per player.
- Shows a `Karma Market` end-round tab when the TTT UI can be safely extended.
- Falls back to a standalone Derma popup when no compatible end-round sheet is found.
- Provides player sorting by name, biggest gain, biggest loss, and volatility.
- Uses only Lua, Derma, VGUI, and custom panel painting. No DHTML, web libraries, or remote assets.

## 📦 Installation

Copy this repository folder into your Garry's Mod addons directory:

```text
garrysmod/addons/ttt-karma-market
```

Restart the server or change map after installation.

## 🧪 Local Testing

For local development, install the repository into your Garry's Mod addons
directory before starting the game.

On macOS with the default Steam install path:

```sh
bash scripts/install_local.sh
```

That creates a symlink at:

```text
~/Library/Application Support/Steam/steamapps/common/GarrysMod/garrysmod/addons/ttt-karma-market
```

To pass the addons directory explicitly:

```sh
bash scripts/install_local.sh symlink "/path/to/GarrysMod/garrysmod/addons"
```

If you prefer a physical copy instead of a symlink:

```sh
bash scripts/install_local.sh copy "/path/to/GarrysMod/garrysmod/addons"
```

The helper runs `bash scripts/check_all.sh` before installing. After install,
restart Garry's Mod or change map.

Recommended manual smoke test:

- Start a local TTT game or server with this addon installed.
- Confirm the addon appears in `Utilities > TTT > Karma Market`.
- Click `Open sample chart` to verify the client UI and candlestick renderer without waiting for a round.
- Start and finish a TTT round.
- Confirm the `Karma Market` end-round tab appears, or that the fallback popup opens.
- Toggle `ttt_karma_market_debug` in the admin panel and check the console for lifecycle messages.

## ⚙️ Configuration

Edit `lua/ttt_karma_market/sh_config.lua`.

Server settings are exposed as replicated ConVars and through Garry's Mod's
spawn menu:

```text
Utilities > TTT > Karma Market
```

Important ConVars:

- `ttt_karma_market_enabled`: enables tracking and display.
- `ttt_karma_market_debug`: prints lifecycle, sampling, networking, and admin messages.
- `ttt_karma_market_sample_interval`: seconds between karma samples.
- `ttt_karma_market_popup_fallback`: enables the standalone popup if tab injection is unavailable.
- `ttt_karma_market_max_candles`: maximum candles kept for each player.
- `ttt_karma_market_chart_height`: preferred fallback popup chart height.
- `ttt_karma_market_show_grid`: toggles chart grid lines.
- `ttt_karma_market_show_labels`: toggles chart axis labels.
- `ttt_karma_market_auto_sort`: applies the default sort when the panel opens.
- `ttt_karma_market_default_sort`: `alpha`, `gain`, `loss`, or `volatile`.

Non-admin clients can read replicated settings, but server setting changes and
admin actions are validated server-side.

## 🛠️ Workshop Packaging

From the repository root:

```sh
gmad create -folder . -out ttt-karma-market.gma
```

The addon is designed for `gmad` and `gmpublish` and avoids unsupported file
types, external dependencies, generated junk, and modifications to TTT core
files.

## 🆕 First Workshop Publish

You do not get a Workshop item ID until the first successful publish. The first
publish creates the Workshop page; after that, the numeric ID in the page URL is
used for updates and CI deployment.

Run this locally once:

```sh
bash scripts/create_workshop_item.sh
```

The script:

- runs the local validation suite
- builds `dist/ttt-karma-market.gma`
- uploads a new Workshop item with `gmpublish create`
- uses `workshop/icon.jpg` as the Workshop icon

On macOS, the script looks in the normal Steam install and the signed app bundle:

```text
~/Library/Application Support/Steam/steamapps/common/GarrysMod/GarrysMod_Signed.app/Contents/MacOS
```

If the script cannot find Garry's Mod tools automatically, set paths explicitly:

```sh
GMOD_BIN="/path/to/GarrysMod" bash scripts/create_workshop_item.sh
```

or:

```sh
GMAD_BIN="/path/to/gmad" GMPUBLISH_BIN="/path/to/gmpublish" bash scripts/create_workshop_item.sh
```

If `gmpublish create` fails with:

```text
Creation failed! Not logged on
```

the script falls back to SteamCMD and creates the Workshop item with
`publishedfileid "0"`. SteamCMD may prompt for your Steam password and Steam
Guard code the first time. You can provide the username up front:

```sh
STEAM_USERNAME="your_steam_username" bash scripts/create_workshop_item.sh
```

After SteamCMD succeeds, it writes the new item ID back to
`dist/workshop-create.vdf` and prints the Workshop URL.

After the upload succeeds, open the new Workshop item and copy the number from
the URL:

```text
https://steamcommunity.com/sharedfiles/filedetails/?id=1234567890
```

Use that number as the `STEAM_WORKSHOP_ITEM_ID` GitHub Actions repository
variable, or as the `STEAM_WORKSHOP_ID` secret. Future pushes to `main` can then
update the existing item instead of creating a new one.

## 🧪 Checks

Run the local validation suite from the repository root:

```sh
bash scripts/check_all.sh
```

This checks:

- addon metadata and required file layout
- Workshop package surface and ignored repository files
- 64x64 in-game icon and 512x512 Workshop icon dimensions
- Lua syntax with `luac`
- simple GLua policy checks for forbidden web/DHTML patterns
- dry-run build behavior, using `gmad` when available
- release-note generation

Run the GLua linter separately:

```sh
./scripts/glualint.sh
```

The linter helper installs GLuaFixer locally into `.tools/` if it is not already
available.

## 🔖 Versioning

The current package version lives in `VERSION`.

Manual bumps:

```sh
./scripts/bump-version.sh patch
./scripts/bump-version.sh minor
./scripts/bump-version.sh major
```

Automatic bumps use conventional commit messages:

```sh
./scripts/bump-version.sh auto
```

You can enable the bundled pre-commit hook if you want local version bumps
before commits:

```sh
./scripts/setup-hooks.sh
```

Release notes are generated from commit subjects:

```sh
node scripts/generate-release-notes.mjs
```

This writes:

- `dist/release-notes.md`
- `dist/steam-change-notes.txt`

## 🚀 GitHub Actions

This addon is intentionally kept in a clean addon root so a future workflow can
package the repository root and deploy the resulting `.gma` to Steam Workshop.

Workflows:

- `CI`: runs on pull requests and pushes to `main`.
- `Lint`: runs GLua lint on pull requests and pushes to `main`.
- `Release`: builds a ZIP package, generates release notes, uploads artifacts on pull requests, and publishes/updates a GitHub Release on pushes to `main` when addon files change.
- `Deploy to Steam Workshop`: builds a GMA and deploys to Steam Workshop on pushes to `main` when addon files change, or manual dispatch.

Version-only commits do not trigger release or Steam Workshop deployment by
themselves. The workflows still read `VERSION` when packaging a real addon
change.

Required deploy repository variable or secret:

- `STEAM_USERNAME`: repository variable or secret for the Steam account username.
- `STEAM_WORKSHOP_ITEM_ID`: repository variable for the existing Workshop item ID.
- `STEAM_WORKSHOP_ID`: optional secret fallback for the existing Workshop item ID.

Required deploy secrets:

- `STEAM_CONFIG_VDF_BASE64`: base64-encoded SteamCMD `config.vdf`.
- `STEAM_LOGINUSERS_VDF_BASE64`: base64-encoded SteamCMD `loginusers.vdf`.

Generate both files from a successful local SteamCMD login, then base64 encode
them as one-line values:

```sh
steamcmd +login YOUR_STEAM_USERNAME +quit
openssl base64 -A -in "/path/to/steamcmd/config/config.vdf"
openssl base64 -A -in "/path/to/steamcmd/config/loginusers.vdf"
```

The deploy workflow validates those files, installs Garry's Mod tools through
SteamCMD, builds the `.gma`, generates Steam change notes, and uploads with
`workshop_build_item`.

The deploy workflow has a preflight job that checks required deploy variables
and secrets before checkout, SteamCMD installation, packaging, or upload. If
anything is missing, the Steam deploy job is skipped instead of failing the
workflow.

## ✅ Compatibility

Primary target: Classic TTT.

The code is namespaced under `TTTKarmaMarket` and split into shared, server, and
client modules so TTT2 support can be added later without changing TTT core
files.
