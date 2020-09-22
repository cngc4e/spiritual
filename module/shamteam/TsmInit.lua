local IsOfficialRoom = function(name)
    local normalised_matches = {
        "^%w-%-#(.-)$",  -- public room, in form of xx-#module(args)?
        "^*#(.-)$"  -- private room, in form of *#module(args)?
    }
    for i = 1, #normalised_matches do
        local x = name:match(normalised_matches[i])
        if x then name = x break end
    end
    return name and (name == MODULE_ROOMNAME or name:find("^"..MODULE_ROOMNAME.."[^a-zA-Z].-$"))
end

init_ext = function()
    for _,v in ipairs({'AllShamanSkills','AutoNewGame','AutoScore','AutoTimeLeft','PhysicalConsumables'}) do
        tfm.exec['disable'..v](true)
    end
    system.disableChatCommandDisplay(nil,true)
    is_official_room = IsOfficialRoom(room.name)
    
end

postinit_ext = function()
    TsmRotation.doLobby()
    MDHelper.trySync()
end
