SpCommon = {}

do
    SpCommon.chooseMapFromDiff = function(diff)
        local pool = TsmModuleData.getMapcodesByDiff(diff)
        -- TODO: priority for less completed maps?
        return pool[math.random(#pool)]
    end
end
