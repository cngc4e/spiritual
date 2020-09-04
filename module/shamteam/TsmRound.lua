@include module/IRound.lua

-- int difficulty
-- TsmEnums.Phase phase
do
    TsmRound = setmetatable({}, IRound)
    TsmRound.__index = TsmRound

    local getShamans = function()
        local shams, shams_key = {}, {}
        for name, p in pairs(room.playerList) do
            if p.isShaman then
                shams[#shams + 1] = name
                shams_key[name] = true
            end
        end
        return shams, shams_key
    end

    local showMapInfo = function()
        for name, player in pairs(players) do
            local shamanstr = pnDisp(ThisRound.shamans[1])
            if ThisRound.shamans[2] then
                shamanstr = shamanstr .. " - " .. pnDisp(ThisRound.shamans[2])
            end
            local t_str = {
                player:tlFmt("map_info", ThisRound.mapcode, ThisRound.original_author or ThisRound.author, ThisRound.difficulty,
                        ThisRound.mode == TSM_HARD and player:tlFmt("hard") or player:tlFmt("divine")),
                player:tlFmt("shaman_info", shamanstr)
            }
            local propstr = player:tlFmt("windgrav_info", ThisRound.wind, ThisRound.gravity)
            local props = { }
            if ThisRound.portals then
                props[#props+1] = player:tlFmt("portals")
            end
            if ThisRound.no_balloon then
                props[#props+1] = player:tlFmt("no_balloon")
            end
            if ThisRound.opportunist then
                props[#props+1] = player:tlFmt("opportunist")
            end
            if #props > 0 then
                propstr = propstr .. " <G>| <VP>" .. table.concat(props, " <G>| <VP>")
            end
            t_str[#t_str+1] = propstr
            player:chatMsg(table.concat(t_str, "\n"))
        end
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
        -- Init data
        IRound.onNew(self)

        local dbmap = TsmModuleData.getMapInfo(self.mapcode)
        local key = {[TSM_HARD] = "difficulty_hard", [TSM_HARD] = "difficulty_divine"}
        self.difficulty = dbmap and dbmap[key[self.mode]] or -1
        self.shamans, self.shamans_key = getShamans()
        self.mods = boolset:new()

        -- Hide GUI for shamans
        for i = 1, #self.shamans do
            local name = self.shamans[i]
            TsmWindow.close(WINDOW_GUI, name)
        end

        showMapInfo()

        tfm.exec.disableAfkDeath(false)
        tfm.exec.disableMortCommand(false)
        tfm.exec.disablePrespawnPreview(self.mods[MOD_TELEPATHY] == true)
    
        -- All set up and ready to go!
        self.phase = PHASE_READY
    end

    TsmRound.onLobby = function(self)
        self.shamans, self.shamans_key = getShamans()

        tfm.exec.disableAfkDeath(true)
        tfm.exec.disableMortCommand(true)
        tfm.exec.disablePrespawnPreview(false)
    end

    TsmRound.onEnd = function(self)
        self.phase = PHASE_TIMESUP
        IRound.onEnd(self)

        if self.is_lobby then
            TsmRotation.setDiffRange(1, 5)
            TsmRotation.doRotate()
        else
            -- Show back GUI for shamans
            for i = 1, #self.shamans do
                local name = self.shamans[i]
                if players[name]:isToggleSet(OPT_GUI) then
                    TsmWindow.open(WINDOW_GUI, name)
                end
            end
            -- add map completion, player xp, etc
            TsmRotation.doLobby()
        end
    end

    TsmRound.isReady = function(self)
        return self.phase >= PHASE_READY
    end

    TsmRound.isShaman = function(self, pn)
        return self.shamans_key[pn] == true
    end

    TsmRound.new = function(_, vars)
        vars = vars or {}
        vars.phase = PHASE_START
        return setmetatable(vars, TsmRound)
    end
end

ThisRound = TsmRound:new()
