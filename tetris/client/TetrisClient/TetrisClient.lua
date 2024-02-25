--!strict

export type Piece = {
	Type: number,
	Position: Vector2,
	Rotation: number,
	Id: string,
}
--[[
	The class instance for a Tetris arcade machine.
]]
export type TetrisObject = {
	Screen: Part,
	GetPlayer: any,
	CurrentPiece: Piece,
	Contents: {[number]:{[number]:number?}},
	State: string,
	Paused: boolean,
	Selection: string?,
	SelectionId: number?,
	ClientGui: SurfaceGui,
	CommEvent: RemoteEvent,
	Locked: boolean,
	
	Render: any,
	SendEvent: any,
	PlaySound: any,
	RenderBlock: any,
	SelectFrame: any,
	SelectButton: any,
	Place: any,
	Move: any,
	Rotate: any,
	UpdatePreview: any,
	ShowNotif: any,
	Hold: any,
	Select: any,
	Pause: any,
	Navigate: any,
	UpdateControls: any,
	
	Lines: number,
	Score: number,
	Level: number,
	Bag: {[number]:number},
	Held: number?,
	AllowHold: boolean,
	HighScore: number,
	
	AllowedInputs: {
		Select: string?,
		Down: string?,
		Left: string?,
		Pause: string?,
		Hold: string?,
		QuickDrop: string?,
		Right: string?
	},
	
	_oldprev:  BlockCollection,
	_ct: Tween?,
	StateInfo: {[string]: any?}?
}
export type BlockCollection = {[number]:{[number]:number?}}

local Tetris = {}

local HttpService = game:GetService('HttpService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local LocalPlayer = game.Players.LocalPlayer
local util = require(game.ReplicatedStorage.util)
local global = require(game.ReplicatedStorage.TetrisGlobal)
local anims = require(script.InteractAnims)
local getActiveControls = require(script.GetActiveControls)

local PieceData = global.PieceData

local ScreenGui = script.Parent.Parent
local controlsFrame = ScreenGui:WaitForChild('Controls')

local function getPlayer(obj: TetrisObject): Player
	local current: ObjectValue = obj.Screen:FindFirstChild('CurrentPlayer')
	return current.Value
end

local ContentsMeta = {
	__index = function(tab,key)
		if typeof(key) ~= 'number' then
			error('Invalid key "'..typeof(key)..' '..tostring(key)..'"',2)
		elseif key < 1 then
			return table.create(10,1)
		end
		return table.create(10,nil)
	end,
}
local ContentsEditableMeta = {
	__index = function(tab,key)
		if typeof(key) ~= 'number' then
			error('Invalid key '..typeof(key)..' "'..tostring(key)..'"',2)
		elseif key < 1 then
			return table.create(10,1)
		end
		local new = table.create(10)
		tab[key] = new
		return new
	end
}

local ContentsEmpty = setmetatable({},ContentsMeta)

local select_functions = {
	Menu = {
		Play = function(obj: TetrisObject)
			obj.State = 'LevelSelect'
			obj:SendEvent('menu_navigate','LevelSelect')
			obj:Render('stats')
		end,
		Leaderboard = function(obj: TetrisObject)
			obj.State = 'Leaderboard'
			obj:SendEvent('menu_navigate','Leaderboard')
			obj:Render('stats')
		end,
		Quit = function(obj: TetrisObject)
			obj:SendEvent('quit')
		end
	},
	Paused = {
		Resume = function(obj: TetrisObject)
			obj:Pause(false)
		end,
		Quit = function(obj: TetrisObject)
			obj:SendEvent('quit')
		end
	},
	LevelSelect = {
		Begin = function(obj: TetrisObject)
			local lsel = util.fd(obj.ClientGui).LevelSelect
			obj:SendEvent('start_game',tonumber(lsel.Level.Text),tonumber(lsel.High.Text))
		end
	},
	Leaderboard = {
		Close = function(obj: TetrisObject)
			obj.State = 'Menu'
			obj:SendEvent('menu_navigate','Menu')
			obj:Render('stats')
		end
	},
}
Tetris._select_nav = {
	Menu = {
		'Play',
		'Leaderboard',
		'Quit'
	},
	Paused = {
		'Resume',
		'Quit'
	},
	LevelSelect = {
		'Begin',
	},
	Leaderboard = {
		'Close'
	}
}

local function updateBlock(block: ImageLabel, color: Color3?, transparency: number?)
	debug.profilebegin('updateBlock')
	
	if not block then warn('none block') end
	
	block.BackgroundColor3 = color or Color3.new()
	transparency = transparency or (color and 0 or 1)
	block.ImageTransparency = transparency
	block.BackgroundTransparency = transparency
	
	debug.profileend()
end

local function renderBlock(obj: TetrisObject, block: ImageLabel)
	debug.profilebegin('renderBlock')
	
	local x: number = tonumber(block.Name)
	local y: number = tonumber(block.Parent.Name)
	if not x or not y then
		warn('Failed to render block',block:GetFullName(),'- Invalid XY coordinates',x,y)
		return
	end
	local occupant = obj.Contents[y][x]
	updateBlock(block, occupant and PieceData[occupant].Color or nil)
	
	debug.profileend()
end

local function playSound(obj: TetrisObject, name: string)
	local sound = obj.Screen:FindFirstChild(name)
	if sound and sound:IsA('Sound') then
		sound:Play()
	end
end

local getRotatedOffset = global.getRotatedOffset

function pause(obj: TetrisObject, force: boolean?)
	if obj.State ~= 'Game' and obj.State ~= 'Paused' then --[[warn('pause cancelled')]] return end
	local set if typeof(force) == 'boolean' then
		set = force
	else
		set = obj.State ~= 'Paused'
	end
	obj.State = set and 'Paused' or 'Game'
	obj:Render('stats')
	obj:SendEvent(set and 'pause' or 'unpause')
end

function selectFrame(obj: TetrisObject)
	debug.profilebegin('SelectFrame')
	
	local name = obj.State
	local selef = obj.ClientGui:FindFirstChild('SelectedFrame')
	if not selef or name == selef.Value then return end
	selef.Value = name
	
	local names = {[name] = true}
	if name == 'Paused' then
		names.Game = true
	end
	
	for _,v in pairs(obj.ClientGui:GetChildren()) do
		if v:IsA('Frame') then
			v.Visible = names[v.Name]
		end
	end
	
	debug.profileend()
end
function selectButton(obj: TetrisObject)
	debug.profilebegin('SelectButton')
	
	local name = UserInputService:GetLastInputType() == Enum.UserInputType.Touch or obj.Selection
		
	for _,button in pairs(obj.ClientGui[obj.State]:GetChildren()) do
		if not button:IsA('TextButton') then continue end
		button.TextColor3 = button.Name == name and Color3.new(1,1,0) or Color3.new(1,1,1)
	end
	
	debug.profileend()
end

local function updatePreview(obj: TetrisObject)
	
	debug.profilebegin('updatePreview')
		
	local blocks = util.fd(obj.ClientGui).Game.Blocks
	
	if not blocks() then warn('none blocks') return end
	
	local pdata = PieceData[obj.CurrentPiece.Type]
	
	local bpos = setmetatable(table.create(20),ContentsEditableMeta)
	for _,offset in pairs(pdata.BlockPositions) do
		local rpos = getRotatedOffset(obj.CurrentPiece.Position,offset,obj.CurrentPiece.Rotation)
		bpos[rpos.Y][rpos.X] = 0
	end
	
	local update: BlockCollection = setmetatable(table.create(20),ContentsEditableMeta)
	for y,row in pairs(obj._oldprev) do
		for x,val in pairs(row) do
			if not obj.Contents[y][x] and not bpos[y][x] and val < 1 then
				update[y][x] = 1
			end
		end
	end
	
	local down = 0
	repeat
		local finished = false
		for y,row in pairs(bpos) do
			if finished then break end
			for x,val in pairs(row) do
				if finished then break end
				local pos = Vector2.new(x,y - down - 1)
				if pos.Y < 1  or (obj.Contents[pos.Y] and obj.Contents[pos.Y][pos.X]) then
					finished = true
					break
				end
			end
		end
		if finished then break end
		down += 1
	until finished
	
	local downVector = Vector2.new(0,-down)
	
	for y,row in pairs(bpos) do
		for x,val in pairs(row) do
			update[y - down][x] = .75
		end
	end
	
	for y,row in pairs(update) do
		for x,trans in pairs(row) do
			if bpos[y][x] then continue end
			local block = blocks[y][x]()
			if not block then continue end
			updateBlock(block, pdata.Color, trans)
		end
	end
	obj._oldprev = update
	
	debug.profileend()
	
end

local function updateControls(obj: TetrisObject)
	local mobile = UserInputService:GetLastInputType() == Enum.UserInputType.Touch
	local playing = obj:GetPlayer() == LocalPlayer
	
	ScreenGui.MobileControls.Visible = playing and mobile and obj.State == 'Game'
	controlsFrame.Visible = playing and not mobile
	
	if playing and not mobile then
		local keep = {}
		for _,v in pairs(getActiveControls(obj)) do
			local frame = controlsFrame:FindFirstChild(v.Name)
			if not frame then
				frame = script.TempInput:Clone()
				frame.Name = v.Name
				frame.Parent = controlsFrame
			end
			frame.Label.Text = v.Label or 'Unknown'
			frame.Icon.Image = v.Img or ''
			frame.Icon.IconText.Text = v.Key or ''
			keep[frame] = true
		end
		for _,v in pairs(controlsFrame:GetChildren()) do
			if v:IsA('Frame') and not keep[v] then
				v:Destroy()
			end
		end
	end
end

local function render(obj: TetrisObject, mode: string, oldPosition: Vector2?, oldRotation: number?, oldType: number?)
	debug.profilebegin('TetroRender')
	
	mode = mode or 'full'
	
	if obj.State == 'Game' then
		
		obj.Selection = nil
		
		local gamef = util.fd(obj.ClientGui).Game
		local blocks = gamef.Blocks
		
		if not blocks() then warn('none blocks') return end
		
		if mode == 'full' then
			for y = 1,20 do
				for x = 1,10 do
					local block = blocks[y][x]()
					if not block then continue end
					obj:RenderBlock(block)
				end
			end
		end
		
		if mode ~= 'current_only' then
			gamef.Level.Text = obj.Level
			gamef.Lines.Text = obj.Lines
			gamef.Score.Text = obj.Score
			
			for i = 1,3 do
				local pdata = PieceData[obj.Bag[i]]
				gamef.Bag[i].Image = pdata and pdata.Preview or ''
			end
				
			local hpdata = PieceData[obj.Held]
			gamef.Held.Preview.Image = hpdata and hpdata.Preview or ''
			gamef.Held.Preview.ImageTransparency = obj.AllowHold and 0 or .5
			
			gamef.HighScore.Score.Text = obj.HighScore
		end
		
		if obj.CurrentPiece then
			local use_remove = oldPosition and oldRotation
			
			local pdata = PieceData[obj.CurrentPiece.Type]
			local opdata = PieceData[oldType or obj.CurrentPiece.Type]
			
			local add = {}
			for id: number, offset: Vector2 in pairs(pdata.BlockPositions) do
				table.insert(add, getRotatedOffset(obj.CurrentPiece.Position, offset, obj.CurrentPiece.Rotation))
			end
			if use_remove then
				for id: number, offset: Vector2 in pairs(opdata.BlockPositions) do
					local pos = getRotatedOffset(oldPosition, offset, oldRotation)
					
					local block = blocks[pos.Y][pos.X]()
					if not block then continue end
					updateBlock(block)
				end
			end
			for _,pos in pairs(add) do
				local block = blocks[pos.Y][pos.X]()
				if not block then continue end
				updateBlock(block, pdata.Color)
			end
			
			obj:UpdatePreview()
		end
		
	elseif obj.State == 'Leaderboard' then
		
		util.fd(obj.ClientGui).Leaderboard.Place.Value = obj.StateInfo and obj.StateInfo.Place or 0
		
	end
	
	if Tetris._select_nav[obj.State] then
		local valid_now = Tetris._select_nav[obj.State][obj.SelectionId]
		local id = valid_now and obj.SelectionId or 1
		obj.Selection = Tetris._select_nav[obj.State][id]
		obj.SelectionId = id
		obj:SelectButton()
	else
		obj.Selection = nil
		obj.SelectionId = nil
	end
	
	obj:SelectFrame()
	
	if obj:GetPlayer() == LocalPlayer then
		obj:UpdateControls()
	end
	
	debug.profileend()
end

local function sendEvent(obj: TetrisObject, ...)
	obj.CommEvent:FireServer(os.clock(), ...)
end

local function place(obj: TetrisObject)
	if not obj.CurrentPiece or obj.Locked then return end
	obj.Locked = true
	obj:SendEvent('placed', obj.CurrentPiece.Position, obj.CurrentPiece.Rotation)
end

local function move(obj: TetrisObject, direction: Vector2, silent: boolean?, noevent: boolean?): boolean
	debug.profilebegin('TetroMove')
	
	assert(obj,'No Tetris object given')
	assert(direction,'I don\'t know where to move')
	
	if obj.State ~= 'Game' or not obj.CurrentPiece or obj.Locked then return true end
	local pdata = PieceData[obj.CurrentPiece.Type]
	
	for _,offset in pairs(pdata.BlockPositions) do
		local pos = getRotatedOffset(obj.CurrentPiece.Position + direction, offset, obj.CurrentPiece.Rotation)
		if pos.Y < 1 or obj.Contents[pos.Y][pos.X] then
			if direction.Y < 0 and (math.abs(direction.X) < .95 or obj.Contents[pos.Y][pos.X - direction.X]) then
				obj:Place()
				return true
			elseif math.abs(direction.Y) > .95 then
				obj:Move(Vector2.new(0,direction.Y),silent)
			end
			return false
		end
		if pos.X > 10 or pos.X < 1 then
			if math.abs(direction.X) > .95 and math.abs(direction.Y) > .95 then
				obj:Move(Vector2.new(0,direction.Y),silent)
			end
			return false
		end
	end
	
	obj.CurrentPiece.Position += direction
	if not noevent then
		if not silent then
			obj:PlaySound('move')
		end
		obj:SendEvent('move',obj.CurrentPiece.Position,silent)
		obj:Render('current_only', obj.CurrentPiece.Position - direction, obj.CurrentPiece.Rotation)
	end
	
	debug.profileend()
end

local function rotate(obj: TetrisObject, amount: number)
	debug.profilebegin('TetroRotate')
	
	local piece = obj.CurrentPiece
	local pdata = PieceData[piece and piece.Type]
	if obj.State ~= 'Game' or not piece or not pdata or not pdata.AllowRotate or obj.Locked then return end
	local center = piece.Position
	amount = math.floor(amount+.5)
	for id: number, pos: Vector2 in pairs(pdata.BlockPositions) do
		if id ~= pdata.Center then
			local desired = getRotatedOffset(center,pos,piece.Rotation + amount)
			if desired.Y > 25 or desired.Y < 1 or desired.X > 10 or desired.X < 1 or obj.Contents[desired.Y][desired.X] then
				return
			end
		end
	end
	obj.CurrentPiece.Rotation = (obj.CurrentPiece.Rotation + amount) % 4
	obj:SendEvent('rotate',obj.CurrentPiece.Rotation)
	obj:PlaySound('rotate')
	obj:Render('current_only', obj.CurrentPiece.Position, obj.CurrentPiece.Rotation - amount)
	
	debug.profileend()
	
	local play_anim = amount > 0 and 'ClockRotate' or 'CounterRotate'
	anims()[play_anim]:Play()
end

local function quickDrop(obj: TetrisObject)
	while not obj:Move(Vector2.new(0,-1), true, true) do end
end

function hold(obj: TetrisObject)
	if not obj.AllowHold then return end
	obj.Locked = true
	obj:SendEvent('hold')
end

local notifs = {
	'Single!',
	'Double!',
	'Triple!',
	'Quadruple!'
}
local info1 = TweenInfo.new(.75,Enum.EasingStyle.Quart)
local info2 = TweenInfo.new(.75,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
function showNotif(obj: TetrisObject, text: string)
	local notif = util.fd(obj.ClientGui).Game.EventNotif()
	if not notif then warn('none notif') return end
	notif.Text = text
	if obj._ct then
		obj._ct:Cancel()
	end
	notif.TextTransparency = 1
	notif.Position = UDim2.fromScale(.125,.65)
	local tw = TweenService:Create(notif,info1,{Position = UDim2.fromScale(.125,.5), TextTransparency = 0})
	tw:Play()
	obj._ct = tw
	delay(.75,function()
		local tw = TweenService:Create(notif,info2,{TextTransparency = 1, Position = UDim2.fromScale(.125, .35)})
		tw:Play()
		obj._ct = tw
		wait(.75)
		obj._ct = nil
	end)
end

function fixContents(contents)
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

function buttonSelect(obj: TetrisObject, selection: string?)
	selection = selection or obj.Selection
	--print(selection)
	if not selection then --[[warn('none selection')]] return end
	
	local func = (select_functions[obj.State] or {})[selection]
	
	if not func then warn('no select function found for',obj.State,selection) return end
	
	anims().Select:Play()
	
	return func(obj)
end

function navigate(obj: TetrisObject, direction: number)
	if not Tetris._select_nav[obj.State] then
		obj.Selection = nil
		obj.SelectionId = nil
		return
	end
	
	local id = (obj.SelectionId or 1) + direction
	if not Tetris._select_nav[obj.State][id] then return end
	
	obj.SelectionId = id
	obj.Selection = Tetris._select_nav[obj.State][id]
	
	obj:Render('stats')
end



local clear_info = TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.In)
function Tetris.new(screen: Part, gui: SurfaceGui): TetrisObject
	assert(screen,'Screen part not given')
	local comm = screen:WaitForChild('GameEvent')
	local updc = screen:WaitForChild('UpdateContents')
	local updd = screen:WaitForChild('UpdateData')
	local emsnd = screen:WaitForChild('EmitSound')
	local dataNow = updd.OnClientEvent:Wait()
	local new: TetrisObject = {
		Screen = screen,
		Contents = fixContents(updc.OnClientEvent:Wait()),
		GetPlayer = getPlayer,
		CurrentPiece = dataNow.CurrentPiece,
		State = dataNow.State,
		Paused = dataNow.Paused,
		Selection = nil,
		Locked = false,
		
		Rotate = rotate,
		Move = move,
		Render = render,
		SendEvent = sendEvent,
		CommEvent = comm,
		ClientGui = gui,
		PlaySound = playSound,
		RenderBlock = renderBlock,
		SelectFrame = selectFrame,
		SelectButton = selectButton,
		Place = place,
		QuickDrop = quickDrop,
		UpdatePreview = updatePreview,
		ShowNotif = showNotif,
		Hold = hold,
		Select = buttonSelect,
		Pause = pause,
		Navigate = navigate,
		UpdateControls = updateControls,
		
		AllowedInputs = {},
		
		Level = dataNow.Level,
		Score = dataNow.Score,
		Lines = dataNow.Lines,
		Bag = dataNow.Bag,
		HighScore = dataNow.HighScore,
		AllowHold = dataNow.AllowHold,
		StateInfo = dataNow.StateInfo,
		
		_oldprev = setmetatable(table.create(20),ContentsEditableMeta)
	}
	xpcall(function()
		new:Render()
	end,warn)
	updd.OnClientEvent:Connect(function(dataNow)
		debug.profilebegin('DataChanged')
		
		new.State = dataNow.State
		new.Level = dataNow.Level
		new.Score = dataNow.Score
		new.Lines = dataNow.Lines
		new.Bag = dataNow.Bag
		new.Held = dataNow.Held
		new.HighScore = dataNow.HighScore
		new.AllowHold = dataNow.AllowHold
		new.StateInfo = dataNow.StateInfo
		
		local pieceb4 = new.CurrentPiece
		
		if not dataNow.CurrentPiece or not new.CurrentPiece or new.CurrentPiece.Id ~= dataNow.CurrentPiece.Id or new:GetPlayer() ~= LocalPlayer then
			new.CurrentPiece = dataNow.CurrentPiece
			new.Locked = false
		end
		
		new:Render('stats', pieceb4 and pieceb4.Position, pieceb4 and pieceb4.Rotation, pieceb4 and pieceb4.Type)
		
		debug.profileend()
	end)
	updc.OnClientEvent:Connect(function(contents)
		new.Contents = setmetatable(fixContents(contents), ContentsMeta)
		
		new:Render('full')
	end)
	emsnd.OnClientEvent:Connect(function(sound)
		if not sound then return end
		sound:Play()
	end)
	comm.OnClientEvent:Connect(function(event,...)
		if event == 'lines_cleared' then
			local lines,allClear,tspin = ...
			for _,y in pairs(lines) do
				local effect = util.fd(gui).Game.ClearEffect[y]()
				if not effect then warn('no line cleared effect for',y) continue end
				effect.BackgroundTransparency = 0
				TweenService:Create(effect,clear_info,{BackgroundTransparency = 1}):Play()
			end
			
			new:ShowNotif((allClear and 'All-Clear!') or (tspin and 'T-Spin!') or notifs[#lines] or '')
		end
	end)
	return new
end

return Tetris