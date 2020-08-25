-- Serves as a wrapper for system.newTimer(), adding a failsafe method to run
-- tasks via eventLoop if system.newTimer does not work
local TimedTask = {}
do
    local TIMER_OFFSET_MS = 400
    local tasks = {}
    local last_id = 0

    TimedTask.add = function(time_ms, cb)
        last_id = last_id + 1
        local id = last_id
        local timer_id = system.newTimer(function()
                tasks[id] = nil
                cb()
            end, time_ms)
        tasks[id] = { timer_id, os.time() + time_ms + TIMER_OFFSET_MS, cb }
        return id
    end

    TimedTask.remove = function(id)
        system.removeTimer(tasks[id][1])
        tasks[id] = nil
    end

    TimedTask.onLoop = function()
        for id, task in pairs(tasks) do
            if os.time() >= task[2] then
                -- timer did not execute in time
                system.removeTimer(task[1])
                task[3]()
            end
        end
        tasks = {}
    end
end
