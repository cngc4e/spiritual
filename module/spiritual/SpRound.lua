@include module/IRound.lua

-- int difficulty
-- SpCommon.Phase phase

local SpRound
do
    SpRound = setmetatable({}, IRound)
    SpRound.__index = SpRound

    SpRound.parseXMLObj = function(self, xmlobj)
        IRound.parseXMLObj(self, xmlobj)

    end

    SpRound.onNew = function(self)
        IRound.onNew(self)
        self.difficulty = -1

        self.phase = SpCommon.PHASE_READY
    end

    SpRound.onEnd = function(self)
        IRound.onEnd(self)
        self.phase = SpCommon.PHASE_TIMESUP
    end

    SpRound.isReady = function(self)
        return self.phase >= SpCommon.PHASE_READY
    end

    SpRound.new = function(_)
        return setmetatable({
            phase = SpCommon.PHASE_START
        }, SpRound)
    end
end

local ThisRound = SpRound:new()
