do

    Events.hookEvent("NewPlayer", function(pn)
        local player = TsmPlayer:new(pn)
        players[pn] = player

        player:tlChatMsg("welcome_message")

        if not is_official_room then
            player:tlChatMsg("tribehouse_mode_warning", MODULE_ROOMNAME)
        end

        tfm.exec.setPlayerScore(pn, 0)

        if player:isToggleSet(OPT_GUI) then
            TsmWindow.open(WINDOW_GUI, pn)
        end

        if pL.room:len() == 2 and ThisRound:isReady() and ThisRound.is_lobby and module_started then
            -- reload lobby
            TsmRotation.doLobby()
        end
    end)

    local handleDeathForRotate = function(pn, win)
        if not ThisRound.is_lobby then
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
        end
    end)

end