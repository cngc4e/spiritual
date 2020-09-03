-- Player methods specific to Spiritual
do
    TsmPlayer = setmetatable({}, Player)
    TsmPlayer.__index = TsmPlayer


    TsmPlayer.new = function(self, pn)
        local data = Player:newData(pn)

        return setmetatable(data, self)
    end
end
