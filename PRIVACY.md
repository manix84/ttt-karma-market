# 🔒 Privacy Policy

TTT Karma Market is a Garry's Mod addon for Trouble in Terrorist Town. It runs
inside Garry's Mod servers and clients and is designed to be self-contained.

## 📊 Current Data Use

During a TTT round, the addon records temporary karma data for players on the
server so it can show the end-round `Karma Market` chart.

The current version may process:

- Player display names
- SteamID or SteamID64 values
- Karma values sampled during the round
- Derived round statistics, such as net change, high, low, volatility, biggest gain, and biggest loss

This data is used only for the in-game chart and admin/debug views.

## 📡 Network Transmission

At the end of a round, the server sends the round's Karma Market data to
connected clients using Garry's Mod net messages.

This transmission stays inside the current game server session. The addon does
not send data to any external website, analytics service, API, database, or
remote server controlled by the addon author.

## 💾 Data Storage

The addon currently stores round data only in memory. It does not write player
karma history, SteamIDs, names, or chart data to disk.

Round data is cleared when a new round starts, when an admin uses the clear
action, or when the server shuts down.

## 🛡️ Admin Controls

Server settings are exposed through replicated ConVars and the Garry's Mod
Utilities menu. Non-admin players can read replicated settings where Garry's Mod
allows it, but server-side setting changes and admin actions are validated on
the server.

Debug mode may print player names, sample counts, timer state, and networking
status to the server console. Debug mode is disabled by default.

## 🌐 External Services

The addon currently uses no external services.

It does not use:

- Web analytics
- Remote asset loading
- DHTML pages
- External JavaScript libraries
- External APIs
- Persistent cloud storage

## 🔭 Future Direction

Future versions should continue to follow these principles:

- Keep gameplay data local to the server whenever practical.
- Avoid external services unless they are clearly documented and optional.
- Avoid persistent player history unless server owners explicitly enable it.
- Document any new data collection before release.
- Keep Steam Workshop builds self-contained and free of remote assets.

If a future version adds persistent storage, export features, web dashboards,
Workshop automation metadata, or TTT2-specific integrations that change data
handling, this file should be updated before that version is released.

## 👤 Server Owner Responsibility

Server owners are responsible for configuring their Garry's Mod server, logs,
addons, hosting provider, and any other tools that may separately collect or
store player information. This policy only describes TTT Karma Market itself.
