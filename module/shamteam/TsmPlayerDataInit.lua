
local CURRENT_VERSION = 1
local PD_SCHEMA = {
    [1] = {
        VERSION = 1,
        db2.UnsignedInt{ key="exp", size=6 },  -- experience points
        db2.Bitset{ key="toggles", size=7 },  -- player options bit set (togglebles), set multiples of 7
    }
}

local DEFAULT_PD = {
    exp = 0,
    toggles = boolset:new():set(OPT_GUI, OPT_CIRCLE):toFilledSet(),
}

PDHelper.init(
    MODULE_ID,
    PD_SCHEMA,
    CURRENT_VERSION,
    DEFAULT_PD,
    function(pn, mpdata)
        if players[pn] then
            players[pn]:onPdataLoaded(mpdata)
        end
    end,
    params)
