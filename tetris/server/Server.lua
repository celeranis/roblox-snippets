local HttpService = game:GetService('HttpService')
local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')

local DataStoreService = game:GetService('DataStoreService')

local screen = script.Parent
local machine = screen.Parent
local comm = screen.GameEvent
local updateContents = screen.UpdateContents
local updateData = screen.UpdateData
local emitSound = screen.EmitSound

local global = require(game.ReplicatedStorage.TetrisGlobal)
local util = require(game.ReplicatedStorage.util)

local death_conn

local ContentsMeta = {
	__index = function(tab, key)
		if typeof(key) ~= 'number' then
			error('Invalid key '..typeof(key)..' "'..tostring(key)..'"',2)
		elseif key < 1 then
			return table.create(10,1)
		end
		
		local new = table.create(10,nil)
		tab[key] = new
		
		return new
	end
}

function getBag()
	local bag = {}
	local choices = {1,2,3,4,5,6,7}
	
	for i = 1,7 do
		local index = math.random(1,#choices)
		table.insert(bag,choices[index])
		for i = index,7 do
			choices[i] = choices[i + 1]
		end
	end
	
	return bag
end

local contents = setmetatable(table.create(20), ContentsMeta)
local data = {
	State = 'Awaiting',
	CurrentPiece = nil,
	Bag = getBag(),
	Held = nil,
	HighScore = 0,
	Score = 0,
	Lines = 0,
	Level = 1,
	StartingLevel = 1,
	AllowHold = true,
	StateInfo = nil
}

function stringContents()
	debug.profilebegin('stringContents')
	local contentsString = {}
	for y,line in pairs(contents) do
		
		for i,v in pairs(contents) do -- fix weird duplicate memory addresses
			if i < y and line == v then
				line = table.create(10,nil)
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

function updateData(range)
	if range then
		util.ForPlayersInRange(screen.Position, range, function(plr)
			updateData:FireClient(plr,data)
		end)
	else
		updateData:FireAllClients(data)
	end
end

function sendUpdateContents()
	updateContents:FireAllClients(stringContents())
end

local getRotatedOffset = global.getRotatedOffset
local pdata = global.PieceData

function shiftBag()
	if not data.Bag[4] then
		for _,v in pairs(getBag()) do
			table.insert(data.Bag,v)
		end
	end
	for i = 1,math.max(#data.Bag,3) do
		data.Bag[i] = data.Bag[i + 1]
	end
end

function newPiece()
	data.CurrentPiece = {
		Type = data.Bag[1] or math.random(1,7),
		Position = Vector2.new(5,21),
		Rotation = 0,
		Id = HttpService:GenerateGUID(false)
	}
	shiftBag()
end

function getLeaderboardPlace(score)
	for i,data in pairs(global.Leaderboard) do
		if score > data[1] then
			return i - 1
		end
	end
	return #global.Leaderboard + 1
end

local just_died = false
function gameOver(force)
	if just_died then return end
	just_died = true
	
	if death_conn then
		death_conn:Disconnect()
		death_conn = nil
	end
	
	local plr = screen.CurrentPlayer.Value
	if data.State == 'Game' then
		screen.music:Stop()
		emitSound('death')
		
		if plr and data.HighScore < data.Score then
			print(plr,'got a new best:',data.Score)
			global.setBest(plr,data.Score)
		end
		
		global.addHighScore(data.Score,plr.UserId)
		
		if not force then
			wait(3)
		end
		
		local place = getLeaderboardPlace(data.Score)
		if not force and place <= 10 then
			data.State = 'Leaderboard'
			data.StateInfo = {
				Place = place,
			}
			updateData()
			screen.music:Stop()
			print(plr,'finished a tetrominoes game with',data.Score,'putting them at',place,'on the leaderboard')
			just_died = false
			return
		end
	end
	
--	print('m')
	screen.music:Stop()
	data.State = 'Awaiting'
	screen.CurrentPlayer.Value = nil
	plr.InArcadeGame.Value = false
	data.Score = 0
	data.Held = nil
	data.CurrentPiece = nil
	data.Lines = 0
	data.Level = 1
	data.HighScore = 0
	updateData()
	screen.ClickDetector.MaxActivationDistance = 16
	just_died = false
	
	if plr and plr.Character then
		if plr.Character.PrimaryPart then
			plr.Character.PrimaryPart.Anchored = false
		end
		for _,v in pairs(plr.Character:GetChildren()) do
			if v:IsA('ForceField') then
				v:Destroy()
			end
		end
	end
end

function clearLine(linenum)
	for y = linenum,20 do
		contents[y] = rawget(contents, y + 1) or table.create(10,nil)
	end
end

function isAllClear(): boolean
	for y,row in pairs(contents) do
		for x,val in pairs(row) do
			return false
		end
	end
	return true
end

function emitSound(sound: string, ignorePlayer: boolean?)
	local sobj = screen:FindFirstChild(sound)
	if not sobj then
		warn('unknown sound',sound)
	end
	util.ForPlayersInRange(screen.Position, sobj.MaxDistance, function(plr)
		if ignorePlayer and plr == screen.CurrentPlayer.Value then return end
		emitSound:FireClient(plr, sobj)
	end)
end

function moveReward(pos)
	if not data.CurrentPiece then warn('no CurrentPiece') return end
	local dir = pos - data.CurrentPiece.Position
	if math.abs(dir.X) < .1 and dir.Y < 0 then
		data.Score += -dir.Y * math.ceil(data.Level / 3)
	end
end

local check_directions = {
	Vector2.new(1,1),
	Vector2.new(1,-1),
	Vector2.new(-1,1),
	Vector2.new(-1,-1)
}
function get3Corner(pos)
	local open = 0
	for _,dir in pairs(check_directions) do
		local vec = pos + dir
		if not contents[vec.Y][vec.X] then
			open += 1
		end
	end
	return open < 2
end

updateData()
sendUpdateContents()

CollectionService:AddTag(screen,'TetroScreen')

local lastMove = 'move'
screen.ClickDetector.MouseClick:Connect(function(plr)
	if data.State == 'Awaiting' and not plr:WaitForChild('InArcadeGame').Value then
		print(plr,'starting tetrominoes game')
		plr.InArcadeGame.Value = true
		screen.CurrentPlayer.Value = plr
		data.State = 'Menu'
		screen.ClickDetector.MaxActivationDistance = 0
		data.HighScore = global.getBest(plr)
		updateData()
		plr.Character.PrimaryPart.Anchored = true
		plr.Character:SetPrimaryPartCFrame(screen.CFrame * CFrame.new(0, -2.4, -3.25) * CFrame.fromOrientation(0,math.pi,0))
		Instance.new('ForceField',plr.Character).Visible = false
		
		local hum = plr.Character:WaitForChild('Humanoid')
		if death_conn then
			death_conn:Disconnect()
			death_conn = nil
		end
		death_conn = hum.Died:Connect(function()
			gameOver()
		end)
	end
end)

screen.GameEvent.OnServerEvent:Connect(function(plr, time, event, ...)
	if plr ~= screen.CurrentPlayer.Value then return end
	if event == 'placed' then
		if data.State ~= 'Game' then return end
		
		local pos,rot = ...
		
		if not data.CurrentPiece or typeof(pos) ~= 'Vector2' or typeof(rot) ~= 'number' or (pos.Y - data.CurrentPiece.Position.Y) > 0 then 
			warn('Placement blocked - invalid rotation or position')
			return 
		end
		rot = math.floor(rot) % 4
		pos = Vector2.new(math.floor(pos.X),math.floor(pos.Y))
		
		moveReward(pos)
		
		local curpiece = data.CurrentPiece
		data.CurrentPiece = nil
		local positions = {}
		for id, offset in pairs(pdata[curpiece.Type].BlockPositions) do
			local blockpos = getRotatedOffset(pos, offset, rot)
			table.insert(positions,blockpos)
			if blockpos.X > 10 or blockpos.X < 1 or blockpos.Y < 1 or contents[blockpos.Y][blockpos.X] then
				gameOver()
				return
			end
		end
		local checkLines = {}
		for _,blockpos in pairs(positions) do
			contents[blockpos.Y][blockpos.X] = curpiece.Type
			table.insert(checkLines,blockpos.Y)
		end
		local linesCleared = {}
		for _,y in pairs(checkLines) do
			local clear = true
			local line = contents[y]
			for x = 1,10 do
				if not line[x] then
					clear = false
					break
				end
			end
			if clear then
				clearLine(y)
				for i,v in pairs(checkLines) do
					if v > y then
						checkLines[i] = v - 1
					end
				end
				table.insert(linesCleared,y)
			end
		end
		data.Lines += #linesCleared
		
		local tspin = curpiece.Type == 4 and lastMove == 'rotate' and get3Corner(curpiece.Position)
		
		if #linesCleared > 0 or tspin then
			local allClear = isAllClear()
			do
				local allClearBonus = allClear and 10 or 1
				local tSpinBonusMult = tspin and 2 or 1
				local tSpinBonusAdd = tspin and 100 or 0
				local addBase = global.Rewards.ScoreReward[#linesCleared] or 0
				data.Score += (addBase + tSpinBonusAdd) * data.Level * allClearBonus * tSpinBonusMult
			end
			
			xpcall(function()
				local plr = screen.CurrentPlayer.Value
				if plr then
					plr.leaderstats.Noobits.Value += (allClear and 2000) or global.Rewards.NoobitReward[#linesCleared] or (tspin and 200) or 0
				end
			end,warn)
			
			local lb4 = data.Level
			data.Level = math.floor(data.Lines / 10) + data.StartingLevel
			
			if #linesCleared > 0 then
				emitSound(#linesCleared >= 4 and 'tetris' or 'line_clear')
			end
			
			if allClear then
				emitSound('all_clear')
			end
			
			if data.Level ~= lb4 then
				emitSound('levelup')
			end
			
			util.ForPlayersInRange(screen.Position,256,function(plr)
				screen.GameEvent:FireClient(plr,'lines_cleared',linesCleared,allClear,tspin)
			end)
			
		end
		
		data.AllowHold = true
		
		--data.CurrentPiece = nil
		--updateData()
		--wait(.5)
		newPiece()
		updateData()
		sendUpdateContents()
		
		emitSound('placed')
		
	elseif event == 'move' then
		
		if data.State ~= 'Game' or not data.CurrentPiece then return end
		
		local pos,silent = ...
		
		if typeof(pos) ~= 'Vector2' or (pos.Y - data.CurrentPiece.Position.Y) > 0 then
			warn('Move replication blocked - invalid arguments passed')
			return
		end
		pos = Vector2.new(math.floor(pos.X),math.floor(pos.Y))
		
		for id, offset in pairs(pdata[data.CurrentPiece.Type].BlockPositions) do
			local blockpos = getRotatedOffset(pos, offset, data.CurrentPiece.Rotation)
			if blockpos.X > 10 or blockpos.X < 1 or blockpos.Y < 1 or contents[blockpos.Y][blockpos.X] then
				warn('Move replication blocked - destination taken')
				return
			end
		end
		
		if not silent then
			moveReward(pos)
			emitSound('move',true)
		end
		
		lastMove = 'move'
		
		data.CurrentPiece.Position = pos
		
		updateData(256)
		
	elseif event == 'rotate' then
		
		if data.State ~= 'Game' then return end
		
		local rot = ...
		
		if typeof(rot) ~= 'number' then
			warn('Invalid rotation',typeof(rot),rot)
			return
		end
		rot = math.floor(rot) % 4
		
		for id, offset in pairs(pdata[data.CurrentPiece.Type].BlockPositions) do
			local blockpos = getRotatedOffset(data.CurrentPiece.Position, offset, rot)
			if blockpos.X > 10 or blockpos.X < 1 or blockpos.Y < 1 or contents[blockpos.Y][blockpos.X] then
				return
			end
		end
		
		data.CurrentPiece.Rotation = rot
		
		lastMove = 'rotate'
		
		updateData(256)
		emitSound('rotate',true)
		
	elseif event == 'hold' then
		
		if data.State ~= 'Game' then return end
		
		if not data.AllowHold then return end
		local curp = data.CurrentPiece
		
		if data.Held then
			data.CurrentPiece = {
				Type = data.Held,
				Position = Vector2.new(5,21),
				Rotation = 0,
				Id = HttpService:GenerateGUID(false)
			}
		else
			newPiece()
		end
		
		data.Held = curp and curp.Type or nil
		data.AllowHold = false
		
		updateData()
		
	elseif event == 'menu_navigate' then
		
		if data.State == 'Game' then return end
		
		local new_state, info = ...
		
		if typeof(new_state) ~= 'string' or (info and typeof(info) ~= 'table') then
			return
		end
		
		data.State = new_state
		data.StateInfo = info
		updateData()
		
	elseif event == 'quit' then
		
		gameOver(true)
		
	elseif event == 'start_game' then
		
		if data.State == 'Game' then return end
		
		local lvl,high = ...
		
		if typeof(lvl) ~= 'number' then
			lvl = 1
		end
		if typeof(high) ~= 'number' then
			high = 1
		end
		
		lvl = math.clamp(math.floor(lvl),1,15)
		high = math.clamp(math.floor(high),0,17)
		
		data.StartingLevel = lvl
		data.Level = lvl
		data.State = 'Game'
		data.Held = nil
		data.Score = 0
		data.AllowHold = true
		newPiece()
		data.HighScore = global.getBest(plr)
		updateData()
		
		contents = setmetatable(table.create(20,nil),ContentsMeta)
		for i = 1,high do
			local randomRow = table.create(10,0)
			for i = 1,math.random(1,4) do
				randomRow[math.random(1,10)] = nil
			end
			contents[i] = randomRow
		end
		sendUpdateContents()
		
		screen.music:Play()
		
	elseif event == 'pause' then
		
		if data.State ~= 'Game' then return end
		
		data.State = 'Paused'
		emitSound('pause')
		screen.music.Playing = false
		updateData()
		
	elseif event == 'unpause' then
		
		if data.State ~= 'Paused' then return end
		
		data.State = 'Game'
		screen.music.Playing = true
		updateData()
		
	end
end)

function firePlayer(plr)
	updateData:FireClient(plr,data)
	updateContents:FireClient(plr,stringContents())
end
Players.PlayerAdded:Connect(firePlayer)
for _,v in pairs(Players:GetPlayers()) do
	firePlayer(v)
end

Players.PlayerRemoving:Connect(function(plr)
	if plr == screen.CurrentPlayer.Value then
		gameOver()
	end
end)