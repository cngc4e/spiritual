TsmRotation = {}

local LOBBY_MAPCODE = 7740307
local custom_map
local custom_mode

local is_awaiting_lobby
local awaiting_mapcode
local awaiting_diff
local awaiting_mode

local chosen_mode
local preferred_diff_range
local chosen_mods

local choose_map = function(mode, diff)
    local mapcodes = TsmModuleData.getMapcodesByDiff(mode, diff)
    return mapcodes[math.random(#mapcodes)]
end

TsmRotation.overrideMap = function(mapcode)
    custom_map = int_mapcode(mapcode)
end

TsmRotation.overrideMode = function(mode)
    custom_mode = mode
end

TsmRotation.setMode = function(mode)
    chosen_mode = mode
end

TsmRotation.setDiffRange = function(lower, upper)
    if not upper then
        upper = lower
    end
    preferred_diff_range = {lower, upper}
end

TsmRotation.setMods = function(mods)
    chosen_mods = mods
end

TsmRotation.doLobby = function()
    is_awaiting_lobby = true
    map_sched.load(LOBBY_MAPCODE)
end

--[[
    signal newGame.
    status => false if current map is unexpected, will auto reload.
    return status (bool), fields (table)
    fields:
        - is_lobby
        - difficulty
        - mode
        - is_custom_load
]]--
TsmRotation.signalNgAndRead = function()
    local mapcode = int_mapcode(room.currentMap)

    if is_awaiting_lobby then
        if mapcode ~= LOBBY_MAPCODE then
            map_sched.load(LOBBY_MAPCODE)
            return false
        end
    elseif awaiting_mapcode == nil then
        TsmRotation.doLobby()
        return false
    elseif awaiting_mapcode ~= mapcode then
        map_sched.load(awaiting_mapcode)
        return false
    end

    local ret = {}
    ret.is_lobby = is_awaiting_lobby
    ret.mods = chosen_mods

    if not is_awaiting_lobby then
        ret.difficulty = awaiting_diff
        ret.mode = awaiting_mode
        ret.is_custom_load = custom_map ~= nil
        ret.mods = chosen_mods

        custom_map = nil
        custom_mode = nil
    end

    is_awaiting_lobby = nil
    awaiting_mapcode = nil
    awaiting_diff = nil
    chosen_mode = nil
    preferred_diff_range = nil
    chosen_mods = nil

    return true, ret
end

TsmRotation.doRotate = function()
    if not MDHelper.getMdLoaded() then
        print("module data hasn't been loaded, retrying...")
        TimedTask.add(1000, TsmRotation.doRotate)
        return
    end

    local map
    local mode = custom_mode or chosen_mode or TSM_HARD
    if custom_map then
        map = custom_map
        awaiting_diff = 0
    else
        local diff = math.random(preferred_diff_range[1], preferred_diff_range[2])
        map = choose_map(mode, diff)
        awaiting_diff = diff
    end
    awaiting_mapcode = map
    awaiting_mode = mode
    map_sched.load(map)
end
