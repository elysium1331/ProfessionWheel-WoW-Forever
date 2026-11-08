# [Elysium] ProfessionWheel

Part of the **Elysium** addon collection for WoW Forever by
[elysium1331](https://github.com/elysium1331).

Open any of your professions from one radial wheel and one key, instead of
keeping every profession on your action bars.

**Release:** 0.1.0, tested in game on WoW Forever 1.60.1 (see
[docs/VALIDATION.md](docs/VALIDATION.md)).

ProfessionWheel is an unofficial community addon. Blizzard Entertainment did not
make or endorse it.

## Supported client

| Client | Version / build | Interface | Status |
|---|---|---|---|
| World of Warcraft: Forever | 1.60.1.70862 | 16001 | Built against this build's Blizzard UI source and tested in game. |

## How it works

1. Bind a key: Options > Keybindings > AddOns > **Open ProfessionWheel**.
2. Press the key. The wheel opens at the cursor with your current professions.
3. Point toward a profession and click.

| Profession | Left-click | Right-click |
|---|---|---|
| Alchemy, Blacksmithing, Engineering, Leatherworking, Tailoring, Cooking, First Aid | Opens its window | - |
| Enchanting | Opens its window | Disenchant |
| Mining | Smelting | Toggles Find Minerals |
| Herbalism | Toggles Find Herbs | - |
| Fishing | Casts Fishing | - |
| Skinning | Hidden (nothing to open); can be shown in options | - |

- The wheel always reflects what the character knows right now; there is nothing to set up.
- A green ring means that profession's tracking is on.
- Close without doing anything: right-click the center, left-click the center,
  Escape, or press the key again.
- **Out of combat only.** Professions can't be used in combat, and the wheel
  closes the moment combat starts.

## Commands

- `/pwheel` (or `/professionwheel`): options
- `/pwheel open`: toggle the wheel
- `/pwheel status`: list each detected profession and what its clicks do
- `/pwheel version`: addon and client version

## Options

Wheel size, icon scale, names on or off, open at the cursor or screen center, and
whether professions with nothing to use (Skinning) appear. Settings are saved per
character.

## Install

Copy the `Elysium_ProfessionWheel` folder from the release zip into
`World of Warcraft\_forever_\Interface\AddOns\`, then `/reload` or restart the game.

For development: `python scripts/check.py` (needs `pip install lupa`),
`python scripts/package.py`, and `Install-ProfessionWheel.cmd` to install the
built zip into your local WoW Forever folder.

## How it casts (technical)

Casting a spell is a protected action. ProfessionWheel shows one full-screen
`SecureActionButtonTemplate` button while the wheel is open and, as you move the
mouse, points that button's left- and right-click spell at the highlighted
profession. Your click then casts through Blizzard's secure button code, the same
way an action bar button does. This setup is only possible out of combat, which
is why the wheel is out-of-combat only. No secure snippets are used.

## License

MIT for the code. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
