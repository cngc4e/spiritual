
local chooseMapFromDiff = function(diff)
    local pool = TsmModuleData.getMapcodesByDiff(diff)
    -- TODO: priority for less completed maps?
    return pool[math.random(#pool)]
end

local pnDisp = function(pn)
    -- TODO: check if the player has the same name as another existing player in the room.
    return pn and (pn:find('#') and pn:sub(1,-6) or pn) or "N/A"
end
