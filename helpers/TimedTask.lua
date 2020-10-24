-- Serves as a wrapper for system.newTimer(), adding a failsafe method to run
-- tasks via eventLoop if system.newTimer does not work
local TimedTask = {}
do
    local TIMER_OFFSET_MS = 400
    local tasks = {}
    local last_id = 0

    local add_task = function(use_timer, id, time_ms, cb, a1, a2, a3, a4)
        if id == nil then
            last_id = last_id + 1
            id = last_id
        end

        -- "A timer interval must be superior than 1000 ms."
        if not use_timer or time_ms < 1000 then
            -- Back to good ol' eventLoop
            tasks[id] = { nil, os.time() + time_ms, cb, {a1, a2, a3, a4} }
        else
            local timer_id = system.newTimer(function(_, a1, a2, a3, a4)
                    if not tasks[id] then return end
                    tasks[id] = nil
                    cb(a1, a2, a3, a4)
                end, time_ms, false, a1, a2, a3, a4)
            tasks[id] = { timer_id, os.time() + time_ms + TIMER_OFFSET_MS, cb, {a1, a2, a3, a4} }
        end

        return id
    end

    TimedTask.add = function(time_ms, cb, a1, a2, a3, a4)
        return add_task(true, nil, time_ms, cb, a1, a2, a3, a4)
    end

    TimedTask.addUseLoop = function(time_ms, cb, a1, a2, a3, a4)
        return add_task(false, nil, time_ms, cb, a1, a2, a3, a4)
    end

    TimedTask.remove = function(id)
        if not id or not tasks[id] then return end
        if tasks[id][1] then
            system.removeTimer(tasks[id][1])
        end
        tasks[id] = nil
    end

    TimedTask.exists = function(id)
        return id ~= nil and tasks[id]
    end

    TimedTask.overrideUseLoop = function(id, time_ms, cb, a1, a2, a3, a4)
        if id and tasks[id] then
            if tasks[id][1] then
                system.removeTimer(tasks[id][1])
            end
            tasks[id] = nil
        end
        return add_task(false, id, time_ms, cb, a1, a2, a3, a4)
    end

    TimedTask.onLoop = function()
        local done, sz = {}, 0
        for id, task in pairs(tasks) do
            if os.time() >= task[2] then
                if task[1] then
                    -- timer did not execute in time
                    system.removeTimer(task[1])
                end
                task[3](table.unpack(task[4]))
                sz = sz + 1
                done[sz] = id
            end
        end
        for i = 1, sz do
            tasks[done[i]] = nil
        end
    end
end
