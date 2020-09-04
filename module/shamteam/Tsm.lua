
-- Module variables
local is_official_room = false
local module_started = false
local ThisRound = nil

local TsmRound
local TsmModuleData
local TsmPlayer
local TsmRotation
local TsmWindow

@include module/shamteam/TsmEnums.lua
@include module/shamteam/TsmCommon.lua
@includescp translations-gen-shamteam/*.lua

@includescp module/shamteam/TsmPlayer.lua
@includescp module/shamteam/TsmModuleData.lua
@includescp module/shamteam/TsmRound.lua
@includescp module/shamteam/TsmCommands.lua
@includescp module/shamteam/TsmKeys.lua
@includescp module/shamteam/TsmCallbacks.lua
@includescp module/shamteam/TsmEvents.lua
@includescp module/shamteam/TsmRotation.lua
@includescp module/shamteam/TsmWindow.lua
@includescp module/shamteam/TsmInit.lua
