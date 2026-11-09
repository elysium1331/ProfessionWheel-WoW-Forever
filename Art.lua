-- Paths of the addon's own textures (built by scripts/build_wheel_art.py).
-- Every path is written out literally so scripts/package.py can check that the
-- file exists and ship it.
local _, ns = ...

local Art = {}
ns.Art = Art

Art.DISC = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Wheel\\disc.tga"
Art.SLOT = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Wheel\\slot.tga"
Art.SLOT_GLOW = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Wheel\\slot_glow.tga"
Art.HUB = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Wheel\\hub.tga"
Art.HUB_GLOW = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Wheel\\hub_glow.tga"
Art.SPOKE = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Wheel\\spoke.tga"
Art.STAR = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Wheel\\star.tga"

Art.GENERIC_ICON = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\generic.tga"

-- Painted icon per vanilla-era skill line ID (see Professions.SKILL).
Art.ICONS = {
	[171] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\alchemy.tga",
	[164] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\blacksmithing.tga",
	[333] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\enchanting.tga",
	[202] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\engineering.tga",
	[182] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\herbalism.tga",
	[165] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\leatherworking.tga",
	[186] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\mining.tga",
	[393] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\skinning.tga",
	[197] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\tailoring.tga",
	[185] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\cooking.tga",
	[129] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\firstaid.tga",
	[356] = "Interface\\AddOns\\Elysium_ProfessionWheel\\Media\\Icons\\fishing.tga",
}

-- Icon for a profession entry. Returns path, isPainted.
--   gameIcons: the player chose the game's own profession icons in options.
-- Unknown skill lines use the game's icon, then the painted generic one.
function Art.IconFor(entry, gameIcons)
	if not gameIcons and entry.skillLine and Art.ICONS[entry.skillLine] then
		return Art.ICONS[entry.skillLine], true
	end
	if entry.icon then
		return entry.icon, false
	end
	return Art.GENERIC_ICON, true
end
