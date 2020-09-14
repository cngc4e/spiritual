-- Player methods specific to Team Shaman
do
    TsmPlayer = setmetatable({}, Player)
    TsmPlayer.__index = TsmPlayer

    local TOGGLESAVE_WAIT_COOLDOWN = 3000

    local schedule_toggle_save = function(self)
        if not self.pdata_loaded then return end
        self.save_toggle_id = TimedTask.overrideUseLoop(self.save_toggle_id,
                TOGGLESAVE_WAIT_COOLDOWN,
                function(pn, toggles)
                    PDHelper.setScheduleSave(pn, function(mpdata)
                        mpdata.toggles = toggles
                    end)
                end,
                self.name, self.toggles:toFilledSet())
    end

    -- Persistent player data updated/loaded
    TsmPlayer.onPdataLoaded = function(self, pdata)
        if not self.pdata_loaded then self.pdata_loaded = true end
        
        -- Cache xp
        self.exp = pdata.exp

        -- Cache toggles
        self.toggles = boolset:new(pdata.toggles)

    end

    TsmPlayer.setTogglePersist = function(self, ...)
        self.toggles:set(...)
        schedule_toggle_save(self)
    end

    TsmPlayer.flipTogglePersist = function(self, ...)
        self.toggles:flip(...)
        schedule_toggle_save(self)
    end

    TsmPlayer.updateCircle = function(self, target)
        self:removeCircle()
        if ThisRound:isReady() and ThisRound.mode ~= TSM_DIV then
            local current_sham = target or ThisRound:getCurrentTurnShaman()
            if current_sham and self.name ~= current_sham and self.toggles[OPT_CIRCLE] then
                self.circle_imgid = tfm.exec.addImage(IMG_RANGE_CIRCLE, "$"..current_sham, -120, -120, self.name)
            end
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

        data.pdata_loaded = false
        data.toggles = boolset:new():set(OPT_GUI, OPT_CIRCLE)
        data.exp = 0

        return setmetatable(data, self)
    end
end
