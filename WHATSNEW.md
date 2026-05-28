# 📰 What's New

## 🚧 Unreleased

Initial production-ready addon structure for TTT Karma Market.

✨ Added:

- Workshop-ready root layout with `addon.json`, Lua modules, README, license, and icon path.
- Classic TTT round hooks using `TTTPrepareRound` and `TTTEndRound`.
- Server-side karma sampling with configurable interval and maximum candle count.
- Safe karma helper with fallbacks for `GetBaseKarma`, `GetLiveKarma`, and networked karma values.
- End-round OHLC candlestick data per player.
- Compact server-to-client end-round networking.
- End-round `Karma Market` tab injection when a compatible TTT property sheet is available.
- Standalone Derma popup fallback when tab injection is unavailable.
- Reusable custom VGUI candlestick chart renderer.
- Player list with sorting by alphabetical order, biggest gain, biggest loss, and most volatile.
- Summary header with starting karma, ending karma, net change, volatility, biggest gain, and biggest loss.
- Garry's Mod Utilities admin panel at `Utilities > TTT > Karma Market`.
- Replicated/server ConVars for enabling the addon, debug logging, sample interval, popup fallback, max candles, chart height, grid visibility, label visibility, auto-sort, and default sort.
- Admin actions to reset settings, clear round data, and print a debug summary.
- Debug status reporting for active tracked players, candle counts, timer state, last sample, and networking state.
- Local validation scripts for addon metadata, Workshop package surface, Lua syntax, image dimensions, and dry-run builds.
- GitHub Actions CI for pull requests and pushes to `main`.
- GitHub Actions Steam Workshop deploy workflow for pushes to `main` and manual dispatch.
- 512x512 Workshop icon at `workshop/icon.jpg`.
- Local install helper for symlink or copy-based Garry's Mod testing.
- First-publish helper and documentation for creating the initial Steam Workshop item ID.

🔄 Changed:

- Moved the addon contents to the repository root so the repository itself can be packaged with `gmad create -folder .`.
- Replaced the old `ttt_karma_tracker` skeleton with the `TTTKarmaMarket` namespaced addon implementation.

📝 Notes:

- The addon does not modify TTT core files.
- The addon avoids DHTML, external rendering libraries, remote assets, and unsupported Workshop file types.
- Current round data is stored in memory only and is not persisted to disk.
