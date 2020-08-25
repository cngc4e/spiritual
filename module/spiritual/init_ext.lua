for _,v in ipairs({'AllShamanSkills','AutoNewGame','AutoTimeLeft','PhysicalConsumables'}) do
    tfm.exec['disable'..v](true)
end
system.disableChatCommandDisplay(nil,true)
MDHelper.trySync()