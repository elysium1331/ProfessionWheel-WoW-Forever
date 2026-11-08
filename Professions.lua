-- Builds the wheel's contents from the character's current professions and
-- decides what each slot does. Uses only ns.Compat (stubbed in unit tests).
--
-- Each entry: { skillLine, name, icon, rank, maxRank, primary, secondary }
-- An action is { kind = "spell", spellID, name } or
--               { kind = "tracking", spellIDs, spellID (may be nil), name }.
local _, ns = ...

local Compat = ns.Compat

local Professions = {}
ns.Professions = Professions

-- Vanilla-era skill line IDs.
local SKILL = {
	ALCHEMY = 171, BLACKSMITHING = 164, ENCHANTING = 333, ENGINEERING = 202,
	HERBALISM = 182, LEATHERWORKING = 165, MINING = 186, SKINNING = 393,
	TAILORING = 197, COOKING = 185, FIRST_AID = 129, FISHING = 356,
}
Professions.SKILL = SKILL

-- Known spells per skill line, used before the spellbook section is consulted:
--   primary   rank spells, lowest first (the highest known one is used)
--   secondary right-click spell
--   tracking  minimap tracking spells (Find Minerals / Find Herbs, ranks 1-2)
local DEFS = {
	[SKILL.ALCHEMY] = { primary = { 2259, 3101, 3464, 11611 } },
	[SKILL.BLACKSMITHING] = { primary = { 2018, 3100, 3538, 9785 } },
	[SKILL.ENCHANTING] = { primary = { 7411, 7412, 7413, 13920 }, secondary = { 13262 } },
	[SKILL.ENGINEERING] = { primary = { 4036, 4037, 4038, 12656 } },
	[SKILL.LEATHERWORKING] = { primary = { 2108, 3104, 3811, 10662 } },
	[SKILL.TAILORING] = { primary = { 3908, 3909, 3910, 12180 } },
	[SKILL.COOKING] = { primary = { 2550, 3102, 3413, 18260 } },
	[SKILL.FIRST_AID] = { primary = { 3273, 3274, 7924, 10846 } },
	[SKILL.FISHING] = { primary = { 7620, 7731, 7732, 18248 } },
	[SKILL.MINING] = { primary = { 2656 }, tracking = { 2580, 8388 } }, -- Smelting
	[SKILL.HERBALISM] = { tracking = { 2383, 8387 } },
	[SKILL.SKINNING] = {},
}
Professions.DEFS = DEFS

local function Contains(list, value)
	if list then
		for _, v in ipairs(list) do
			if v == value then
				return true
			end
		end
	end
	return false
end

-- Highest known spell from a lowest-first rank list.
local function HighestKnown(list)
	if not list then
		return nil
	end
	for i = #list, 1, -1 do
		if Compat.IsSpellKnown(list[i]) then
			return list[i]
		end
	end
	return nil
end

-- Active (non-passive) spells in a profession's spellbook section.
local function SectionSpells(info)
	local spells = {}
	for i = 1, math.min(info.numSpells, 8) do
		local spell = Compat.GetSpellBookSpell(info.spellOffset + i)
		if spell and not spell.isPassive then
			spells[#spells + 1] = spell
		end
	end
	return spells
end

local function SpellAction(spellID, fallbackName)
	return { kind = "spell", spellID = spellID, name = Compat.GetSpellName(spellID) or fallbackName or ("#" .. spellID) }
end

local function TrackingAction(ids, section)
	local known
	for _, id in ipairs(ids) do
		if Compat.IsSpellKnown(id) then
			known = id
		end
	end
	local sectionName
	for _, spell in ipairs(section) do
		if Contains(ids, spell.spellID) then
			known = known or spell.spellID
			sectionName = spell.name
		end
	end
	local index, _, trackingName = Compat.FindTracking(ids)
	if not known and not index then
		return nil
	end
	local name = trackingName or sectionName or (known and Compat.GetSpellName(known)) or "?"
	return { kind = "tracking", spellIDs = ids, spellID = known, name = name }
end

-- Decides the actions for one profession.
function Professions.ResolveActions(info)
	local def = (info.skillLine and DEFS[info.skillLine]) or {}
	local section = SectionSpells(info)
	local tracking = def.tracking and TrackingAction(def.tracking, section) or nil

	local candidates = {} -- non-tracking section spells
	for _, spell in ipairs(section) do
		if not Contains(def.tracking, spell.spellID) then
			candidates[#candidates + 1] = spell
		end
	end

	local primary
	local primaryID = HighestKnown(def.primary)
	if primaryID then
		primary = SpellAction(primaryID)
	else
		for _, spell in ipairs(candidates) do
			if not Contains(def.secondary, spell.spellID) then
				primary = SpellAction(spell.spellID, spell.name)
				break
			end
		end
	end

	local secondary
	if primary then
		if tracking then
			secondary = tracking
		else
			local secondaryID = HighestKnown(def.secondary)
			if secondaryID then
				secondary = SpellAction(secondaryID)
			else
				for _, spell in ipairs(candidates) do
					if spell.spellID ~= primary.spellID and not Contains(def.primary, spell.spellID) then
						secondary = SpellAction(spell.spellID, spell.name)
						break
					end
				end
			end
		end
	else
		primary = tracking
	end
	return primary, secondary
end

-- Returns visible, all where `all` lists every profession found (for /pwheel status)
-- and `visible` is what the wheel shows. Entries without an action are left out
-- of `visible` unless showInactive is set.
function Professions.Build(showInactive)
	local all, visible = {}, {}
	local indices = Compat.GetProfessionIndices()
	-- The list has holes (e.g. no second primary), so ipairs would stop early.
	for position = 1, 5 do
		local index = indices[position]
		local info = index and Compat.GetProfessionInfo(index)
		if info then
			local primary, secondary = Professions.ResolveActions(info)
			local entry = {
				skillLine = info.skillLine,
				name = info.name,
				icon = info.icon,
				rank = info.rank,
				maxRank = info.maxRank,
				primary = primary,
				secondary = secondary,
			}
			entry.hidden = not primary and not showInactive
			all[#all + 1] = entry
			if not entry.hidden and #visible < ns.WheelMath.MAX_SLOTS then
				visible[#visible + 1] = entry
			end
		end
	end
	return visible, all
end

-- How to perform a tracking action right now, plus whether tracking is on.
--   { mode = "untrack", index }  turn tracking off through the minimap API
--   { mode = "cast", spellID }   cast the tracking spell (secure button)
--   { mode = "track", index }    turn tracking on through the minimap API
function Professions.ResolveTracking(action)
	local index, active = Compat.FindTracking(action.spellIDs)
	if index and active then
		return { mode = "untrack", index = index }, true
	end
	if action.spellID then
		return { mode = "cast", spellID = action.spellID }, false
	end
	if index then
		return { mode = "track", index = index }, false
	end
	return nil, false
end

function Professions.IsTrackingActive(action)
	if not action or action.kind ~= "tracking" then
		return false
	end
	local index, active = Compat.FindTracking(action.spellIDs)
	return index ~= nil and active == true
end
