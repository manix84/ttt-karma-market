# Contributing

Thanks for helping improve TTT Karma Market.

## Scope

Good contributions for this addon include:

- Bug fixes for karma tracking, chart rendering, networking, or TTT integration.
- Compatibility improvements for Garry's Mod, Classic TTT, or future TTT2 support.
- Admin panel and configuration improvements that keep server owners in control.
- Documentation updates that help installation, configuration, testing, or deployment.

Large feature changes are best discussed in an issue first so they fit the addon
and do not surprise server owners.

## Development

Run the local checks before opening a pull request:

```sh
bash scripts/check_all.sh
```

Run the GLua linter when changing Lua:

```sh
./scripts/glualint.sh
```

For changes that affect release packaging or Steam Workshop deployment, keep
generated addon payloads limited to:

- `addon.json`
- `lua/**`
- `materials/**`

## Versioning

Version bumps are stored in `VERSION`.

Use:

```sh
./scripts/bump-version.sh patch
./scripts/bump-version.sh minor
./scripts/bump-version.sh major
```

The helper also supports conventional-commit-based automatic bumps:

```sh
./scripts/bump-version.sh auto
```

## Pull Requests

Please include:

- A short summary of the change.
- How you tested it, including any local GMod/TTT checks.
- Any new or changed ConVars.

Documentation-only, version-only, script, and workflow-only changes do not need
to trigger Steam Workshop deployment.
