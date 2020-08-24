do
    local LEVEL_DEV = function(pn) return DEVS[pn] end
    
    commands = {
        --[[tfmcmd.Main {
            name = "map",
            aliases = {"np"},
            description = "Loads specified map",
            allowed = LEVEL_DEV,
            args = {
                tfmcmd.ArgString { optional = true },
            },
            func = function(pn, code)
                map_sched.load(code)
            end,
        },]]
    }

    tfmcmd.setDefaultAllow(true)
    tfmcmd.initCommands(commands)
end
