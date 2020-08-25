for _,v in ipairs({'AllShamanSkills','AutoNewGame','PhysicalConsumables'}) do
    tfm.exec['disable'..v](true)
end
system.disableChatCommandDisplay(nil,true)
MDHelper.trySync()
TimedTask.add(3000, function()
    SpCommon.module_started = true
    Events.doEvent("TimesUp", elapsed)
end)
