local metaX = {
	__index = function(table, index)
		local new = {}
		table[index] = new
		return new
	end
}
local metaGlobal = {
	__index = function(table, index)
		local new = setmetatable({},metaX)
		table[index] = new
		return new
	end
}

local raw = {}
_G.raw = raw
return setmetatable(raw,metaGlobal)