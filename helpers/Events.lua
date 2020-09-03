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
