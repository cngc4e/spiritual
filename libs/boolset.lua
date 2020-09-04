-- Simple boolset wrapper with several useful utilities to make life easier.
-- Accept position >= 1 only. To check boolean value of position, simply use bs[pos].

local boolset = {}

do
    -- boolset:set(pos1, ..., posn)
    -- Set boolean values at all nth positions to true.
    -- For single flag setting just simply use bs[position] = true
    boolset.set = function(self, ...)
        local a = {...}
        for i = 1, #a do
            self[a[i]] = true
        end
        return self
    end

    -- boolset:unset(pos1, ..., posn)
    -- Set boolean values at all nth positions to false.
    -- For single flag setting just simply use bs[position] = false
    boolset.unset = function(self, ...)
        local a = {...}
        for i = 1, #a do
            self[a[i]] = nil
        end
        return self
    end

    -- boolset:flip(pos)
    -- Flip boolean value at position pos.
    boolset.flip = function(self, pos)
        if self[pos] then
            self[pos] = nil
        else
            self[pos] = true
        end
        return self
    end

    -- boolset.toFilledSet()
    -- Returns a boolean set which fills up empty positions with false values. 
    boolset.toFilledSet = function(self)
        local ret = {}
        local highest = 0
        for pos in pairs(self) do
            if type(pos) == "number" and pos > highest then
                highest = pos
            end
        end
        for i = 1, highest do
            if self[i] == nil then
                ret[i] = false
            else
                ret[i] = self[i]
            end
        end
        return ret
    end

    local mt = {__index = boolset}
    boolset.new = function(_, bs)
        bs = bs or {}
        return setmetatable(bs, mt)
    end

end
