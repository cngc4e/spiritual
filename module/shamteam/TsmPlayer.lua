-- Player methods specific to Spiritual
do
    TsmPlayer = setmetatable({}, Player)
    TsmPlayer.__index = TsmPlayer


    TsmPlayer.isToggleSet = function(self, toggle_id)
        --return self.pdata.toggles[toggle_id]
        if toggle_id == OPT_GUI then return true end  -- TODO
    end

    TsmPlayer.new = function(self, pn)
        local data = Player:newData(pn)

        return setmetatable(data, self)
    end
end
