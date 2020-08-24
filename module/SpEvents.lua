local SpEvents = {}
do
    SpEvents.Loop = function(elapsed, remaining)
    end

    SpEvents.NewGame = function()
    end

    SpEvents.NewPlayer = function(pn)
        players[pn] = SpPlayer:new(pn)

        system.bindMouse(pn, true)
        for key, a in pairs(keys) do
            if a.trigger == DOWN_ONLY then
                system.bindKeyboard(pn, key, true)
            elseif a.trigger == UP_ONLY then
                system.bindKeyboard(pn, key, false)
            elseif a.trigger == DOWN_UP then
                system.bindKeyboard(pn, key, true)
                system.bindKeyboard(pn, key, false)
            end
        end
    end

    SpEvents.PlayerLeft = function(pn)
        players[pn] = nil
    end

    SpEvents.SummoningEnd = function(pn, type, xPos, yPos, angle, desc)
    end
end
