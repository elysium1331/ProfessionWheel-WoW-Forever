# Validation report: [Elysium] ProfessionWheel 0.1.0

Target client: **WoW Forever 1.60.1.70862, interface 16001**.

**Status: tested in game on 2026-11-08.** Ryan ran it on WoW Forever
1.60.1.70862 (Night Elf priest with Tailoring, Enchanting, Cooking, Fishing and
First Aid) and reported that everything works as intended. Mining, Herbalism and
Skinning could not be tested on that character; they remain covered only by unit
tests and the smoke run.

## 1. Verified from Blizzard UI source (build 1.60.1.70862)

Source: the `forever` branch of the Gethe/wow-ui-source mirror, commit `9dc84f0`
("1.60.1 (70862)"). Used only as reference; not redistributed.

| Topic | Finding | Where it is used |
|---|---|---|
| Profession list | `GetProfessions()` returns prof1, prof2, firstAid, fishing, cooking (Camelot `Blizzard_ProfessionsBook.lua`). `GetProfessionInfo(i)` returns name, texture, rank, maxRank, numSpells, spellOffset, skillLine. | `Compat.GetProfessionIndices`, `Compat.GetProfessionInfo` |
| Profession spells | Blizzard's profession tabs read `C_SpellBook.GetSpellBookItemInfo(spellOffset + n, Enum.SpellBookSpellBank.Player)` and open a profession with `C_SpellBook.CastSpellBookItem` (protected). | `Professions.ResolveActions` |
| Secure casting | `SECURE_ACTIONS.spell` casts `CastSpellByID` for a numeric `spell` attribute. Addon buttons never get the "secure mouse press" flag, so `useOnKeyDown` (else the `ActionButtonUseKeyDown` CVar) decides down vs up; the addon sets `useOnKeyDown = false`. | `Wheel.lua` catcher |
| Combat hide | `RegisterStateDriver(frame, "visibility", "[combat] hide")` hides on combat and ignores other states (`SecureStateDriver.lua`). The restricted environment loads for `camelot`. | `Compat.HideInCombat` |
| Tracking | `C_Minimap.GetNumTrackingTypes`, `GetTrackingInfo(i)` -> `{ name, active, spellID, ... }`, `SetTracking(i, on)`. Blizzard's minimap maps Find Minerals 2580/8388 and Find Herbs 2383/8387. | `Compat.FindTracking`, `Compat.SetTracking` |
| Spell checks | `C_SpellBook.IsSpellKnown(spellID, bank)`, `C_Spell.GetSpellName`. `IsPlayerSpell` is only a deprecation shim. | `Compat` |
| Events | PLAYER_REGEN_DISABLED / ENABLED, PLAYER_LEAVING_WORLD, LOADING_SCREEN_ENABLED, ADDON_ACTION_BLOCKED / FORBIDDEN, UPDATE_BINDINGS. | `Core.lua` |

**Assumptions not verified in game:**
- The vanilla spell IDs in `Professions.DEFS` match this client. If one doesn't, the addon falls back to the profession's spellbook section, and `/pwheel status` shows what it picked.
- Insecure addon code may call `C_Minimap.SetTracking` to turn tracking **off** (and on, when no tracking spell is known). If the client blocks it, a chat line says to use the minimap menu.
- `Interface\Icons\Trade_Engineering` (the AddOns-list icon) exists in this client.

## 2. Automated checks

| Check | Command | Result |
|---|---|---|
| Lua 5.1 syntax + no stray globals, all 8 TOC Lua files | `python scripts/check.py` | Pass |
| Unit tests: WheelMath for 1-5 slots, Database, Professions (crafting, Mining, Herbalism, Skinning, Enchanting, fallbacks, order with gaps, tracking plans) | `python scripts/check.py` | 24/24 pass |
| Source + zip validation | `python scripts/package.py` | see below |

A dev-only stub smoke run (kept in the author's scratch space, not part of this
repository) loaded every file in TOC order and drove open, highlight, left/right
click, tracking off, the dead zone, closing on combat, refusing to open in combat,
`/pwheel status`, and the options window. It catches nil calls and typos only. **It
is not evidence of in-game behavior.**

## 3. In-game checklist

Run on 1.60.1.70862. [x] = passed per Ryan's report (2026-11-08): the wheel showed
Tailoring, Enchanting, Cooking, Fishing, First Aid in order with correct skill
levels (screenshot), every slot did its job, Enchanting's right-click was
Disenchant, closing and combat behaved, and no blocked-action popup or Lua error
appeared.

1. [x] The addon appears in the AddOns list under Elysium and loads with no Lua errors after `/reload`.
2. [x] "Open ProfessionWheel" appears under Options > Keybindings > AddOns, with no key assigned by default.
3. [x] Pressing the key opens the wheel at the cursor with your current professions (icons and names), in the order: primaries, Cooking, Fishing, First Aid.
4. [x] `/pwheel status` lists every profession you have and what left/right-click do. Paste it if anything looks wrong.
5. [x] Each crafting profession (and Cooking, First Aid) opens its window with one left-click.
6. [ ] (not testable: no such profession on the test character) Mining: left-click opens Smelting. Right-click turns Find Minerals on, and right-click again turns it off. The ring turns green while it's on.
7. [ ] (not testable: no such profession on the test character) Herbalism: left-click turns Find Herbs on and off (if you have it).
8. [x] Fishing: left-click casts a line near water.
9. [ ] (not testable: no such profession on the test character) Skinning is not on the wheel; turning on "Show professions with nothing to use" adds it greyed out, and clicking it just closes the wheel.
10. [x] Closing does nothing: Escape, the key again, left- or right-click in the center, Alt+Z, a loading screen.
11. [x] Pressing the key in combat prints "professions can't be used in combat" once. Entering combat with the wheel open closes it, and clicks work normally afterwards (no invisible screen-blocker).
12. [x] Typing in chat while the wheel is open closes it. Movement keys work while it's open.
13. [x] Options: size, icon scale, names, cursor / screen center work and persist across `/reload`.
14. [x] No "addon blocked" popup appears during any of the above.

## 4. Version 0.2.0 (painted look): in-game checklist

Ryan installed 0.2.0 on 2026-11-09 and reported that the new wheel looks good. [x]
marks what that covers; the other items were not reported separately. The click,
close and combat code is unchanged from 0.1.0.

Automated: `scripts/check.py` 27/27 tests pass; stub smoke run passes; `scripts/package.py` passes.

1. [x] The wheel shows the painted disc, gold rim, slot rings, spokes, stars and hub; no green/black squares (a missing texture).
2. [x] Each profession shows its painted icon, centered inside its ring, no pink fringe.
3. [x] Hovering a slot makes it glow; the name, skill and clicks show under the wheel and stay readable over bright scenery.
4. [x] Spokes point from the hub to each slot (no crooked or clipped spokes).
5. [ ] Options: "Use the game's profession icons" switches to the round game icons and back; size and icon scale still look right.
6. [ ] Everything from 0.1.0 still works (clicks, closing, combat).
