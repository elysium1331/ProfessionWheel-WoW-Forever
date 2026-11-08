-- Options window (/pwheel) and the Options > AddOns entry.
local _, ns = ...

local L, Compat, Database, Wheel = ns.L, ns.Compat, ns.Database, ns.Wheel

local SettingsUI = {}
ns.Settings = SettingsUI

local FRAME_NAME = "ElysiumProfessionWheelConfigFrame"
local frame
local controls = {}
local pendingKeybindings = false

-- Widgets ------------------------------------------------------------------------------

local function Button(parent, text, width, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(width, 22)
	b:SetText(text)
	b:SetScript("OnClick", onClick)
	return b
end

local function Label(parent, text, template)
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
	fs:SetText(text)
	fs:SetJustifyH("LEFT")
	return fs
end

local function Check(parent, text, onClick)
	local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	c:SetSize(24, 24)
	c.label = Label(parent, text, "GameFontHighlightSmall")
	c.label:SetPoint("LEFT", c, "RIGHT", 2, 1)
	c:SetScript("OnClick", onClick)
	return c
end

local function Stepper(parent, label, x, y, onStep)
	local fs = Label(parent, label, "GameFontNormalSmall")
	fs:SetPoint("TOPLEFT", x, y)
	fs:SetWidth(90)
	local minus = Button(parent, "-", 24, function() onStep(-1) end)
	minus:SetPoint("LEFT", fs, "RIGHT", 4, 0)
	local value = Label(parent, "", "GameFontHighlight")
	value:SetWidth(40)
	value:SetJustifyH("CENTER")
	value:SetPoint("LEFT", minus, "RIGHT", 2, 0)
	local plus = Button(parent, "+", 24, function() onStep(1) end)
	plus:SetPoint("LEFT", value, "RIGHT", 2, 0)
	return value
end

-- Window -------------------------------------------------------------------------------

local function UpdateOptions()
	local db = ns.db
	controls.sizeValue:SetText(tostring(db.wheelSize))
	controls.scaleValue:SetText(("%.1f"):format(db.iconScale))
	controls.labels:SetChecked(db.showLabels)
	controls.inactive:SetChecked(db.showInactive)
	controls.posCursor:SetChecked(db.position == "CURSOR")
	controls.posScreen:SetChecked(db.position == "SCREEN")
	local key = Compat.GetBindingText("PROFESSIONWHEEL_OPEN")
	if key then
		controls.keyText:SetText(L.CURRENT_KEY:format("|cffffffff" .. key .. "|r"))
	else
		controls.keyText:SetText(L.CURRENT_KEY:format("|cffff6060" .. L.NOT_BOUND .. "|r"))
	end
end

local function Changed()
	UpdateOptions()
	Wheel.RefreshIfOpen()
end

local function Build()
	frame = CreateFrame("Frame", FRAME_NAME, UIParent, "ButtonFrameTemplate")
	frame:SetSize(460, 330)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	if ButtonFrameTemplate_HidePortrait then
		ButtonFrameTemplate_HidePortrait(frame)
	end
	if frame.SetTitle then
		frame:SetTitle(L.CONFIG_TITLE .. "  " .. ns.version)
	end
	frame:Hide()
	Compat.RegisterEscapeClose(FRAME_NAME)

	local howto = Label(frame, L.CONFIG_HOWTO, "GameFontHighlightSmall")
	howto:SetPoint("TOPLEFT", 20, -70)
	howto:SetWidth(420)
	howto:SetWordWrap(true)
	howto:SetSpacing(2)

	local limits = Database.LIMITS
	controls.sizeValue = Stepper(frame, L.WHEEL_SIZE, 20, -134, function(dir)
		local l = limits.wheelSize
		ns.db.wheelSize = math.max(l.min, math.min(l.max, ns.db.wheelSize + dir * l.step))
		Changed()
	end)
	controls.scaleValue = Stepper(frame, L.ICON_SCALE, 20, -164, function(dir)
		local l = limits.iconScale
		local v = math.floor((ns.db.iconScale + dir * l.step) * 10 + 0.5) / 10
		ns.db.iconScale = math.max(l.min, math.min(l.max, v))
		Changed()
	end)

	local posLabel = Label(frame, L.POSITION, "GameFontNormalSmall")
	posLabel:SetPoint("TOPLEFT", 20, -200)
	controls.posCursor = Check(frame, L.POSITION_CURSOR, function()
		ns.db.position = "CURSOR"
		Changed()
	end)
	controls.posCursor:SetPoint("TOPLEFT", 110, -194)
	controls.posScreen = Check(frame, L.POSITION_SCREEN, function()
		ns.db.position = "SCREEN"
		Changed()
	end)
	controls.posScreen:SetPoint("TOPLEFT", 210, -194)

	controls.labels = Check(frame, L.SHOW_LABELS, function(self)
		ns.db.showLabels = self:GetChecked() and true or false
		Changed()
	end)
	controls.labels:SetPoint("TOPLEFT", 16, -222)
	controls.inactive = Check(frame, L.SHOW_INACTIVE, function(self)
		ns.db.showInactive = self:GetChecked() and true or false
		Changed()
	end)
	controls.inactive:SetPoint("TOPLEFT", 16, -248)

	controls.keybind = Button(frame, L.KEYBINDINGS, 130, function()
		SettingsUI.OpenKeybindings()
	end)
	controls.keybind:SetPoint("BOTTOMLEFT", 12, 4)
	controls.keyText = Label(frame, "", "GameFontNormalSmall")
	controls.keyText:SetPoint("LEFT", controls.keybind, "RIGHT", 10, 0)

	controls.restore = Button(frame, L.RESTORE_DEFAULTS, 140, function()
		Compat.Confirm(L.RESTORE_CONFIRM, function()
			Database.Reset(ns.db)
			ns.db.tipShown = true
			Changed()
		end)
	end)
	controls.restore:SetPoint("BOTTOMRIGHT", -10, 4)

	frame:SetScript("OnShow", function(self)
		self:RegisterEvent("UPDATE_BINDINGS")
		UpdateOptions()
	end)
	frame:SetScript("OnHide", function(self)
		self:UnregisterEvent("UPDATE_BINDINGS")
	end)
	frame:SetScript("OnEvent", UpdateOptions)
end

function SettingsUI.Toggle()
	if not ns.db then
		return
	end
	if not frame then
		Build()
	end
	frame:SetShown(not frame:IsShown())
end

function SettingsUI.Open()
	if not ns.db then
		return
	end
	if not frame then
		Build()
	end
	frame:Show()
	frame:Raise()
end

function SettingsUI.OpenKeybindings()
	if Compat.InCombat() then
		pendingKeybindings = true
		ns.Notify("combatsettings", L.MSG_COMBAT_SETTINGS)
		return
	end
	if frame then
		frame:Hide()
	end
	if not Compat.OpenKeybindings() then
		ns.Notify("nobinding", L.MSG_NO_BINDING)
	end
end

function SettingsUI.OnCombatEnded()
	if pendingKeybindings then
		pendingKeybindings = false
		SettingsUI.OpenKeybindings()
	end
end

-- Options > AddOns > ProfessionWheel: a short page that launches the window.
function SettingsUI.RegisterOptionsCategory()
	if SettingsUI.category then
		return
	end
	local panel = CreateFrame("Frame")
	local title = Label(panel, L.ADDON_TITLE, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	local desc = Label(panel, L.SETTINGS_DESC, "GameFontHighlight")
	desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
	desc:SetWidth(560)
	desc:SetWordWrap(true)
	local open = Button(panel, L.SETTINGS_OPEN, 260, function()
		SettingsUI.Open()
	end)
	open:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
	local keys = Button(panel, L.KEYBINDINGS, 160, function()
		SettingsUI.OpenKeybindings()
	end)
	keys:SetPoint("LEFT", open, "RIGHT", 10, 0)
	local note = Label(panel, L.UNOFFICIAL, "GameFontDisableSmall")
	note:SetPoint("TOPLEFT", open, "BOTTOMLEFT", 0, -24)
	note:SetWidth(560)
	note:SetWordWrap(true)
	SettingsUI.category = Compat.RegisterSettingsCanvas(panel, L.ADDON_TITLE)
end
