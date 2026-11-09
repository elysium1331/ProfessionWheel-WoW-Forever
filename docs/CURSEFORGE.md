# CurseForge listing: [Elysium] ProfessionWheel

Everything below is ready to paste. Nothing has been submitted.

## Project name

```
[Elysium] ProfessionWheel
```

Suggested slug: `elysium-professionwheel`. Category: **Professions** (secondary: *Action Bars*
or *Miscellaneous*, if a second is allowed). License: **MIT**. Game flavor: **Forever**, game
version **1.60.1** only.

## Summary (≤ 256 characters)

```
One key opens a radial wheel of your current professions. Point and click to open Tailoring, Smelting, Cooking, First Aid and more, cast Fishing, or toggle Find Herbs / Find Minerals. No action-bar slots needed.
```

(211 characters.)

## Description (CurseForge accepts Markdown)

```markdown
# [Elysium] ProfessionWheel

**Stop giving up action-bar slots to your professions.** Press one key and a wheel of your current professions opens right at your cursor. Point at one, click, done.

ProfessionWheel is part of the **Elysium** addon collection for **WoW Forever**.

## How it works

1. Bind a key under **Options > Keybindings > AddOns > Open ProfessionWheel**.
2. Press it. The wheel opens at your cursor with every profession your character knows: your two primaries, then Cooking, Fishing and First Aid.
3. Point toward one and click. You don't have to hit the icon itself; anywhere in its direction works.

| Profession | Left-click | Right-click |
|---|---|---|
| Alchemy, Blacksmithing, Engineering, Leatherworking, Tailoring, Cooking, First Aid | Opens its window | - |
| Enchanting | Opens its window | Disenchant |
| Mining | Smelting | Toggles Find Minerals |
| Herbalism | Toggles Find Herbs | - |
| Fishing | Casts Fishing | - |
| Skinning | Hidden (nothing to open); can be shown in options | - |

Under the wheel you see the highlighted profession, your skill level, and what each click will do. A green ring means that profession's tracking is on.

## Features

- **Zero setup.** The wheel always shows what your character knows right now. Learn or drop a profession and the wheel follows.
- **Painted look:** a gold-rimmed wheel with its own hand-painted icon for every profession (or switch to the game's icons in options).
- **Opens at the cursor** (or screen center, if you prefer).
- **Click anywhere in a slot's direction**, not just on the icon.
- Escape, pressing the key again, or clicking the center closes it without doing anything.
- Options for wheel size, icon scale and names. Settings are saved per character.
- `/pwheel` opens options; `/pwheel status` lists what the addon detected for each profession.
- No dependencies, no libraries, no network access, no telemetry.

## Good to know

- **Out of combat only**, just like professions themselves. The wheel closes the moment combat starts.
- Every action comes from your own click. ProfessionWheel never automates anything.
- Tested in game on WoW Forever 1.60.1 with Tailoring, Enchanting, Cooking, Fishing and First Aid. Mining, Herbalism and Skinning haven't been tested in game yet. If something looks off, please open an issue and include the output of `/pwheel status`.

## Feedback and source

Bug reports and source code: [GitHub](https://github.com/elysium1331/ProfessionWheel-WoW-Forever)

*Artwork (wheel, profession icons and logo): original, made with AI image generation (OpenAI, via Codex) and reviewed by hand, MIT-licensed like the code. ProfessionWheel is an unofficial community addon, not affiliated with or endorsed by Blizzard Entertainment.*
```

## Images

| File | Use |
|---|---|
| `art/curseforge/logo.png` | Project logo / avatar (1024 × 1024). Rendered from the addon's own wheel textures and icons by `scripts/render_listing_art.py`, so it matches the game. |
| `art/curseforge/banner.png` | Gallery image or page header (1920 × 1080): the same wheel over a workshop scene. |
| (to capture) | Gallery screenshots of the 0.2.0 wheel in game: one with a slot highlighted, one with the options window. |

## Upload

- File: `dist/Elysium_ProfessionWheel-0.2.0.zip` (same as the GitHub release; SHA-256 `4f9e29ed61d47271b740c723aa86abebd7390edf3b853302bc2d98342143a6ed`).
- Release type: **Release**. Game version: Forever 1.60.1 only.
- Changelog: paste the `## [0.2.0]` section of `CHANGELOG.md`.
- After approval: add the CurseForge URL to `README.md` and `## X-Curse-Project-ID:` to the TOC.
