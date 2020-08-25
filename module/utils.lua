local function math_round(num, dp)
    local mult = 10 ^ (dp or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function math_pythag(x1, y1, x2, y2, r)
	local x,y,r = x2-x1, y2-y1, r+r
	return x*x+y*y<r*r
end

local function string_split(str, delimiter)
    local delimiter,a = delimiter or ',', {}
    for part in str:gmatch('[^'..delimiter..']+') do
        a[#a+1] = part
    end
    return a
end

local function table_copy(tbl)
    local out = {}
    for k, v in next, tbl do
        out[k] = v
    end
    return out
end

local function dumptbl (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            dumptbl(v, indent+1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

-- returns map code in integer type, nil if invalid
local function int_mapcode(code)
    if type(code) == "string" then
        return tonumber(code:match("@?(%d+)"))
    elseif type(code) == "number" then
        return code
    else
        return nil
    end
end

local function tl(pn, kname)
    local pref_lang = players[pn] and players[pn].lang or "en"
    local lang = translations[pref_lang] and pref_lang or "en"
    if translations[lang][kname] then
        return translations[lang][kname]
    else
        return kname
    end
end

local function ZeroTag(pn, add) --#0000 removed for tag matches
    if add then
        if not pn:find('#') then
            return pn.."#0000"
        else return pn
        end
    else
        return pn:find('#0000') and pn:sub(1,-6) or pn
    end
end

local function pFind(target, pn)
    local ign = string.lower(target or ' ')
    for name in pairs(room.playerList) do
        if string.lower(name):find(ign) then return name end
    end
    if pn then tfm.exec.chatMessage("<R>error: no such target", pn) end
end
