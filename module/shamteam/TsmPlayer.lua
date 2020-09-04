-- Player methods specific to Spiritual
do
    TsmPlayer = setmetatable({}, Player)
    TsmPlayer.__index = TsmPlayer

    TsmPlayer.updateCircle = function(self, target)
        self:removeCircle()
        local current_sham = target or ThisRound:getCurrentTurnShaman()
        if self.name ~= current_sham and self.toggles[OPT_CIRCLE] then
            self.circle_imgid = tfm.exec.addImage(IMG_RANGE_CIRCLE, "$"..current_sham, -120, -120, self.name)
        end
    end

    TsmPlayer.removeCircle = function(self)
        if self.circle_imgid then
            tfm.exec.removeImage(self.circle_imgid)
            self.circle_imgid = nil
        end
    end

    TsmPlayer.new = function(self, pn)
        local data = Player:newData(pn)

        data.toggles = boolset:new():set(OPT_GUI)

        return setmetatable(data, self)
    end
end
