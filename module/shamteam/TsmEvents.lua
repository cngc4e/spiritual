do

    Events.hookEvent("NewPlayer", function(pn)
        local player = TsmPlayer:new(pn)
        players[pn] = player

        player:tlChatMsg("welcome_message")

        if not is_official_room then
            player:tlChatMsg("tribehouse_mode_warning", MODULE_ROOMNAME)
        end

        tfm.exec.setPlayerScore(pn, 0)
    end)

    Events.hookEvent("PlayerDied", function(pn)

    end)

    Events.hookEvent("PlayerWon", function(pn)

    end)

    Events.hookEvent("NewGame", function()
        local valid, vars = TsmRotation.signalNgAndRead()
        if not valid then
            print("unexpected map loaded, retrying.")
        end

        if not module_started then module_started = true end

        ThisRound = TsmRound:new(vars)

        if ThisRound.is_lobby then
            --ThisRound:onLobby()
        else
            ThisRound:onNew()

            for name, player in pairs(players) do
                local t_str = {
                    player:tlFmt("map_info", ThisRound.mapcode, ThisRound.author, ThisRound.difficulty, "Hard/Divine"),
                    player:tlFmt("shaman_info", "Unknown#0000", 999)
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