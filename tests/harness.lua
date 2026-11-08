-- Minimal test helpers. Tests load individual addon files that contain pure
-- logic; no WoW runtime is emulated.
local H = { passed = 0, failed = 0, failures = {} }

H.root = (ROOT or ".") .. "/"

-- Loads an addon file the way the client does: the chunk receives (addonName, ns).
function H.load(relPath, ns)
	local chunk, err = loadfile(H.root .. relPath)
	if not chunk then
		error(err)
	end
	chunk("Elysium_ProfessionWheel", ns)
	return ns
end

function H.test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		H.passed = H.passed + 1
	else
		H.failed = H.failed + 1
		H.failures[#H.failures + 1] = name .. ": " .. tostring(err)
	end
end

local function show(v)
	if type(v) == "string" then
		return string.format("%q", v)
	end
	return tostring(v)
end

function H.eq(actual, expected, msg)
	if actual ~= expected then
		error((msg or "values differ") .. ": expected " .. show(expected) .. ", got " .. show(actual), 2)
	end
end

function H.truthy(v, msg)
	if not v then
		error(msg or "expected a true value", 2)
	end
end

return H
