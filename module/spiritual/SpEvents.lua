Events.hookEvent("NewPlayer", function(pn)
    players[pn] = SpPlayer:new(pn)
end)
