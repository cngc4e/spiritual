do

    Events.hookEvent("NewPlayer", function(pn)
        local player = TsmPlayer:new(pn)
        players[pn] = player

        system.loadPlayerData(pn)

        player:tlChatMsg("welcome_message", MODULE_VERSION)

        if not is_official_room then
            player:tlChatMsg("tribehouse_mode_warning", MODULE_ROOMNAME)
        end

        tfm.exec.setPlayerScore(pn, 0)

        if player.toggles[OPT_GUI] then
            TsmWindow.open(WINDOW_GUI, pn)
        end

        if ThisRound.lobby_ready and ThisRound.phase < PHASE_TIMESUP then
            TsmWindow.open(WINDOW_LOBBY, pn)
        end

        if pL.room:len() == 2 and ThisRound.lobby_ready and module_started then
            -- reload lobby
            TsmRotation.doLobby()
        end
    end)

    Events.hookEvent("PlayerLeft", function(pn)
        local is_shaman = players[pn] and ThisRound.is_lobby and players[pn]:isRoundShaman()

        players[pn] = nil

        if is_shaman then
            for name, player in pairs(players) do
                player:tlChatMsg("shaman_left_lobby", pnDisp(pn))
            end
            -- reload lobby
            TsmRotation.doLobby()
        end
    end)

    local handleDeathForRotate = function(pn, win)
        if ThisRound:isReady() and not ThisRound.is_lobby and ThisRound.phase < PHASE_TIMESUP then
            if pL.alive:len() == 0 then
                Events.doEvent("TimesUp", elapsed)
            elseif ThisRound:isShaman(pn) then
                tfm.exec.setGameTime(20)
            elseif pL.alive:len() <= 2 then
                local aliveAreShams = true
                for name in pL.alive:pairs() do
                    if not ThisRound:isShaman(name) then
                        aliveAreShams = false
                        break
                    end
                end
                if aliveAreShams then
                    if win then tfm.exec.setGameTime(20) end
                    if ThisRound.opportunist then
                        for i = 1, #ThisRound.shamans do
                            local name = ThisRound.shamans[i]
                            tfm.exec.giveCheese(name)
                            tfm.exec.playerVictory(name)
                        end
                    end
                end
            end
            local p = players[pn]
            if p and not p:isRoundShaman() then
                p:setScore(win and 10 or 1, true)
            end
        end
    end

    Events.hookEvent("PlayerDied", function(pn)
        handleDeathForRotate(pn)
    end)

    Events.hookEvent("PlayerWon", function(pn)
        handleDeathForRotate(pn, true)
    end)

    Events.hookEvent("SummoningStart", function(pn, type, xPos, yPos, angle)
        if not ThisRound:isReady() then return end
        ThisRound.startsummon = true  -- workaround b/2
        if type == O_TYPE_TOTEM then  -- totems are banned; TODO: need more aggressive ban since this can be bypassed with (forced) lag
            local player = room.playerList[pn]
            local x, y, vx, vy = player.x, player.y, player.vx, player.vy
            ThisRound:setCorrectShamanMode(pn)
            tfm.exec.movePlayer(pn, x, y, false, vx, vy, false)
        end
    end)

    Events.hookEvent("SummoningEnd", function(pn, type, xPos, yPos, angle, desc)
        if ThisRound.startsummon then  -- workaround b/2: map prespawned object triggers summoning end event
            -- AntiLag™ by Leafileaf
            if players[pn].toggles[OPT_ANTILAG] and desc.baseType ~= 17 and desc.baseType ~= 32 then
                tfm.exec.moveObject(desc.id, xPos, yPos, false, 0, 0, false, angle, false)
            end
            if not ThisRound.is_lobby then
                if ThisRound:onSpawnCheck(pn, type, xPos, yPos, angle, desc) then
                    ThisRound:passShamanTurn()
                end
            end
        elseif ThisRound.is_lobby and type == 90 then
            -- ping detector
            local ping = nil
            if ThisRound.start_epoch then
                ping = os.time() - ThisRound.start_epoch
            end
            if ThisRound:isShaman(pn) and ping then
                if ping >= ANTILAG_FORCE_THRESHOLD then
                    -- enable antilag
                    players[pn]:tlChatMsg("antilag_enabled")
                    players[pn].toggles[OPT_ANTILAG] = true
                elseif ping >= ANTILAG_WARN_THRESHOLD and not players[pn].toggles[OPT_ANTILAG] then
                    -- enable antilag if it isn't already so
                    players[pn]:tlChatMsg("antilag_warn")
                end
            end
            print("[dbg] the sync is "..pn.." with a ping of "..(ping or "N/A").." ms")
        end
    end)

    Events.hookEvent("NewGame", function()
        local valid, vars = TsmRotation.signalNgAndHandover()
        if not valid then
            print(room.currentMap.." unexpected map loaded, retrying.")
            return
        end

        if not module_started then module_started = true end

        ThisRound = TsmRound:new(vars)

        if ThisRound.is_lobby then
            ThisRound:onLobby()
        else
            ThisRound:onNew()
        end
    end)

    Events.hookEvent("TimesUp", function(elapsed)
        if not module_started then return end
        ThisRound:onEnd()
    end)

    Events.hookEvent("Loop", function(elapsed, remaining)
        if remaining <= 0 then
            if ThisRound.phase < PHASE_TIMESUP then
                Events.doEvent("TimesUp", elapsed)
            end
        else
            if ThisRound.is_lobby then
                ui.setMapName(string.format("<N>Next Shamans: <CH>%s <N>- <CH2>%s  <G>|  <N>Game starts in: <V>%s  <G>|  <N>Mice: <V>%s<",
                        pnDisp(ThisRound.shamans[1]), pnDisp(ThisRound.shamans[2]),
                        math_round(remaining/1000), pL.room:len()))
            end
        end
    end)

end