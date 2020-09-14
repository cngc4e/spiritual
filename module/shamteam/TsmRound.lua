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

    local showMapInfo = function(self)
        for name, player in pairs(players) do
            local shamanstr = pnDisp(self.shamans[1])
            if self.shamans[2] then
                shamanstr = shamanstr .. " - " .. pnDisp(self.shamans[2])
            end
            local t_str = {
                player:tlFmt("map_info", self.mapcode, self.original_author or self.author, self.difficulty,
                self.mode == TSM_HARD and player:tlFmt("hard") or player:tlFmt("divine")),
                player:tlFmt("shaman_info", shamanstr)
            }

            local propstr = player:tlFmt("windgrav_info", self.wind, self.gravity)
            local props = { }
            if self.portals then
                props[#props+1] = player:tlFmt("portals")
            end
            if self.no_balloon then
                props[#props+1] = player:tlFmt("no_balloon")
            end
            if self.opportunist then
                props[#props+1] = player:tlFmt("opportunist")
            end
            if #props > 0 then
                propstr = propstr .. " <G>| <VP>" .. table.concat(props, " <G>| <VP>")
            end
            t_str[#t_str+1] = propstr

            local mods = { }
            for k, mod in pairs(GAME_MODS) do
                if self.mods[k] then
                    mods[#mods+1] = player:tlFmt(mod[1])
                end
            end
            if #mods > 0 then
                t_str[#t_str+1] = string.format("<ROSE>%s: <N>%s", player:tlFmt("mods"), table.concat(mods, ", "))
            end

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
        local key = {[TSM_HARD] = "difficulty_hard", [TSM_DIV] = "difficulty_divine"}
        self.difficulty = dbmap and dbmap[key[self.mode]] or -1
    
        self.shamans, self.shamans_key = getShamans()
        self.st_index = 1  -- current shaman's turn, index of self.shamans
        self.arrow_count = 0
        self.sballoon_count = 0
        self.spawnlist = {}

        for i = 1, #self.shamans do
            local name = self.shamans[i]
            -- Hide GUI for shamans
            TsmWindow.close(WINDOW_GUI, name)
            -- Lower sync delay to 400ms max for more accurate shaman positions
            tfm.exec.lowerSyncDelay(name)
            -- Set shaman mode
            self:setCorrectShamanMode(name)
            -- Init spawnlist
            self.spawnlist[name] = { _len = 0 }
        end

        showMapInfo(self)
        self:updateMapTitle()
        self:updateTurnUI()
        self:updateCircle()

        tfm.exec.disableAfkDeath(false)
        tfm.exec.disableMortCommand(false)
        tfm.exec.disablePrespawnPreview(self.mods[MOD_TELEPATHY] == true)

        local time_limit = self.mode == TSM_HARD and 200 or 180
        if self.mods[MOD_WORK_FAST] then
            time_limit = time_limit - 60
        end
        if self.mods[MOD_SNAIL_NAIL] then
            time_limit = time_limit + 30
        end
        tfm.exec.setGameTime(time_limit)
    
        -- All set up and ready to go!
        self.phase = PHASE_READY
    end

    TsmRound.onLobby = function(self)
        self.start_epoch = os.time()
        self.shamans, self.shamans_key = getShamans()
        self.chosen_mode = TSM_HARD
        self.chosen_diff = {1, 5}
        self.chosen_mods = boolset:new()
        self.shaman_ready = {false, false}

        TsmWindow.close(WINDOW_LOBBY, nil)
        TsmWindow.open(WINDOW_LOBBY, nil)

        tfm.exec.disableAfkDeath(true)
        tfm.exec.disableMortCommand(true)
        tfm.exec.disablePrespawnPreview(false)
        tfm.exec.setGameTime(30)

        -- Lobby all set!
        self.lobby_ready = true
    end

    TsmRound.onEnd = function(self)
        self.phase = PHASE_TIMESUP
        IRound.onEnd(self)

        if self.is_lobby then
            TsmWindow.close(WINDOW_LOBBY, nil)
            TsmRotation.setDiffRange(self.chosen_diff[1], self.chosen_diff[2])
            TsmRotation.setMode(self.chosen_mode)
            TsmRotation.setMods(self.chosen_mods)
            TsmRotation.doRotate()
        else
            -- Show back GUI for shamans
            for i = 1, #self.shamans do
                local name = self.shamans[i]
                if players[name] and players[name].toggles[OPT_GUI] then
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

    TsmRound.isCurrentTurn = function(self, pn)
        return self:isReady() and self.shamans[self.st_index] == pn
    end

    TsmRound.getCurrentTurnShaman = function(self)
        return self.shamans[self.st_index]
    end

    TsmRound.getNextTurnShaman = function(self)
        local nidx = self.st_index + 1
        if nidx > #self.shamans then
            nidx = 1
        end
        return self.shamans[nidx]
    end

    TsmRound.passShamanTurn = function(self)
        local nidx = self.st_index + 1
        if nidx > #self.shamans then
            nidx = 1
        end
        self.st_index = nidx
        self:updateTurnUI()
        self:updateCircle()
    end

    TsmRound.updateMapTitle = function(self)
        local t_mode = {
            [TSM_HARD]={"J", "THM"},
            [TSM_DIV]={"VI", "TDM"}
        }
        local mode_disp = t_mode[self.mode]
        ui.setMapName(string.format("<%s>[%s] <ROSE>Difficulty %s - <VP>@%s", mode_disp[1], mode_disp[2], self.difficulty, self.mapcode))
    end

    TsmRound.updateTurnUI = function(self)
        local color = "CH"
        local shaman = self:getCurrentTurnShaman()
        ui.setShamanName(string.format("<%s>%s's <J>Turn", color, pnDisp(shaman)))
    end

    TsmRound.updateCircle = function(self)
        for name, player in pairs(players) do
            player:updateCircle(self:getCurrentTurnShaman())
        end
    end

    TsmRound.setCorrectShamanMode = function(self, pn)
        tfm.exec.setShamanMode(pn, self.mode == TSM_HARD and 1 or 2)
    end

    -- Checks game rules and penalise/warn accordingly.
    -- Return true if shaman turn should pass, and spawnlist was updated.
    TsmRound.onSpawnCheck = function(self, pn, type, xPos, yPos, angle, desc)  
        if type == O_BTYPE_ARROW then
            if self.mode == TSM_DIV then
                -- TODO: points deduct for tdm
                self.arrow_count = self.arrow_count + 1
                for name, player in pairs(players) do
                    player:tlChatMsg("used_an_arrow", pnDisp(pn), self.arrow_count)
                end
                return false
            end
        end

        if not self:isCurrentTurn(pn) then
            tfm.exec.removeObject(desc.id)
            players[pn]:tlChatMsg("not_your_turn")
            -- TODO: points deduct
            return false
        end

        if self.mode ~= TSM_DIV and #self.shamans == 2 then
            local s1, s2 = room.playerList[self.shamans[1]], room.playerList[self.shamans[2]]
            if s1 and s2 and not math_pythag(s1.x, s1.y, s2.x, s2.y, THM_SPAWN_RANGE) then
                -- Not within range!
                tfm.exec.removeObject(desc.id)
                players[pn]:tlChatMsg("warn_self_range")
                local nextsham = self:getNextTurnShaman()
                if players[nextsham] then
                    players[nextsham]:tlChatMsg("warn_self_range")
                end
                return false
            end
        end

        if desc.baseType == O_BTYPE_BALLOON then
            if self.no_balloon then
                tfm.exec.removeObject(desc.id)
                return true
            elseif not desc.ghost then
                if self.sballoon_count >= MAX_SOLID_BALLOONS then
                    tfm.exec.removeObject(desc.id)
                    players[pn]:tlChatMsg("no_more_solid_balloon")
                    return true
                else
                    self.sballoon_count = self.sballoon_count + 1
                    for name, player in pairs(players) do
                        player:tlChatMsg("used_a_solid_balloon", pnDisp(pn), MAX_SOLID_BALLOONS - self.sballoon_count)
                    end
                end
            end
        end

        local sl = self.spawnlist[pn]
        sl._len = sl._len + 1
        sl[sl._len] = desc.id
        return true
    end

    TsmRound.getExpMult = function(self)
        local mods = self.is_lobby and self.chosen_mods or self.mods
        local ret = 0
        for k, mod in pairs(GAME_MODS) do
            if mods[k] then
                ret = ret + mod[2]
            end
        end
        if ret > 0.7 then
            ret = 0.7
        elseif ret < -0.7 then
            ret = -0.7
        end
        return ret
    end

    TsmRound.new = function(_, vars)
        vars = vars or {}
        vars.phase = PHASE_START
        return setmetatable(vars, TsmRound)
    end
end

ThisRound = TsmRound:new()
