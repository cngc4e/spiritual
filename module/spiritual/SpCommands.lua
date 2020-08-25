do
    local LEVEL_DEV = function(pn) return DEVS[pn] end

    commands = {
        tfmcmd.Main {
            name = "version",
            func = function(pn)
                tfm.exec.chatMessage("<J>Version v0", pn)
            end,
        },
        tfmcmd.Main {
            name = "db",
            args = tfmcmd.ALL_WORDS,
            func = function(pn, w1, w2, w3, w4)
                if not MDHelper.getMdLoaded() then
                    tfm.exec.chatMessage("Module data not loaded yet, please try again.", pn)
                    return
                end
                local subcommands = {
                    map = function(action, p1)
                        local actions = {
                            info = function()
                                local map = SpModuleData.getMapInfo(ThisRound.mapcode)
                                if not map then
                                    tfm.exec.chatMessage("<R>This map is not in rotation.", pn)
                                    return
                                end
                                local info = string.format("Mapcode: @%s\nDifficulty: %s\nCompletion: %s / %s",
                                        map.code, map.difficulty, map.completed, map.rounds)
                                tfm.exec.chatMessage(info, pn)
                            end,
                            diff = function()
                                local map = SpModuleData.getMapInfo(ThisRound.mapcode)
                                if not map then
                                    tfm.exec.chatMessage("<R>This map is not in rotation.", pn)
                                    return
                                end
                                local diff = tonumber(p1)
                                if not diff then
                                    tfm.exec.chatMessage("<R>Specify a valid difficulty number.", pn)
                                    return
                                end
                                SpModuleData.commit(pn, SpModuleData.OP_UPDATE_MAP_DIFF, map.code, diff)
                                tfm.exec.chatMessage("Difficulty of @"..map.code.." will be changed to "..p1, pn)
                            end,
                            add = function()
                                local map = SpModuleData.getMapInfo(ThisRound.mapcode)
                                if map then
                                    tfm.exec.chatMessage("<R>This map is already in rotation.", pn)
                                    return
                                end
                                SpModuleData.commit(pn, SpModuleData.OP_ADD_MAP, ThisRound.mapcode)
                                tfm.exec.chatMessage("Adding @"..ThisRound.mapcode, pn)
                            end,
                            remove = function()
                                local map = SpModuleData.getMapInfo(ThisRound.mapcode)
                                if not map then
                                    tfm.exec.chatMessage("<R>This map is not in rotation.", pn)
                                    return
                                end
                                SpModuleData.commit(pn, SpModuleData.OP_REMOVE_MAP, map.code)
                                tfm.exec.chatMessage("Removing @"..map.code, pn)
                            end,
                            list = function()
                                local diff = tonumber(p1)
                                if not diff then
                                    tfm.exec.chatMessage("<R>Specify a valid difficulty number.", pn)
                                    return
                                end
                                local list = SpModuleData.getMapcodesByDiff(diff)
                                players[pn]:chatMsgFmt("Difficulty %s:\n<p align='center'>%s</p>",
                                        diff, table.concat(list, " "))
                            end,
                        }
                        if actions[action] then
                            actions[action]()
                        else
                            local a = {}
                            for sb in pairs(actions) do
                                a[#a+1] = sb
                            end
                            tfm.exec.chatMessage("Usage: !db map [ "..table.concat(a, " | ").." ]", pn)
                        end
                    end,
                    history = function()
                        local logs = MDHelper.getTable("module_log")
                        tfm.exec.chatMessage("Change logs:", pn)
                        for i = 1, #logs do
                            local log = logs[i]
                            local log_str = MDHelper.getChangelog(log.op) or ""
                            tfm.exec.chatMessage(string.format("<ROSE>\t- %s\t%s\t%s", log.committer, os.date("%d/%m/%y %X", log.time*1000), log_str), pn)
                        end
                        --sWindow.open(WINDOW_DB_HISTORY, pn)
                    end,
                }
                if subcommands[w1] then
                    subcommands[w1](w2, w3)
                else
                    local s = {}
                    for sb in pairs(subcommands) do
                        s[#s+1] = sb
                    end
                    tfm.exec.chatMessage("Usage: !db [ "..table.concat(s, " | ").." ]", pn)
                end
            end,
        },
    }

    tfmcmd.setDefaultAllow(true)
    tfmcmd.initCommands(commands)
end
