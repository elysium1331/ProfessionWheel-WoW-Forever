-- Client compatibility layer. Every call into a client API whose presence or
-- shape could differ between WoW client flavors goes through this file.
--
-- Verified against Blizzard UI source for WoW Forever 1.60.1.70862 (interface 16001):
--   GetProfessions() -> prof1, prof2, firstAid, fishing, cooking (Camelot ProfessionsBook).
--   GetProfessionInfo(index) -> name, texture, rank, maxRank, numSpells, spellOffset, skillLine, ...
--   C_SpellBook.GetSpellBookItemInfo(slot, Enum.SpellBookSpellBank.Player) -> { spellID, name, iconID, isPassive, ... }
--   C_SpellBook.IsSpellKnown(spellID, bank), C_Spell.GetSpellName / GetSpellTexture.
--   C_Minimap.GetNumTrackingTypes / GetTrackingInfo(i) -> { name, active, spellID, ... } / SetTracking(i, on).
--   Blizzard's own profession tabs open a profession by casting its spellbook spell
--   (C_SpellBook.CastSpellBookItem), which is protected; this addon casts through a
--   SecureActionButtonTemplate button instead (type "spell").
--   RegisterStateDriver(frame, "visibility", "[combat] hide") hides a secure frame in combat.
local _, ns = ...

local Compat = {}
ns.Compat = Compat

Compat.VERIFIED_INTERFACE = 16001
Compat.VERIFIED_BUILD = "1.60.1.70862"

function Compat.GetBuildInfo()
	if type(GetBuildInfo) ~= "function" then
		return nil, nil
	end
	local version, build, _, interface = GetBuildInfo()
	return (version or "?") .. "." .. (build or "?"), interface
end

function Compat.GetAddOnVersion(addonName)
	local getter = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	if getter then
		local ok, value = pcall(getter, addonName, "Version")
		if ok and type(value) == "string" then
			return value
		end
	end
	return "?"
end

-- Professions -------------------------------------------------------------------------

-- Profession indices in wheel order: two primaries, then Cooking, Fishing, First Aid
-- (the order of the Professions book on this client). Missing ones are nil.
function Compat.GetProfessionIndices()
	if type(GetProfessions) ~= "function" then
		return {}
	end
	local ok, prof1, prof2, firstAid, fishing, cooking = pcall(GetProfessions)
	if not ok then
		return {}
	end
	return { prof1, prof2, cooking, fishing, firstAid }
end

function Compat.GetProfessionInfo(index)
	if type(GetProfessionInfo) ~= "function" or not index then
		return nil
	end
	local ok, name, texture, rank, maxRank, numSpells, spellOffset, skillLine = pcall(GetProfessionInfo, index)
	if not ok or type(name) ~= "string" then
		return nil
	end
	return {
		name = name,
		icon = texture,
		rank = tonumber(rank) or 0,
		maxRank = tonumber(maxRank) or 0,
		numSpells = tonumber(numSpells) or 0,
		spellOffset = tonumber(spellOffset) or 0,
		skillLine = tonumber(skillLine),
	}
end

local function PlayerBank()
	return Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
end

-- One spellbook entry of the player's book: { spellID, name, icon, isPassive } or nil.
function Compat.GetSpellBookSpell(slot)
	if not (C_SpellBook and C_SpellBook.GetSpellBookItemInfo) then
		return nil
	end
	local ok, info = pcall(C_SpellBook.GetSpellBookItemInfo, slot, PlayerBank())
	if not ok or type(info) ~= "table" or not info.spellID then
		return nil
	end
	return { spellID = info.spellID, name = info.name, icon = info.iconID, isPassive = info.isPassive and true or false }
end

function Compat.IsSpellKnown(spellID)
	if C_SpellBook and C_SpellBook.IsSpellKnown then
		local ok, known = pcall(C_SpellBook.IsSpellKnown, spellID, PlayerBank())
		return ok and known == true
	end
	return false
end

function Compat.GetSpellName(spellID)
	if C_Spell and C_Spell.GetSpellName then
		local ok, name = pcall(C_Spell.GetSpellName, spellID)
		if ok and type(name) == "string" then
			return name
		end
	end
	return nil
end

function Compat.GetSpellTexture(spellID)
	if C_Spell and C_Spell.GetSpellTexture then
		local ok, tex = pcall(C_Spell.GetSpellTexture, spellID)
		if ok then
			return tex
		end
	end
	return nil
end

-- Minimap tracking --------------------------------------------------------------------

-- Finds the tracking entry for any of `spellIDs`. Returns index, active, name or nil.
function Compat.FindTracking(spellIDs)
	if not (C_Minimap and C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingInfo) then
		return nil
	end
	local ok, count = pcall(C_Minimap.GetNumTrackingTypes)
	if not ok or type(count) ~= "number" then
		return nil
	end
	local wanted = {}
	for _, id in ipairs(spellIDs) do
		wanted[id] = true
	end
	for i = 1, count do
		local okInfo, info = pcall(C_Minimap.GetTrackingInfo, i)
		if okInfo and type(info) == "table" and info.spellID and wanted[info.spellID] then
			return i, info.active and true or false, info.name
		end
	end
	return nil
end

-- Returns true when the call was made without a Lua error.
function Compat.SetTracking(index, on)
	if not (C_Minimap and C_Minimap.SetTracking) then
		return false
	end
	local ok = pcall(C_Minimap.SetTracking, index, on and true or false)
	return ok
end

-- Secure frames -----------------------------------------------------------------------

-- Hides a secure frame whenever the player enters combat (no secure snippet needed).
function Compat.HideInCombat(frame)
	if type(RegisterStateDriver) == "function" then
		RegisterStateDriver(frame, "visibility", "[combat] hide")
		return true
	end
	return false
end

-- General -----------------------------------------------------------------------------

function Compat.InCombat()
	return type(InCombatLockdown) == "function" and InCombatLockdown() or false
end

function Compat.HasKeyboardFocus()
	if type(GetCurrentKeyBoardFocus) ~= "function" then
		return false
	end
	return GetCurrentKeyBoardFocus() ~= nil
end

function Compat.IsMouselooking()
	return type(IsMouselooking) == "function" and IsMouselooking() or false
end

-- Cursor position in the coordinate space of `frame` (accounts for UI scale).
function Compat.GetCursorInFrameSpace(frame)
	local x, y = GetCursorPosition()
	local scale = frame:GetEffectiveScale()
	if not scale or scale == 0 then
		scale = 1
	end
	return x / scale, y / scale
end

function Compat.GetBindingText(action)
	if type(GetBindingKey) ~= "function" then
		return nil
	end
	local key = GetBindingKey(action)
	if not key then
		return nil
	end
	if type(GetBindingText) == "function" then
		return GetBindingText(key)
	end
	return key
end

-- Settings panel registration. Returns the category or nil.
function Compat.RegisterSettingsCanvas(frame, name)
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
		return nil
	end
	local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, frame, name)
	if not ok or not category then
		return nil
	end
	Settings.RegisterAddOnCategory(category)
	return category
end

-- Opens Options > Keybindings scrolled to the AddOns section.
function Compat.OpenKeybindings()
	if Compat.InCombat() then
		return false
	end
	if Settings and Settings.OpenToCategory and Settings.KEYBINDINGS_CATEGORY_ID then
		local ok = pcall(Settings.OpenToCategory, Settings.KEYBINDINGS_CATEGORY_ID, ADDONS)
		return ok
	end
	return false
end

-- Confirmation dialog. Falls back to a private StaticPopup definition.
function Compat.Confirm(text, onAccept)
	if type(StaticPopup_ShowGenericConfirmation) == "function" then
		StaticPopup_ShowGenericConfirmation(text, onAccept)
		return
	end
	if type(StaticPopup_Show) == "function" and StaticPopupDialogs then
		StaticPopupDialogs.PROFESSIONWHEEL_CONFIRM = {
			text = text,
			button1 = YES or "Yes",
			button2 = NO or "No",
			OnAccept = onAccept,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show("PROFESSIONWHEEL_CONFIRM")
	end
end

-- Lets Escape close a named frame through the standard UI mechanism.
function Compat.RegisterEscapeClose(frameName)
	if type(UISpecialFrames) == "table" and type(frameName) == "string" then
		for _, name in ipairs(UISpecialFrames) do
			if name == frameName then
				return
			end
		end
		table.insert(UISpecialFrames, frameName)
	end
end

-- The circular alpha mask used for round slots (referenced by Blizzard UI in this build).
Compat.CIRCLE_MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
Compat.QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"
