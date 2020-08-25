-- Common player stuff
local Player
do
    Player = {}
    Player.__index = Player

    Player.chatMsg = function(self, str)
        return tfm.exec.chatMessage(str, self.name)
    end

    Player.tlFmt = function(self, kname, ...)
        local str = translations[self.lang][kname]
        return string.format(str, ...)
    end

    Player.tlChatMsg = function(self, kname, ...)
        local str = translations[self.lang][kname]
        return tfm.exec.chatMessage(string.format(str, ...), self.name)
    end

    -- Base data for this class, to be used in inherited new() methods
    Player.newData = function(self, pn)
        local p = room.playerList[pn]
        local ret = {
            name = pn,
            lang = "en",
        }
        if translations[p.community] then
            ret.lang = p.community
        end
        return ret
    end

    Player.new = function(self, pn)
        return setmetatable(self:newData(pn), self)
    end
end
