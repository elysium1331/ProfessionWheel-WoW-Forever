-- The radial wheel: a view that draws 1..5 profession slots, and the controller
-- that opens it, tracks the highlighted slot and performs the chosen action.
--
-- Input model (out of combat only):
--   * One full-screen SecureActionButtonTemplate button (the "catcher") is shown
--     while the wheel is open. As the cursor moves, ordinary addon code points the
--     catcher's attributes at the highlighted slot's spells (allowed out of combat):
--       left button  -> "*type1" = "spell", "*spell1" = primary spell ID
--       right button -> "*type2" = "spell", "*spell2" = secondary spell ID
--     A real mouse click on the catcher then casts that spell through Blizzard's
--     secure button code, just like a click on an action bar button.
--   * Turning minimap tracking off (and on, where no spell exists) is done in
--     PostClick through C_Minimap.SetTracking.
--   * A visibility state driver hides the catcher the moment combat starts.
--   * Escape closes through UISpecialFrames; the key binding toggles.
local _, ns = ...

local L, Compat, WheelMath, Professions = ns.L, ns.Compat, ns.WheelMath, ns.Professions

local Wheel = {}
ns.Wheel = Wheel

local CATCHER_NAME = "ElysiumProfessionWheelCatcher"
local GOLD = { 0.62, 0.52, 0.32, 1 }
local GOLD_BRIGHT = { 1.0, 0.82, 0.42, 1 }
local GOLD_DIM = { 0.36, 0.31, 0.22, 1 }
local TRACKING_ON = { 0.45, 0.85, 0.40, 1 }
local DARK = { 0.05, 0.045, 0.04, 0.82 }
local SLOT_DARK = { 0.09, 0.08, 0.07, 0.95 }
local HIGHLIGHT_HYSTERESIS = 6

-- View ------------------------------------------------------------------------------

local function MakeDisc(parent, layer, sublevel, color)
	local tex = parent:CreateTexture(nil, layer, nil, sublevel)
	tex:SetColorTexture(color[1], color[2], color[3], color[4])
	local mask = parent:CreateMaskTexture()
	mask:SetTexture(Compat.CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(tex)
	tex:AddMaskTexture(mask)
	return tex
end

local function SetDiscColor(tex, color)
	tex:SetColorTexture(color[1], color[2], color[3], color[4])
end

local View = {}
View.__index = View

function Wheel.CreateView(parent)
	local self = setmetatable({ count = 0, entries = {} }, View)
	local root = CreateFrame("Frame", nil, parent)
	root:EnableMouse(false)
	self.root = root

	self.rim = MakeDisc(root, "BACKGROUND", 0, GOLD_DIM)
	self.rim:SetPoint("CENTER")
	self.bg = MakeDisc(root, "BACKGROUND", 1, DARK)
	self.bg:SetPoint("CENTER")
	self.hubRim = MakeDisc(root, "BORDER", 0, GOLD_DIM)
	self.hubRim:SetPoint("CENTER")
	self.hub = MakeDisc(root, "BORDER", 1, SLOT_DARK)
	self.hub:SetPoint("CENTER")

	self.centerText = root:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.centerText:SetPoint("CENTER")
	self.centerText:SetJustifyH("CENTER")
	self.centerText:SetWordWrap(true)
	self.centerText:SetSpacing(2)

	self.slots = {}
	for i = 1, WheelMath.MAX_SLOTS do
		local slot = CreateFrame("Frame", nil, root)
		slot:EnableMouse(false)
		slot.glow = MakeDisc(slot, "BACKGROUND", 0, { GOLD_BRIGHT[1], GOLD_BRIGHT[2], GOLD_BRIGHT[3], 0.22 })
		slot.glow:SetPoint("CENTER")
		slot.glow:Hide()
		slot.ring = MakeDisc(slot, "BORDER", 0, GOLD)
		slot.ring:SetPoint("CENTER")
		slot.base = MakeDisc(slot, "BORDER", 1, SLOT_DARK)
		slot.base:SetPoint("CENTER")
		slot.icon = slot:CreateTexture(nil, "ARTWORK")
		slot.icon:SetPoint("CENTER")
		slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		local mask = slot:CreateMaskTexture()
		mask:SetTexture(Compat.CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		mask:SetAllPoints(slot.icon)
		slot.icon:AddMaskTexture(mask)
		slot.label = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		slot.label:SetJustifyH("CENTER")
		slot:Hide()
		self.slots[i] = slot
	end

	self.hint = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	self.hint:SetPoint("TOP", root, "BOTTOM", 0, -4)
	self.hint:SetText(L.WHEEL_HINT)
	return self
end

-- Sizes everything for a wheel diameter, icon scale and slot count.
function View:Layout(size, iconScale, showLabels, count)
	local slotSize = math.floor(size * 0.2 * iconScale + 0.5)
	slotSize = math.max(32, math.min(slotSize, math.floor(size * 0.3)))
	local radius = size / 2 - slotSize / 2 - 10
	self.size, self.slotSize, self.radius, self.count = size, slotSize, radius, count
	self.deadZone = math.floor(size * 0.17)

	self.root:SetSize(size, size)
	self.rim:SetSize(size, size)
	self.bg:SetSize(size - 4, size - 4)
	self.hubRim:SetSize(self.deadZone * 2 + 2, self.deadZone * 2 + 2)
	self.hub:SetSize(self.deadZone * 2, self.deadZone * 2)
	self.centerText:SetWidth(self.deadZone * 2 + 40)

	for i, slot in ipairs(self.slots) do
		if i <= count then
			local x, y = WheelMath.SlotOffset(i, count, radius)
			slot:SetSize(slotSize, slotSize)
			slot:ClearAllPoints()
			slot:SetPoint("CENTER", self.root, "CENTER", x, y)
			slot.glow:SetSize(slotSize + 14, slotSize + 14)
			slot.ring:SetSize(slotSize + 4, slotSize + 4)
			slot.base:SetSize(slotSize, slotSize)
			slot.icon:SetSize(slotSize - 6, slotSize - 6)
			slot.label:ClearAllPoints()
			slot.label:SetWidth(slotSize + 36)
			if y < -radius * 0.7 then
				slot.label:SetPoint("BOTTOM", slot, "TOP", 0, 2)
			else
				slot.label:SetPoint("TOP", slot, "BOTTOM", 0, -2)
			end
			slot.label:SetShown(showLabels)
			slot:Show()
		else
			slot:Hide()
		end
	end
end

-- Fills the slots from profession entries (see Professions.Build).
function View:Refresh(entries)
	self.entries = entries
	for i, slot in ipairs(self.slots) do
		local entry = entries[i]
		slot.entry = entry
		if entry then
			slot.icon:SetTexture(entry.icon or Compat.QUESTION_MARK)
			slot.label:SetText(entry.name)
			local usable = entry.primary ~= nil
			slot.icon:SetDesaturated(not usable)
			slot.icon:SetVertexColor(usable and 1 or 0.6, usable and 1 or 0.6, usable and 1 or 0.6, 1)
			slot.label:SetTextColor(usable and 0.95 or 0.55, usable and 0.93 or 0.55, usable and 0.86 or 0.55)
			local trackingOn = Professions.IsTrackingActive(entry.primary) or Professions.IsTrackingActive(entry.secondary)
			slot.ringColor = (trackingOn and TRACKING_ON) or (usable and GOLD) or GOLD_DIM
		end
		slot.glow:Hide()
	end
	self:SetHighlight(self.highlight)
end

local function DescribeAction(action)
	if action.kind == "tracking" then
		return (Professions.IsTrackingActive(action) and L.TRACKING_ON or L.TRACKING_OFF):format(action.name)
	end
	return action.name
end

-- Highlights one slot (or none) and updates the center text.
function View:SetHighlight(index)
	self.highlight = index
	for i, slot in ipairs(self.slots) do
		local on = i == index
		slot.glow:SetShown(on)
		SetDiscColor(slot.ring, on and GOLD_BRIGHT or (slot.ringColor or GOLD))
	end
	local entry = index and self.entries[index]
	if not entry then
		self.centerText:SetFontObject("GameFontDisableSmall")
		self.centerText:SetText(L.CHOOSE)
		return
	end
	local lines = { "|cffffd200" .. entry.name .. "|r" }
	if entry.maxRank and entry.maxRank > 0 then
		lines[#lines + 1] = L.SKILL:format(entry.rank or 0, entry.maxRank)
	end
	if entry.primary then
		lines[#lines + 1] = L.LEFT_CLICK:format(DescribeAction(entry.primary))
		if entry.secondary then
			lines[#lines + 1] = L.RIGHT_CLICK:format(DescribeAction(entry.secondary))
		end
	else
		lines[#lines + 1] = L.NOTHING_TO_USE
	end
	self.centerText:SetFontObject("GameFontHighlightSmall")
	self.centerText:SetText(table.concat(lines, "\n"))
end

-- Controller -------------------------------------------------------------------------

local catcher, view, fadeIn
local isOpen = false
local centerX, centerY = 0, 0
local entries = {}
local plans = {} -- [1] left button, [2] right button, for the highlighted slot

-- Points one mouse button of the secure catcher at an action (out of combat only).
local function SetButtonAction(button, action)
	local plan
	if action then
		if action.kind == "spell" then
			plan = { mode = "cast", spellID = action.spellID }
		else
			plan = Professions.ResolveTracking(action)
		end
		if plan then
			plan.name = action.name
		end
	end
	plans[button] = plan
	if plan and plan.mode == "cast" then
		catcher:SetAttribute("*type" .. button, "spell")
		catcher:SetAttribute("*spell" .. button, plan.spellID)
	else
		catcher:SetAttribute("*type" .. button, nil)
		catcher:SetAttribute("*spell" .. button, nil)
	end
end

local function ApplyHighlight(index)
	if Compat.InCombat() then
		return
	end
	view:SetHighlight(index)
	local entry = index and entries[index]
	SetButtonAction(1, entry and entry.primary)
	SetButtonAction(2, entry and entry.secondary)
end

local function OnUpdate()
	if Compat.HasKeyboardFocus() then
		Wheel.Cancel() -- the player started typing; never act on a stale wheel
		return
	end
	local x, y = Compat.GetCursorInFrameSpace(catcher)
	local selected = WheelMath.SelectSlot(x - centerX, y - centerY, view.count, view.deadZone, view.highlight, HIGHLIGHT_HYSTERESIS)
	if selected ~= view.highlight then
		ApplyHighlight(selected)
	end
end

local function Cleanup()
	isOpen = false
	if catcher then
		catcher:SetScript("OnUpdate", nil)
		if not Compat.InCombat() then
			for button = 1, 2 do
				catcher:SetAttribute("*type" .. button, nil)
				catcher:SetAttribute("*spell" .. button, nil)
			end
		end
	end
	wipe(plans)
	if view then
		view.highlight = nil
	end
end

-- Runs after the secure click handler has cast (or not cast) the spell.
local function OnPostClick(_, button)
	local index = view and view.highlight
	local plan = plans[button == "RightButton" and 2 or 1]
	Wheel.Cancel()
	if index and plan and (plan.mode == "untrack" or plan.mode == "track") then
		ns.SetTracking(plan.index, plan.mode == "track", plan.name)
	end
end

local function EnsureFrames()
	if catcher then
		return
	end
	catcher = CreateFrame("Button", CATCHER_NAME, UIParent, "SecureActionButtonTemplate")
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata("DIALOG")
	catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	-- Addon buttons do not get Blizzard's "secure mouse press" flag, so without this
	-- the ActionButtonUseKeyDown setting would make the button act on mouse-down only.
	catcher:SetAttribute("useOnKeyDown", false)
	catcher:Hide()
	catcher:SetScript("PostClick", OnPostClick)
	-- Any hide (Escape, combat, UI hidden, loading screen) cleans up without acting.
	catcher:SetScript("OnHide", Cleanup)
	Compat.HideInCombat(catcher)
	Compat.RegisterEscapeClose(CATCHER_NAME)

	view = Wheel.CreateView(catcher)
	view.root:SetFrameLevel(catcher:GetFrameLevel() + 5)
	fadeIn = view.root:CreateAnimationGroup()
	local alpha = fadeIn:CreateAnimation("Alpha")
	alpha:SetFromAlpha(0)
	alpha:SetToAlpha(1)
	alpha:SetDuration(0.08)
end

local function PlaceWheel(db)
	local w, h = catcher:GetWidth(), catcher:GetHeight()
	local cx, cy
	if db.position == "SCREEN" or Compat.IsMouselooking() then
		cx, cy = w / 2, h / 2
	else
		cx, cy = Compat.GetCursorInFrameSpace(catcher)
	end
	-- Extra margin keeps outer labels and the hint on screen.
	cx, cy = WheelMath.ClampCenter(cx, cy, db.wheelSize / 2 + 24, w, h)
	centerX, centerY = cx, cy
	view.root:ClearAllPoints()
	view.root:SetPoint("CENTER", catcher, "BOTTOMLEFT", cx, cy)
end

function Wheel.IsOpen()
	return isOpen
end

function Wheel.Open()
	local db = ns.db
	if isOpen or not db or Compat.HasKeyboardFocus() then
		return
	end
	if Compat.InCombat() then
		ns.Notify("combat", L.MSG_COMBAT)
		return
	end
	local visible, all = Professions.Build(db.showInactive)
	if #visible == 0 then
		ns.Notify("empty", #all == 0 and L.MSG_NO_PROFESSIONS or L.MSG_NOTHING_TO_USE)
		return
	end
	EnsureFrames()
	entries = visible
	view.highlight = nil
	view:Layout(db.wheelSize, db.iconScale, db.showLabels, #entries)
	view:Refresh(entries)
	PlaceWheel(db)
	ApplyHighlight(nil)
	isOpen = true
	catcher:Show()
	catcher:SetScript("OnUpdate", OnUpdate)
	fadeIn:Stop()
	fadeIn:Play()
end

-- Closes without performing anything.
function Wheel.Cancel()
	if catcher and catcher:IsShown() and not Compat.InCombat() then
		catcher:Hide() -- OnHide -> Cleanup
	else
		Cleanup()
	end
end

function Wheel.Toggle()
	if isOpen then
		Wheel.Cancel()
	else
		Wheel.Open()
	end
end

-- Re-render an open wheel after settings change.
function Wheel.RefreshIfOpen()
	if isOpen and ns.db and not Compat.InCombat() then
		Wheel.Cancel()
		Wheel.Open()
	end
end
