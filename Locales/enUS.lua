-- English strings. This is also the fallback for every other locale.
local _, ns = ...

local L = {
	ADDON_TITLE = "[Elysium] ProfessionWheel",
	BINDING_OPEN = "Open ProfessionWheel",

	CHOOSE = "Choose a profession",
	NOTHING_TO_USE = "Nothing to use",
	SKILL = "Skill %d / %d",
	LEFT_CLICK = "Left-click: %s",
	RIGHT_CLICK = "Right-click: %s",
	TRACKING_ON = "%s (on)",
	TRACKING_OFF = "%s (off)",
	WHEEL_HINT = "Escape, the key again, or a click in the center: close",

	-- Chat feedback (kept short; never repeated rapidly).
	MSG_PREFIX = "ProfessionWheel:",
	MSG_COMBAT = "professions can't be used in combat.",
	MSG_NO_PROFESSIONS = "you haven't learned any professions yet.",
	MSG_NOTHING_TO_USE = "you have no professions with something to use. Skinning, for example, has no window.",
	MSG_TRACKING_BLOCKED = "the game blocked changing %s from an addon. Use the minimap tracking menu instead.",
	MSG_TRACKING_FAILED = "%s could not be changed right now.",
	MSG_RECOVERED = "your saved settings were unreadable and have been reset to defaults.",
	MSG_NO_SLASH = "both /professionwheel and /pwheel are used by another addon. Open ProfessionWheel from Options > AddOns.",
	MSG_SLASH_PARTIAL = "%s is used by another addon; use %s instead.",
	MSG_COMBAT_SETTINGS = "that can't be opened in combat. It will open when combat ends.",
	MSG_TIP = "type /pwheel for options.",
	MSG_TIP_BIND = "bind a key under Options > Keybindings > AddOns > Open ProfessionWheel. Type /pwheel for options.",
	MSG_NO_BINDING = "no key is bound yet. Set one in Options > Keybindings > AddOns > Open ProfessionWheel.",
	MSG_STATUS_HEADER = "detected professions:",
	MSG_STATUS_NONE = "  none",
	MSG_STATUS_LINE = "  %d. %s (%s) - left: %s, right: %s%s",
	MSG_STATUS_HIDDEN = " [hidden]",
	MSG_STATUS_NOTHING = "nothing",

	-- Configuration window.
	CONFIG_TITLE = "[Elysium] ProfessionWheel",
	WHEEL_SIZE = "Wheel size",
	ICON_SCALE = "Icon scale",
	SHOW_LABELS = "Show names",
	SHOW_INACTIVE = "Show professions with nothing to use (Skinning)",
	GAME_ICONS = "Use the game's profession icons instead of the painted ones",
	POSITION = "Open at:",
	POSITION_CURSOR = "Cursor",
	POSITION_SCREEN = "Screen center",
	KEYBINDINGS = "Key Bindings",
	CURRENT_KEY = "Key: %s",
	NOT_BOUND = "not bound",
	RESTORE_DEFAULTS = "Restore defaults",
	RESTORE_CONFIRM = "Restore ProfessionWheel's default settings?",
	CONFIG_HOWTO = "Press your key to open the wheel, point toward a profession and left-click. Mining's right-click toggles Find Minerals; Enchanting's right-click is Disenchant. The wheel always shows your current professions.",

	-- Options > AddOns page.
	SETTINGS_DESC = "A wheel of your current professions, opened with one key. It works out of combat only, like professions themselves.",
	SETTINGS_OPEN = "Open ProfessionWheel options",
	UNOFFICIAL = "ProfessionWheel is an unofficial community addon. Blizzard Entertainment did not make or endorse it.",
}

ns.L = L

-- Key Bindings label (global name required by the client).
BINDING_NAME_PROFESSIONWHEEL_OPEN = L.BINDING_OPEN
