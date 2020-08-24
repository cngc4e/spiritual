local bitset = {}
do
    -- Note: Error checking for OOB have been commented out, ensure
    -- that positions stay within the size of MAX_POSITION_SIZE
    -- (AKA: 0 < position < MAX_POSITION_SIZE - 1)
    local bit    = bit32
    local band   = bit.band
    local bnot   = bit.bnot
    local bor    = bit.bor
    local bxor   = bit.bxor
    local lshift = bit.lshift
    local MAX_POSITION_SIZE = 32  -- Maximum size supported by bit32 library

    local bits = {}
    for i = 0, MAX_POSITION_SIZE - 1 do
        bits[i] = lshift(1, i)
    end

    -- bitset:set(pos1, ..., posn)
    -- Set bits at all nth positions to true.
    bitset.set = function(self, ...)
        for i = 1, arg.n do
            --if arg[i] < 0 or arg[i] >= MAX_POSITION_SIZE then error("position out of bounds") end
            self._b = bor(self._b, bits[arg[i]])
        end
        return self
    end

    -- bitset:unset(pos1, ..., posn)
    -- Set bits at all nth positions to false.
    bitset.unset = function(self, ...)
        for i = 1, arg.n do
            --if arg[i] < 0 or arg[i] >= MAX_POSITION_SIZE then error("position out of bounds") end
            self._b = band(self._b, bnot(bits[arg[i]]))
        end
        return self
    end

    -- bitset:flip(pos)
    -- Flips bit at position pos.
    bitset.flip = function(self, pos)
        self._b = bxor(self._b, bits[pos])
        return self
    end

    -- bitset:setall()
    -- Set all bits within MAX_POSITION_SIZE to true.
    bitset.setall = function(self)
        self._b = bnot(0)
        return self
    end

    -- bitset:reset()
    -- Sets all bits to false (0).
    bitset.reset = function(self)
        self._b = 0
        return self
    end

    -- bitset:isset(pos)
    -- Returns true if the bit at position pos is set, false otherwise.
    bitset.isset = function(self, pos)
        return band(self._b, bits[pos]) ~= 0
    end

    -- bitset:issubset(bitset_object)
    -- Returns true if bitset_object is a subset of this bitset.
    bitset.issubset = function(self, bitset_object)
        --if not bitset_object._b then return error("not a valid bitset object") end
        return band(self._b, bitset_object._b) ~= 0
    end

    -- bitset:tonumber()
    -- Returns an integer representation of the bitset.
    bitset.tonumber = function(self, bitset_object)
        return self._b
    end

    bitset.new = function(number)
        return setmetatable({
            _b = number or 0,
        }, bitset)
    end
    
    bitset.__index = bitset
end
