# Agent notes

## Repo relationship
This is a personal copy of `FFXIV-CombatReborn/GatherBuddyReborn` (itself a downstream of `Ottermandias/GatherBuddy`).

- `origin` may point at the user's personal fork **or** at `FFXIV-CombatReborn/GatherBuddyReborn` directly.
- If `origin` is the user's fork, an `upstream` remote pointing at `https://github.com/FFXIV-CombatReborn/GatherBuddyReborn.git` is the source of truth for new code.
- New code is pulled by fast-forward merge: `git fetch <remote> && git merge --ff-only <remote>/<branch>`.

## Submodules
`ElliCon` and `ElliLib` are git submodules under the repo root. They must be initialized after a fresh clone:

```
git submodule update --init --recursive
```

We track the commits **pinned by upstream** — do not pass `--remote`, which would advance them to the latest tip of each submodule's own main branch.

## Local publish
`publish-local.ps1` (PowerShell 7+) is the one-stop script for syncing + building locally. It:

1. Aborts early if `build\GatherBuddyReborn.dll` is locked (Dalamud has the plugin loaded — disable it in-game first).
2. Self-heals the `upstream` remote on a fresh clone if needed.
3. Fetches and fast-forward merges `<sync-remote>/<current-branch>` into `HEAD`.
4. Inits/updates submodules.
5. Restores, wipes `.\build`, and builds `GatherBuddy\GatherBuddy.csproj` in Release to `.\build\`.

The plugin DLL lands at `.\build\GatherBuddyReborn.dll` — the path Dalamud's dev plugins folder should point at.

When asked to "publish locally" / "rebuild" / "pick up the latest", run `publish-local.ps1`. Do **not** push tags or trigger the GitHub release workflow without explicit user confirmation.

## CI publish (do not trigger casually)
`.github/workflows/publish.yaml` runs on tag push matching `*.*.*.*`. It builds the plugin, additionally compiles `raphael-cli.exe` from `KonaeAkira/raphael-rs`, zips the result, and creates a GitHub release. `publish-local.ps1` does **not** replicate the `raphael-cli` step — local builds skip it.
