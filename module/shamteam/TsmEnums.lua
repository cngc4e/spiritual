
--- Module
local MODULE_ID = 3
local MODULE_ROOMNAME = "shamteam"

--- Round phases
local PHASE_START = 0
local PHASE_READY = 1
local PHASE_MORTED = 2
local PHASE_TIMESUP = 3

--- Modes
local TSM_HARD = 1
local TSM_DIV = 2

--- Staff
local MODULE_MANAGERS = {
    ["Emeryaurora#0000"] = true,
    ["Pegasusflyer#0000"] = true,
    ["Rini#5475"] = true,
    ["Rayallan#0000"] = true,
    ["Shibbbbbyy#1143"] = true
}

--- Windows
local WINDOW_GUI = bit32.lshift(0, 7)
local WINDOW_HELP = bit32.lshift(1, 7)
local WINDOW_LOBBY = bit32.lshift(2, 7)
local WINDOW_OPTIONS = bit32.lshift(3, 7)
local WINDOW_DB_MAP = bit32.lshift(4, 7)
local WINDOW_DB_HISTORY = bit32.lshift(5, 7)

--- TextAreas
local TA_SPECTATING = 9000

--- GUI color defs
local GUI_BTN = "<font color='#EDCC8D'>"

--- Images
local IMG_FEATHER_HARD = "172e1332b11.png" -- hard feather 30px width
local IMG_FEATHER_DIVINE = "172e14b438a.png" -- divine feather 30px width
local IMG_FEATHER_HARD_DISABLED = "172ed052b25.png"
local IMG_FEATHER_DIVINE_DISABLED = "172ed050e45.png"
local IMG_TOGGLE_ON = "172e5c315f1.png" -- 30px width
local IMG_TOGGLE_OFF = "172e5c335e7.png" -- 30px width
local IMG_LOBBY_BG = "172e68f8d24.png"
local IMG_HELP = "172e72750d9.png" -- 18px width
local IMG_OPTIONS_BG = "172eb766bdd.png" -- 240 x 325
local IMG_RANGE_CIRCLE = "172ef5c1de4.png" -- 240 x 240

-- Link IDs
local LINK_DISCORD = 1

-- AntiLag ping (ms) thresholds
local ANTILAG_WARN_THRESHOLD = 690
local ANTILAG_FORCE_THRESHOLD = 1100

--- MODS
local MOD_TELEPATHY = 1
local MOD_WORK_FAST = 2
local MOD_BUTTER_FINGERS = 3
local MOD_SNAIL_NAIL = 4

-- {name (localisation key), multiplier, description (localisation key)}
local MODS = {
    [MOD_TELEPATHY] = {"Telepathic Communication", 0.5, "Disables prespawn preview. You won't be able to see what and where your partner is trying to spawn."},
    [MOD_WORK_FAST] = {"We Work Fast!", 0.3, "Reduces building time limit by 60 seconds. For the quick hands."},
    [MOD_BUTTER_FINGERS] = {"Butter Fingers", -0.5, "Allows you and your partner to undo your last spawned object by pressing U up to two times."},
    [MOD_SNAIL_NAIL] = {"Snail Nail", -0.5, "Increases building time limit by 30 seconds. More time for our nails to arrive."},
}

--- OPTIONS
local OPT_ANTILAG = 1
local OPT_GUI = 2
local OPT_CIRCLE = 3
local OPT_LANGUAGE = 4

-- {name (localisation key), description (localisation key)}
local OPTIONS = {
    [OPT_ANTILAG] = {"AntiLag", "Attempt to minimise impacts on buildings caused by delayed anchor spawning during high latency."},
    [OPT_GUI] = {"Show GUI", "Whether to show or hide the help menu, player settings and profile buttons on-screen."},
    [OPT_CIRCLE] = {"Show partner's range", "Toggles an orange circle that shows the spawning range of your partner in Team Hard Mode."},
}
