
local chooseMapFromDiff = function(diff)
    local pool = TsmModuleData.getMapcodesByDiff(diff)
    -- TODO: priority for less completed maps?
    return pool[math.random(#pool)]
end

local pnDisp = function(pn)
    -- TODO: check if the player has the same name as another existing player in the room.
    return pn and (pn:find('#') and pn:sub(1,-6) or pn) or "N/A"
end

local expDisp = function(n, addColor)
    if addColor == nil then addColor = true end
    local sign, color = "", "<J>"
    if n > 0 then
        sign = "+"
        color = "<VP>"
    elseif n < 0 then
        sign = "-"
        color = "<R>"
    end
    if not addColor then color = "" end
    return color..sign..math.abs(n*100).."%"
end
