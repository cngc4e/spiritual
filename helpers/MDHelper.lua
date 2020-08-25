-- Module data helper
local MDHelper = {}
do
    local FILE_LOAD_INTERVAL = 60005  -- in milliseconds

    local db_cache = {}
    local db_commits = {}
    local inform_filesave = {}
    local module_data_loaded = false
    local next_module_sync = nil  -- when the next module data syncing can occur
    local operations = nil
    local schema = nil
    local file_id = nil
    local latest_schema_version = nil
    local file_parse_callback = nil
    local inited = false

    local MODULE_LOG_OP = {
        init = function(self, committer, op_id, logobj)
            local nlogobj = table_copy(logobj)
            nlogobj.op_id = op_id
            self.logobj = nlogobj
            self.committer = committer
            self.time = math.floor(os.time()/1000)
        end,
        merge = function(self, db)
            local md_log = db.module_log
            local entry = {
                committer = self.committer,
                time = self.time,
                op = self.logobj
            }
            md_log[#md_log+1] = entry
            return MDHelper.MERGE_OK
        end,
        logobject = function(self)
            return nil
        end,
    }

    MDHelper.OP_ADD_MODULE_LOG = 0

    MDHelper.MERGE_OK = 0
    MDHelper.MERGE_NOTHING = 1
    MDHelper.MERGE_FAIL = 2

    MDHelper.commit = function(pn, op_id, a1, a2, a3, a4)
        local op = operations[op_id]
        if op then
            local op_mt = setmetatable({}, { __index = {
                init = op.init,
                merge = op.merge,
                logobject = op.logobject,
                op_id = op_id
            }})
            op_mt:init(a1, a2, a3, a4)
            local status, result = op_mt:merge(db_cache)
            if status ~= MDHelper.MERGE_OK then
                return status, result or "Merge unsuccessful"
            else
                local logobj = op_mt:logobject()
                if logobj then
                    -- add module log
                    MDHelper.commit(nil, MDHelper.OP_ADD_MODULE_LOG, pn, op_id, logobj)
                end
                -- don't schedule and sync commit if the operation specifies to be passive in non-official rooms
                if is_official_room or not op_mt.PASSIVE_ON_NOR then
                    -- Schedule the commit to be done again during the next syncing
                    db_commits[#db_commits+1] = { op_mt, pn }
                end
                return status, result or ""
            end
        else
            return MDHelper.MERGE_FAIL, "Invalid operation."
        end
    end

    local save = function(db)
        local encoded_md = db2.encode(schema[latest_schema_version], db)
        system.saveFile(encoded_md, file_id)
        print("module data save")
    end

    MDHelper.getTable = function(tbl_name)
        return db_cache[tbl_name]
    end

    MDHelper.getChangelog = function(logobj)
        if type(logobj) == "table" then
            local op_id = logobj.op_id
            if op_id and operations[op_id].changelog then
                return operations[op_id].changelog(logobj)
            end
        end
    end

    MDHelper.getMdLoaded = function()
        return module_data_loaded
    end

    MDHelper.eventFileLoaded = function(file, data)
        if not inited then return end
        if tonumber(file) ~= file_id then return end
        if #data == 0 then
			print("init and save default db")
            save(db_cache)
        else
            local new_db = db2.decode(schema, data)
            local commit_sz = #db_commits
            if commit_sz > 0 then
                for i = 1, commit_sz do
                    local op = db_commits[i][1]
                    local committer = db_commits[i][2]
                    local status, result = op:merge(new_db)
                    print("new db: did "..op.op_id)
                    if status ~= MDHelper.MERGE_OK then
                        print("Error occurred while merging on the new database: "..result or "No reason")
                    elseif committer then
                        inform_filesave[committer] = true
                    end
                end
                save(new_db)
                db_commits = {}
            end
            db_cache = new_db
        end
        if file_parse_callback then
            file_parse_callback()
        end
        module_data_loaded = true
        print("module data load")
    end

    MDHelper.eventFileSaved = function(file)
        if not inited then return end
        if tonumber(file) ~= file_id then return end
        for name in pairs(inform_filesave) do
            tfm.exec.chatMessage("<J>All changes have been successfully saved to the database!", name)
        end
        inform_filesave = {}
    end

    MDHelper.trySync = function()
        if not inited then return end
        if not next_module_sync or os.time() >= next_module_sync then
            system.loadFile(file_id)
            next_module_sync = os.time() + FILE_LOAD_INTERVAL
        end
    end

    MDHelper.init = function(fid, schms, latest, ops, default_db, parsed_cb)
        file_id = fid
        schema = schms
        latest_schema_version = latest
        operations = ops
        operations[MDHelper.OP_ADD_MODULE_LOG] = MODULE_LOG_OP
        db_cache = default_db
        file_parse_callback = parsed_cb
        inited = true
    end
end
