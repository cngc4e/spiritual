local Events = {}
do
    local registered_evts = {}

    Events.hookEvent = function(name, fn)
        local evt = registered_evts[name]
        if not evt then
            registered_evts[name] = { _len = 0 }
            evt = registered_evts[name]
        end
        evt._len = evt._len + 1
        evt[evt._len] = fn
    end

    Events.doEvent = function(name, ...)
        local evt = registered_evts[name]
        if not evt then return end
        for i = 1, evt._len do
            evt[i](...)
        end
    end
end

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
