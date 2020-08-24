@include libs/PairTable.lua
@include libs/bitset.lua
@include libs/boolset.lua
@include libs/db2.lua
@include libs/XMLParse.lua

local DEFAULT_MAX_PLAYERS = 50

-- Init extension
local init_ext = nil
local postinit_ext = nil

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
@include helpers/MDHelper.lua
@include helpers/PDHelper.lua
@include helpers/TimedTask.lua
@include helpers/Events.lua

@include module/Common.lua
@include module/Commands.lua
@include module/Keys.lua
@include module/Callbacks.lua
@include module/Events.lua
@include module/Player.lua

do
    @tsminclude module/shamteam/Tsm.lua
end

@spinclude module/spiritual/SpCommon.lua
@spinclude module/spiritual/SpPlayer.lua
@spinclude module/spiritual/SpModuleData.lua
@spinclude module/spiritual/SpRound.lua
@spinclude module/spiritual/SpCommands.lua
@spinclude module/spiritual/SpKeys.lua
@spinclude module/spiritual/SpEvents.lua

@divinclude module/divinity/DivCommon.lua
@divinclude module/divinity/DivCommands.lua
@divinclude module/divinity/DivKeys.lua
@divinclude module/divinity/DivPlayer.lua
@divinclude module/divinity/DivRound.lua
@divinclude module/divinity/DivEvents.lua

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
    TimedTask.onLoop()
    Events.doEvent("Loop", elapsed, remaining)  
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
    pL.room:add(pn)
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

function eventSummoningStart(pn, type, xPos, yPos, angle)
    Events.doEvent("SummoningStart", pn, type, xPos, yPos, angle)
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

function eventFileLoaded(file, data)
    Events.doEvent("FileLoaded", file, data)
end

function eventFileSaved(file)
    Events.doEvent("FileSaved", file)
end

function eventPlayerDataLoaded(pn, data)
    Events.doEvent("PlayerDataLoaded", pn, data)
end

local init = function()
    print("Module is starting...")

    @spinclude module/spiritual/init_ext.lua
    @divinclude module/divinity/init_ext.lua

    if type(init_ext) == "function" then
        init_ext()
    end

    for name in pairs(room.playerList) do eventNewPlayer(name) end
    tfm.exec.setRoomMaxPlayers(DEFAULT_MAX_PLAYERS)
    tfm.exec.setRoomPassword("")

    if type(postinit_ext) == "function" then
        postinit_ext()
    end
end

init()
debug.disableEventLog(true)
