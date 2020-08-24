@include libs/PairTable.lua
@include libs/bitset.lua

-- Module variables
local translations = {}
local players = {}  -- Players[]

@include translations-gen/*.lua

-- Cached variable lookups
local room = tfm.get.room

-- Keeps an accurate list of players and their states by rely on asynchronous events to update
-- This works around playerList issues which are caused by it relying on sync and can be slow to update
local pL = {}
do
    local states = {
        "room",
        "alive",
        "dead",
        "spectator"
    }
    for i = 1, #states do
        pL[states[i]] = PairTable:new()
    end
end

----- ENUMS / CONST DEFINES

-- Key trigger types
local DOWN_ONLY = 1
local UP_ONLY = 2
local DOWN_UP = 3

-- Others
local DEVS = {["Cass11337#8417"]=true, ["Casserole#1798"]=true}

----- Forward declarations (local)
local keys, callbacks

----- GENERAL UTILS
local function math_round(num, dp)
    local mult = 10 ^ (dp or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function string_split(str, delimiter)
    local delimiter,a = delimiter or ',', {}
    for part in str:gmatch('[^'..delimiter..']+') do
        a[#a+1] = part
    end
    return a
end

local function table_copy(tbl)
    local out = {}
    for k, v in next, tbl do
        out[k] = v
    end
    return out
end

local function dumptbl (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            dumptbl(v, indent+1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

-- returns map code in integer type, nil if invalid
local function int_mapcode(code)
    if type(code) == "string" then
        return tonumber(code:match("@?(%d+)"))
    elseif type(code) == "number" then
        return code
    else
        return nil
    end
end

local function tl(kname, pn)
    local pref_lang = players[pn] and players[pn].lang or "en"
    local lang = translations[pref_lang] and pref_lang or "en"
    if translations[lang][kname] then
        return translations[lang][kname]
    else
        return kname
    end
end

local function ZeroTag(pn, add) --#0000 removed for tag matches
    if add then
        if not pn:find('#') then
            return pn.."#0000"
        else return pn
        end
    else
        return pn:find('#0000') and pn:sub(1,-6) or pn
    end
end

local function pFind(target, pn)
    local ign = string.lower(target or ' ')
    for name in pairs(room.playerList) do
        if string.lower(name):find(ign) then return name end
    end
    if pn then tfm.exec.chatMessage("<R>error: no such target", pn) end
end

local function pythag(x1, y1, x2, y2, r)
	local x,y,r = x2-x1, y2-y1, r+r
	return x*x+y*y<r*r
end

----- HELPERS
@include helpers/map_sched.lua
@include helpers/tfmcmd.lua

-- init commands
@include module/commands.lua

@include module/keys.lua

@include module/SpPlayer.lua

@include module/SpEvents.lua

callbacks = {}

----- EVENTS
function eventChatCommand(pn, msg)
    local ret, msg = tfmcmd.executeChatCommand(pn, msg)
    if ret ~= tfmcmd.OK then
        local default_msgs = {
            [tfmcmd.ENOCMD] = "no command found",
            [tfmcmd.EPERM] = "no permission",
            [tfmcmd.EMISSING] = "missing argument",
            [tfmcmd.EINVAL] = "invalid argument"
        }
        msg = msg or default_msgs[ret]
        tfm.exec.chatMessage("<R>error" .. (msg and (": "..msg) or ""), pn)
    end
end

function eventKeyboard(pn, k, d, x, y)
    if keys[k] then
        keys[k].func(pn, d, x, y)
    end
end

function eventLoop(elapsed, remaining)
    map_sched.run()
    SpEvents.Loop(elapsed, remaining)  
end

function eventMouse(pn, x, y)
    if not players[pn] then
        return
    end
    if players[pn].pos then  -- Debugging function
        tfm.exec.chatMessage("<J>X: "..x.."  Y: "..y, pn)
    end
end

function eventNewGame()
    pL.dead = PairTable:new()
    pL.alive = PairTable:new(pL.room)

    for name in pL.spectator:pairs() do
        tfm.exec.killPlayer(name)
        tfm.exec.setPlayerScore(name, -5)
    end

    SpEvents.NewGame()
end

function eventNewPlayer(pn)
    SpEvents.NewPlayer(pn)
    pL.dead:add(pn)
end

function eventPlayerDied(pn)
    pL.alive:remove(pn)
    pL.dead:add(pn)
end

function eventPlayerWon(pn, elapsed)
    pL.alive:remove(pn)
    pL.dead:add(pn)
end

function eventPlayerLeft(pn)
    pL.room:remove(pn)
    if pL.spectator[pn] then
        pL.spectator:remove(pn)
    end
    SpEvents.PlayerLeft(pn)
end

function eventPlayerRespawn(pn)
    pL.dead:remove(pn)
    pL.alive:add(pn)
end

function eventSummoningEnd(pn, type, xPos, yPos, angle, desc)
    SpEvents.SummoningEnd(pn, type, xPos, yPos, angle, desc)
end

function eventTextAreaCallback(id, pn, cb)
    local params = {}
    if cb:find('!') then 
        params = string_split(cb:match('!(.*)'), '&')
        cb = cb:match('(%w+)!')
    end
    -- It is possible for players to alter callback strings
    local success, result = pcall(callbacks[cb], pn, table.unpack(params))
    if not success then
        print(string.format("Exception encountered in eventTextAreaCallback (%s): %s", pn, result))
    end
end

local init = function()
    print("Module is starting...")
    for _,v in ipairs({'AllShamanSkills','AutoNewGame','AutoScore','AutoTimeLeft','PhysicalConsumables'}) do
        tfm.exec['disable'..v](true)
    end
    system.disableChatCommandDisplay(nil,true)
    for name in pairs(room.playerList) do eventNewPlayer(name) end
    tfm.exec.setRoomMaxPlayers(DEFAULT_MAX_PLAYERS)
    tfm.exec.setRoomPassword("")
end

init()
debug.disableEventLog(true)
