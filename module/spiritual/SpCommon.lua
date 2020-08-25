local SpCommon
local SpRound
local SpModuleData

do
    SpCommon = {}

    SpCommon.MAP_SUBMISSION_LINK = "atelier801.com/topic?f=6&t=809105"
    SpCommon.DISCORD_LINK = "discord.gg/KZQQRRr"

    SpCommon.PHASE_START = 0
    SpCommon.PHASE_READY = 1
    SpCommon.PHASE_TIMESUP = 2

    SpCommon.HIGHEST_DIFF = 10

    SpCommon.MODULE_ID = 20

    SpCommon.MANAGERS = {
        ["Dukeonkled#0000"] = true,
        ["Anthonyjones#0000"] = true,
        ["Stefanmocarz#0000"]= true,
        ["TheWav#0095"] = true,
    }

    SpCommon.module_started = false

    SpCommon.chooseMapFromDiff = function(diff)
        local pool = SpModuleData.getMapcodesByDiff(diff)
        -- TODO: priority for less completed maps?
        return pool[math.random(#pool)]
    end
end
