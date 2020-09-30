local XMLParse
local XMLNode
do
    -- XML Parser by Leafileaf
    -- Modified version
    XMLNode = {}
    XMLNode.__index = XMLNode
    XMLNode.addchild = function( o , c )
        o.children = o.children + 1
        o.child[o.children] = c
        -- o[o.children] = c
    end
    XMLNode.traverse_first = function( d , ... )
        -- XMLNode d
        -- string ...traversalpath
        -- return XMLNode? = result
        local res = d
        local tpath = { ... }
        for i = 1 , #tpath do
            local found = nil
            for k = 1 , res.children do
                local c = res.child[k]
                if c.name == tpath[i] then
                    found = c
                    break
                end
            end
            if not found then return nil end
            res = found
        end
        return res
    end
    XMLNode.toXMLString = function( o )
        local attrs = {}
        for k,v in pairs(o.attrib) do attrs[#attrs+1] = k..'="'..v..'"' end
        local str = string.format("<%s%s", o.name, #attrs > 0 and " " .. table.concat(attrs, " ") .. " " or "")
        if o.children > 0 then
            local cstr = {}
            for i = 1, o.children do
                cstr[i] = o.child[i]:toXMLString()
            end
            str = str .. ">" .. table.concat(cstr) .. "</" .. o.name .. ">"
        else
            str = str .. "/>"
        end
        return str
    end
    XMLNode.new = function( c , n , p )
        local o = setmetatable( {} , XMLNode )
        o.name = n
        o.attrib = {}
        o.parent = p or o
        o.child = {}
        o.children = 0
        if p then p:addchild( o ) end
        return o
    end

    local xml = {
        parse = function( s )
            -- Parses an XML string.
            -- string s
            -- return XMLNode = document
            -- return false if malformed document
            local document = XMLNode:new("Document") -- root node
            local cnode = document
            for closing , name , attrib , leaf in s:gmatch("<(/?)([%w_]+)(.-)(/?)>") do -- parse nodes. will fail if attributes contain >, use a more robust parser to handle
                if closing == "/" then
                    if leaf == "/" then return false end -- </Name/> doesn't make sense
                    if name ~= cnode.name then return false end -- <a></b> doesn't make sense
                    if attrib ~= "" then return false end -- </Name a="b"> doesn't make sense
                    if cnode == document then return false end -- faking out the system? nice try
                    cnode = cnode.parent -- go up one level
                else
                    local e = XMLNode:new( name , cnode ) -- make a node
                    for k , v in attrib:gmatch("%s([%a_:][^%s%c]-)%s*=%s*\"(.-)\"") do -- attribute key/value matching. will fail if attribute value contain " (through escaping), use a more robust parser to handle
                        e.attrib[k] = v
                    end
                    if leaf == "" then cnode = e end -- not a self-closing tag, 
                end
            end
            if cnode ~= document then return false end
            return document
        end,
        traverse = function( d , ... )
            -- XMLNode[] d
            -- string ...traversalpath
            -- return XMLNode[] = results
            local res = d.name and {d} or d
            local tpath = { ... }
            for i = 1 , #tpath do
                local nres = {}
                for j = 1 , #res do
                    for k = 1 , res[j].children do
                        local c = res[j].child[k]
                        if c.name == tpath[i] then
                            nres[#nres+1] = c
                        end
                    end
                end
                res = nres
            end
            
            return res
        end,
        toXMLString = function( d )
            -- XMLNode[] d
            -- return string = xml
            local nodes = d.name and {d} or d
            local res = {}
            for i = 1, #nodes do
                res[i] = nodes[i]:toXMLString()
            end
            return table.concat( res )
        end,
        XMLNode = XMLNode,
    }
    
    XMLNode.traverse = xml.traverse
    
    XMLParse = xml
end
