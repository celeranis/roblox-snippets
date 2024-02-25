local RowsGlobal = {}

type Array<T> = {[number]:T}
type Stringray<T> = {[string]:T}

function RowsGlobal.FindColumnBottom(contents, column: number): number
	for y = 6,1,-1 do
		if contents[column][y] then
			return y + 1
		end
	end
	return 1
end

function RowsGlobal.DecodeStringray(contents: Stringray<Stringray<number>>): Array<Array<number>>
	debug.profilebegin('fixContents')
	local contentsFixed = {}
	for y,xtab in pairs(contents) do
		local xtabFix = {}
		for x,val in pairs(xtab) do
			xtabFix[tonumber(x)] = val
		end
		contentsFixed[tonumber(y)] = xtabFix
	end
	debug.profileend()
	return contentsFixed
end

function RowsGlobal.EncodeStringray(contents: Array<Array<number>>): Stringray<Stringray<number>>
	debug.profilebegin('stringContents')
	local contentsString = {}
	for y,line in pairs(contents) do
		
		for i,v in pairs(contents) do -- fix weird duplicate memory addresses
			if i < y and line == v then
				line = table.create(6,nil)
				contents[y] = line
			end
		end
		
		local lineFix = {}
		for x,val in pairs(line) do
			lineFix[tostring(x)] = val
		end
		contentsString[tostring(y)] = lineFix
	end
	debug.profileend()
	return contentsString
end

return RowsGlobal