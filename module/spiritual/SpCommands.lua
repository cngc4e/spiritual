do
    local LEVEL_DEV = function(pn) return DEVS[pn] end

    commands = {
        tfmcmd.Main {
            name = "version",
            func = function(pn)
                tfm.exec.chatMessage("<J>Version v0", pn)
            end,
        },
    }

    tfmcmd.setDefaultAllow(true)
    tfmcmd.initCommands(commands)
end
