do
    local LEVEL_DEV = function(pn) return DEVS[pn] end
    local LEVEL_MANAGER = function(pn) return MODULE_MANAGERS[pn] or LEVEL_DEV(pn) end
    local LEVEL_STAFF = function(pn) return TsmModuleData.isStaff(pn) or LEVEL_MANAGER(pn) end

    commands = {
        tfmcmd.Main {
            name = "version",
            func = function(pn)
                tfm.exec.chatMessage("<J>Version v0", pn)
            end,
        },
        tfmcmd.Main {
            name = "map",
            aliases = {"np"},
            description = "Loads specified map",
            allowed = LEVEL_DEV,
            args = {
                tfmcmd.ArgString { optional = true },
            },
            func = function(pn, code)
                if not module_started then return end
                map_sched.load(code)
            end,
        },
        tfmcmd.Main {
            name = "liststaff",
            allowed = LEVEL_STAFF,
            func = function(pn)
                local managers = {}
                for name in pairs(DEVS) do managers[#managers+1] = name end
                for name in pairs(MODULE_MANAGERS) do managers[#managers+1] = name end
                players[pn]:chatMsgFmt("Team managers:\n%s", table.concat(managers, " "))
                local list = TsmModuleData.getTable("staff")
                players[pn]:chatMsgFmt("\nStaff:\n%s", table.concat(list, " "))
            end
        },
        tfmcmd.Main {
            name = "addstaff",
            args = {
                tfmcmd.ArgString { },
            },
            allowed = LEVEL_MANAGER,
            func = function(pn, target)
                local status, msg = TsmModuleData.commit(pn, TsmModuleData.ADD_STAFF, target)
                if status == MDHelper.MERGE_OK then
                    players[pn]:chatMsgFmt("%s will be given Staff rights.", target)
                else
                    players[pn]:chatMsg(msg)
                end
            end
        },
        tfmcmd.Main {
            name = "remstaff",
            args = {
                tfmcmd.ArgString { },
            },
            allowed = LEVEL_MANAGER,
            func = function(pn, target)
                local status, msg = TsmModuleData.commit(pn, TsmModuleData.REMOVE_STAFF, target)
                if status == MDHelper.MERGE_OK then
                    players[pn]:chatMsgFmt("%s will be revoked of Staff rights.", target)
                else
                    players[pn]:chatMsg(msg)
                end
            end
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
                                local map = TsmModuleData.getMapInfo(ThisRound.mapcode)
                                if not map then
                                    tfm.exec.chatMessage("<R>This map is not in rotation.", pn)
                                    return
                                end
                                local info = string.format("Mapcode: @%s\nDifficulty: %s, %s\nCompletion: %s / %s, %s / %s",
                                        map.code, map.difficulty_hard, map.difficulty_divine,
                                        map.completed_hard, map.rounds_hard, map.completed_divine, map.rounds_divine)
                                tfm.exec.chatMessage(info, pn)
                            end,
                            diffh = function()
                                local map = TsmModuleData.getMapInfo(ThisRound.mapcode)
                                if not map then
                                    tfm.exec.chatMessage("<R>This map is not in rotation.", pn)
                                    return
                                end
                                local diff = tonumber(p1)
                                if not diff then
                                    tfm.exec.chatMessage("<R>Specify a valid difficulty number.", pn)
                                    return
                                end
                                TsmModuleData.commit(pn, TsmModuleData.OP_UPDATE_MAP_DIFF_HARD, map.code, diff)
                                tfm.exec.chatMessage("THM Difficulty of @"..map.code.." will be changed to "..p1, pn)
                            end,
                            diffd = function()
                                local map = TsmModuleData.getMapInfo(ThisRound.mapcode)
                                if not map then
                                    tfm.exec.chatMessage("<R>This map is not in rotation.", pn)
                                    return
                                end
                                local diff = tonumber(p1)
                                if not diff then
                                    tfm.exec.chatMessage("<R>Specify a valid difficulty number.", pn)
                                    return
                                end
                                TsmModuleData.commit(pn, TsmModuleData.OP_UPDATE_MAP_DIFF_DIVINE, map.code, diff)
                                tfm.exec.chatMessage("TDM Difficulty of @"..map.code.." will be changed to "..p1, pn)
                            end,
                            add = function()
                                local map = TsmModuleData.getMapInfo(ThisRound.mapcode)
                                if map then
                                    tfm.exec.chatMessage("<R>This map is already in rotation.", pn)
                                    return
                                end
                                TsmModuleData.commit(pn, TsmModuleData.OP_ADD_MAP, ThisRound.mapcode)
                                tfm.exec.chatMessage("Adding @"..ThisRound.mapcode, pn)
                            end,
                            remove = function()
                                local map = TsmModuleData.getMapInfo(ThisRound.mapcode)
                                if not map then
                                    tfm.exec.chatMessage("<R>This map is not in rotation.", pn)
                                    return
                                end
                                TsmModuleData.commit(pn, TsmModuleData.OP_REMOVE_MAP, map.code)
                                tfm.exec.chatMessage("Removing @"..map.code, pn)
                            end,
                            listh = function()
                                local diff = tonumber(p1)
                                if not diff then
                                    tfm.exec.chatMessage("<R>Specify a valid difficulty number.", pn)
                                    return
                                end
                                local list = TsmModuleData.getMapcodesByDiff(TSM_HARD, diff)
                                players[pn]:chatMsgFmt("THM Difficulty %s:\n%s",
                                        diff, table.concat(list, " "))
                            end,
                            listd = function()
                                local diff = tonumber(p1)
                                if not diff then
                                    tfm.exec.chatMessage("<R>Specify a valid difficulty number.", pn)
                                    return
                                end
                                local list = TsmModuleData.getMapcodesByDiff(TSM_DIV, diff)
                                players[pn]:chatMsgFmt("TDM Difficulty %s:\n%s",
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
        tfmcmd.Main {
            name = "skip",
            allowed = LEVEL_STAFF,
            func = function(pn)
                Events.doEvent("TimesUp")
            end,
        },
        tfmcmd.Main {
            name = "roomlimit",
            args = {
                tfmcmd.ArgNumber { default = DEFAULT_MAX_PLAYERS, min = 1 },
            },
            allowed = LEVEL_STAFF,
            func = function(pn, limit)
                tfm.exec.setRoomMaxPlayers(limit)
                players[pn]:chatMsg("Room limit set to "..limit..".")
            end,
        },
        tfmcmd.Main {
            name = "time",
            args = {
                tfmcmd.ArgNumber { },
            },
            allowed = LEVEL_STAFF,
            func = function(pn, limit)
                tfm.exec.setGameTime(limit)
                players[pn]:chatMsg("Time limit set to "..limit..".")
            end,
        },
    }

    tfmcmd.setDefaultAllow(true)
    tfmcmd.initCommands(commands)
end
