@include module/IRound.lua

-- int difficulty
-- TsmEnums.Phase phase
do
    TsmRound = setmetatable({}, IRound)
    TsmRound.__index = TsmRound

    local getShamans = function()
        local shams = {}
        for name, p in pairs(room.playerList) do
            if p.isShaman then
                shams[#shams + 1] = name
            end
        end
        return shams
    end

    TsmRound.parseXMLObj = function(self, xmlobj)
        IRound.parseXMLObj(self, xmlobj)
        local xo_prop = xmlobj:traverse_first("P").attrib
        if xo_prop.P then
            self.portals = true
        end
        if xo_prop.NOBALLOON then
            self.no_balloon = true
        end
        if xo_prop.OPPORTUNIST then
            self.opportunist = true
        end
        if xo_prop.SEPARATESHAM then
            self.seperate_sham = true
        end
        if xo_prop.ORIGINALAUTHOR then
            self.original_author = xo_prop.ORIGINALAUTHOR
        end
    end

    TsmRound.onNew = function(self)
        IRound.onNew(self)

        local dbmap = TsmModuleData.getMapInfo(self.mapcode)
        local key = {[TSM_HARD] = "difficulty_hard", [TSM_HARD] = "difficulty_divine"}
        self.difficulty = dbmap and dbmap[key[self.mode]] or -1
        self.shamans = getShamans()
        self.mods = boolset:new()
    
        self.phase = PHASE_READY
    end

    TsmRound.onLobby = function(self)
        self.shamans = getShamans()
    end

    TsmRound.onEnd = function(self)
        self.phase = PHASE_TIMESUP
        IRound.onEnd(self)
        
        if self.is_lobby then
            TsmRotation.setDiffRange(1, 5)
        else
            -- add map completion, player xp, etc
        end
    end

    TsmRound.isReady = function(self)
        return self.phase >= PHASE_READY
    end

    TsmRound.new = function(_, vars)
        vars = vars or {}
        vars.phase = PHASE_START
        return setmetatable(vars, TsmRound)
    end
end

ThisRound = TsmRound:new()
