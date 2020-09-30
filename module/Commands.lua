do
    local LEVEL_DEV = function(pn) return DEVS[pn] end
    
    commands = {
        tfmcmd.Main {
            name = "exec",
            allowed = LEVEL_DEV,
            args = tfmcmd.ALL_WORDS,
            func = function ( pn , ... )
                local argv = {...}
                if argv[1] and tfm.exec[argv[1]]~=nil then
                    local args = {}
                    local buildstring = {false}
                    for i = 2, #argv do
                        arg = argv[i]
                        if arg=='true' then args[#args+1]=true
                        elseif arg=='false' then args[#args+1]=false
                        elseif arg=='nil' then args[#args+1]=nil
                        elseif tonumber(arg) ~= nil then args[#args+1]=tonumber(arg)
                        elseif arg:find('{(.-)}') then
                            local params = {}
                            for _,p in pairs(string_split(arg:match('{(.-)}'), ',')) do
                                local prop = string_split(p, '=')
                                local attr,val=prop[1],prop[2]
                                if val=='true' then val=true
                                elseif val=='false' then val=false
                                elseif val=='nil' then val=nil
                                elseif tonumber(val) ~= nil then val=tonumber(val)
                                end
                                params[attr] = val
                            end
                            args[#args+1] = params
                        elseif arg:find('^"(.*)"$') then
                            args[#args+1] = arg:match('^"(.*)"$'):gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&amp;', '&')
                        elseif arg:find('^"(.*)') then
                            buildstring[1] = true
                            buildstring[2] = arg:match('^"(.*)'):gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&amp;', '&')
                        elseif arg:find('(.*)"$') then
                            buildstring[1] = false
                            args[#args+1] = buildstring[2] .. " " .. arg:match('(.*)"$'):gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&amp;', '&')
                        elseif buildstring[1] then
                            buildstring[2] = buildstring[2] .. " " .. arg:gsub('&lt;', '<'):gsub('&gt;', '>'):gsub('&amp;', '&')
                        else
                            args[#args+1] = arg
                        end
                    end
                    tfm.exec[argv[1]](table.unpack(args))
                else
                    tfm.exec.chatMessage('<R>no such exec '..(argv[1] and argv[1] or 'nil'), pn)
                end
            end
        },
    }

    tfmcmd.setDefaultAllow(true)
    tfmcmd.initCommands(commands)
end
