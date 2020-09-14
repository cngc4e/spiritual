local IRound = {}

-- int mapcode
-- string author
-- bool is_mirrored
-- bool is_vanilla
-- ENUM phase : to be set by inherited classes

do
    IRound.parseXMLObj = function(self, xmlobj)
        local xo_prop = xmlobj:traverse_first("P").attrib
        if xo_prop.G then
            local wind, grav = xo_prop.G:match("(%-?%S+),(%-?%S+)")
            self.wind = tonumber(wind) or 0
            self.gravity = tonumber(grav) or 10
        end
    end

    IRound.onNew = function(self)
        local mapcode = tonumber(room.currentMap:match('%d+'))
        self.mapcode = mapcode
        self.is_mirrored = room.mirroredMap
        self.wind = 0
        self.gravity = 10
        if mapcode < 1000 or not room.xmlMapInfo then
            self.is_vanilla = true
            self.author = "Vanilla#0020"
            return
        end
        self.author = room.xmlMapInfo.author
        local xmlobj = XMLParse.parse(room.xmlMapInfo.xml):traverse_first("C")
        self:parseXMLObj(xmlobj)
    end

    IRound.onEnd = function(self)
    end
end