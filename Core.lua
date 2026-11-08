-- Startup, saved variables, tracking toggles, slash commands and quiet messaging.
local ADDON_NAME, ns = ...

local L, Compat, Database, Professions = ns.L, ns.Compat, ns.Database, ns.Professions

-- The single global table: the Bindings.xml handler and a tiny public surface.
ProfessionWheel = ProfessionWheel or {}
local API = ProfessionWheel

ns.version = "?"
ns.db = nil

-- Messaging --------------------------------------------------------------------

local lastMessage = {}
local MESSAGE_COOLDOWN = 10

-- Prints at most once per `key` every MESSAGE_COOLDOWN seconds.
function ns.Notify(key, text, force)
	local now = GetTime and GetTime() or 0
	if not force and lastMessage[key] and now - lastMessage[key] < MESSAGE_COOLDOWN then
		return
	end
	lastMessage[key] = now
	local frame = DEFAULT_CHAT_FRAME
	if frame and frame.AddMessage then
		frame:AddMessage("|cffd4b56a" .. L.MSG_PREFIX .. "|r " .. text)
	end
end

-- Tracking ---------------------------------------------------------------------------

local pendingTracking -- name of the tracking being changed, while the call runs

function ns.SetTracking(index, on, name)
	pendingTracking = name or "?"
	local ok = Compat.SetTracking(index, on)
	pendingTracking = nil
	if not ok then
		ns.Notify("trackfail", L.MSG_TRACKING_FAILED:format(name or "?"))
	end
end

-- /pwheel status ---------------------------------------------------------------------

local function PrintStatus()
	local _, all = Professions.Build(ns.db and ns.db.showInactive)
	ns.Notify("status", L.MSG_STATUS_HEADER, true)
	if #all == 0 then
		ns.Notify("status0", L.MSG_STATUS_NONE, true)
	end
	for i, entry in ipairs(all) do
		local function describe(action)
			if not action then
				return L.MSG_STATUS_NOTHING
			end
			return ("%s [%s %s]"):format(action.name, action.kind, tostring(action.spellID or "-"))
		end
		ns.Notify("status" .. i, L.MSG_STATUS_LINE:format(i, entry.name, tostring(entry.skillLine),
			describe(entry.primary), describe(entry.secondary), entry.hidden and L.MSG_STATUS_HIDDEN or ""), true)
	end
end

-- Events -------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")

local function OnAddonLoaded()
	ns.version = Compat.GetAddOnVersion(ADDON_NAME)
	local db, report = Database.Load(ProfessionWheelCharDB)
	ProfessionWheelCharDB = db
	ns.db = db
	if report.reset then
		ns.Notify("recovered", L.MSG_RECOVERED)
	end
end

local function RegisterSlash()
	-- Never replace another addon's command.
	local taken = {}
	pcall(function()
		for key, value in pairs(_G) do
			if type(key) == "string" and type(value) == "string" and key:sub(1, 6) == "SLASH_" then
				taken[value:lower()] = true
			end
		end
	end)
	if type(hash_SlashCmdList) == "table" then
		for cmd in pairs(hash_SlashCmdList) do
			if type(cmd) == "string" then
				taken[cmd:lower()] = true
			end
		end
	end
	local wanted = { "/professionwheel", "/pwheel" }
	local free = {}
	for _, cmd in ipairs(wanted) do
		if not taken[cmd] then
			free[#free + 1] = cmd
		end
	end
	if #free == 0 or (SlashCmdList and SlashCmdList.PROFESSIONWHEEL) then
		ns.Notify("slash", L.MSG_NO_SLASH)
		return
	end
	for i, cmd in ipairs(free) do
		_G["SLASH_PROFESSIONWHEEL" .. i] = cmd
	end
	SlashCmdList.PROFESSIONWHEEL = function(msg)
		msg = (msg or ""):lower():match("^%s*(.-)%s*$")
		if msg == "version" then
			local build, interface = Compat.GetBuildInfo()
			ns.Notify("version", ("%s, client %s (interface %s)"):format(ns.version, tostring(build), tostring(interface)), true)
		elseif msg == "status" then
			PrintStatus()
		elseif msg == "open" then
			API.Toggle()
		else
			ns.Settings.Toggle()
		end
	end
	if #free < #wanted then
		local missing = free[1] == wanted[1] and wanted[2] or wanted[1]
		ns.Notify("slashpartial", L.MSG_SLASH_PARTIAL:format(missing, free[1]))
	end
end

local function OnPlayerLogin()
	if not ns.db then
		eventFrame:UnregisterEvent("ADDON_LOADED")
		OnAddonLoaded()
	end
	RegisterSlash()
	ns.Settings.RegisterOptionsCategory()
	if not ns.db.tipShown then
		ns.db.tipShown = true
		ns.Notify("tip", Compat.GetBindingText("PROFESSIONWHEEL_OPEN") and L.MSG_TIP or L.MSG_TIP_BIND)
	end
end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
		eventFrame:UnregisterEvent("ADDON_LOADED")
		OnAddonLoaded()
	elseif event == "PLAYER_LOGIN" then
		OnPlayerLogin()
	elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_LEAVING_WORLD" or event == "LOADING_SCREEN_ENABLED"
		or event == "CINEMATIC_START" or event == "PLAY_MOVIE" then
		-- PLAYER_REGEN_DISABLED fires just before combat lockdown, so the secure
		-- catcher can still be hidden here (the state driver is the backstop).
		ns.Wheel.Cancel()
	elseif event == "PLAYER_REGEN_ENABLED" then
		ns.Settings.OnCombatEnded()
	elseif (event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN") and arg1 == ADDON_NAME then
		if pendingTracking then
			ns.Notify("trackblocked", L.MSG_TRACKING_BLOCKED:format(pendingTracking))
		end
	end
end)

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
eventFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
eventFrame:RegisterEvent("CINEMATIC_START")
eventFrame:RegisterEvent("PLAY_MOVIE")
eventFrame:RegisterEvent("ADDON_ACTION_BLOCKED")
eventFrame:RegisterEvent("ADDON_ACTION_FORBIDDEN")

-- Public surface -----------------------------------------------------------------

function API.OnBinding()
	ns.Wheel.Toggle()
end

function API.Toggle()
	ns.Wheel.Toggle()
end

-- Minimap AddOns menu entry (TOC: AddonCompartmentFunc).
function ProfessionWheel_OnAddonCompartmentClick()
	ns.Settings.Toggle()
end
