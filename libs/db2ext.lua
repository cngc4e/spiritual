-- db2 type extensions
do
    local numbertobytes = db2.numbertobytes
    local nbytestonumber = db2.nbytestonumber
    local Datatype = db2.Datatype

    db2.TfmUsername = Datatype {
        init = function( o , params )
            db2.info = 0
        end,
        encode = function( o , data , bpb )
            if type(data) ~= "string" then db2.info = 1 return error( "db2: TfmUsername: encode: Expected string, found " .. type(data) ) end

            local name , tag = data:match("(%S+)#(%d+)")
            if not name or not tag then db2.info = 1 return error( "db2: TfmUsername: encode: Invalid username syntax " .. data ) end
            if #name > 20 then db2.info = 2 return error( "db2: TfmUsername: encode: Username length is bigger than 20" ) end
            if #tag ~= 4 then db2.info = 1 return error( "db2: TfmUsername: encode: Tag length is not equal to 4" ) end
            tag = tonumber( tag )

            -- <(int) username size; 1 byte><(str) username><(int) tag; 2 bytes>
            return numbertobytes( #name , bpb , 1 ) .. name .. numbertobytes( tag , bpb , 2 )
        end,
        decode = function( o , enc , ptr , bpb )
            local name_len , name , tag

            -- 1 byte used for username size
            name_len = nbytestonumber( { enc:byte( ptr , ptr ) } , bpb )
            name = enc:sub( ptr + 1 , ptr + name_len )
            ptr = ptr + name_len + 1

            -- 2 bytes used for username tag
            tag = nbytestonumber( { enc:sub( ptr , ptr + 1 ) } , bpb )
            ptr = ptr + 2

            return string.format( "%s#%04d" , name , tag ) , ptr
        end
    }
end
