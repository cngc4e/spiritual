-- Command handler for Transformice
local tfmcmd = {}
do
    --[[
        ++ Command Types (CmdType) ++
        Name: tfmcmd.Main
        Description:
            A normal command.
        Supported parameters:
            - name (String) : The command name.
                                (NOTE: Will override any previous commands and aliases
                                registered with the same names)
            - aliases (String[]) : Numeric table containing alias names for the command
                                (NOTE: Will override any previous commands and aliases
                                registered with the same names) [Optional]
            - allowed (Boolean / Function) : Override the default permission rule set by
                                tfmcmd.setDefaultAllow [Optional]
            - args (ArgType[] / ArgType) : Arguments specification (see below for supported types)
            - func (Function(playerName, ...)) :
                Function to handle the command, called on successful checks against permission and args.
                    - playerName (String) : The player who invoked the command
                    - ... (Mixed) : A collection of arguments, each type specified according to args.

        Name: tfmcmd.Interface
        Description:
            Similar to Main command type, but accepts multiple command names and calls the command
            handler with the target command name. Used to define commands that operate nearly the same
            way, providing a way to commonise and clean up code.
        Supported parameters:
            - commands (String[]) : Numeric table containing names for the commands that will use this
                                interface.
                                (NOTE: Will override any previous commands and aliases
                                registered with the same names)
            - allowed (Boolean / Function) : Override the default permission rule set by
                                tfmcmd.setDefaultAllow [Optional]
            - args (ArgType[] / ArgType) : Arguments specification (see below for supported types)
            - func (Function(playerName, commandName, ...)) :
                Function to handle the command, called on successful checks against permission and args.
                    - playerName (String) : The player who invoked the command
                    - commandName (String) : The command name used to invoke this interface
                    - ... (Mixed) : A collection of arguments, each type specified according to args.
        
        ++ Argument Types (ArgType) ++
        Name: tfmcmd.ArgString
        Return on success: String, or nil if optional is set
        Supported parameters:
            - optional (Boolean) : If true, and if command does not specify this argument, will return nil.
                                Otherwise will error on EMISSING.
            - default (String) : Will return this string if command does not specify this argument
            - lower (Boolean) : Whether the string should be converted to all lowercase
        
        Name: tfmcmd.ArgJoinedString
        Return on success: String, or nil if optional is set
        Supported parameters:
            - optional (Boolean) : If true, and if command does not specify this argument, will return nil.
                                Otherwise will error on EMISSING.
            - default (String) : Will return this string if command does not specify this argument
            - length (Integer) : The maximum number of words to join

        Name: tfmcmd.ArgNumber
        Return on success: Integer, or nil if optional is set
        Supported parameters:
            - optional (Boolean) : If true, and if command does not specify this argument, will return nil.
                                Otherwise will error on EMISSING.
            - default (Integer) : Will return this number if command does not specify this argument
            - min (Integer) : If specified, and the number parsed is < min, will error on ERANGE
            - max (Integer) : If specified, and the number parsed is > max, will error on ERANGE

        Name: tfmcmd.ALL_WORDS
        Description:
            Simply returns all raw arguments in strings. No fixed length. Will not error out due to no error
            checking / processing. Not recommended to use if you are sure on the specific types / number of
            arguments (if so specify them using a table of ArgType).
        Return on success: All raw arguments in strings
        No parameters
    ]]

    local commands = {}
    local default_allowed = true  -- can be fn(pn) or bool

    --- Error enums
    tfmcmd.OK       = 0  -- No errors
    tfmcmd.ENOCMD   = 1  -- No such valid command found
    tfmcmd.EPERM    = 2  -- Permission denied
    tfmcmd.EINVAL   = 3  -- Invalid argument value
    tfmcmd.EMISSING = 4  -- Missing argument
    tfmcmd.ETYPE    = 5  -- Invalid argument type
    tfmcmd.ERANGE   = 6  -- Number out of range
    tfmcmd.EOTHER   = 7  -- Other unknown errors

    -- Args enums
    tfmcmd.ALL_WORDS = 1

    --- Command types
    local MT_Main = { __index = {
        register = function(self)
            if not self.name or not self.func then
                error("Invalid command def"..(self.name and ": name = "..self.name))
            end
            commands[self.name] = {
                args = self.args or {},
                func = self.func,
                call = self.call,
                allowed = self.allowed
            }
            if self.aliases then
                for i = 1, #self.aliases do
                    local alias = self.aliases[i]
                    if commands[alias] then
                        error("Alias '"..alias.."' is duplicated!!")
                    end
                    commands[alias] = commands[self.name]
                end
            end
        end,
        call = function(self, pn, a)
            if self.args == tfmcmd.ALL_WORDS then
                local ret, retmsg = self.func(pn, table.unpack(a, a.current, a._len))
                if ret then
                    return ret, retmsg
                end
                return tfmcmd.OK
            end
            local args = {}
            local arg_len = #self.args
            for i = 1, arg_len do
                local err, res = self.args[i]:verify(a, pn)
                if err ~= tfmcmd.OK then
                    return err, res
                end
                args[i] = res
            end
            local ret, retmsg = self.func(pn, table.unpack(args, 1, arg_len))
            if ret then
                return ret, retmsg
            end
            return tfmcmd.OK
        end,
    }}
    tfmcmd.Main = function(attr)
        return setmetatable(attr or {}, MT_Main)
    end

    local MT_Interface = { __index = {
        register = function(self)
            if not self.commands or not self.func then
                error("Invalid command def"..(self.name and ": name = "..self.name))
            end
            for i = 1, #self.commands do
                commands[self.commands[i]] = {
                    name = self.commands[i],
                    args = self.args or {},
                    func = self.func,
                    call = self.call,
                    allowed = self.allowed
                }
            end
        end,
        call = function(self, pn, a)
            if self.args == tfmcmd.ALL_WORDS then
                local ret, retmsg = self.func(pn, self.name, table.unpack(a, a.current, a._len))
                if ret then
                    return ret, retmsg
                end
                return tfmcmd.OK
            end
            local args = {}
            local arg_len = #self.args
            for i = 1, arg_len do
                local err, res = self.args[i]:verify(a, pn)
                if err ~= tfmcmd.OK then
                    return err, res
                end
                args[i] = res
            end
            local ret, retmsg = self.func(pn, self.name, table.unpack(args, 1, arg_len))
            if ret then
                return ret, retmsg
            end
            return tfmcmd.OK
        end,
    }}
    tfmcmd.Interface = function(attr)
        return setmetatable(attr or {}, MT_Interface)
    end

    local MT_ArgString = { __index = {
        verify = function(self, a)
            local str = a[a.current]
            if not str then
                if self.optional or self.default then
                    return tfmcmd.OK, self.default or nil
                else
                    return tfmcmd.EMISSING
                end
            end
            a.current = a.current + 1  -- go up one word
            return tfmcmd.OK, self.lower and str:lower() or str
        end,
    }}
    tfmcmd.ArgString = function(attr)
        return setmetatable(attr or {}, MT_ArgString)
    end

    local MT_ArgJoinedString = { __index = {
        verify = function(self, a)
            local join = {}
            local max_index = a._len
            if self.length then
                max_index = math.min(a._len, a.current + self.length - 1)
            end
            for i = a.current, max_index do
                a.current = i + 1  -- go up one word
                join[#join + 1] = a[i]
            end
            if #join == 0 then
                if self.optional or self.default then
                    return tfmcmd.OK, self.default or nil
                else
                    return tfmcmd.EMISSING
                end
            end
            return tfmcmd.OK, table.concat(join, " ")
        end,
    }}
    tfmcmd.ArgJoinedString = function(attr)
        return setmetatable(attr or {}, MT_ArgJoinedString)
    end

    local MT_ArgNumber = { __index = {
        verify = function(self, a)
            local word = a[a.current]
            if not word then
                if self.optional or self.default then
                    return tfmcmd.OK, self.default or nil
                else
                    return tfmcmd.EMISSING
                end
            end
            local res = tonumber(word)
            if not res then
                return tfmcmd.ETYPE, "Expected number"
            end
            if self.min and res < self.min then
                return tfmcmd.ERANGE, "Min: " .. self.min
            end
            if self.max and res > self.max then
                return tfmcmd.ERANGE, "Max: " .. self.max
            end
            a.current = a.current + 1  -- go up one word
            return tfmcmd.OK, res
        end,
    }}
    tfmcmd.ArgNumber = function(attr)
        return setmetatable(attr or {}, MT_ArgNumber)
    end

    --- Methods
    tfmcmd.initCommands = function(cmds)
        for i = 1, #cmds do
            cmds[i]:register()
        end
    end

    tfmcmd.setDefaultAllow = function(allow)
        default_allowed = allow
    end

    local execute_command = function(pn, words)
        local cmd = commands[words[1]:lower()]
        if cmd then
            local allow_target
            if cmd.allowed ~= nil then  -- override default permission rule
                allow_target = cmd.allowed
            else
                allow_target = default_allowed
            end

            local allowed
            if type(allow_target) == "function" then
                allowed = allow_target(pn)
            else
                allowed = allow_target
            end

            if allowed then
                return cmd:call(pn, words)
            else
                return tfmcmd.EPERM
            end
        else
            return tfmcmd.ENOCMD
        end
    end

    tfmcmd.executeCommand = function(pn, words)
        words.current = 2  -- current = index of argument which is to be accessed first in the next arg type
        words._len = #words
        return execute_command(pn, words)
    end

    tfmcmd.executeChatCommand = function(pn, msg)
        local words = { current = 2, _len = 0 }  -- current = index of argument which is to be accessed first in the next arg type
        for word in msg:gmatch("[^ ]+") do
            words._len = words._len + 1
            words[words._len] = word
        end
        return execute_command(pn, words)
    end
end
