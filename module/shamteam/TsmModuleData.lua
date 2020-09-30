TsmModuleData = setmetatable({}, { __index = MDHelper })
do
    local FILE_NUMBER = MODULE_ID
    local LATEST_MD_VER = 1

    -- DB operations/commits
    TsmModuleData.OP_ADD_MAP = 1
    TsmModuleData.OP_REMOVE_MAP = 2
    TsmModuleData.OP_UPDATE_MAP_DIFF_HARD = 3
    TsmModuleData.OP_UPDATE_MAP_DIFF_DIVINE = 4
    TsmModuleData.OP_ADD_MAP_COMPLETION_HARD = 5
    TsmModuleData.OP_ADD_MAP_COMPLETION_DIVINE = 6
    TsmModuleData.OP_REPLACE_MAPS = 7
    TsmModuleData.OP_ADD_BAN = 8
    TsmModuleData.OP_REMOVE_BAN = 9
    TsmModuleData.OP_ADD_STAFF = 10
    TsmModuleData.OP_REMOVE_STAFF = 11

    -- pre-computed cache
    local maps_by_diff = {}
    local maps_by_key = {}
    local staff_cache = {}
    
    -- Module data DB2 schemas
    local MD_SCHEMA = {
        [1] = {
            VERSION = 1,
            db2.VarDataList{ key="maps", size=10000, datatype=db2.Object{schema={
                db2.UnsignedInt{ key="code", size=4 },
                db2.UnsignedInt{ key="difficulty_hard", size=1 },
                db2.UnsignedInt{ key="difficulty_divine", size=1 },
                db2.UnsignedInt{ key="completed_hard", size=2 },
                db2.UnsignedInt{ key="completed_divine", size=2 },
                db2.UnsignedInt{ key="rounds_hard", size=2 },
                db2.UnsignedInt{ key="rounds_divine", size=2 },
            }}},
            db2.VarDataList{ key="banned", size=1000, datatype=db2.Object{schema={
                db2.TfmUsername{ key="name" },
                db2.VarChar{ key="reason", size=100 },
                db2.UnsignedInt{ key="time", size=5 },  -- in seconds
            }}},
            db2.VarDataList{ key="staff", size=100, datatype=db2.TfmUsername{} },
            db2.VarDataList{ key="module_log", size=100, datatype=db2.Object{schema={
                db2.VarChar{ key="committer", size=25 },
                db2.UnsignedInt{ key="time", size=5 },  -- in seconds
                db2.Switch{ key="op", typekey = "op_id", typedatatype = db2.UnsignedInt{ size = 2 }, datatypemap = {
                    [TsmModuleData.OP_ADD_MAP] = db2.Object{schema={
                        db2.UnsignedInt{ key="code", size=4 },
                    }},
                    [TsmModuleData.OP_REMOVE_MAP] = db2.Object{schema={
                        db2.UnsignedInt{ key="code", size=4 },
                    }},
                    [TsmModuleData.OP_UPDATE_MAP_DIFF_HARD] = db2.Object{schema={
                        db2.UnsignedInt{ key="code", size=4 },
                        db2.UnsignedInt{ key="old_diff", size=1 },
                        db2.UnsignedInt{ key="diff", size=1 },
                    }},
                    [TsmModuleData.OP_UPDATE_MAP_DIFF_DIVINE] = db2.Object{schema={
                        db2.UnsignedInt{ key="code", size=4 },
                        db2.UnsignedInt{ key="old_diff", size=1 },
                        db2.UnsignedInt{ key="diff", size=1 },
                    }},
                    [TsmModuleData.OP_REPLACE_MAPS] = db2.Object{schema={}},
                    [TsmModuleData.OP_ADD_BAN] = db2.Object{schema={
                        db2.TfmUsername{ key="name" },
                    }},
                    [TsmModuleData.OP_REMOVE_BAN] = db2.Object{schema={
                        db2.TfmUsername{ key="name" },
                    }},
                    [TsmModuleData.OP_ADD_STAFF] = db2.Object{schema={
                        db2.TfmUsername{ key="name" },
                    }},
                    [TsmModuleData.OP_REMOVE_STAFF] = db2.Object{schema={
                        db2.TfmUsername{ key="name" },
                    }},
                }},
            }}},
        }
    }

    local DEFAULT_DB = {
        maps = {},
        banned = {},
        staff = {},
        module_log = {},
    }

    local operations = {
        [TsmModuleData.OP_ADD_MAP] = {
            init = function(self, mapcode)
                self.mapcode = mapcode
            end,
            merge = function(self, db)
                local maps = db.maps
                local found = false
                for i = 1, #maps do
                    if maps[i].code == self.mapcode then
                        found = true
                        break
                    end
                end
                if found then
                    return MDHelper.MERGE_NOTHING, "@"..self.mapcode.." already exists in the database."
                end
                maps[#maps+1] = {code=self.mapcode, difficulty_hard=0, difficulty_divine=0, completed_hard=0, rounds_hard=0, completed_divine=0, rounds_divine=0}
                return MDHelper.MERGE_OK, "@"..self.mapcode.." successfully added."
            end,
            logobject = function(self)
                return {
                    code = self.mapcode
                }
            end,
            changelog = function(log)
                return "Added @"..log.code
            end,
        },
        [TsmModuleData.OP_REMOVE_MAP] = {
            init = function(self, mapcode)
                self.mapcode = mapcode
            end,
            merge = function(self, db)
                local maps = db.maps
                local found = false
                for i = 1, #maps do
                    if maps[i].code == self.mapcode then
                        table.remove(maps, i)
                        found = true
                        break
                    end
                end
                if not found then
                    return MDHelper.MERGE_NOTHING, "@"..self.mapcode.."  does not exist in the database."
                end
                return MDHelper.MERGE_OK, "@"..self.mapcode.." successfully removed."
            end,
            logobject = function(self)
                return {
                    code = self.mapcode
                }
            end,
            changelog = function(log)
                return "Removed @"..log.code
            end,
        },
        [TsmModuleData.OP_UPDATE_MAP_DIFF_HARD] = {
            init = function(self, mapcode, diff)
                self.mapcode = mapcode
                self.diff = diff
            end,
            merge = function(self, db)
                local maps = db.maps
                local found = false
                for i = 1, #maps do
                    if maps[i].code == self.mapcode then
                        if not self.old_diff then
                            self.old_diff = maps[i].difficulty_hard
                        end
                        maps[i].difficulty_hard = self.diff
                        found = true
                        break
                    end
                end
                if not found then
                    return MDHelper.MERGE_NOTHING, "@"..self.mapcode.." does not exist in the database."
                end
                return MDHelper.MERGE_OK, "@"..self.mapcode.." Hard difficulty updated to "..self.diff
            end,
            logobject = function(self)
                return {
                    code = self.mapcode,
                    old_diff = self.old_diff or 0,
                    diff = self.diff
                }
            end,
            changelog = function(log)
                return "Updated @"..log.code.." - difficulty: "..log.old_diff.." -&gt; "..log.diff
            end,
        },
        [TsmModuleData.OP_UPDATE_MAP_DIFF_DIVINE] = {
            init = function(self, mapcode, diff)
                self.mapcode = mapcode
                self.diff = diff
            end,
            merge = function(self, db)
                local maps = db.maps
                local found = false
                for i = 1, #maps do
                    if maps[i].code == self.mapcode then
                        if not self.old_diff then
                            self.old_diff = maps[i].difficulty_divine
                        end
                        maps[i].difficulty_divine = self.diff
                        found = true
                        break
                    end
                end
                if not found then
                    return MDHelper.MERGE_NOTHING, "@"..self.mapcode.." does not exist in the database."
                end
                return MDHelper.MERGE_OK, "@"..self.mapcode.." Divine difficulty updated to "..self.diff
            end,
            logobject = function(self)
                return {
                    code = self.mapcode,
                    old_diff = self.old_diff or 0,
                    diff = self.diff
                }
            end,
            changelog = function(log)
                return "Updated @"..log.code.." - difficulty: "..log.old_diff.." -&gt; "..log.diff
            end,
        },
        [TsmModuleData.OP_ADD_MAP_COMPLETION_HARD] = {
            init = function(self, mapcode, completed)
                self.mapcode = mapcode
                self.completed = completed
            end,
            merge = function(self, db)
                local maps = db.maps
                local found = false
                for i = 1, #maps do
                    if maps[i].code == self.mapcode then
                        found = maps[i]
                        break
                    end
                end
                if not found then
                    return MDHelper.MERGE_NOTHING, "@"..self.mapcode.." does not exist in the database."
                end

                if self.completed then
                    found.completed_hard = db2.minuint(found.completed_hard + 1, 2)
                end
                found.rounds_hard = db2.minuint(found.rounds_hard + 1, 2)
                return MDHelper.MERGE_OK
            end,
            logobject = function(self)
                return nil
            end,
            PASSIVE_ON_NOR = true
        },
        [TsmModuleData.OP_ADD_MAP_COMPLETION_DIVINE] = {
            init = function(self, mapcode, completed)
                self.mapcode = mapcode
                self.completed = completed
            end,
            merge = function(self, db)
                local maps = db.maps
                local found = false
                for i = 1, #maps do
                    if maps[i].code == self.mapcode then
                        found = maps[i]
                        break
                    end
                end
                if not found then
                    return MDHelper.MERGE_NOTHING, "@"..self.mapcode.." does not exist in the database."
                end

                if self.completed then
                    found.completed_divine = db2.minuint(found.completed_divine + 1, 2)
                end
                found.rounds_divine = db2.minuint(found.rounds_divine + 1, 2)
                return MDHelper.MERGE_OK
            end,
            logobject = function(self)
                return nil
            end,
            PASSIVE_ON_NOR = true
        },
        [TsmModuleData.OP_REPLACE_MAPS] = {
            init = function(self, map_table)
				self.map_table = map_table
            end,
            merge = function(self, db)
                db.maps = self.map_table
                return MDHelper.MERGE_OK
            end,
            logobject = function(self)
                return {}
            end,
            changelog = function(log)
                return "Mass update map database"
            end,
        },
        [TsmModuleData.OP_ADD_BAN] = {
            init = function(self, pn, reason)
                self.pn = pn
                self.reason = reason or ""
            end,
            merge = function(self, db)
                local banned = db.banned
                for i = 1, #banned do
                    if banned[i].name == self.pn then
                        found = true
                        break
                    end
                end
                if found then
                    return MDHelper.MERGE_NOTHING, self.pn.." is already banned."
                end

                banned[#banned+1] = {
                    name = self.pn,
                    reason = self.reason,
                    time = math.floor(os.time()/1000)
                }
                return MDHelper.MERGE_OK, self.pn.." has been added to the ban list."
            end,
            logobject = function(self)
                return {
                    name = self.pn
                }
            end,
            changelog = function(log)
                return "Permanently banned "..log.name
            end,
        },
        [TsmModuleData.OP_REMOVE_BAN] = {
            init = function(self, pn)
                self.pn = pn
            end,
            merge = function(self, db)
                local banned = db.banned
                local found = false
                for i = 1, #banned do
                    if banned[i].name == self.pn then
                        table.remove(banned, i)
                        found = true
                        break
                    end
                end
                if not found then
                    return MDHelper.MERGE_NOTHING, "No existing player was banned."
                end
                return MDHelper.MERGE_OK, self.pn.." was removed from the ban list."
            end,
            logobject = function(self)
                return {
                    name = self.pn
                }
            end,
            changelog = function(log)
                return "Revoked permanent ban on "..log.name
            end,
        },
        [TsmModuleData.OP_ADD_STAFF] = {
            init = function(self, pn)
                self.pn = pn
            end,
            merge = function(self, db)
                local staff = db.staff
                local found = false
                for i = 1, #staff do
                    if staff[i] == self.pn then
                        found = true
                        break
                    end
                end
                if found then
                    return MDHelper.MERGE_NOTHING, self.pn.." is already a staff."
                end

                staff[#staff+1] = self.pn
                return MDHelper.MERGE_OK, self.pn.." has been added to the staff list."
            end,
            logobject = function(self)
                return {
                    name = self.pn
                }
            end,
            changelog = function(log)
                return "Added staff: "..log.name
            end,
        },
        [TsmModuleData.OP_REMOVE_STAFF] = {
            init = function(self, pn)
                self.pn = pn
            end,
            merge = function(self, db)
                local staff = db.staff
                local found = false
                for i = 1, #staff do
                    if staff[i] == self.pn then
                        table.remove(staff, i)
                        found = true
                        break
                    end
                end
                if not found then
                    return MDHelper.MERGE_NOTHING, "No existing player is a staff."
                end
                return MDHelper.MERGE_OK, self.pn.." was removed from the staff list."
            end,
            logobject = function(self)
                return {
                    name = self.pn
                }
            end,
            changelog = function(log)
                return "Revoked staff rights on: "..log.name
            end,
        },
    }

    local precomp_maps = function()
        -- sort maps table for faster lookups
        local maps = MDHelper.getTable("maps")
        maps_by_diff = {
            [TSM_HARD] = {},
            [TSM_DIV] = {}
        }
        maps_by_key = {}
        for i = 1, #maps do
            maps_by_key[maps[i].code] = maps[i]

            for _, m in ipairs({{TSM_HARD, "difficulty_hard"}, {TSM_DIV, "difficulty_divine"}}) do
                local diff = maps[i][m[2]]
                local difft = maps_by_diff[m[1]][diff]
                if not difft then
                    difft = { _len = 0 }
                    maps_by_diff[m[1]][diff] = difft
                end
                difft._len = difft._len + 1
                difft[difft._len] = maps[i].code
            end
        end
    end

    local precomp_staff = function()
        local staff = MDHelper.getTable("staff")
        for i = 1, #staff do
            staff_cache[staff[i]] = true
        end
    end

    TsmModuleData.getMapInfo = function(mapcode)
        mapcode = int_mapcode(mapcode)
        if not mapcode then return end
        return maps_by_key[mapcode]
    end

    TsmModuleData.getMapcodesByDiff = function(mode, diff)
        if not diff then return maps_by_diff end
        return maps_by_diff[mode][diff] or {}
    end

    TsmModuleData.isStaff = function(pn)
        return staff_cache[pn] == true
    end

    local should_precomp_maps = {
        TsmModuleData.OP_ADD_MAP,
        TsmModuleData.OP_REMOVE_MAP,
        TsmModuleData.OP_UPDATE_MAP_DIFF_HARD,
        TsmModuleData.OP_UPDATE_MAP_DIFF_DIVINE
    }
    local should_precomp_staff = {
        TsmModuleData.OP_ADD_STAFF,
        TsmModuleData.OP_REMOVE_STAFF
    }
    TsmModuleData.commit = function(pn, op_id, a1, a2, a3, a4)
        local ret, msg = MDHelper.commit(pn, op_id, a1, a2, a3, a4)
        if should_precomp_maps[op_id] then
            precomp_maps()
        end
        if should_precomp_staff[op_id] then
            precomp_staff()
        end
        return ret, msg
    end
    
    MDHelper.init(FILE_NUMBER, MD_SCHEMA,
            LATEST_MD_VER, operations, DEFAULT_DB, not is_official_room,
            function()
                precomp_maps()
                precomp_staff()
            end
    )
end
