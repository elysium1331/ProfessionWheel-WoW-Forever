-- Saved-variable schema, defaults, validation and migrations. Pure Lua; unit-tested.
--
-- Only display options are stored. The wheel's contents always come from the
-- character's current professions, so there is nothing to keep in sync.
local _, ns = ...

local Database = {}
ns.Database = Database

Database.SCHEMA_VERSION = 1

Database.LIMITS = {
	wheelSize = { min = 200, max = 420, default = 260, step = 20 },
	iconScale = { min = 0.6, max = 1.6, default = 1.0, step = 0.1 },
}

Database.POSITIONS = { CURSOR = true, SCREEN = true }

local function CopyDefaults()
	return {
		schemaVersion = Database.SCHEMA_VERSION,
		wheelSize = Database.LIMITS.wheelSize.default,
		iconScale = Database.LIMITS.iconScale.default,
		showLabels = true,
		showInactive = false,
		position = "CURSOR",
		tipShown = false,
	}
end
Database.CopyDefaults = CopyDefaults

local function ClampNumber(value, limit)
	if type(value) ~= "number" or value ~= value then
		return limit.default
	end
	if value < limit.min then
		return limit.min
	end
	if value > limit.max then
		return limit.max
	end
	return value
end

local BOOLEANS = { showLabels = true, showInactive = false, tipShown = false }

-- MIGRATIONS[n] upgrades a table from schema n to n+1 in place. Schema 0 means
-- "no schemaVersion field" (hand-edited data); its fields are repaired below.
local MIGRATIONS = {
	[0] = function(db)
		db.schemaVersion = 1
	end,
}
Database.MIGRATIONS = MIGRATIONS

-- Validates and repairs a stored table.
-- Returns db, report where report = { reset = bool, repaired = { ... } }.
function Database.Load(stored)
	local report = { reset = false, repaired = {} }
	if type(stored) ~= "table" then
		report.reset = stored ~= nil
		return CopyDefaults(), report
	end

	local db = stored
	local version = db.schemaVersion
	if type(version) ~= "number" or version ~= version or version < 0 or version % 1 ~= 0 then
		version = 0
	end
	while version < Database.SCHEMA_VERSION do
		local step = MIGRATIONS[version]
		if not step or not pcall(step, db) then
			report.reset = true
			return CopyDefaults(), report
		end
		version = version + 1
		db.schemaVersion = version
	end
	-- A newer schema (downgraded addon) is kept apart from field repair.

	for key, limit in pairs(Database.LIMITS) do
		local value = ClampNumber(db[key], limit)
		if value ~= db[key] then
			table.insert(report.repaired, key)
		end
		db[key] = value
	end
	for key, default in pairs(BOOLEANS) do
		if type(db[key]) ~= "boolean" then
			if db[key] ~= nil then
				table.insert(report.repaired, key)
			end
			db[key] = default
		end
	end
	if not Database.POSITIONS[db.position] then
		if db.position ~= nil then
			table.insert(report.repaired, "position")
		end
		db.position = "CURSOR"
	end
	return db, report
end

-- Resets everything to defaults in place (keeps the same table reference).
function Database.Reset(db)
	for k in pairs(db) do
		db[k] = nil
	end
	for k, v in pairs(CopyDefaults()) do
		db[k] = v
	end
	return db
end
