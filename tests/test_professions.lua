local H = ...
local test, eq, truthy = H.test, H.eq, H.truthy

-- A fake client: professions, spellbook sections, known spells, minimap tracking.
local world
local function NewWorld()
	world = { professions = {}, book = {}, known = {}, tracking = {}, names = {} }
	return world
end

-- prof = { slot = 1..5 (wheel order), name, skillLine, spells = { {id, name, passive} } }
local function AddProfession(slot, name, skillLine, spells, rank, maxRank)
	local offset = #world.book
	for _, s in ipairs(spells or {}) do
		world.book[#world.book + 1] = { spellID = s[1], name = s[2], isPassive = s[3] and true or false }
		world.names[s[1]] = s[2]
	end
	world.professions[slot] = { name = name, icon = 100 + slot, rank = rank or 1, maxRank = maxRank or 75,
		numSpells = #(spells or {}), spellOffset = offset, skillLine = skillLine }
end

local Compat = {
	GetProfessionIndices = function()
		local out = {}
		for i = 1, 5 do
			out[i] = world.professions[i] and i or nil
		end
		return out
	end,
	GetProfessionInfo = function(index) return world.professions[index] end,
	GetSpellBookSpell = function(slot) return world.book[slot] end,
	IsSpellKnown = function(id) return world.known[id] == true end,
	GetSpellName = function(id) return world.names[id] end,
	FindTracking = function(ids)
		for i, t in ipairs(world.tracking) do
			for _, id in ipairs(ids) do
				if t.spellID == id then
					return i, t.active, t.name
				end
			end
		end
		return nil
	end,
}

local ns = { Compat = Compat }
H.load("WheelMath.lua", ns)
H.load("Professions.lua", ns)
local P = ns.Professions

test("crafting profession: left-click opens it with the highest known rank", function()
	NewWorld()
	AddProfession(1, "Tailoring", 197, { { 3909, "Tailoring" } })
	world.known[3908], world.known[3909] = true, true
	local visible = P.Build(false)
	eq(#visible, 1)
	eq(visible[1].primary.kind, "spell")
	eq(visible[1].primary.spellID, 3909)
	eq(visible[1].secondary, nil)
end)

test("mining: left Smelting, right Find Minerals tracking", function()
	NewWorld()
	AddProfession(1, "Mining", 186, { { 2575, "Mining", true }, { 2656, "Smelting" }, { 2580, "Find Minerals" } })
	world.known[2656], world.known[2580] = true, true
	world.tracking = { { spellID = 2580, active = false, name = "Find Minerals" } }
	local e = P.Build(false)[1]
	eq(e.primary.spellID, 2656)
	eq(e.secondary.kind, "tracking")
	eq(e.secondary.spellID, 2580)
	eq(e.secondary.name, "Find Minerals")
end)

test("herbalism: left-click toggles Find Herbs; skinning is hidden", function()
	NewWorld()
	AddProfession(1, "Herbalism", 182, { { 2366, "Herb Gathering", true }, { 2383, "Find Herbs" } })
	AddProfession(2, "Skinning", 393, { { 8613, "Skinning", true } })
	world.known[2383] = true
	local visible, all = P.Build(false)
	eq(#all, 2)
	eq(#visible, 1)
	eq(visible[1].name, "Herbalism")
	eq(visible[1].primary.kind, "tracking")
	eq(visible[1].secondary, nil)
	eq(all[2].hidden, true)
	eq(all[2].primary, nil)
end)

test("showInactive keeps skinning on the wheel without an action", function()
	NewWorld()
	AddProfession(1, "Skinning", 393, { { 8613, "Skinning", true } })
	local visible = P.Build(true)
	eq(#visible, 1)
	eq(visible[1].primary, nil)
	eq(visible[1].hidden, false)
end)

test("enchanting: right-click is Disenchant", function()
	NewWorld()
	AddProfession(1, "Enchanting", 333, { { 7411, "Enchanting" }, { 13262, "Disenchant" } })
	world.known[7411], world.known[13262] = true, true
	local e = P.Build(false)[1]
	eq(e.primary.spellID, 7411)
	eq(e.secondary.spellID, 13262)
end)

test("unknown spell IDs fall back to the profession's spellbook section", function()
	NewWorld()
	AddProfession(1, "Alchemy", 171, { { 999001, "Alchemy" } })
	AddProfession(2, "Mystery", 4242, { { 999002, "Mystery Craft" }, { 999003, "Mystery Extra" } })
	local visible = P.Build(false)
	eq(visible[1].primary.spellID, 999001)
	eq(visible[1].primary.name, "Alchemy")
	eq(visible[2].primary.spellID, 999002)
	eq(visible[2].secondary.spellID, 999003)
end)

test("wheel order: two primaries, then cooking, fishing, first aid; gaps skipped", function()
	NewWorld()
	AddProfession(1, "Alchemy", 171, { { 2259, "Alchemy" } })
	AddProfession(3, "Cooking", 185, { { 2550, "Cooking" } })
	AddProfession(4, "Fishing", 356, { { 7620, "Fishing" } })
	AddProfession(5, "First Aid", 129, { { 3273, "First Aid" } })
	for _, id in ipairs({ 2259, 2550, 7620, 3273 }) do
		world.known[id] = true
	end
	local visible = P.Build(false)
	eq(#visible, 4)
	eq(visible[1].name, "Alchemy")
	eq(visible[2].name, "Cooking")
	eq(visible[3].name, "Fishing")
	eq(visible[3].primary.spellID, 7620)
	eq(visible[4].name, "First Aid")
end)

test("no professions gives an empty wheel", function()
	NewWorld()
	local visible, all = P.Build(false)
	eq(#visible, 0)
	eq(#all, 0)
end)

test("tracking plan: cast when off, minimap-untrack when on, minimap-track without a spell", function()
	NewWorld()
	world.tracking = { { spellID = 2383, active = false, name = "Find Herbs" } }
	local action = { kind = "tracking", spellIDs = { 2383, 8387 }, spellID = 2383, name = "Find Herbs" }
	local plan, on = P.ResolveTracking(action)
	eq(plan.mode, "cast")
	eq(plan.spellID, 2383)
	eq(on, false)
	world.tracking[1].active = true
	plan, on = P.ResolveTracking(action)
	eq(plan.mode, "untrack")
	eq(plan.index, 1)
	eq(on, true)
	truthy(P.IsTrackingActive(action), "reported active")
	world.tracking[1].active = false
	plan = P.ResolveTracking({ kind = "tracking", spellIDs = { 2383 }, name = "Find Herbs" })
	eq(plan.mode, "track")
end)

test("tracking with no spell and no minimap entry gives no action", function()
	NewWorld()
	AddProfession(1, "Herbalism", 182, { { 2366, "Herb Gathering", true } })
	local visible, all = P.Build(false)
	eq(#visible, 0)
	eq(all[1].primary, nil)
	eq(P.ResolveTracking({ kind = "tracking", spellIDs = { 2383 }, name = "x" }), nil)
end)
