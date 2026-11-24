# Changelog

All notable changes to ForeverGMManager are documented here.

## v1.0.0 (2026-11-24)

### Commands & Presets
- 26 additional GM commands added, filling out the in-game command list. [#3](https://github.com/TortoiseBots/ForeverGMManager/pull/3)
- Full command reference generated from addon data: 183 commands grouped by tab, with access level and danger marks, and a server check that fails if it goes stale. [#1](https://github.com/TortoiseBots/ForeverGMManager/pull/1)
- Command table regenerated from source; the talent-points help text now reads correctly. [#6](https://github.com/TortoiseBots/ForeverGMManager/pull/6)

### Teleports
- 114 teleport points available in the teleport tab. [#3](https://github.com/TortoiseBots/ForeverGMManager/pull/3)

### Lookups & Search
- Shift+click item links straight out of lookup results to paste into chat or mail. [#3](https://github.com/TortoiseBots/ForeverGMManager/pull/3)

### Mail
- Mail composer for sending items to players directly from the UI. [#3](https://github.com/TortoiseBots/ForeverGMManager/pull/3)
- Target button only fills the recipient with plain names, so a secret creature name can never land in a field that gets checked and sent later. [#7](https://github.com/TortoiseBots/ForeverGMManager/pull/7)

### UI & Controls
- New addon icon and recolored palette; icons no longer render underneath their frames on the new client. [#1](https://github.com/TortoiseBots/ForeverGMManager/pull/1)
- ON/OFF buttons now clearly show which state is active. [#1](https://github.com/TortoiseBots/ForeverGMManager/pull/1)
- Minimap button can be hidden. [#3](https://github.com/TortoiseBots/ForeverGMManager/pull/3)
- Fixed the Lua error when right-clicking a creature: the target pill still displays a secret name but only compares or measures it when it is a plain string. [#7](https://github.com/TortoiseBots/ForeverGMManager/pull/7)

### Docs & Screenshots
- README gets a Screenshots section with five previews (command search, favourites, item lookup, mail composer, dangerous command awaiting its second EXECUTE), redrawable via `tools/preview` after UI changes. [#4](https://github.com/TortoiseBots/ForeverGMManager/pull/4)
- README now states the project is an unofficial community project made for educational purposes. [#5](https://github.com/TortoiseBots/ForeverGMManager/pull/5)
- Docs retargeted to WoW Forever on ForeverCore; stale client version and build numbers dropped. [#6](https://github.com/TortoiseBots/ForeverGMManager/pull/6)

### Release Tooling
- Manual Release action: runs tests, bumps the `.toc` version (patch/minor/major/custom), tags, packs a ready-to-install zip and publishes a GitHub release listing merged PRs. [#8](https://github.com/TortoiseBots/ForeverGMManager/pull/8)
- Release notes and `CHANGELOG.md` now written by AI from merged PRs; without an API key the release still works using GitHub's plain PR list. [#9](https://github.com/TortoiseBots/ForeverGMManager/pull/9)
- AI changelog endpoint and model configurable via repo variables (`OPENCODE_ENDPOINT`, `OPENCODE_MODEL`) with secret fallback, plus optional `OPENCODE_REASONING_EFFORT` to control how hard the model thinks. [#10](https://github.com/TortoiseBots/ForeverGMManager/pull/10)
