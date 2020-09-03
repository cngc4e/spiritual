keys[71] = {
    func = function(pn, enable) -- g (display GUI for shamans)
        if not roundv.lobby and pL.shaman[pn] then
            if enable then
                sWindow.open(WINDOW_GUI, pn)
            else
                sWindow.close(WINDOW_GUI, pn)
            end
        end
    end,
    trigger = DOWN_UP
}

keys[72] = {
    func = function(pn) -- h (display help)
        if sWindow.isOpened(WINDOW_HELP, pn) then
            sWindow.close(WINDOW_HELP, pn)
        else
            sWindow.open(WINDOW_HELP, pn)
        end
    end,
    trigger = DOWN_ONLY
}

keys[79] = {
    func = function(pn) -- o (display player options)
        if sWindow.isOpened(WINDOW_OPTIONS, pn) then
            sWindow.close(WINDOW_OPTIONS, pn)
        else
            sWindow.open(WINDOW_OPTIONS, pn)
        end
    end,
    trigger = DOWN_ONLY
}

keys[85] = {
    func = function(pn) -- u (undo spawn)
        if not pL.shaman[pn] or not roundv.mods:isset(MOD_BUTTER_FINGERS) then return end
        local sl = roundv.spawnlist[pn]
        if sl._len > 0 and roundv.undo_count < 2 then
            tfm.exec.removeObject(sl[sl._len])
            sl[sl._len] = nil
            sl._len = sl._len - 1
            roundv.undo_count = roundv.undo_count + 1
            tfm.exec.chatMessage(string.format("<ROSE>%s used an undo! (%s left)", pDisp(pn), 2 - roundv.undo_count))
        end
    end,
    trigger = DOWN_ONLY
}
