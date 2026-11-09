# Third-party notices

## Bundled third-party code or libraries

None. ProfessionWheel uses no external libraries and does not require any other addon.

## Blizzard Entertainment material (not covered by the MIT License)

- **Textures:** the game's profession icons (only when chosen in options) and
  `Interface\CharacterFrame\TempPortraitAlphaMask` are read from the installed
  game client at runtime. The release package contains none of them.
- **Game data:** profession names, icons and spell names are read from the
  running client. `Professions.lua` lists vanilla-era skill line and spell ID
  numbers so it can find each profession's spells. Those are identifiers only and
  contain no Blizzard code or text.

## Original artwork (Media/, art/)

The wheel textures (`Media/Wheel/`), profession icons (`Media/Icons/`) and the
listing images (`art/curseforge/`) are original artwork created for
ProfessionWheel on 2026-11-09 with OpenAI's image generation tool through Codex
CLI, from the briefs in `art/briefs/` (prompts and run logs alongside). Claude
(Anthropic) directed and reviewed them for Ryan Novak. No Blizzard or third-party
artwork was supplied as input. They are licensed MIT with the code.

World of Warcraft and Blizzard Entertainment are trademarks or registered
trademarks of Blizzard Entertainment, Inc. ProfessionWheel is an unofficial
community project that Blizzard has not endorsed.
