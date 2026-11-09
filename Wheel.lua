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

local L, Compat, WheelMath, Professions, Art = ns.L, ns.Compat, ns.WheelMath, ns.Professions, ns.Art

local Wheel = {}
ns.Wheel = Wheel

local CATCHER_NAME = "ElysiumProfessionWheelCatcher"
local SLOT_DARK = { 0.07, 0.06, 0.05, 1 }
-- Vertex tints for the gold slot frame (multiplied with the texture).
local FRAME_NORMAL = { 0.88, 0.88, 0.88 }
local FRAME_SELECTED = { 1, 1, 1 }
local FRAME_TRACKING = { 0.55, 1, 0.55 }
local FRAME_UNUSABLE = { 0.5, 0.5, 0.5 }
local HIGHLIGHT_HYSTERESIS = 6

-- View ------------------------------------------------------------------------------

local function Tint(tex, c)
	tex:SetVertexColor(c[1], c[2], c[3], 1)
end

local function CircleMask(owner, tex)
	local mask = owner:CreateMaskTexture()
	mask:SetTexture(Compat.CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	mask:SetAllPoints(tex)
	tex:AddMaskTexture(mask)
end

local View = {}
View.__index = View

function Wheel.CreateView(parent)
	local self = setmetatable({ count = 0, entries = {} }, View)
	local root = CreateFrame("Frame", nil, parent)
	root:EnableMouse(false)
	self.root = root

	self.disc = root:CreateTexture(nil, "BACKGROUND", nil, 0)
	self.disc:SetTexture(Art.DISC)
	self.disc:SetAllPoints(root)

	self.spokes, self.stars = {}, {}
	for i = 1, WheelMath.MAX_SLOTS do
		local spoke = root:CreateTexture(nil, "BORDER", nil, 0)
		spoke:SetTexture(Art.SPOKE)
		self.spokes[i] = spoke
		local star = root:CreateTexture(nil, "BORDER", nil, 1)
		star:SetTexture(Art.STAR)
		self.stars[i] = star
	end

	self.hubGlow = root:CreateTexture(nil, "ARTWORK", nil, 0)
	self.hubGlow:SetTexture(Art.HUB_GLOW)
	self.hubGlow:SetBlendMode("ADD")
	self.hubGlow:SetPoint("CENTER")
	self.hub = root:CreateTexture(nil, "ARTWORK", nil, 1)
	self.hub:SetTexture(Art.HUB)
	self.hub:SetPoint("CENTER")
	self.hub:SetVertexColor(0.8, 0.8, 0.8, 1)

	self.slots = {}
	for i = 1, WheelMath.MAX_SLOTS do
		local slot = CreateFrame("Frame", nil, root)
		slot:EnableMouse(false)
		slot.glow = slot:CreateTexture(nil, "BACKGROUND", nil, 0)
		slot.glow:SetTexture(Art.SLOT_GLOW)
		slot.glow:SetBlendMode("ADD")
		slot.glow:SetPoint("CENTER")
		slot.glow:Hide()
		slot.base = slot:CreateTexture(nil, "BORDER", nil, 0)
		slot.base:SetColorTexture(SLOT_DARK[1], SLOT_DARK[2], SLOT_DARK[3], SLOT_DARK[4])
		slot.base:SetPoint("CENTER")
		CircleMask(slot, slot.base)
		-- Painted icons carry their own transparency; game icons are square and are
		-- cropped round by a mask.
		slot.icon = slot:CreateTexture(nil, "ARTWORK")
		slot.icon:SetPoint("CENTER")
		slot.gameIcon = slot:CreateTexture(nil, "ARTWORK")
		slot.gameIcon:SetPoint("CENTER")
		slot.gameIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		CircleMask(slot, slot.gameIcon)
		slot.frame = slot:CreateTexture(nil, "OVERLAY", nil, 0)
		slot.frame:SetTexture(Art.SLOT)
		slot.frame:SetAllPoints(slot)
		slot.label = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		slot.label:SetJustifyH("CENTER")
		slot:Hide()
		self.slots[i] = slot
	end

	-- Details of the highlighted profession, on a dark plate under the wheel.
	self.infoText = root:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.infoText:SetPoint("TOP", root, "BOTTOM", 0, -10)
	self.infoText:SetJustifyH("CENTER")
	self.infoText:SetSpacing(3)
	self.infoBg = root:CreateTexture(nil, "BACKGROUND", nil, -1)
	self.infoBg:SetColorTexture(0, 0, 0, 0.6)
	self.infoBg:SetPoint("TOPLEFT", self.infoText, "TOPLEFT", -10, 5)
	self.infoBg:SetPoint("BOTTOMRIGHT", self.infoText, "BOTTOMRIGHT", 10, -5)

	self.hint = root:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	self.hint:SetPoint("TOP", self.infoText, "BOTTOM", 0, -10)
	self.hint:SetText(L.WHEEL_HINT)
	return self
end

-- Sizes everything for a wheel diameter, icon scale and slot count.
function View:Layout(size, iconScale, showLabels, count)
	local slotSize = math.floor(size * 0.27 * iconScale + 0.5)
	slotSize = math.max(34, math.min(slotSize, math.floor(size * 0.32)))
	local radius = size / 2 - slotSize / 2 - size * 0.06
	self.size, self.slotSize, self.radius, self.count = size, slotSize, radius, count
	self.deadZone = math.floor(size * 0.17)

	self.root:SetSize(size, size)
	local hub = math.floor(size * 0.18)
	self.hub:SetSize(hub, hub)
	self.hubGlow:SetSize(hub * 1.8, hub * 1.8)

	local sector = 360 / math.max(count, 1)
	for i = 1, WheelMath.MAX_SLOTS do
		local spoke, star = self.spokes[i], self.stars[i]
		if i <= count then
			-- The spoke art is a horizontal bar spanning 90% of a square texture;
			-- it runs from the center to the slot, under both.
			local len = radius / 0.9
			local x, y = WheelMath.SlotOffset(i, count, radius / 2)
			spoke:SetSize(len, len)
			spoke:ClearAllPoints()
			spoke:SetPoint("CENTER", self.root, "CENTER", x, y)
			spoke:SetRotation(math.rad(90 - (i - 1) * sector))
			spoke:Show()
			local starAngle = math.rad((i - 0.5) * sector)
			local starRadius = radius + slotSize * 0.05
			star:SetSize(slotSize * 0.34, slotSize * 0.34)
			star:ClearAllPoints()
			star:SetPoint("CENTER", self.root, "CENTER", starRadius * math.sin(starAngle), starRadius * math.cos(starAngle))
			star:SetShown(count > 1)
		else
			spoke:Hide()
			star:Hide()
		end
	end

	for i, slot in ipairs(self.slots) do
		if i <= count then
			local x, y = WheelMath.SlotOffset(i, count, radius)
			slot:SetSize(slotSize, slotSize)
			slot:ClearAllPoints()
			slot:SetPoint("CENTER", self.root, "CENTER", x, y)
			slot.glow:SetSize(slotSize * 1.5, slotSize * 1.5)
			slot.base:SetSize(slotSize * 0.88, slotSize * 0.88)
			slot.icon:SetSize(slotSize * 0.84, slotSize * 0.84)
			slot.gameIcon:SetSize(slotSize * 0.8, slotSize * 0.8)
			slot.label:ClearAllPoints()
			slot.label:SetWidth(slotSize + 40)
			if y < -radius * 0.7 then
				slot.label:SetPoint("BOTTOM", slot, "TOP", 0, 1)
			else
				slot.label:SetPoint("TOP", slot, "BOTTOM", 0, -1)
			end
			slot.label:SetShown(showLabels)
			slot:Show()
		else
			slot:Hide()
		end
	end
end

-- Fills the slots from profession entries (see Professions.Build).
function View:Refresh(entries, gameIcons)
	self.entries = entries
	for i, slot in ipairs(self.slots) do
		local entry = entries[i]
		slot.entry = entry
		if entry then
			local path, painted = Art.IconFor(entry, gameIcons)
			slot.icon:SetShown(painted)
			slot.gameIcon:SetShown(not painted)
			local tex = painted and slot.icon or slot.gameIcon
			tex:SetTexture(path)
			local usable = entry.primary ~= nil
			tex:SetDesaturated(not usable)
			local shade = usable and 1 or 0.55
			tex:SetVertexColor(shade, shade, shade, 1)
			slot.label:SetText(entry.name)
			slot.label:SetTextColor(usable and 0.95 or 0.55, usable and 0.9 or 0.55, usable and 0.78 or 0.55)
			local trackingOn = Professions.IsTrackingActive(entry.primary) or Professions.IsTrackingActive(entry.secondary)
			slot.frameTint = (trackingOn and FRAME_TRACKING) or (usable and FRAME_NORMAL) or FRAME_UNUSABLE
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

-- Highlights one slot (or none) and updates the details under the wheel.
function View:SetHighlight(index)
	self.highlight = index
	for i, slot in ipairs(self.slots) do
		local on = i == index
		slot.glow:SetShown(on)
		if slot.entry then
			Tint(slot.frame, on and FRAME_SELECTED or slot.frameTint or FRAME_NORMAL)
		end
	end
	self.hubGlow:SetAlpha(index and 0.75 or 0.45)
	local entry = index and self.entries[index]
	if not entry then
		self.infoText:SetText("|cffbfb39a" .. L.CHOOSE .. "|r")
		return
	end
	local head = "|cffffd200" .. entry.name .. "|r"
	if entry.maxRank and entry.maxRank > 0 then
		head = head .. "   |cffbfb39a" .. L.SKILL:format(entry.rank or 0, entry.maxRank) .. "|r"
	end
	local lines = { head }
	if entry.primary then
		local actions = L.LEFT_CLICK:format(DescribeAction(entry.primary))
		if entry.secondary then
			actions = actions .. "     " .. L.RIGHT_CLICK:format(DescribeAction(entry.secondary))
		end
		lines[#lines + 1] = actions
	else
		lines[#lines + 1] = "|cff999999" .. L.NOTHING_TO_USE .. "|r"
	end
	self.infoText:SetText(table.concat(lines, "\n"))
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
	-- Extra margin keeps the details and hint under the wheel on screen.
	cx, cy = WheelMath.ClampCenter(cx, cy, db.wheelSize / 2 + 64, w, h)
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
	view:Refresh(entries, db.gameIcons)
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
