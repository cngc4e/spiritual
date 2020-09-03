do
    Events.hookEvent("NewPlayer", function(pn)
        system.bindMouse(pn, true)
    end)

    Events.hookEvent("PlayerLeft", function(pn)
        players[pn] = nil
    end)

    Events.hookEvent("Loop", function(elapsed, remaining)
        MDHelper.trySync()
    end)

    Events.hookEvent("FileLoaded", function(file, data)
        local success, result = pcall(MDHelper.eventFileLoaded, file, data)
        if not success then
            print(string.format("Exception encountered in eventFileLoaded: %s", result))
        end
    end)

    Events.hookEvent("FileSaved", function(file)
        MDHelper.eventFileSaved(file)
    end)
end
