# Changelog

All notable user-facing changes. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/). The saved-settings schema
version is tracked separately (currently schema 1).

## [0.1.0] - 2026-11-08

First release. Tested in game on WoW Forever 1.60.1.70862 (see docs/VALIDATION.md;
Mining, Herbalism and Skinning were not available to test).

### Added
- A wheel of your current professions (up to 5: two primaries, then Cooking,
  Fishing, First Aid), opened at the cursor with one key binding.
- Left-click opens a crafting profession's window or casts Fishing.
- Mining: left-click Smelting, right-click toggles Find Minerals.
- Herbalism: left-click toggles Find Herbs. A green ring means tracking is on.
- Enchanting: right-click Disenchant.
- Professions with nothing to use (Skinning) are hidden unless you turn them on.
- Out of combat only; the wheel closes when combat starts.
- Options: wheel size, icon scale, names, cursor or screen-center position.
- `/pwheel status` lists what the addon detected for each profession.
