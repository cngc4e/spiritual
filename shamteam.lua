--[[ libs/PairTable.lua ]]--
local PairTable
do
    local function cnext(tbl, k)
        local v
        k, v = next(tbl, k)
        if k ~= "_len" then 
            return k,v
        else
            k, v = next(tbl, k)
            return k,v
        end
    end
    local PairTableProto = {
        add = function(self, key)
            self[key] = true
            self._len = self._len + 1
        end,
        remove = function(self, key)
            self[key] = nil
            self._len = self._len - 1
        end,
        len = function(self)
            return self._len
        end,
        pairs = function(self)
            return cnext, self, nil
        end,
    }
    PairTableProto.__index = PairTableProto
    PairTable = {
        new = function(self, t)
            local tbl
            if t then
                tbl = {}
                local len = 0
                for k, v in cnext, t do
                    tbl[k] = v
                    len = len + 1
                end
                tbl._len = len
            else
                tbl = { _len = 0 }
            end
            return setmetatable(tbl, PairTableProto)
        end,
    }
end
--[[ end of libs/PairTable.lua ]]--
--[[ libs/bitset.lua ]]--
local bitset = {}
do
    -- Note: Error checking for OOB have been commented out, ensure
    -- that positions stay within the size of MAX_POSITION_SIZE
    -- (AKA: 0 < position < MAX_POSITION_SIZE - 1)
    local bit    = bit32
    local band   = bit.band
    local bnot   = bit.bnot
    local bor    = bit.bor
    local bxor   = bit.bxor
    local lshift = bit.lshift
    local MAX_POSITION_SIZE = 32  -- Maximum size supported by bit32 library

    local bits = {}
    for i = 0, MAX_POSITION_SIZE - 1 do
        bits[i] = lshift(1, i)
    end

    -- bitset:set(pos1, ..., posn)
    -- Set bits at all nth positions to true.
    bitset.set = function(self, ...)
        for i = 1, arg.n do
            --if arg[i] < 0 or arg[i] >= MAX_POSITION_SIZE then error("position out of bounds") end
            self._b = bor(self._b, bits[arg[i]])
        end
        return self
    end

    -- bitset:unset(pos1, ..., posn)
    -- Set bits at all nth positions to false.
    bitset.unset = function(self, ...)
        for i = 1, arg.n do
            --if arg[i] < 0 or arg[i] >= MAX_POSITION_SIZE then error("position out of bounds") end
            self._b = band(self._b, bnot(bits[arg[i]]))
        end
        return self
    end

    -- bitset:flip(pos)
    -- Flips bit at position pos.
    bitset.flip = function(self, pos)
        self._b = bxor(self._b, bits[pos])
        return self
    end

    -- bitset:setall()
    -- Set all bits within MAX_POSITION_SIZE to true.
    bitset.setall = function(self)
        self._b = bnot(0)
        return self
    end

    -- bitset:reset()
    -- Sets all bits to false (0).
    bitset.reset = function(self)
        self._b = 0
        return self
    end

    -- bitset:isset(pos)
    -- Returns true if the bit at position pos is set, false otherwise.
    bitset.isset = function(self, pos)
        return band(self._b, bits[pos]) ~= 0
    end

    -- bitset:issubset(bitset_object)
    -- Returns true if bitset_object is a subset of this bitset.
    bitset.issubset = function(self, bitset_object)
        --if not bitset_object._b then return error("not a valid bitset object") end
        return band(self._b, bitset_object._b) ~= 0
    end

    -- bitset:tonumber()
    -- Returns an integer representation of the bitset.
    bitset.tonumber = function(self, bitset_object)
        return self._b
    end

    bitset.new = function(number)
        return setmetatable({
            _b = number or 0,
        }, bitset)
    end
    
    bitset.__index = bitset
end
--[[ end of libs/bitset.lua ]]--
--[[ libs/db2.lua ]]--
local db2
do
    -- database2
    -- serialisating objects with known structure
    -- by Leafileaf

    ----- IMPORTANT -----
    -- database2 can decode and encode database1 strings, but encoding to db1 is discouraged

	db2 = {}
	db2.VERSION = "1.3"
	
	local error = error
	
	local log2 = math.log(2)
	
	db2.info = 0
	-- INFO ENUMS --
	db2.INFO_OK = 0
	db2.INFO_INTERNALERROR = -1 -- uh oh!
	db2.INFO_ENCODE_DATAERROR = 1 -- invalid parameter
	db2.INFO_ENCODE_DATASIZEERROR = 2 -- data is too large to store
	db2.INFO_ENCODE_GENERICERROR = 3
	db2.INFO_DECODE_BADSTRING = 4 -- not a db2 string
	db2.INFO_DECODE_MISSINGSCHEMA = 5 -- schema with given version doesn't exist
	db2.INFO_DECODE_CORRUPTSTRING = 6 -- end of parsing but not end of string or vice versa
	db2.INFO_DATATYPE_ERROR = 7 -- errors when initialising datatypes
	db2.INFO_GENERICERROR = 8
	db2.INFO_DECODE_GENERICERROR = 9
	-- END INFO ENUMS --
	
	local lbtn = function( str , b ) -- big-endian byte to number
		local n = 0
		local mult = 2^b
		for i = 1 , str:len() do
			n = n * mult + str:byte( i )
		end
		return n
	end
	local lntb = function( num , b , expected_length ) -- legacy; shouldn't be needed here actually
		local str = ""
		local mult = 2^b
		while num ~= 0 do
			local x = num % mult
			str = string.char( x ) .. str
			num = math.floor( num / mult )
		end
		while str:len() < expected_length do str = string.char( 0 ) .. str end
		return str
	end
	local bytestonumber = function( str , bpb )
		local n = 0
		local mult = 2^bpb
		local strlen = str:len()
		local bytes = {str:byte(1,strlen)}
		for i = 1 , strlen do
			n = n + bytes[i]*(mult^(i-1))
		end
		return n
	end
	local strchar = {}
	for i = 0 , 2^8 - 1 do
		strchar[i] = string.char( i )
	end
	local numbertobytes = function( num , bpb , len )
		local t = {}
		local mult = 2^bpb
		for i = 1 , len do -- ensures no overflow, and forces length to be exactly len
			local x = num % mult
			t[i] = strchar[x]
			num = ( num - num % mult ) / mult -- floored divide
		end
		return table.concat( t )
	end
	local islegacy = false
	
	--local datatypeCopy = function(  ) ------- WIP
	
	local Datatype = function( dtinfo )
		
		if type(dtinfo) ~= "table" or not ( dtinfo.init and dtinfo.encode and dtinfo.decode ) then
			db2.info = -1
			return error( "db2: internal error: incorrect parameters to Datatype" , 2 )
		end
		if type(dtinfo.init) ~= "function" or type(dtinfo.encode) ~= "function" or type(dtinfo.decode) ~= "function" then
			db2.info = -1
			return error( "db2: internal error: invalid type of parameters to Datatype" , 2 )
		end
		local init , encode , decode = dtinfo.init , dtinfo.encode , dtinfo.decode
		local mt
		local r = function( params )
			local o = setmetatable( {key=params.key} , mt )
			init( o , params )
			return o
		end
		mt = { __index = { encode = encode , decode = decode , basetype = r } }
		
		
		return r
	end
	
	db2.UnsignedInt = Datatype{
		init = function( o , params )
			db2.info = 0
			
			local bytes = params.size
			if type(bytes) ~= "number" then db2.info = 7 return error( "db2: UnsignedInt: Expected number, found " .. type(bytes) , 2 ) end
			if math.floor(bytes) ~= bytes then db2.info = 7 return error( "db2: UnsignedInt: Expected integer" , 2 ) end
			
			o.__bytes = bytes
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "number" then db2.info = 1 return error( "db2: UnsignedInt: encode: Expected number, found " .. type(data) ) end
			if math.floor(data) ~= data or data < 0 then db2.info = 1 return error( "db2: UnsignedInt: encode: Can only encode unsigned integers" ) end
			return numbertobytes( data , bpb , o.__bytes )
		end,
		decode = function( o , enc , ptr , bpb )
			local r = bytestonumber( enc:sub( ptr , ptr + o.__bytes - 1 ) , bpb )
			ptr = ptr + o.__bytes
			return r , ptr
		end
	}
	
	db2.Float = Datatype{ -- single-precision floats -- https://stackoverflow.com/questions/14416734/lua-packing-ieee754-single-precision-floating-point-numbers
		init = function( o , params )
			db2.info = 0
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "number" then db2.info = 1 return error( "db2: Float: encode: Expected number, found " .. type(data) ) end
			
			local fullbits = 2^bpb - 1 -- 1111111(1)
			local msb = 2^(bpb-1) -- 1000000(0)
			local fmsb = msb - 1 -- 0111111(1)
			local bytesep = 2^bpb
			
			if data == 0 then
				return string.char( 0 , 0 , 0 , 0 )
			elseif data ~= data then
				return string.char( fullbits , fullbits , fullbits , fullbits ) -- nan
			else
				local sign = 0
				if data < 0 then
					sign = msb
					data = -data
				end
				
				local mant , expo = math.frexp( data )
				
				expo = expo + fmsb
				if expo < 0 then -- small number
					mant = math.ldexp( mant , expo - 1 )
					expo = 0
				elseif expo > 0 then
					if expo >= fullbits then
						return string.char( 0 , 0 , msb , sign + fmsb )
					elseif expo == 1 then
						expo = 0
					else
						mant = mant * 2 - 1
						expo = expo - 1
					end
				end
				mant = math.floor( math.ldexp( mant , 3 * bpb - 1 ) + 0.5 ) -- round to nearest integer mantissa
				return string.char(
					mant % bytesep,
					math.floor( mant / bytesep ) % bytesep,
					( expo % 2 ) * msb + math.floor( mant / bytesep / bytesep ),
					sign + math.floor( expo / 2 )
				)
			end
		end,
		decode = function( o , enc , ptr , bpb )
			local b4 , b3 , b2 , b1 = enc:byte( ptr , ptr + 3 )
			ptr = ptr + 4
			
			local fullbits=  2^bpb - 1
			local msb = 2^(bpb-1)
			local fmsb = msb - 1
			local bytesep = 2^bpb
			
			local expo = ( b1 % msb ) * 2 + math.floor( b2 / msb )
			local mant = math.ldexp( ( ( b2 % msb ) * bytesep + b3 ) * bytesep + b4 , -( 3 * bpb - 1 ) )
			
			if expo == fullbits then
				if mant > 0 then
					return 0/0
				else
					mant = math.huge
					expo = fmsb
				end
			elseif expo > 0 then
				mant = mant + 1
			else
				expo = expo + 1
			end
			if b1 >= msb then
				mant = -mant
			end
			return math.ldexp( mant , expo - fmsb ) , ptr
		end
	}
	
	db2.Double = Datatype{
		init = function( o , params )
			db2.info = 0
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "number" then db2.info = 1 return error( "db2: Double: encode: Expected number, found " .. type(data) ) end
			
			local fullbits = 2^bpb - 1 -- 1111111(1)
			local msb = 2^(bpb-1) -- 1000000(0)
			local fmsb = msb - 1 -- 0111111(1)
			local fullexpo = 2^(bpb+3) - 1 -- 1111111111(1), full bits of expo field
			local mpe = 2^(bpb+2) - 1 -- 0111111111(1), making expo positive
			local top4 = fullbits - ( 2^(bpb-4) - 1 ) -- 1111000(0), top 4 bits filled
			local top4msb = 2^(bpb-4) -- 0001000(0), encoding expo
			local bytesep = 2^bpb
			
			if data == 0 then
				return string.char( 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 )
			elseif data ~= data then
				return string.char( fullbits , fullbits , fullbits , fullbits , fullbits , fullbits , fullbits , fullbits ) -- nan
			else
				local sign = 0
				if data < 0 then
					sign = msb
					data = -data
				end
				
				local mant , expo = math.frexp( data )
				
				expo = expo + mpe
				if expo < 0 then -- small number
					mant = math.ldexp( mant , expo - 1 )
					expo = 0
				elseif expo > 0 then
					if expo >= fullexpo then
						return string.char( 0 , 0 , 0 , 0 , 0 , 0 , top4 , sign + fmsb )
					elseif expo == 1 then
						expo = 0
					else
						mant = mant * 2 - 1
						expo = expo - 1
					end
				end
				mant = math.floor( math.ldexp( mant , 7 * bpb - 4 ) + 0.5 ) -- round to nearest integer mantissa
				return numbertobytes( mant , bpb , 6 ) .. string.char(
					( expo % 16 ) * top4msb + math.floor( mant / ( bytesep ^ 6 ) ),
					sign + math.floor( expo / 16 )
				)
			end
		end,
		decode = function( o , enc , ptr , bpb )
			local b2 , b1 = enc:byte( ptr + 6 , ptr + 7 )
			local b38 = enc:sub( ptr , ptr + 5 )
			ptr = ptr + 8
			
			local fullbits=  2^bpb - 1
			local msb = 2^(bpb-1)
			local fmsb = msb - 1
			local fullexpo = 2^(bpb+3) - 1
			local mpe = 2^(bpb+2) - 1
			local top4 = fullbits - ( 2^(bpb-4) - 1 )
			local top4msb = 2^(bpb-4)
			local bytesep = 2^bpb
			
			local expo = ( b1 % msb ) * 16 + math.floor( b2 / top4msb )
			local mant = math.ldexp( ( b2 % top4msb ) * ( bytesep ^ 6 ) + bytestonumber( b38 , bpb ) , -( 7 * bpb - 4 ) )
			
			if expo == fullexpo then
				if mant > 0 then
					return 0/0
				else
					mant = math.huge
					expo = fmsb
				end
			elseif expo > 0 then
				mant = mant + 1
			else
				expo = expo + 1
			end
			if b1 >= msb then
				mant = -mant
			end
			return math.ldexp( mant , expo - mpe ) , ptr
		end
	}
	
	db2.VarChar = Datatype{
		init = function( o , params )
			db2.info = 0
			
			local sz , nbits = params.size , math.log( params.size + 1 ) / log2
			if type(sz) ~= "number" then db2.info = 7 return error( "db2: VarChar: Expected number, found " .. type(sz) , 2 ) end
			if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: VarChar: Expected integer" , 2 ) end
			
			o.__sz , o.__nbits = sz , nbits
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "string" then db2.info = 1 return error( "db2: VarChar: encode: Expected string, found " .. type(data) ) end
			if data:len() > o.__sz then db2.info = 2 return error( "db2: VarChar: encode: Data is bigger than is allocated for" ) end
			local lsz = math.ceil(o.__nbits/bpb) -- length of size
			return numbertobytes( data:len() , bpb , lsz ) .. data
		end,
		decode = function( o , enc , ptr , bpb )
			local lsz = math.ceil(o.__nbits/bpb)
			local len = bytestonumber( enc:sub( ptr , ptr + lsz - 1 ) , bpb )
			ptr = ptr + lsz + len
			return enc:sub( ptr - len , ptr - 1 ) , ptr
		end
	}
	
	db2.FixedChar = Datatype{
		init = function( o , params )
			db2.info = 0
			
			local sz = params.size
			if type(sz) ~= "number" then db2.info = 7 return error( "db2: FixedChar: Expected number, found " .. type(sz) , 2 ) end
			if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: FixedChar: Expected integer" , 2 ) end
			
			o.__sz = sz
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "string" then db2.info = 1 return error( "db2: FixedChar: encode: Expected string, found " .. type(data) ) end
			if data:len() > o.__sz then db2.info = 2 return error( "db2: FixedChar: encode: Data is bigger than is allocated for" ) end
			return data .. string.char(0):rep( o.__sz - data:len() )
		end,
		decode = function( o , enc , ptr , bpb )
			local r = enc:sub( ptr , ptr + o.__sz - 1 )
			ptr = ptr + o.__sz
			return r , ptr
		end
	}
	
	db2.Bitset = Datatype{
		init = function( o , params )
			db2.info = 0
			
			local sz = params.size
			if type(sz) ~= "number" then db2.info = 7 return error( "db2: Bitset: Expected number, found " .. type(sz) , 2 ) end
			if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: Bitset: Expected integer" , 2 ) end
			
			o.__sz = sz
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "table" then db2.info = 1 return error( "db2: Bitset: encode: Expected table, found " .. type(data) ) end
			if #data > o.__sz then db2.info = 2 return error( "db2: Bitset: encode: Data is bigger than is allocated for" ) end
			local r = {}
			local nr = 0
			for i = 1 , math.ceil( o.__sz / bpb ) do
				local n = 0
				for j = 1 , bpb do
					n = n + ( data[(i-1)*bpb+j] and 1 or 0 ) * 2^(j-1)
				end
				nr = nr + 1
				r[nr] = strchar[n]
			end
			return table.concat( r )
		end,
		decode = function( o , enc , ptr , bpb )
			local r = {}
			local nr = 0
			local bssz = math.ceil( o.__sz / bpb )
			local bytes = { enc:byte( ptr , ptr+bssz-1 ) }
			for i = 1 , bssz do
				local n = bytes[i]
				for j = 1 , bpb do
					nr = nr+1
					r[nr] = n%2 == 1
					if nr == o.__sz then break end
					n = (n-n%2)/2 -- floored divide
				end
			end
			ptr = ptr + bssz
			return r , ptr
		end
	}
	
	db2.VarBitset = Datatype{
		init = function( o , params )
			db2.info = 0
			
			local sz , nbits = params.size , math.log( params.size + 1 ) / log2
			if type(sz) ~= "number" then db2.info = 7 return error( "db2: VarBitset: Expected number, found " .. type(sz) , 2 ) end
			if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: VarBitset: Expected integer" , 2 ) end
			
			o.__sz , o.__nbits = sz , nbits
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "table" then db2.info = 1 return error( "db2: VarBitset: encode: Expected table, found " .. type(data) ) end
			if #data > o.__sz then db2.info = 2 return error( "db2: VarBitset: encode: Data is bigger than is allocated for" ) end
			local lsz = math.ceil(o.__nbits/bpb)
			local ldata = #data
			local r = { numbertobytes( ldata , bpb , lsz ) }
			local nr = 1
			for i = 1 , math.ceil( ldata / bpb ) do
				local n = 0
				for j = 1 , bpb do
					n = n + ( data[(i-1)*bpb+j] and 1 or 0 ) * 2^(j-1)
				end
				nr = nr + 1
				r[nr] = strchar[n]
			end
			return table.concat( r )
		end,
		decode = function( o , enc , ptr , bpb )
			local lsz = math.ceil(o.__nbits/bpb)
			local num = bytestonumber( enc:sub( ptr , ptr + lsz - 1 ) , bpb )
			local r = {}
			local nr = 0
			local bssz = math.ceil( num / bpb )
			local bytes = { enc:byte( ptr+lsz , ptr+lsz+bssz-1 ) }
			for i = 1 , bssz do
				local n = bytes[i]
				for j = 1 , bpb do
					nr = nr + 1
					r[nr] = n%2 == 1
					if nr == num then break end
					n = (n-n%2)/2 -- floored divide
				end
			end
			ptr = ptr + lsz + bssz
			return r , ptr
		end
	}
	
	db2.VarDataList = Datatype{
		init = function( o , params )
			db2.info = 0
			
			local sz , nbits , dt = params.size , math.log( params.size + 1 ) / log2 , params.datatype
			if type(sz) ~= "number" then db2.info = 7 return error( "db2: VarDataList: Expected number, found " .. type(sz) , 2 ) end
			if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: VarDataList: Expected integer" , 2 ) end
			if type(dt) ~= "table" or not dt.basetype then db2.info = 7 return error( "db2: VarDataList: Expected datatype, found " .. type(dt) , 2 ) end
			
			o.__sz , o.__nbits , o.__dt = sz , nbits , dt
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "table" then db2.info = 1 return error( "db2: VarDataList: encode: Expected table, found " .. type(data) ) end
			if #data > o.__sz then db2.info = 2 return error( "db2: VarDataList: encode: Data is bigger than is allocated for" ) end
			local lsz = math.ceil(o.__nbits/bpb) -- length of size
			local enc = { numbertobytes( #data , bpb , lsz ) }
			for i = 1 , #data do
				enc[i+1] = o.__dt:encode( data[i] , bpb )
			end
			return table.concat( enc )
		end,
		decode = function( o , enc , ptr , bpb )
			local lsz = math.ceil(o.__nbits/bpb)
			local n = bytestonumber( enc:sub( ptr , ptr + lsz - 1 ) , bpb ) -- size of list
			ptr = ptr + lsz
			local out = {}
			for i = 1 , n do
				out[i] , ptr = o.__dt:decode( enc , ptr , bpb )
			end
			return out , ptr
		end
	}
	
	db2.FixedDataList = Datatype{
		init = function( o , params )
			db2.info = 0
			
			local sz , dt = params.size , params.datatype
			if type(sz) ~= "number" then db2.info = 7 return error( "db2: FixedDataList: Expected number, found " .. type(sz) , 2 ) end
			if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: FixedDataList: Expected integer" , 2 ) end
			if type(dt) ~= "table" or not dt.basetype then db2.info = 7 return error( "db2: FixedDataList: Expected datatype, found " .. type(dt) , 2 ) end
			
			o.__sz , o.__dt = sz , dt
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "table" then db2.info = 1 return error( "db2: FixedDataList: encode: Expected table, found " .. type(data) ) end
			if #data ~= o.__sz then db2.info = 2 return error( "db2: FixedDataList: encode: Data size is not as declared" ) end
			local enc = {}
			for i = 1 , o.__sz do
				enc[i] = o.__dt:encode( data[i] , bpb )
			end
			return table.concat( enc )
		end,
		decode = function( o , enc , ptr , bpb )
			local out = {}
			for i = 1 , o.__sz do
				out[i] , ptr = o.__dt:decode( enc , ptr , bpb )
			end
			return out , ptr
		end
	}
	
	db2.VarObjectList = Datatype{
		init = function( o , params )
			db2.info = 0
			
			print("NOTE: VarObjectList is deprecated. Use db2.VarDataList with a db2.Object as the datatype instead")
			
			local sz , nbits , schema = params.size , math.log( params.size + 1 ) / log2 , params.schema
			if type(sz) ~= "number" then db2.info = 7 return error( "db2: VarObjectList: Expected number, found " .. type(sz) , 2 ) end
			if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: VarObjectList: Expected integer" , 2 ) end
			if type(schema) ~= "table" then db2.info = 7 return error( "db2: VarObjectList: Expected table, found " .. type(schema) , 2 ) end
			
			o.__sz , o.__nbits , o.__schema = sz , nbits , schema
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "table" then db2.info = 1 return error( "db2: VarObjectList: encode: Expected table, found " .. type(data) ) end
			if #data > o.__sz then db2.info = 2 return error( "db2: VarObjectList: encode: Data is bigger than is allocated for" ) end
			local lsz = math.ceil(o.__nbits/bpb) -- length of size
			local enc = { numbertobytes( #data , bpb , lsz ) }
			for i = 1 , #data do
				for j = 1 , #o.__schema do -- same loop as db2.encode
					table.insert( enc , o.__schema[j]:encode( data[i][o.__schema[j].key] , bpb ) )
				end
			end
			return table.concat( enc )
		end,
		decode = function( o , enc , ptr , bpb )
			local lsz = math.ceil(o.__nbits/bpb)
			local n = bytestonumber( enc:sub( ptr , ptr + lsz - 1 ) , bpb ) -- size of list
			ptr = ptr + lsz
			local out = {}
			for i = 1 , n do
				out[i] = {}
				for j = 1 , #o.__schema do -- same loop as db2.decode
					out[i][o.__schema[j].key] , ptr = o.__schema[j]:decode( enc , ptr , bpb )
				end
			end
			return out , ptr
		end
	}
	
	db2.FixedObjectList = Datatype{
		init = function( o , params )
			db2.info = 0
			
			print("NOTE: FixedObjectList is deprecated. Use db2.FixedDataList with a db2.Object as the datatype instead")
			
			local sz , schema = params.size , params.schema
			if type(sz) ~= "number" then db2.info = 7 return error( "db2: FixedObjectList: Expected number, found " .. type(sz) , 2 ) end
			if math.floor(sz) ~= sz then db2.info = 7 return error( "db2: FixedObjectList: Expected integer" , 2 ) end
			if type(schema) ~= "table" then db2.info = 7 return error( "db2: FixedObjectList: Expected table, found " .. type(schema) , 2 ) end
			
			o.__sz , o.__schema = sz , schema
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "table" then db2.info = 1 return error( "db2: FixedObjectList: encode: Expected table, found " .. type(data) ) end
			if #data ~= o.__sz then db2.info = 2 return error( "db2: FixedObjectList: encode: Data size is not as declared" ) end
			local enc = {}
			for i = 1 , o.__sz do
				for j = 1 , #o.__schema do
					table.insert( enc , o.__schema[j]:encode( data[i][o.__schema[j].key] , bpb ) )
				end
			end
			return table.concat( enc )
		end,
		decode = function( o , enc , ptr , bpb )
			local out = {}
			for i = 1 , o.__sz do
				out[i] = {}
				for j = 1 , #o.__schema do
					out[i][o.__schema[j].key] , ptr = o.__schema[j]:decode( enc , ptr , bpb )
				end
			end
			return out , ptr
		end
	}
	
	db2.Switch = Datatype{
		init = function( o , params )
			db2.info = 0
			
			local typekey , typedt , dtmap = params.typekey == nil and "type" or params.typekey , params.typedatatype , params.datatypemap
			if type(dtmap) ~= "table" then db2.info = 7 return error( "db2: Switch: Expected table, found " .. type(dtmap) , 2 ) end
			if type(typedt) ~= "table" or not typedt.basetype then db2.info = 7 return error( "db2: Switch: Expected datatype, found " .. type(typedt) , 2 ) end
			
			o.__typekey , o.__typedt , o.__dtmap = typekey , typedt , dtmap
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "table" then db2.info = 1 return error( "db2: Switch: encode: Expected table, found " .. type(data) ) end
			if data[o.__typekey] and o.__dtmap[data[o.__typekey]] then
				local dt = o.__dtmap[data[o.__typekey]]
				if type(dt) ~= "table" or not dt.basetype then db2.info = 1 return error( "db2: Switch: encode: datatypemap is not a map of typekey->datatype" ) end
				local enc = {}
				return o.__typedt:encode( data[o.__typekey] , bpb ) .. dt:encode( data , bpb )
			else db2.info = 1 return error( "db2: Switch: encode: Typekey value not found or datatypemap does not contain key" ) end
		end,
		decode = function( o , enc , ptr , bpb )
			local typ , ptr = o.__typedt:decode( enc , ptr , bpb )
			local dt = o.__dtmap[typ]
			if type(dt) ~= "table" or not dt.basetype then db2.info = 9 return error( "db2: Switch: decode: datatype of decoded type is not available" ) end
			local out , ptr = dt:decode( enc , ptr , bpb )
			out[o.__typekey] = typ
			return out , ptr
		end
	}
	
	db2.SwitchObject = Datatype{
		init = function( o , params )
			db2.info = 0
			
			print("NOTE: SwitchObject is deprecated. Use db2.Switch with a db2.Object as the datatype instead")
			
			local typekey , typedt , schemamap = params.typekey == nil and "type" or params.typekey , params.typedt , params.schemamap
			if type(schemamap) ~= "table" then db2.info = 7 return error( "db2: SwitchObject: Expected table, found " .. type(schemamap) , 2 ) end
			if type(typedt) ~= "table" or not typedt.basetype then db2.info = 7 return error( "db2: SwitchObject: Expected datatype, found " .. type(typedt) , 2 ) end
			
			o.__typekey , o.__typedt , o.__schemamap = typekey , typedt , schemamap
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "table" then db2.info = 1 return error( "db2: SwitchObject: encode: Expected table, found " .. type(data) ) end
			if data[o.__typekey] and o.__schemamap[data[o.__typekey]] then
				local schema = o.__schemamap[data[o.__typekey]]
				if type(schema) ~= "table" then db2.info = 1 return error( "db2: SwitchObject: encode: schemamap is not a map of typekey->schema" ) end
				local enc = {}
				enc[1] = o.__typedt:encode( data[o.__typekey] , bpb )
				for i = 1 , #schema do
					enc[i+1] = schema[i]:encode( data[schema[i].key] , bpb )
				end
				return table.concat( enc )
			else db2.info = 1 return error( "db2: SwitchObject: encode: Typekey value not found or schemamap does not contain key" ) end
		end,
		decode = function( o , enc , ptr , bpb )
			local typ , ptr = o.__typedt:decode( enc , ptr , bpb )
			local schema = o.__schemamap[typ]
			if type(schema) ~= "table" then db2.info = 9 return error( "db2: SwitchObject: decode: schema of decoded type is not available" ) end
			local out = {[o.__typekey]=typ}
			for i = 1 , #schema do
				out[schema[i].key] , ptr = schema[i]:decode( enc , ptr , bpb )
			end
			return out , ptr
		end
	}
	
	db2.Object = Datatype{
		init = function( o , params )
			db2.info = 0
			
			local schema = params.schema
			if type(schema) ~= "table" then db2.info = 7 return error( "db2: Object: Expected table, found " .. type(schema) , 2 ) end
			
			o.__schema = schema
		end,
		encode = function( o , data , bpb )
			if type(data) ~= "table" then db2.info = 1 return error( "db2: Object: encode: Expected table, found " .. type(data) ) end
			local enc = {}
			for i = 1 , #o.__schema do
				enc[i] = o.__schema[i]:encode( data[o.__schema[i].key] , bpb )
			end
			return table.concat( enc )
		end,
		decode = function( o , enc , ptr , bpb )
			local out = {}
			for i = 1 , #o.__schema do
				out[o.__schema[i].key] , ptr = o.__schema[i]:decode( enc , ptr , bpb )
			end
			return out , ptr
		end
	}
	
	local togglelegacy = function()
		local a , b = bytestonumber , numbertobytes
		bytestonumber , numbertobytes = lbtn , lntb
		lbtn , lntb = a , b
		islegacy = not islegacy
	end
	
	local checklegacy = function() -- maybe an error occurred while encoding/decoding in legacy mode
		if islegacy then togglelegacy() end
	end
	
	local legacy = function( f , ... )
		togglelegacy()
		local r = f( ... )
		togglelegacy()
		return r
	end
	
	local function encode( schema , data , params ) -- schema , data
		db2.info = 0
		--checklegacy()
		
		params = params or {}
		local USE_SETTINGS = params.USE_SETTINGS or true
		local USE_EIGHTBIT = params.USE_EIGHTBIT or false
		local USE_MAGIC = params.USE_MAGIC or true
		local USE_VERSION = params.USE_VERSION
		local USE_LEGACY = params.USE_LEGACY
		local VERSION = params.VERSION or schema.VERSION
		
		if USE_LEGACY then
			return legacy( encode , schema , data , {
				USE_SETTINGS = false,
				USE_EIGHTBIT = USE_EIGHTBIT,
				USE_MAGIC = false,
				USE_VERSION = USE_VERSION or 2
			} )
		end
		if params.USE_SCHEMALIST then db2.info = 3 return error("db2: encode: Cannot treat schema as a list",2) end
		
		local bpb = USE_EIGHTBIT and 8 or 7
		
		local vl = params.USE_VERSION or ( ( not VERSION ) and 0 or math.ceil((math.log(VERSION+1)/log2)/bpb) )
		local enc = {
			USE_SETTINGS and numbertobytes( vl + 8 + ( USE_MAGIC and 16 or 0 ) + 32 + ( USE_EIGHTBIT and 128 or 0 ) , bpb , 1 ) or "",
			USE_MAGIC and numbertobytes( 9224 + ( USE_EIGHTBIT and 32768 or 0 ) , bpb , 2 ) or "",
			numbertobytes( VERSION or 0 , bpb , vl ),
		}
        for i = 1 , #schema do
			enc[i+3] = schema[i]:encode( data[schema[i].key] , bpb )
			if db2.info ~= 0 then return end
		end
		return table.concat( enc )
	end
	
	local function decode( t , enc , params )
		db2.info = 0
		--checklegacy()
		
		params = params or {}
		local USE_SETTINGS = params.USE_SETTINGS or true
		local USE_EIGHTBIT = params.USE_EIGHTBIT or false
		local USE_MAGIC = params.USE_MAGIC or true
		local USE_VERSION = params.USE_VERSION or nil
		local USE_LEGACY = params.USE_LEGACY
		
		if USE_LEGACY then
			return legacy( decode , t , enc , {
				USE_SETTINGS = false,
				USE_EIGHTBIT = USE_EIGHTBIT,
				USE_MAGIC = false,
				USE_VERSION = USE_VERSION or 2
			} )
		end
		
		local bpb = USE_EIGHTBIT and 8 or 7
		
		local ptr = 1
		local vl = USE_VERSION
		
		if USE_SETTINGS then
			local settings = enc:byte(ptr)
			
			if not ( settings % 2^6 >= 2^5 and settings % 2^4 >= 2^3 ) then db2.info = 4 return error("db2: decode: Invalid settings byte",2) end
			
			vl = settings % 2^3
			USE_MAGIC = settings % 2^5 >= 2^4
			USE_EIGHTBIT = settings >= 2^7
			bpb = USE_EIGHTBIT and 8 or 7
			
			ptr = ptr + 1
		end
		
		if USE_MAGIC then
			local n = bytestonumber( enc:sub(ptr,ptr+1) , bpb )
			if ( not ( n % 32768 == 9224 ) ) or ( n > 32768 and n - 32768 ~= 9224 ) then db2.info = 4 return error("db2: decode: Invalid magic number",2) end
			
			ptr = ptr + 2
		end
		
		local vn = bytestonumber( enc:sub(ptr,ptr+vl-1) , bpb )
		ptr = ptr + vl
		
		local schema = vl == 0 and ( not params.USE_SCHEMALIST and t or t[0] ) or t[vn]
		
		if not schema then db2.info = 5 return error("db2: decode: Missing schema",2) end
		
		local dat = {}
		for i = 1 , #schema do
			dat[ schema[i].key ] , ptr = schema[i]:decode( enc , ptr , bpb )
			if ptr > enc:len() + 1 then db2.info = 6 return error("db2: decode: End of string reached while parsing",2) end
			if db2.info ~= 0 then return end
		end
		
		if ptr ~= enc:len() + 1 then db2.info = 6 return error("db2: decode: End of schema reached while parsing",2) end
		
		return dat
	end
	
	local test = function( enc , params )
		db2.info = 0
		--checklegacy()
		
		params = params or {}
		local USE_SETTINGS = params.USE_SETTINGS or true
		local USE_EIGHTBIT = params.USE_EIGHTBIT or false
		local USE_MAGIC = params.USE_MAGIC or true
		
		local bpb = USE_EIGHTBIT and 8 or 7
		
		local ptr = 1
		
		if USE_SETTINGS then
			local settings = enc:byte(ptr)
			
			if not ( settings % 2^6 >= 2^5 and settings % 2^4 >= 2^3 ) then db2.info = 4 return false end
			
			USE_MAGIC = settings % 2^5 >= 2^4
			USE_EIGHTBIT = settings >= 2^7
			bpb = USE_EIGHTBIT and 8 or 7
			
			ptr = ptr + 1
		end
		
		if USE_MAGIC then
			local n = bytestonumber( enc:sub(ptr,ptr+1) , bpb )
			if ( not ( n % 32768 == 9224 ) ) or ( n > 32768 and n - 32768 ~= 9224 ) then db2.info = 4 return false end
			
			ptr = ptr + 2
		end
		
		return true
	end
	local errorfunc = function( f )
		db2.info = 0
		
		if type(f) == "function" then error = f
		else db2.info = 8 return error( "db2: errorfunc: Expected function, found " .. type(f) , 2 ) end
	end
	
	db2.Datatype = Datatype
	db2.encode = encode
	db2.decode = decode
	db2.test = test
	db2.errorfunc = errorfunc
	db2.bytestonumber = bytestonumber
	db2.numbertobytes = numbertobytes
	db2.lbtn = lbtn
	db2.lntb = lntb
end
--[[ end of libs/db2.lua ]]--
--[[ libs/XMLParse.lua ]]--
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
        -- return XMLNode = result
        local res = d
        local tpath = { ... }
        for i = 1 , #tpath do
            for k = 1 , res.children do
                local c = res.child[k]
                if c.name == tpath[i] then
                    res = c
                    break
                end
            end
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
--[[ end of libs/XMLParse.lua ]]--

-- Init extension
local init_ext = nil

-- Cached variable lookups
local room = tfm.get.room

-- Keeps an accurate list of players and their states by rely on asynchronous events to update
-- This works around playerList issues which are caused by it relying on sync and can be slow to update
local pL = {}
do
    local states = {
        "room",
        "alive",
        "dead",
        "spectator"
    }
    for i = 1, #states do
        pL[states[i]] = PairTable:new()
    end
end

----- ENUMS / CONST DEFINES

-- Key trigger types
local DOWN_ONLY = 1
local UP_ONLY = 2
local DOWN_UP = 3

-- Others
local DEVS = {["Cass11337#8417"]=true, ["Casserole#1798"]=true}

----- Forward declarations (local)
local keys, callbacks

----- GENERAL UTILS
--[[ module/utils.lua ]]--
local function math_round(num, dp)
    local mult = 10 ^ (dp or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function math_pythag(x1, y1, x2, y2, r)
	local x,y,r = x2-x1, y2-y1, r+r
	return x*x+y*y<r*r
end

local function string_split(str, delimiter)
    local delimiter,a = delimiter or ',', {}
    for part in str:gmatch('[^'..delimiter..']+') do
        a[#a+1] = part
    end
    return a
end

local function table_copy(tbl)
    local out = {}
    for k, v in next, tbl do
        out[k] = v
    end
    return out
end

local function dumptbl (tbl, indent)
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            dumptbl(v, indent+1)
        elseif type(v) == 'boolean' then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

-- returns map code in integer type, nil if invalid
local function int_mapcode(code)
    if type(code) == "string" then
        return tonumber(code:match("@?(%d+)"))
    elseif type(code) == "number" then
        return code
    else
        return nil
    end
end

local function tl(pn, kname)
    local pref_lang = players[pn] and players[pn].lang or "en"
    local lang = translations[pref_lang] and pref_lang or "en"
    if translations[lang][kname] then
        return translations[lang][kname]
    else
        return kname
    end
end

local function ZeroTag(pn, add) --#0000 removed for tag matches
    if add then
        if not pn:find('#') then
            return pn.."#0000"
        else return pn
        end
    else
        return pn:find('#0000') and pn:sub(1,-6) or pn
    end
end

local function pFind(target, pn)
    local ign = string.lower(target or ' ')
    for name in pairs(room.playerList) do
        if string.lower(name):find(ign) then return name end
    end
    if pn then tfm.exec.chatMessage("<R>error: no such target", pn) end
end
--[[ end of module/utils.lua ]]--

----- HELPERS
--[[ helpers/map_sched.lua ]]--
local map_sched = {}
do
    local queued_code
    local queued_mirror
    local call_after
    local is_waiting = false

    local function load(code, mirror)
        queued_code = code
        queued_mirror = mirror
        if not call_after or call_after <= os.time() then
            is_waiting = false
            call_after = os.time() + 3000
            tfm.exec.newGame(code, mirror)
        else
            is_waiting = true
        end
    end

   local function run()
        if is_waiting and call_after <= os.time() then
            call_after = nil
            load(queued_code, queued_mirror)
        end
    end

    map_sched.load = load
    map_sched.run = run
end
--[[ end of helpers/map_sched.lua ]]--
--[[ helpers/tfmcmd.lua ]]--
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
--[[ end of helpers/tfmcmd.lua ]]--
--[[ helpers/MDHelper.lua ]]--
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
--[[ end of helpers/MDHelper.lua ]]--
--[[ helpers/TimedTask.lua ]]--
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
        local done, sz = {}, 0
        for id, task in pairs(tasks) do
            if os.time() >= task[2] then
                -- timer did not execute in time
                system.removeTimer(task[1])
                task[3]()
                sz = sz + 1
                done[sz] = id
            end
        end
        for i = 1, sz do
            tasks[done[i]] = nil
        end
    end
end
--[[ end of helpers/TimedTask.lua ]]--
--[[ helpers/Events.lua ]]--
local Events = {}
do
    local registered_evts = {}

    Events.hookEvent = function(name, fn)
        local evt = registered_evts[name]
        if not evt then
            registered_evts[name] = { _len = 0 }
            evt = registered_evts[name]
        end
        evt._len = evt._len + 1
        evt[evt._len] = fn
    end

    Events.doEvent = function(name, ...)
        local evt = registered_evts[name]
        if not evt then return end
        for i = 1, evt._len do
            evt[i](...)
        end
    end
end
--[[ end of helpers/Events.lua ]]--

--[[ module/Common.lua ]]--
local players = {}  -- Players[]
local translations = {}
--[[ end of module/Common.lua ]]--
--[[ module/Commands.lua ]]--
do
    local LEVEL_DEV = function(pn) return DEVS[pn] end
    
    commands = {
        --[[tfmcmd.Main {
            name = "map",
            aliases = {"np"},
            description = "Loads specified map",
            allowed = LEVEL_DEV,
            args = {
                tfmcmd.ArgString { optional = true },
            },
            func = function(pn, code)
                map_sched.load(code)
            end,
        },]]
    }

    tfmcmd.setDefaultAllow(true)
    tfmcmd.initCommands(commands)
end
--[[ end of module/Commands.lua ]]--
--[[ module/Keys.lua ]]--
keys = {
}
--[[ end of module/Keys.lua ]]--
--[[ module/Events.lua ]]--
do
    Events.hookEvent("NewPlayer", function(pn)
        system.bindMouse(pn, true)
    end)

    Events.hookEvent("PlayerLeft", function(pn)
        players[pn] = nil
    end)

    Events.hookEvent("Loop", function(elapsed, remaining)
        MDHelper.trySync()
    end)

    Events.hookEvent("FileLoaded", function(file, data)
        local success, result = pcall(MDHelper.eventFileLoaded, file, data)
        if not success then
            print(string.format("Exception encountered in eventFileLoaded: %s", result))
        end
    end)

    Events.hookEvent("FileSaved", function(file)
        MDHelper.eventFileSaved(file)
    end)
end
--[[ end of module/Events.lua ]]--
--[[ module/Player.lua ]]--
-- Common player stuff
local Player
do
    Player = {}
    Player.__index = Player

    Player.chatMsg = function(self, str)
        return tfm.exec.chatMessage(str, self.name)
    end

    Player.chatMsgFmt = function(self, str, ...)
        return tfm.exec.chatMessage(string.format(str, ...), self.name)
    end

    Player.tlFmt = function(self, kname, ...)
        local str = translations[self.lang][kname]
        return string.format(str, ...)
    end

    Player.tlChatMsg = function(self, kname, ...)
        local str = translations[self.lang][kname]
        return tfm.exec.chatMessage(string.format(str, ...), self.name)
    end

    -- Base data for this class, to be used in inherited new() methods
    Player.newData = function(self, pn)
        local p = room.playerList[pn]
        local ret = {
            name = pn,
            lang = "en",
        }
        if translations[p.community] then
            ret.lang = p.community
        end
        return ret
    end

    Player.new = function(self, pn)
        return setmetatable(self:newData(pn), self)
    end
end
--[[ end of module/Player.lua ]]--

do
    --[[ module/shamteam/Tsm.lua ]]--
-- Module variables
local is_official_room = false
local module_started = false
local ThisRound = nil

local TsmCommon
local TsmRound
local TsmModuleData
local TsmPlayer
local TsmRotation

--[[ module/shamteam/TsmEnums.lua ]]--
-- Module
local MODULE_ID = 3
local MODULE_ROOMNAME = "shamteam"

-- Round phases
local PHASE_START = 0
local PHASE_READY = 1
local PHASE_MORTED = 2
local PHASE_TIMESUP = 3

-- Modes
local TSM_HARD = 1
local TSM_DIV = 2

-- Staff
local MODULE_MANAGERS = {
    ["Cass11337#8417"] = true,
    ["Emeryaurora#0000"] = true,
    ["Pegasusflyer#0000"] = true,
    ["Rini#5475"] = true,
    ["Rayallan#0000"] = true,
    ["Shibbbbbyy#1143"] = true
}
--[[ end of module/shamteam/TsmEnums.lua ]]--
--[[ translations-gen-shamteam/*.lua ]]--
do
translations.cn = {
	close="Close",
	help_tab_welcome="Welcome",
	help_tab_rules="Rules",
	help_tab_commands="Commands",
	help_tab_contributors="Contributors",
	help_content_welcome="<p align=\"center\"><J><font size='14'><b>欢迎来到#ShamTeam</b></font></p>\n<p align=\"left\"><font size='12'><N>欢迎来到Team Shaman Mode (TSM)! TSM的游戏过程很简单：您将与另一个萨满配对，并轮流生成对象。您可以根据所保存的鼠标在回合结束时获得积分。但小心点！如果您在轮到自己或垂死时产卵而犯错，您和您的伴侣将失去积分！您将可以使用一些修饰符，使您的游戏更具挑战性，如果您赢得本轮比赛，您的得分将相应地成倍增长。\n\n加入我们的Discord服务器以获取帮助和更多信息！\n网址: %s<a href=\"event:link!%s\">discord.gg/YkzM4rh</a>",
	help_content_rules="<p align=\"center\"><J><font size='14'><b>Rules</b></font></p>\n<p align=\"left\"><font size='12'><N>- In hard mode, you must be within your partner's spawning range for a successful spawn.\n- In divine mode, using arrows deduct points.\n- Only up to 3 solid balloons may be used.\n- Spawning an object while it is not your turn will result in points deduction.",
	help_content_commands="<p align=\"center\"><J><font size='14'><b>Commands</b></font></p>\n<p align=\"left\"><font size='12'><N>!m/!mort - kills yourself\n!afk - mark yourself as a spectator\n!pair [player] - request to pair up with a player\n!cancel - cancels existing forced pairing or pairing request\n\n!stats [player] - view your stats or another player’s",
	help_content_contributors="<p align=\"center\"><J><font size='14'><b>Contributors</b></font></p>\n<p align=\"left\"><font size='12'><N>#shamteam is brought to you by the Academy of Building! It would not be possible without the following people:\n\n<J>Casserole#1798<N> - Developer\n<J>Emeryaurora#0000<N> - Module designer & original concept maker\n<J>Pegasusflyer#0000<N> - Module designer\n\nA full list of staff are available via the !staff command.",
	unafk_message="欢迎回来！"
}
translations.en = {
	close="Close",
	help_tab_welcome="Welcome",
	help_tab_rules="Rules",
	help_tab_commands="Commands",
	help_tab_contributors="Contributors",
	help_content_welcome="<p align=\"center\"><J><font size='14'><b>Welcome to #ShamTeam</b></font></p>\n<p align=\"left\"><font size='12'><N>Welcome to Team Shaman Mode (TSM)! The gameplay of TSM is simple: You will pair with another shaman and take turns spawning objects. You earn points at the end of the round depending on mice saved. But be careful! If you make a mistake by spawning when it's not your turn, or dying, you and your partner will lose points! There will be mods that you can enable to make your gameplay a little bit more challenging, and should you win the round, your score will be multiplied accordingly.\n\nJoin our discord server for help and more information!\nLink: %s<a href=\"event:link!%s\">discord.gg/YkzM4rh</a>",
	help_content_rules="<p align=\"center\"><J><font size='14'><b>Rules</b></font></p>\n<p align=\"left\"><font size='12'><N>- In hard mode, you must be within your partner's spawning range for a successful spawn.\n- In divine mode, using arrows deduct points.\n- Only up to 3 solid balloons may be used.\n- Spawning an object while it is not your turn will result in points deduction.",
	help_content_commands="<p align=\"center\"><J><font size='14'><b>Commands</b></font></p>\n<p align=\"left\"><font size='12'><N>!m/!mort - kills yourself\n!afk - mark yourself as a spectator\n!pair [player] - request to pair up with a player\n!cancel - cancels existing forced pairing or pairing request\n\n!stats [player] - view your stats or another player’s",
	help_content_contributors="<p align=\"center\"><J><font size='14'><b>Contributors</b></font></p>\n<p align=\"left\"><font size='12'><N>#shamteam is brought to you by the Academy of Building! It would not be possible without the following people:\n\n<J>Casserole#1798<N> - Developer\n<J>Emeryaurora#0000<N> - Module designer & original concept maker\n<J>Pegasusflyer#0000<N> - Module designer\n\nA full list of staff are available via the !staff command.",
	welcome_message="\t<VP>Ξ Welcome to <b>Team Shaman (TSM)</b> v1.0 Alpha (Re-write)! Ξ\n<J>TSM is a building module where dual shamans take turns to spawn objects.\nPress H for more information.\n<R>NOTE: <VP>Module is in early stages of development and may see incomplete or broken features.",
	tribehouse_mode_warning="<R>NOTE: The module is running in Tribehouse mode, stats are not saved here. Head to any #%s room for stats to save!",
	unafk_message="<ROSE>Welcome back! We've been expecting you.",
	map_info="<ROSE>• [Map Info]<J> @%s <N>by <VP>%s <N>- Difficulty: <J>%s (%s)",
	shaman_info="<N>Shaman: <VP>%s <N>- Level: <J>%s",
	windgrav_info="<N>Wind: <J>%s <G>| <N>Gravity: <J>%s",
	portals="Portals",
	no_balloon="No-Balloon",
	opportunist="Opportunist"
}
end
--[[ end of translations-gen-shamteam/*.lua ]]--

--[[ module/shamteam/TsmCommon.lua ]]--
do
SpCommon = {}

do
    SpCommon.chooseMapFromDiff = function(diff)
        local pool = TsmModuleData.getMapcodesByDiff(diff)
        -- TODO: priority for less completed maps?
        return pool[math.random(#pool)]
    end
end
end
--[[ end of module/shamteam/TsmCommon.lua ]]--
--[[ module/shamteam/TsmPlayer.lua ]]--
do
-- Player methods specific to Spiritual
do
    TsmPlayer = setmetatable({}, Player)
    TsmPlayer.__index = TsmPlayer


    TsmPlayer.new = function(self, pn)
        local data = Player:newData(pn)

        return setmetatable(data, self)
    end
end
end
--[[ end of module/shamteam/TsmPlayer.lua ]]--
--[[ module/shamteam/TsmModuleData.lua ]]--
do
TsmModuleData = setmetatable({}, { __index = MDHelper })
do
    local FILE_NUMBER = MODULE_ID
    local LATEST_MD_VER = 1

    -- DB operations/commits
    TsmModuleData.OP_ADD_MAP = 1
    TsmModuleData.OP_REMOVE_MAP = 2
    TsmModuleData.OP_UPDATE_MAP_DIFF = 3
    TsmModuleData.OP_ADD_MAP_COMPLETION = 4
    TsmModuleData.OP_REPLACE_MAPS = 5
    TsmModuleData.OP_ADD_BAN = 6
    TsmModuleData.OP_REMOVE_BAN = 7
    TsmModuleData.OP_ADD_STAFF = 8
    TsmModuleData.OP_REMOVE_STAFF = 9

    -- pre-computed cache
    local maps_by_diff = {}
    local maps_by_key = {}
    
    -- Module data DB2 schemas
    local MD_SCHEMA = {
        [1] = {
            VERSION = 1,
            db2.VarDataList{ key="maps", size=10000, datatype=db2.Object{schema={
                db2.UnsignedInt{ key="code", size=4 },
                db2.UnsignedInt{ key="difficulty", size=1 },
                db2.UnsignedInt{ key="completed", size=5 },
                db2.UnsignedInt{ key="rounds", size=5 },
            }}},
            db2.VarDataList{ key="banned", size=1000, datatype=db2.Object{schema={
                db2.VarChar{ key="name", size=25 },
                db2.VarChar{ key="reason", size=100 },
                db2.UnsignedInt{ key="time", size=5 },  -- in seconds
            }}},
            db2.VarDataList{ key="staff", size=100, datatype=db2.VarChar{ size=25 }},
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
                    [TsmModuleData.OP_UPDATE_MAP_DIFF] = db2.Object{schema={
                        db2.UnsignedInt{ key="code", size=4 },
                        db2.UnsignedInt{ key="old_diff", size=1 },
                        db2.UnsignedInt{ key="diff", size=1 },
                    }},
                    [TsmModuleData.OP_REPLACE_MAPS] = db2.Object{schema={}},
                    [TsmModuleData.OP_ADD_BAN] = db2.Object{schema={
                        db2.VarChar{ key="name", size=25 },
                    }},
                    [TsmModuleData.OP_REMOVE_BAN] = db2.Object{schema={
                        db2.VarChar{ key="name", size=25 },
                    }},
                    [TsmModuleData.OP_ADD_STAFF] = db2.Object{schema={
                        db2.VarChar{ key="name", size=25 },
                    }},
                    [TsmModuleData.OP_REMOVE_STAFF] = db2.Object{schema={
                        db2.VarChar{ key="name", size=25 },
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
                maps[#maps+1] = {code=self.mapcode, difficulty=0, completed=0, rounds=0}
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
        [TsmModuleData.OP_UPDATE_MAP_DIFF] = {
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
                            self.old_diff = maps[i].difficulty
                        end
                        maps[i].difficulty = self.diff
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
        [TsmModuleData.OP_ADD_MAP_COMPLETION] = {
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
                    found.completion = found.completion + 1
                end
                found.rounds = found.rounds + 1
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
                for i = 1, #staff do
                    if staff[i].name == self.pn then
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
                    if staff[i].name == self.pn then
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

    local pre_compute = function()
        -- sort maps table for faster lookups
        local maps = MDHelper.getTable("maps")
        maps_by_diff = {}
        maps_by_key = {}
        for i = 1, #maps do
            maps_by_key[maps[i].code] = maps[i]

            local diff = maps[i].difficulty
            local difft = maps_by_diff[diff]
            if not difft then
                difft = { _len = 0 }
                maps_by_diff[diff] = difft
            end
            difft._len = difft._len + 1
            difft[difft._len] = maps[i].code
        end
    end

    TsmModuleData.getMapInfo = function(mapcode)
        mapcode = int_mapcode(mapcode)
        if not mapcode then return end
        return maps_by_key[mapcode]
    end

    TsmModuleData.getMapcodesByDiff = function(diff)
        if not diff then return maps_by_diff end
        return maps_by_diff[diff] or {}
    end

    TsmModuleData.isStaff = function(pn)
        local staff = MDHelper.getTable("staff")
        for i = 1, #staff do
            if staff[i] == pn then
                return true
            end
        end
        return false
    end

    local should_precomp = {
        TsmModuleData.OP_ADD_MAP,
        TsmModuleData.OP_REMOVE_MAP,
        TsmModuleData.OP_UPDATE_MAP_DIFF
    }
    TsmModuleData.commit = function(pn, op_id, a1, a2, a3, a4)
        local ret = MDHelper.commit(pn, op_id, a1, a2, a3, a4)
        if should_precomp[op_id] then
            pre_compute()
        end
        return ret
    end
    
    MDHelper.init(FILE_NUMBER, MD_SCHEMA,
            LATEST_MD_VER, operations, DEFAULT_DB, pre_compute)
end
end
--[[ end of module/shamteam/TsmModuleData.lua ]]--
--[[ module/shamteam/TsmRound.lua ]]--
do
--[[ module/IRound.lua ]]--
local IRound = {}

-- int mapcode
-- string author
-- bool is_mirrored
-- bool is_vanilla
-- ENUM phase : to be set by inherited classes

do
    IRound.parseXMLObj = function(self, xmlobj)
        local xo_prop = xmlobj:traverse_first("P").attrib
        if xo_prop.G then
            local wind, grav = xo_prop.G:match("(%-?%S+),(%-?%S+)")
            self.wind = tonumber(wind) or 0
            self.gravity = tonumber(grav) or 10
        end
    end

    IRound.onNew = function(self)
        local mapcode = tonumber(room.currentMap:match('%d+'))
        self.mapcode = mapcode
        self.is_mirrored = room.mirroredMap
        self.wind = 0
        self.gravity = 10
        if mapcode < 1000 or not room.xmlMapInfo then
            self.is_vanilla = true
            self.author = "Vanilla#0020"
            return
        end
        self.author = room.xmlMapInfo.author
        local xmlobj = XMLParse.parse(room.xmlMapInfo.xml):traverse_first("C")
        self:parseXMLObj(xmlobj)
    end

    IRound.onEnd = function(self)
    end
end
--[[ end of module/IRound.lua ]]--

-- int difficulty
-- TsmEnums.Phase phase
do
    TsmRound = setmetatable({}, IRound)
    TsmRound.__index = TsmRound

    TsmRound.parseXMLObj = function(self, xmlobj)
        IRound.parseXMLObj(self, xmlobj)
        local xo_prop = xmlobj:traverse_first("P").attrib
        if xo_prop.P then
            self.portals = true
        end
        if xo_prop.NOBALLOON then
            self.no_balloon = true
        end
        if xo_prop.OPPORTUNIST then
            self.opportunist = true
        end
        if xo_prop.SEPARATESHAM then
            self.seperate_sham = true
        end
        if xo_prop.ORIGINALAUTHOR then
            self.original_author = xo_prop.ORIGINALAUTHOR
        end
    end

    TsmRound.onNew = function(self)
        IRound.onNew(self)

        local dbmap = TsmModuleData.getMapInfo(self.mapcode)
        self.difficulty = dbmap and dbmap.difficulty or -1

        self.phase = PHASE_READY
    end

    TsmRound.onEnd = function(self)
        self.phase = PHASE_TIMESUP
        IRound.onEnd(self)
        
        if self.is_lobby then
            TsmRotation.setDiffRange(1, 5)
        else
            -- add map completion, player xp, etc
        end
    end

    TsmRound.isReady = function(self)
        return self.phase >= PHASE_READY
    end

    TsmRound.new = function(_, vars)
        vars = vars or {}
        vars.phase = PHASE_START
        return setmetatable(vars, TsmRound)
    end
end

ThisRound = TsmRound:new()
end
--[[ end of module/shamteam/TsmRound.lua ]]--
--[[ module/shamteam/TsmCommands.lua ]]--
do
do
    local LEVEL_DEV = function(pn) return DEVS[pn] end
    local LEVEL_MANAGER = function(pn) return MODULE_MANAGERS[pn] or LEVEL_DEV(pn) end
    local LEVEL_STAFF = function(pn) return --[[TsmModuleData.isStaff(pn) or]] LEVEL_MANAGER(pn) end

    commands = {
        tfmcmd.Main {
            name = "version",
            func = function(pn)
                tfm.exec.chatMessage("<J>Version v0", pn)
            end,
        },
        tfmcmd.Main {
            name = "map",
            aliases = {"np"},
            description = "Loads specified map",
            allowed = LEVEL_DEV,
            args = {
                tfmcmd.ArgString { optional = true },
            },
            func = function(pn, code)
                if not SpCommon.module_started then return end
                map_sched.load(code)
            end,
        },
        tfmcmd.Main {
            name = "liststaff",
            allowed = LEVEL_STAFF,
            func = function(pn)
                local managers = {}
                for name in pairs(DEVS) do managers[#managers+1] = name end
                for name in pairs(SpCommon.MANAGERS) do managers[#managers+1] = name end
                players[pn]:chatMsgFmt("Team managers:\n%s", table.concat(managers, " "))
                local list = SpModuleData.getTable("staff")
                players[pn]:chatMsgFmt("\nStaff:\n%s", table.concat(list, " "))
            end
        },
        tfmcmd.Main {
            name = "addstaff",
            args = {
                tfmcmd.ArgString { },
            },
            allowed = LEVEL_MANAGER,
            func = function(pn, target)
                local status, msg = SpModuleData.commit(pn, SpModuleData.ADD_STAFF, target)
                if status == MDHelper.MERGE_OK then
                    players[pn]:chatMsgFmt("%s will be given Staff rights.", target)
                else
                    players[pn]:chatMsg(msg)
                end
            end
        },
        tfmcmd.Main {
            name = "remstaff",
            args = {
                tfmcmd.ArgString { },
            },
            allowed = LEVEL_MANAGER,
            func = function(pn, target)
                local status, msg = SpModuleData.commit(pn, SpModuleData.REMOVE_STAFF, target)
                if status == MDHelper.MERGE_OK then
                    players[pn]:chatMsgFmt("%s will be revoked of Staff rights.", target)
                else
                    players[pn]:chatMsg(msg)
                end
            end
        },
        tfmcmd.Main {
            name = "db",
            args = tfmcmd.ALL_WORDS,
            func = function(pn, w1, w2, w3, w4)
                if not MDHelper.getMdLoaded() then
                    tfm.exec.chatMessage("Module data not loaded yet, please try again.", pn)
                    return
                end
                local subcommands = {
                    map = function(action, p1)
                        local actions = {
                            info = function()
                                local map = SpModuleData.getMapInfo(ThisRound.mapcode)
                                if not map then
                                    tfm.exec.chatMessage("<R>This map is not in rotation.", pn)
                                    return
                                end
                                local info = string.format("Mapcode: @%s\nDifficulty: %s\nCompletion: %s / %s",
                                        map.code, map.difficulty, map.completed, map.rounds)
                                tfm.exec.chatMessage(info, pn)
                            end,
                            diff = function()
                                local map = SpModuleData.getMapInfo(ThisRound.mapcode)
                                if not map then
                                    tfm.exec.chatMessage("<R>This map is not in rotation.", pn)
                                    return
                                end
                                local diff = tonumber(p1)
                                if not diff then
                                    tfm.exec.chatMessage("<R>Specify a valid difficulty number.", pn)
                                    return
                                end
                                SpModuleData.commit(pn, SpModuleData.OP_UPDATE_MAP_DIFF, map.code, diff)
                                tfm.exec.chatMessage("Difficulty of @"..map.code.." will be changed to "..p1, pn)
                            end,
                            add = function()
                                local map = SpModuleData.getMapInfo(ThisRound.mapcode)
                                if map then
                                    tfm.exec.chatMessage("<R>This map is already in rotation.", pn)
                                    return
                                end
                                SpModuleData.commit(pn, SpModuleData.OP_ADD_MAP, ThisRound.mapcode)
                                tfm.exec.chatMessage("Adding @"..ThisRound.mapcode, pn)
                            end,
                            remove = function()
                                local map = SpModuleData.getMapInfo(ThisRound.mapcode)
                                if not map then
                                    tfm.exec.chatMessage("<R>This map is not in rotation.", pn)
                                    return
                                end
                                SpModuleData.commit(pn, SpModuleData.OP_REMOVE_MAP, map.code)
                                tfm.exec.chatMessage("Removing @"..map.code, pn)
                            end,
                            list = function()
                                local diff = tonumber(p1)
                                if not diff then
                                    tfm.exec.chatMessage("<R>Specify a valid difficulty number.", pn)
                                    return
                                end
                                local list = SpModuleData.getMapcodesByDiff(diff)
                                players[pn]:chatMsgFmt("Difficulty %s:\n%s",
                                        diff, table.concat(list, " "))
                            end,
                        }
                        if actions[action] then
                            actions[action]()
                        else
                            local a = {}
                            for sb in pairs(actions) do
                                a[#a+1] = sb
                            end
                            tfm.exec.chatMessage("Usage: !db map [ "..table.concat(a, " | ").." ]", pn)
                        end
                    end,
                    history = function()
                        local logs = MDHelper.getTable("module_log")
                        tfm.exec.chatMessage("Change logs:", pn)
                        for i = 1, #logs do
                            local log = logs[i]
                            local log_str = MDHelper.getChangelog(log.op) or ""
                            tfm.exec.chatMessage(string.format("<ROSE>\t- %s\t%s\t%s", log.committer, os.date("%d/%m/%y %X", log.time*1000), log_str), pn)
                        end
                        --sWindow.open(WINDOW_DB_HISTORY, pn)
                    end,
                }
                if subcommands[w1] then
                    subcommands[w1](w2, w3)
                else
                    local s = {}
                    for sb in pairs(subcommands) do
                        s[#s+1] = sb
                    end
                    tfm.exec.chatMessage("Usage: !db [ "..table.concat(s, " | ").." ]", pn)
                end
            end,
        },
        tfmcmd.Main {
            name = "skip",
            allowed = LEVEL_STAFF,
            func = function(pn)
                Events.doEvent("TimesUp")
            end,
        },
    }

    tfmcmd.setDefaultAllow(true)
    tfmcmd.initCommands(commands)
end
end
--[[ end of module/shamteam/TsmCommands.lua ]]--
--[[ module/shamteam/TsmKeys.lua ]]--
do
keys[71] = {
    func = function(pn, enable) -- g (display GUI for shamans)
        if not roundv.lobby and pL.shaman[pn] then
            if enable then
                sWindow.open(WINDOW_GUI, pn)
            else
                sWindow.close(WINDOW_GUI, pn)
            end
        end
    end,
    trigger = DOWN_UP
}

keys[72] = {
    func = function(pn) -- h (display help)
        if sWindow.isOpened(WINDOW_HELP, pn) then
            sWindow.close(WINDOW_HELP, pn)
        else
            sWindow.open(WINDOW_HELP, pn)
        end
    end,
    trigger = DOWN_ONLY
}

keys[79] = {
    func = function(pn) -- o (display player options)
        if sWindow.isOpened(WINDOW_OPTIONS, pn) then
            sWindow.close(WINDOW_OPTIONS, pn)
        else
            sWindow.open(WINDOW_OPTIONS, pn)
        end
    end,
    trigger = DOWN_ONLY
}

keys[85] = {
    func = function(pn) -- u (undo spawn)
        if not pL.shaman[pn] or not roundv.mods:isset(MOD_BUTTER_FINGERS) then return end
        local sl = roundv.spawnlist[pn]
        if sl._len > 0 and roundv.undo_count < 2 then
            tfm.exec.removeObject(sl[sl._len])
            sl[sl._len] = nil
            sl._len = sl._len - 1
            roundv.undo_count = roundv.undo_count + 1
            tfm.exec.chatMessage(string.format("<ROSE>%s used an undo! (%s left)", pDisp(pn), 2 - roundv.undo_count))
        end
    end,
    trigger = DOWN_ONLY
}
end
--[[ end of module/shamteam/TsmKeys.lua ]]--
--[[ module/shamteam/TsmEvents.lua ]]--
do
do

    Events.hookEvent("NewPlayer", function(pn)
        local player = TsmPlayer:new(pn)
        players[pn] = player

        player:tlChatMsg("welcome_message")

        if not is_official_room then
            player:tlChatMsg("tribehouse_mode_warning", MODULE_ROOMNAME)
        end

        tfm.exec.setPlayerScore(pn, 0)
    end)

    Events.hookEvent("PlayerDied", function(pn)

    end)

    Events.hookEvent("PlayerWon", function(pn)

    end)

    Events.hookEvent("NewGame", function()
        local valid, vars = TsmRotation.signalNgAndRead()
        if not valid then
            print("unexpected map loaded, retrying.")
        end

        if not module_started then module_started = true end

        ThisRound = TsmRound:new(vars)

        if ThisRound.is_lobby then
            --ThisRound:onLobby()
        else
            ThisRound:onNew()

            for name, player in pairs(players) do
                local t_str = {
                    player:tlFmt("map_info", ThisRound.mapcode, ThisRound.author, ThisRound.difficulty, "Hard/Divine"),
                    player:tlFmt("shaman_info", "Unknown#0000", 999)
                }
                local propstr = player:tlFmt("windgrav_info", ThisRound.wind, ThisRound.gravity)
                local props = { }
                if ThisRound.portals then
                    props[#props+1] = player:tlFmt("portals")
                end
                if ThisRound.no_balloon then
                    props[#props+1] = player:tlFmt("no_balloon")
                end
                if ThisRound.opportunist then
                    props[#props+1] = player:tlFmt("opportunist")
                end
                if #props > 0 then
                    propstr = propstr .. " <G>| <VP>" .. table.concat(props, " <G>| <VP>")
                end
                t_str[#t_str+1] = propstr
                player:chatMsg(table.concat(t_str, "\n"))
            end
        end
    end)

    Events.hookEvent("TimesUp", function(elapsed)
        if not module_started then return end
        ThisRound:onEnd()
        if ThisRound.is_lobby then
            TsmRotation.doRotate()
        else
            TsmRotation.doLobby()
        end
    end)

    Events.hookEvent("Loop", function(elapsed, remaining)
        if remaining <= 0 then
            if ThisRound.phase < PHASE_TIMESUP then
                Events.doEvent("TimesUp", elapsed)
            end
        end
    end)

end
end
--[[ end of module/shamteam/TsmEvents.lua ]]--
--[[ module/shamteam/TsmRotation.lua ]]--
do
TsmRotation = {}

local LOBBY_MAPCODE = 7740307
local custom_map
local custom_mode

local is_awaiting_lobby
local awaiting_mapcode
local awaiting_diff
local awaiting_mode

local chosen_mode
local preferred_diff_range

local choose_map = function(mode, diff)
    return 1365330
end

TsmRotation.overrideMap = function(mapcode)
    custom_map = int_mapcode(mapcode)
end

TsmRotation.overrideMode = function(mode)
    custom_mode = mode
end

TsmRotation.setMode = function(mode)
    chosen_mode = mode
end

TsmRotation.setDiffRange = function(lower, upper)
    if not upper then
        upper = lower
    end
    preferred_diff_range = {lower, upper}
end

TsmRotation.doLobby = function()
    is_awaiting_lobby = true
    map_sched.load(LOBBY_MAPCODE)
end

--[[
    signal newGame.
    status => false if current map is unexpected, will auto reload.
    return status (bool), fields (table)
    fields:
        - is_lobby
        - difficulty
        - mode
        - is_custom_load
]]--
TsmRotation.signalNgAndRead = function()
    local mapcode = tonumber(room.currentMap:match('%d+'))

    if is_awaiting_lobby then
        if mapcode ~= LOBBY_MAPCODE then
            map_sched.load(LOBBY_MAPCODE)
            return false
        end
    elseif awaiting_mapcode ~= mapcode then
        map_sched.load(awaiting_mapcode)
        return false
    end

    local ret = {}
    ret.is_lobby = is_awaiting_lobby
    is_awaiting_lobby = nil
    if not is_awaiting_lobby then
        ret.difficulty = awaiting_diff
        ret.mode = chosen_mode
        ret.is_custom_load = custom_map ~= nil

        awaiting_mapcode = nil
        awaiting_diff = nil
        chosen_mode = nil
        custom_map = nil
        preferred_diff_range = nil
    end

    return true, ret
end

TsmRotation.doRotate = function()
    local map
    local mode = custom_mode or chosen_mode or TSM_HARD
    if custom_map then
        map = custom_map
        awaiting_diff = 0
    else
        local diff = math.random(preferred_diff_range[1], preferred_diff_range[2])
        map = choose_map(mode, diff)
        awaiting_diff = diff
    end
    awaiting_mapcode = map
    awaiting_mode = mode
    map_sched.load(map)
end
end
--[[ end of module/shamteam/TsmRotation.lua ]]--
--[[ module/shamteam/TsmInit.lua ]]--
do
local IsOfficialRoom = function(name)
    local normalised_matches = {
        "^%w-%-#(.-)$",  -- public room, in form of xx-#module(0args)?
        "^*#(.-)$"  -- private room, in form of *#module(0args)?
    }
    for i = 1, #normalised_matches do
        local x = name:match(normalised_matches[i])
        if x then name = x break end
    end
    return name and (name == MODULE_ROOMNAME or name:find("^"..MODULE_ROOMNAME.."%d+.-$"))
end

init_ext = function()
    for _,v in ipairs({'AllShamanSkills','AutoNewGame','AutoScore','AutoTimeLeft','PhysicalConsumables'}) do
        tfm.exec['disable'..v](true)
    end
    system.disableChatCommandDisplay(nil,true)
    is_official_room = IsOfficialRoom(room.name)
    TsmRotation.doLobby()
    MDHelper.trySync()
end
end
--[[ end of module/shamteam/TsmInit.lua ]]--
--[[ end of module/shamteam/Tsm.lua ]]--
end



callbacks = {}

----- EVENTS
function eventChatCommand(pn, msg)
    local ret, msg = tfmcmd.executeChatCommand(pn, msg)
    if ret ~= tfmcmd.OK then
        local default_msgs = {
            [tfmcmd.ENOCMD] = "no command found",
            [tfmcmd.EPERM] = "no permission",
            [tfmcmd.EMISSING] = "missing argument",
            [tfmcmd.EINVAL] = "invalid argument"
        }
        msg = msg or default_msgs[ret]
        tfm.exec.chatMessage("<R>error" .. (msg and (": "..msg) or ""), pn)
    end
end

function eventKeyboard(pn, k, d, x, y)
    if keys[k] then
        keys[k].func(pn, d, x, y)
    end
end

function eventLoop(elapsed, remaining)
    map_sched.run()
    TimedTask.onLoop()
    Events.doEvent("Loop", elapsed, remaining)  
end

function eventNewGame()
    pL.dead = PairTable:new()
    pL.alive = PairTable:new(pL.room)

    for name in pL.spectator:pairs() do
        tfm.exec.killPlayer(name)
        tfm.exec.setPlayerScore(name, -5)
    end

    Events.doEvent("NewGame")
end

function eventNewPlayer(pn)
    pL.dead:add(pn)
    for key, a in pairs(keys) do
        if a.trigger == DOWN_ONLY then
            system.bindKeyboard(pn, key, true)
        elseif a.trigger == UP_ONLY then
            system.bindKeyboard(pn, key, false)
        elseif a.trigger == DOWN_UP then
            system.bindKeyboard(pn, key, true)
            system.bindKeyboard(pn, key, false)
        end
    end
    Events.doEvent("NewPlayer", pn)
end

function eventPlayerDied(pn)
    pL.alive:remove(pn)
    pL.dead:add(pn)
    Events.doEvent("PlayerDied", pn)
end

function eventPlayerWon(pn, elapsed)
    pL.alive:remove(pn)
    pL.dead:add(pn)
    Events.doEvent("PlayerWon", pn)
end

function eventPlayerLeft(pn)
    pL.room:remove(pn)
    if pL.spectator[pn] then
        pL.spectator:remove(pn)
    end
    Events.doEvent("PlayerLeft", pn)
end

function eventPlayerRespawn(pn)
    pL.dead:remove(pn)
    pL.alive:add(pn)
end

function eventSummoningEnd(pn, type, xPos, yPos, angle, desc)
    Events.doEvent("SummoningEnd", pn, type, xPos, yPos, angle, desc)
end

function eventTextAreaCallback(id, pn, cb)
    local params = {}
    if cb:find('!') then 
        params = string_split(cb:match('!(.*)'), '&')
        cb = cb:match('(%w+)!')
    end
    -- It is possible for players to alter callback strings
    local success, result = pcall(callbacks[cb], pn, table.unpack(params))
    if not success then
        print(string.format("Exception encountered in eventTextAreaCallback (%s): %s", pn, result))
    end
end

function eventFileLoaded(file, data)
    Events.doEvent("FileLoaded", file, data)
end

function eventFileSaved(file)
    Events.doEvent("FileSaved", file)
end

local init = function()
    print("Module is starting...")

    
    

    for name in pairs(room.playerList) do eventNewPlayer(name) end
    tfm.exec.setRoomMaxPlayers(DEFAULT_MAX_PLAYERS)
    tfm.exec.setRoomPassword("")

    if type(init_ext) == "function" then
        init_ext()
    end
end

init()
debug.disableEventLog(true)