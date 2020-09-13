callbacks["help"] = function(pn, tab)
    if tab == 'Close' then
        TsmWindow.close(WINDOW_HELP, pn)
    else
        TsmWindow.open(WINDOW_HELP, pn, tab)
    end
end

callbacks["options"] = function(pn, action)
    if action == 'close' then
        TsmWindow.close(WINDOW_OPTIONS, pn)
    elseif not TsmWindow.isOpened(WINDOW_OPTIONS, pn) then
        TsmWindow.open(WINDOW_OPTIONS, pn)
    end
end

callbacks["unafk"] = function(pn)
    SetSpectate(pn, false)
    tfm.exec.chatMessage(tl("unafk_message", pn), pn)
end

callbacks["link"] = function(pn, link_id)
    -- Do not print out raw text from players! Use predefined IDs instead.
    link_id = tonumber(link_id)
    local links = {
        [LINK_DISCORD] = "https://discord.gg/YkzM4rh",
    }
    if links[link_id] then
        tfm.exec.chatMessage(links[link_id], pn)
    end
end

callbacks["setmode"] = function(pn, mode_id)
    mode_id = tonumber(mode_id) or -1
    if not roundv.running or not roundv.lobby or (mode_id ~= TSM_HARD and mode_id ~= TSM_DIV)
            or pn ~= roundv.shamans[1] then -- only shaman #1 gets to set mode
        return
    end
    roundv.mode = mode_id

    for name in pL.room:pairs() do
        local imgs = TsmWindow.getImages(WINDOW_LOBBY, name)
        local img_dats = imgs.mode
        if img_dats and img_dats[mode_id] then
            tfm.exec.removeImage(img_dats[TSM_HARD][1])
            tfm.exec.removeImage(img_dats[TSM_DIV][1])
            if mode_id == TSM_HARD then
                img_dats[TSM_HARD][1] = tfm.exec.addImage(IMG_FEATHER_HARD, ":"..WINDOW_LOBBY, img_dats[TSM_HARD][2], img_dats[TSM_HARD][3], name)
                img_dats[TSM_DIV][1] = tfm.exec.addImage(IMG_FEATHER_DIVINE_DISABLED, ":"..WINDOW_LOBBY, img_dats[TSM_DIV][2], img_dats[TSM_DIV][3], name)
            else
                img_dats[TSM_HARD][1] = tfm.exec.addImage(IMG_FEATHER_HARD_DISABLED, ":"..WINDOW_LOBBY, img_dats[TSM_HARD][2], img_dats[TSM_HARD][3], name)
                img_dats[TSM_DIV][1] = tfm.exec.addImage(IMG_FEATHER_DIVINE, ":"..WINDOW_LOBBY, img_dats[TSM_DIV][2], img_dats[TSM_DIV][3], name)
            end
        end
    end
end

callbacks["setdiff"] = function(pn, id, add)
    id = tonumber(id) or 0
    add = tonumber(add) or 0
    if not roundv.running or not roundv.lobby 
            or pn ~= roundv.shamans[1] -- only shaman #1 gets to choose difficulty
            or (id ~= 1 and id ~= 2)
            or (add ~= -1 and add ~= 1) then
        return
    end
    local diff_id = "diff"..id
    local new_diff = roundv[diff_id] + add

    if new_diff < 1 or new_diff > #mapcodes[roundv.mode]
            or (id == 1 and roundv.diff2 - new_diff < 1)
            or (id == 2 and new_diff - roundv.diff1 < 1) then  -- range error
        tfm.exec.chatMessage(string.format("<R>error: range must have a value of 1-%s and have a difference of at least 1", #mapcodes[roundv.mode]), pn)
        return
    end

    roundv[diff_id] = new_diff
    ui.updateTextArea(WINDOW_LOBBY+9,"<p align='center'><font size='13'><b>"..roundv.diff1)
    ui.updateTextArea(WINDOW_LOBBY+10,"<p align='center'><font size='13'><b>"..roundv.diff2)
end

callbacks["setready"] = function(pn)
    if not roundv.running or not roundv.lobby then return end
    if roundv.shamans[1] == pn then
        local is_ready = not roundv.shaman_ready[1]
        roundv.shaman_ready[1] = is_ready

        local blt = is_ready and "&#9745;" or "&#9744;";
        ui.updateTextArea(WINDOW_LOBBY+18, GUI_BTN.."<font size='2'><br><font size='12'><p align='center'><a href='event:setready'>"..blt.." Ready".."</a>")
    elseif roundv.shamans[2] == pn then
        local is_ready = not roundv.shaman_ready[2]
        roundv.shaman_ready[2] = is_ready

        local blt = is_ready and "&#9745;" or "&#9744;";
        ui.updateTextArea(WINDOW_LOBBY+19, GUI_BTN.."<font size='2'><br><font size='12'><p align='center'><a href='event:setready'>"..blt.." Ready".."</a>")
    end
    if roundv.shaman_ready[1] and roundv.shaman_ready[2] then
        rotate_evt.timesup()
    end
end

callbacks["modtoggle"] = function(pn, mod_id)
    mod_id = tonumber(mod_id)
    if not roundv.running or not roundv.lobby or not mod_id or not mods[mod_id]
            or pn ~= roundv.shamans[2] then -- only shaman #2 gets to choose mods
        return
    end
    local is_set = roundv.mods:flip(mod_id):isset(mod_id)
    for name in pL.room:pairs() do
        local imgs = TsmWindow.getImages(WINDOW_LOBBY, name)
        local img_dats = imgs.toggle
        if img_dats and img_dats[mod_id] then
            tfm.exec.removeImage(img_dats[mod_id][1])
            img_dats[mod_id][1] = tfm.exec.addImage(is_set and IMG_TOGGLE_ON or IMG_TOGGLE_OFF, ":"..WINDOW_LOBBY, img_dats[mod_id][2], img_dats[mod_id][3], name)
        end
    end
    ui.updateTextArea(WINDOW_LOBBY+17,"<p align='center'><font size='13'><N>Exp multiplier:<br><font size='15'>"..expDisp(GetExpMult()))
end

callbacks["modhelp"] = function(pn, mod_id)
    mod_id = tonumber(mod_id) or -1
    local mod = mods[mod_id]
    if mod then
        ui.updateTextArea(WINDOW_LOBBY+16, string.format("<p align='center'><i><J>%s: %s %s of original exp.", mod[1], mod[3], expDisp(mod[2], false)),pn)
    end
end

callbacks["opttoggle"] = function(pn, opt_id)
    opt_id = tonumber(opt_id)
    if not opt_id or not PLAYER_OPTIONS[opt_id] then
        return
    end
    players[pn]:flipTogglePersist(opt_id)  -- flip and toggle the flag
    
    local is_set = players[pn].toggles[opt_id]

    local imgs = TsmWindow.getImages(WINDOW_OPTIONS, pn)
    local img_dats = imgs.toggle
    if img_dats and img_dats[opt_id] then
        tfm.exec.removeImage(img_dats[opt_id][1])
        img_dats[opt_id][1] = tfm.exec.addImage(is_set and IMG_TOGGLE_ON or IMG_TOGGLE_OFF, ":"..WINDOW_OPTIONS, img_dats[opt_id][2], img_dats[opt_id][3], pn)
    end

    -- hide/show GUI on toggle
    if opt_id == OPT_GUI then
        if not ThisRound:isShaman(pn) or ThisRound.is_lobby then
            if is_set then
                TsmWindow.open(WINDOW_GUI, pn)
            else
                TsmWindow.close(WINDOW_GUI, pn)
            end
        end
    end

    if opt_id == OPT_CIRCLE then
        players[pn]:updateCircle()
    end
end

callbacks["opthelp"] = function(pn, opt_id)
    opt_id = tonumber(opt_id) or -1
    local opt = PLAYER_OPTIONS[opt_id]
    if opt then
        local player = players[pn]
        -- Option Name: description
        player:chatMsgFmt("<J>%s: %s", player:tlFmt(opt[1]), player:tlFmt(opt[2]))
    end
end
