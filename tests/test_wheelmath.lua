local H = ...
local ns = H.load("WheelMath.lua", {})
local M = ns.WheelMath
local test, eq = H.test, H.eq

local function at(angleDeg, dist)
	local r = math.rad(angleDeg)
	return dist * math.sin(r), dist * math.cos(r)
end

test("every slot count 1-5: slot centers map to their own slot, clockwise from the top", function()
	for count = 1, M.MAX_SLOTS do
		for i = 1, count do
			local dx, dy = at((i - 1) * 360 / count, 100)
			eq(M.SelectSlot(dx, dy, count, 30), i, ("count %d slot %d"):format(count, i))
		end
	end
end)

test("one slot: any direction outside the dead zone selects it", function()
	for _, a in ipairs({ 0, 90, 179, 180, 270, 359 }) do
		local dx, dy = at(a, 100)
		eq(M.SelectSlot(dx, dy, 1, 30), 1, "angle " .. a)
	end
end)

test("five slots: boundaries belong to the clockwise-next slot and wrap at 360", function()
	eq(M.SlotForAngle(36, 5), 2)
	eq(M.SlotForAngle(35.999, 5), 1)
	eq(M.SlotForAngle(324, 5), 1)
	eq(M.SlotForAngle(323.999, 5), 5)
	eq(M.SlotForAngle(359.9, 5), 1)
end)

test("dead zone, NaN and zero count select nothing", function()
	eq(M.SelectSlot(5, 5, 5, 30), nil)
	eq(M.SelectSlot(0 / 0, 100, 5, 30), nil)
	eq(M.SelectSlot(0, 100, 0, 30), nil)
	eq(M.SelectSlot(0, 100, nil, 30), nil)
end)

test("hysteresis keeps the current slot just past an edge, then lets go", function()
	-- 5 slots: edge between 1 and 2 at 36 degrees.
	local dx, dy = at(39, 100)
	eq(M.SelectSlot(dx, dy, 5, 30, 1, 6), 1)
	dx, dy = at(43, 100)
	eq(M.SelectSlot(dx, dy, 5, 30, 1, 6), 2)
	-- a stale current slot beyond the count is ignored
	dx, dy = at(0, 100)
	eq(M.SelectSlot(dx, dy, 2, 30, 5, 6), 1)
end)

test("slot offsets: top first, then clockwise", function()
	local x, y = M.SlotOffset(1, 4, 100)
	H.truthy(math.abs(x) < 1e-9 and math.abs(y - 100) < 1e-9, "slot 1 top")
	x, y = M.SlotOffset(2, 4, 100)
	H.truthy(math.abs(x - 100) < 1e-9 and math.abs(y) < 1e-9, "slot 2 right")
	x, y = M.SlotOffset(2, 2, 100)
	H.truthy(math.abs(x) < 1e-9 and math.abs(y + 100) < 1e-9, "2 slots: second at the bottom")
end)

test("clamp keeps the wheel on screen and centers it on tiny screens", function()
	local x, y = M.ClampCenter(10, 990, 150, 1920, 1080)
	eq(x, 150)
	eq(y, 930)
	x, y = M.ClampCenter(10, 10, 300, 500, 400)
	eq(x, 250)
	eq(y, 200)
end)
