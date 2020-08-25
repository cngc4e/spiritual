@include libs/PairTable.lua
@include libs/bitset.lua

-- Module variables
local translations = {}
local players = {}  -- Players[]

@spinclude translations-gen-spiritual/*.lua
@divinclude translations-gen-divinity/*.lua

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
@include module/utils.lua

----- HELPERS
@include helpers/map_sched.lua
@include helpers/tfmcmd.lua

@include module/Commands.lua
@include module/Keys.lua
@include module/Events.lua

@spinclude module/spiritual/SpCommon.lua
@spinclude module/spiritual/SpCommands.lua
@spinclude module/spiritual/SpKeys.lua
@spinclude module/spiritual/SpPlayer.lua
@spinclude module/spiritual/SpEvents.lua

@divinclude module/divinity/DivCommon.lua
@divinclude module/divinity/DivCommands.lua
@divinclude module/divinity/DivKeys.lua
@divinclude module/divinity/DivPlayer.lua
@divinclude module/divinity/DivEvents.lua

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
    Events.doEvent("Loop", elapsed, remaining)  
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

    Events.doEvent("NewGame")
end

function eventNewPlayer(pn)
    pL.dead:add(pn)
    for key, a in pairs(keys) do
        if a.trigger == DOWN_ONLY then
            system.bindKeyboard(pn, key, true)
        elseif a.trigger == UP_ONLY then
            system.bindKeyboard(pn, key, false)
        elseif a.trigger == DOWN_UP then
            system.bindKeyboard(pn, key, true)
            system.bindKeyboard(pn, key, false)
        end
    end
    Events.doEvent("NewPlayer", pn)
end

function eventPlayerDied(pn)
    pL.alive:remove(pn)
    pL.dead:add(pn)
    Events.doEvent("PlayerDied", pn)
end

function eventPlayerWon(pn, elapsed)
    pL.alive:remove(pn)
    pL.dead:add(pn)
    Events.doEvent("PlayerWon", pn)
end

function eventPlayerLeft(pn)
    pL.room:remove(pn)
    if pL.spectator[pn] then
        pL.spectator:remove(pn)
    end
    Events.doEvent("PlayerLeft", pn)
end

function eventPlayerRespawn(pn)
    pL.dead:remove(pn)
    pL.alive:add(pn)
end

function eventSummoningEnd(pn, type, xPos, yPos, angle, desc)
    Events.doEvent("SummoningEnd", pn, type, xPos, yPos, angle, desc)
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
