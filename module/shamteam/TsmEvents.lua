do

    Events.hookEvent("NewPlayer", function(pn)
        local player = TsmPlayer:new(pn)
        players[pn] = player

        player:tlChatMsg("welcome_message")

        if not is_official_room then
            player:tlChatMsg("tribehouse_mode_warning", MODULE_ROOMNAME)
        end

        tfm.exec.setPlayerScore(pn, 0)

        if pL.room:len() == 2 and ThisRound:isReady() and ThisRound.is_lobby and module_started then
            -- reload lobby
            TsmRotation.doLobby()
        end
    end)

    local handleDeathForRotate = function(pn, win)
        if not ThisRound.is_lobby then
            if pL.alive:len() == 0 then
                Events.doEvent("TimesUp", elapsed)
            elseif players[pn]:isShaman() then
                tfm.exec.setGameTime(20)
            elseif pL.alive:len() <= 2 then
                local aliveAreShams = true
                for name in pL.alive:pairs() do
                    if not players[name]:isShaman() then
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
        end
    end

    Events.hookEvent("PlayerDied", function(pn)
        handleDeathForRotate(pn)
    end)

    Events.hookEvent("PlayerWon", function(pn)
        handleDeathForRotate(pn, true)
    end)

    Events.hookEvent("NewGame", function()
        local valid, vars = TsmRotation.signalNgAndRead()
        if not valid then
            print("unexpected map loaded, retrying.")
            return
        end

        if not module_started then module_started = true end

        ThisRound = TsmRound:new(vars)

        if ThisRound.is_lobby then
            ThisRound:onLobby()
            tfm.exec.disableAfkDeath(true)
            tfm.exec.disableMortCommand(true)
            tfm.exec.disablePrespawnPreview(false)
        else
            ThisRound:onNew()

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
            
            tfm.exec.disableAfkDeath(false)
            tfm.exec.disableMortCommand(false)
            tfm.exec.disablePrespawnPreview(ThisRound.mods[MOD_TELEPATHY])
        end
    end)

    Events.hookEvent("TimesUp", function(elapsed)
        if not module_started then return end
        ThisRound:onEnd()
        if ThisRound.is_lobby then
            TsmRotation.doRotate()
        else
            TsmRotation.doLobby()
        end
    end)

    Events.hookEvent("Loop", function(elapsed, remaining)
        if remaining <= 0 then
            if ThisRound.phase < PHASE_TIMESUP then
                Events.doEvent("TimesUp", elapsed)
            end
        end
    end)

end