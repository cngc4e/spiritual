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
            local props = { player:tlFmt("portals"), player:tlFmt("no_b") }
            if #props > 0 then
                propstr = propstr .. " <G>| <VP>" .. table.concat(props, " <G>| <VP>")
            end
            t_str[#t_str+1] = propstr
            player:chatMsg(table.concat(t_str, "\n"))
        end
    end)

    local onTimesUp = function(elapsed)
        ThisRound:onEnd()
    end

    Events.hookEvent("Loop", function(elapsed, remaining)
        if remaining <= 0 then
            if ThisRound.phase < SpCommon.PHASE_TIMESUP then
                onTimesUp(elapsed)
            end
        end
    end)

end