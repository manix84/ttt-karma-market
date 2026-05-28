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

If the script cannot find Garry's Mod tools automatically, set paths explicitly:

```sh
GMOD_BIN="/path/to/GarrysMod/bin" bash scripts/create_workshop_item.sh
```

or:

```sh
GMAD_BIN="/path/to/gmad" GMPUBLISH_BIN="/path/to/gmpublish" bash scripts/create_workshop_item.sh
```

After the upload succeeds, open the new Workshop item and copy the number from
the URL:

```text
https://steamcommunity.com/sharedfiles/filedetails/?id=1234567890
```

Use that number as the `STEAM_WORKSHOP_ID` GitHub Actions secret. Future pushes
to `main` can then update the existing item instead of creating a new one.

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

## 🚀 GitHub Actions

This addon is intentionally kept in a clean addon root so a future workflow can
package the repository root and deploy the resulting `.gma` to Steam Workshop.

Workflows:

- `CI`: runs on pull requests and pushes to `main`.
- `Build and Deploy to Steam Workshop`: runs on pushes to `main` and manual dispatch.

Required deploy secrets:

- `STEAM_USERNAME`: Steam account username for publishing.
- `STEAM_VDF`: base64-encoded Steam `config.vdf`, recommended for Steam Guard auth.
- `STEAM_WORKSHOP_ID`: existing Workshop item ID to update, created by the first publish.

The deploy workflow uses `gmod-workshop/workshop-upload@v1`, which packages the
addon directory and uploads it to the Garry's Mod Workshop with `workshop/icon.jpg`.

## ✅ Compatibility

Primary target: Classic TTT.

The code is namespaced under `TTTKarmaMarket` and split into shared, server, and
client modules so TTT2 support can be added later without changing TTT core
files.
