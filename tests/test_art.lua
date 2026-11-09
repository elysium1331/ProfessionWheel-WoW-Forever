local H = ...
local ns = H.load("Art.lua", {})
local Art = ns.Art
local test, eq = H.test, H.eq

test("every vanilla profession has a painted icon", function()
	for _, skillLine in ipairs({ 171, 164, 333, 202, 182, 165, 186, 393, 197, 185, 129, 356 }) do
		H.truthy(Art.ICONS[skillLine], "skill line " .. skillLine)
	end
end)

test("painted icon by default, game icon when chosen in options", function()
	local entry = { skillLine = 197, icon = 136249 }
	local path, painted = Art.IconFor(entry, false)
	eq(path, Art.ICONS[197])
	eq(painted, true)
	path, painted = Art.IconFor(entry, true)
	eq(path, 136249)
	eq(painted, false)
end)

test("unknown profession uses the game icon, then the painted generic", function()
	local path, painted = Art.IconFor({ skillLine = 4242, icon = 99 }, false)
	eq(path, 99)
	eq(painted, false)
	path, painted = Art.IconFor({ skillLine = 4242 }, false)
	eq(path, Art.GENERIC_ICON)
	eq(painted, true)
end)
