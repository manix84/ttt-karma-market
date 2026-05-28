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

## 🚀 GitHub Actions

This addon is intentionally kept in a clean addon root so a future workflow can
package the repository root and deploy the resulting `.gma` to Steam Workshop.

## ✅ Compatibility

Primary target: Classic TTT.

The code is namespaced under `TTTKarmaMarket` and split into shared, server, and
client modules so TTT2 support can be added later without changing TTT core
files.
