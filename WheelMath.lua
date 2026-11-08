-- Pure geometry for a wheel with 1..MAX_SLOTS evenly spaced slots. No WoW API
-- calls; unit-tested.
--
-- Coordinates use WoW's convention: x grows right, y grows up.
-- Slot 1 is at the top; numbering proceeds clockwise.
local _, ns = ...

local WheelMath = {}
ns.WheelMath = WheelMath

WheelMath.MAX_SLOTS = 5

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local floor, sqrt, sin, cos, rad, deg = math.floor, math.sqrt, math.sin, math.cos, math.rad, math.deg

local function Sector(count)
	return 360 / count
end
WheelMath.Sector = Sector

-- Clockwise angle from straight up, in degrees, [0, 360).
function WheelMath.ClockwiseAngle(dx, dy)
	local a = deg(atan2(dx, dy))
	if a < 0 then
		a = a + 360
	end
	if a >= 360 then
		a = a - 360
	end
	return a
end

-- Slot whose sector contains the angle. Sector i is centered on (i-1)*sector.
-- Boundaries belong to the clockwise-next slot.
function WheelMath.SlotForAngle(angle, count)
	local sector = Sector(count)
	return floor((angle + sector / 2) / sector) % count + 1
end

-- Smallest absolute angular distance between two angles, in degrees.
local function AngularDistance(a, b)
	local d = (a - b) % 360
	if d > 180 then
		d = 360 - d
	end
	return d
end

-- Selection for a cursor offset (dx, dy) from the wheel center.
--   count      number of slots on the wheel (>= 1).
--   deadZone   radius inside which nothing is selected.
--   current    currently highlighted slot (or nil).
--   hysteresis degrees past a sector edge before the highlight moves away from
--              `current`.
-- Returns a slot index 1..count or nil (dead zone, or no slots).
function WheelMath.SelectSlot(dx, dy, count, deadZone, current, hysteresis)
	if type(count) ~= "number" or count < 1 then
		return nil
	end
	if dx ~= dx or dy ~= dy then -- NaN guard
		return nil
	end
	if sqrt(dx * dx + dy * dy) < (deadZone or 0) then
		return nil
	end
	local angle = WheelMath.ClockwiseAngle(dx, dy)
	local slot = WheelMath.SlotForAngle(angle, count)
	hysteresis = hysteresis or 0
	if current and current <= count and slot ~= current and hysteresis > 0 then
		local sector = Sector(count)
		local center = (current - 1) * sector
		if AngularDistance(angle, center) <= sector / 2 + hysteresis then
			return current
		end
	end
	return slot
end

-- Offset of a slot's center from the wheel center at the given radius.
function WheelMath.SlotOffset(index, count, radius)
	local a = rad((index - 1) * Sector(count))
	return radius * sin(a), radius * cos(a)
end

-- Clamp a wheel center so a square of `halfExtent` around it stays on screen.
-- If the screen is smaller than the wheel, the wheel is centered.
function WheelMath.ClampCenter(cx, cy, halfExtent, screenW, screenH)
	local function clampAxis(v, size)
		if size <= halfExtent * 2 then
			return size / 2
		end
		if v < halfExtent then
			return halfExtent
		end
		if v > size - halfExtent then
			return size - halfExtent
		end
		return v
	end
	return clampAxis(cx, screenW), clampAxis(cy, screenH)
end
