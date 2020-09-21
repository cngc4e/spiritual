-- Player data helper
local PDHelper = {}
do
    -- Global player data structure - SHARED ACROSS MODULES; DO NOT CHANGE
    local GLOBAL_PD_SCHEMA = {
        db2.VarDataList{ key="modules", size=128, datatype=db2.Object{schema={
            db2.UnsignedInt{ key="id", size=1 },
            db2.VarChar{ key="encoded", size=2097152 },
        }}},
    }

    local LOAD_PD_TICKS = 2

    local noSaveFile = false
    local moduleId = nil
    local mdSchema = nil
    local schemaVer = nil
    local defaultData = nil
    local updateCallback = nil
    local loadPdTicksNow = 0
    local scheduledSaves = {}  -- [pn] = func(mdpd_data)[]

    local updatePd = function(pn, mpdata)
        local s = scheduledSaves[pn]
        if s then
            for i = 1, #s do
                s[i](mpdata)
            end
            scheduledSaves[pn] = nil
            return true
        end
    end

    PDHelper.onPdLoaded = function(pn, data)
        local global_pd = nil
        if data == "" then
            global_pd = {modules={}}
        else
            local success, ret = pcall(db2.decode, GLOBAL_PD_SCHEMA, data)
            if not success then
                global_pd = {modules={}}
                print("corrupt global PD "..pn)
            else
                global_pd = ret
            end
        end

        local modules = global_pd.modules
        local module_index = -1
    
        local encoded_module_pd = nil
        for i = 1, #modules do
            if modules[i].id == moduleId then
                encoded_module_pd = modules[i].encoded
                module_index = i
                break
            end
        end

        local module_pd = nil
        if encoded_module_pd then
            local success, ret = pcall(db2.decode, mdSchema, encoded_module_pd)
            if not success then
                module_pd = table_copy(defaultData)
                print("corrupt module PD "..pn)
            else
                module_pd = ret
            end
            print("load existing "..pn)
        else
            module_pd = table_copy(defaultData)
            print("load new "..pn)
        end

        local should_save = updatePd(pn, module_pd)

        if updateCallback then
            updateCallback(pn, module_pd)
        end

        -- Save it for real
        if should_save and not noSaveFile then
            encoded_module_pd = db2.encode(mdSchema[schemaVer], module_pd)
            if module_index > 0 then
                -- existing data
                modules[module_index].encoded = encoded_module_pd
            else
                -- new data
                modules[#modules+1] = {
                    id = moduleId,
                    encoded = encoded_module_pd
                }
            end
            local encoded_global_pd = db2.encode(GLOBAL_PD_SCHEMA, global_pd)
            system.savePlayerData(pn, encoded_global_pd)
        end
    end

    PDHelper.onLoop = function()
        if loadPdTicksNow >= LOAD_PD_TICKS then
            loadPdTicksNow = 0
        end
        if loadPdTicksNow == 0 then
            for name in pairs(scheduledSaves) do
                system.loadPlayerData(name)
            end
        end
        loadPdTicksNow = loadPdTicksNow + 1
    end
        

    PDHelper.setScheduleSave = function(pn, update_func)
        if not scheduledSaves[pn] then
            scheduledSaves[pn] = {}
        end

        local s = scheduledSaves[pn]
        s[#s+1] = update_func
    end

    PDHelper.init = function(mod_id, schema, schema_version, default_data, update_callback, params)
        params = params or {}
        if params.NOSAVEFILE then
            noSaveFile = true
        end
        moduleId = mod_id
        mdSchema = schema
        schemaVer = schema_version
        defaultData = default_data
        updateCallback = update_callback
    end
end
