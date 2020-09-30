local function math_round(num, dp)
    local mult = 10 ^ (dp or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function math_pythag(x1, y1, x2, y2, r)
	local x,y,r = x2-x1, y2-y1, r+r
	return x*x+y*y<r*r
end

local function math_chance(chance)
	local r = math.random(1, 100)
	return r < (chance or 50)
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

-- shuffle a list using the Fisher–Yates shuffle algorithm
local function table_shuffle(tbl)
    local mr = math.random
    for i = #tbl, 2, -1 do
      local j = mr(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

-- debugging
local function dumptbl (tbl, indent, cb)
    if not indent then indent = 0 end
    if not cb then cb = print end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            cb(formatting)
            dumptbl(v, indent+1, cb)
        elseif type(v) == 'boolean' then
            cb(formatting .. tostring(v))
        elseif type(v) == "function" then
            cb(formatting .. "()")
        else
            cb(formatting .. v)
        end
    end
end

local function dumpXMLNode(node, indent, cb)
    if not indent then indent = 0 end
    if not cb then cb = print end

    local attrs = {}
    for k,v in pairs(node.attrib) do attrs[#attrs+1] = k..'="'..v..'"' end
    cb(string.rep("  ", indent)..node.name.." ["..table.concat(attrs, " ").."]")

    for i = 1, node.children do
        dumpXMLNode(node.child[i], indent+1, cb)
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
    if target then
        local ign = target:lower()
        for name in pL.room:pairs() do
            if name:lower():find(ign) then return name end
        end
    end
    if pn then tfm.exec.chatMessage("<R>error: no such target", pn) end
end

local sendLongChatMessage = function(msg, pn)
    local MAX_MSG_CHARS = 950
    local times = math.ceil(#msg/MAX_MSG_CHARS)
    for i = 0, times - 1 do
        tfm.exec.chatMessage(msg:sub(#msg*(i/times)+1, #msg*((i+1)/times)), pn)
    end
end

-- Returns valid_name (string?)
local validName = function(pn)
    local name, tag
    if not pn:find('#') then
        tag = "0000"
        if pn:find("(%S+)") then
            name = pn
        end
    else
        name, tag = pn:match("(%S+)#(%d+)")
    end
    if not name or #name > 20 then return nil end
    if not tag or #tag ~= 4 then return nil end
    return name:sub(1,1):upper() .. name:sub(2):lower() .. "#" .. tag
end
