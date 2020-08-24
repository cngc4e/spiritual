@include module/common/Player.lua

-- Player methods specific to Spiritual
local SpPlayer
do
    SpPlayer = setmetatable({}, Player)
    SpPlayer.__index = SpPlayer


    SpPlayer.new = function(self, pn)
        local data = Player:newData(pn)

        return setmetatable(data, self)
    end
end
