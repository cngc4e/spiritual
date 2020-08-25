@include module/IRound.lua

-- int difficulty
-- SpCommon.Phase phase
do
    SpRound = setmetatable({}, IRound)
    SpRound.__index = SpRound

    SpRound.parseXMLObj = function(self, xmlobj)
        IRound.parseXMLObj(self, xmlobj)
        local xo_prop = xmlobj:traverse_first("P").attrib
        if xo_prop.P then
            self.portals = true
        end
        if xo_prop.NOB then
            self.no_b = true
        end
    end

    SpRound.onNew = function(self)
        IRound.onNew(self)

        local dbmap = SpModuleData.getMapInfo(self.mapcode)
        self.difficulty = dbmap and dbmap.difficulty or -1

        self.phase = SpCommon.PHASE_READY
    end

    SpRound.onEnd = function(self)
        self.phase = SpCommon.PHASE_TIMESUP
        IRound.onEnd(self)
        
        -- add map completion, player xp, etc
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
