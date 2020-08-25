do
        
    Events.hookEvent("NewPlayer", function(pn)
        local player = SpPlayer:new(pn)
        players[pn] = player

        player:tlChatMsg("welcome_message", SpCommon.MAP_SUBMISSION_LINK, SpCommon.DISCORD_LINK)
    end)

    Events.hookEvent("NewGame", function()
        ThisRound = SpRound:new()
        ThisRound:onNew()

        for name, player in pairs(players) do
            local t_str = {
                player:tlFmt("map_info", ThisRound.mapcode, ThisRound.author, ThisRound.difficulty),
                player:tlFmt("shaman_info", "Unknown#0000", 999)
            }
            local propstr = player:tlFmt("windgrav_info", ThisRound.wind, ThisRound.gravity)
            local props = { }
            if ThisRound.portals then
                props[#props+1] = player:tlFmt("portals")
            end
            if ThisRound.no_b then
                props[#props+1] = player:tlFmt("no_b")
            end
            if #props > 0 then
                propstr = propstr .. " <G>| <VP>" .. table.concat(props, " <G>| <VP>")
            end
            t_str[#t_str+1] = propstr
            player:chatMsg(table.concat(t_str, "\n"))
        end
    end)

    Events.hookEvent("TimesUp", function(elapsed)
        if not SpCommon.module_started then return end
        ThisRound:onEnd()
        -- TODO: get next shaman and their preferred diff
        local diff = 1
        map_sched.load(SpCommon.chooseMapFromDiff(diff))
    end)

    Events.hookEvent("Loop", function(elapsed, remaining)
        if remaining <= 0 then
            if ThisRound.phase < SpCommon.PHASE_TIMESUP then
                Events.doEvent("TimesUp", elapsed)
            end
        end
    end)

end