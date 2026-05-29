# Tests

The current project checks are lightweight repository validation scripts rather
than in-game integration tests.

Run all checks with:

```sh
bash scripts/check_all.sh
```

Coverage today:

- addon metadata and required file layout
- Workshop package surface validation
- Lua syntax parsing
- simple GLua policy checks
- icon dimension checks
- dry-run packaging behavior
- release-note generation

Run GLua lint separately with:

```sh
./scripts/glualint.sh
```

Future in-game tests should live here when a repeatable Garry's Mod test harness
is available.

For manual local game testing, see the Local Testing section in the root
`README.md`.
