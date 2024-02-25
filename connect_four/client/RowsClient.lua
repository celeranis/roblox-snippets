local Rows = {}

local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

local global = require(game.ReplicatedStorage.RowsGlobal)
local util = require(game.ReplicatedStorage.util)
local ending = require(script.EndingText)
local thread = require(game.ReplicatedStorage.Thread)

local info = TweenInfo.new(1, Enum.EasingStyle.Bounce)
local info2 = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local info3 = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local info4 = TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local origin_offset = Vector3.new(0, -1.5, -1.8)
local step = 0.6
local fixCalc = Vector2.new(1, 1)

local fade = game.Lighting.EndCC_4R
local fade_t1 = TweenService:Create(fade, info3, {Brightness = -1})
local fade_t2 = TweenService:Create(fade, info3, {Brightness = 0})

local prompt_again = {
	Title = 'Rematch',
	Body = 'Would you like to play again?',
	Icon = 'rbxassetid://4976318800',
	Button0 = 'PLAY',
	Button1 = 'No thanks'
}

local ContentsMeta = {
	__index = function(tab,key)
		if typeof(key) ~= 'number' then
			error('Invalid key "'..typeof(key)..' '..tostring(key)..'"',2)
		end
		local new = table.create(6,nil)
		rawset(tab, key, new)
		return new
	end,
	__newindex = function(tab, key, value)
		if typeof(key) == 'Instance' and not value then
			for _,column in pairs(tab) do
				for y,piece in pairs(column) do
					if piece == key then
						column[y] = nil
						return
					end
				end
			end
		end
	end
}

Rows.id_map = {
	Name = {
		[0] = 'Red',
		[1] = 'Yellow'
	},
	Color = {
		[0] = Color3.fromRGB(255, 93, 93),
		[1] = Color3.fromRGB(255, 209, 93)
	},
	WinColor = {
		[0] = Color3.fromRGB(255, 111, 111),
		[1] = Color3.fromRGB(185, 168, 100)
	},
	CameraOffset = {
		[0] = CFrame.new(10, 0, 0) * CFrame.fromOrientation(0, math.rad(90), 0),
		[1] = CFrame.new(-10, 0 ,0) * CFrame.fromOrientation(0, math.rad(-90), 0)
	}
}

function sendEvent(self, ...)
	self.CommEvent:FireServer(...)
end

function Rows.ToOffset(pos: Vector2): Vector3
	pos -= fixCalc
	return origin_offset + Vector3.new(0, pos.Y * step, pos.X * step)
end

function addPiece(self, id: number, pos: Vector2): MeshPart
	local piece = script.temp:Clone()
	piece.Color = Rows.id_map.Color[id]
	local board = self.Board
	local world_pos = board.CFrame * CFrame.new(Rows.ToOffset(pos))
	local entry = board.CFrame * CFrame.new(Rows.ToOffset(Vector2.new(pos.X, 8)))
	
	piece.CFrame = entry
	piece.Parent = board.Parent
	TweenService:Create(piece, info, {CFrame = world_pos}):Play()
	
	self.Pieces[pos.X][pos.Y] = piece
	-- print(self.Pieces[pos.X][pos.Y])

	self.Board.Drop:Play()
	--self.Board.TimePosition = .5
	
	return piece
end

function removePiece(self, piece: MeshPart)
	TweenService:Create(piece, info2, {CFrame = piece.CFrame + Vector3.new(0,-5,0), Transparency = 1}):Play()
	game.Debris:AddItem(piece, 1)
	self.Pieces[piece] = nil
end

function renderBoard(self)
	local pieces = {}
	
	--for x,column in pairs(self.Contents) do
	--	for y,occupant in pairs(column) do
	--		print(x,y,occupant,typeof(x),typeof(y))
	--	end
	--end
	
	for x = 1,7 do
		for y = 1,6 do
			local piece = self.Pieces[x][y]
			local occupant = self.Contents[x][y]
			
			if occupant and not piece then
				-- print('adding', piece, occupant, x, y)
				self:AddPiece(occupant, Vector2.new(x, y))
			elseif piece and not occupant then
				-- print('removing', piece, occupant, x, y)
				self:RemovePiece(piece)
			end
		end
	end
end


function getHoveringColumn(self): number?
	local gamepad = UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1
	if gamepad then
		return self.Selected
	end
	local pos = UserInputService:GetMouseLocation()
	local ray = workspace.CurrentCamera:ScreenPointToRay(pos.X, pos.Y)
	local result = workspace:Raycast(ray.Origin, ray.Direction * 32, self.RaycastParams)
	
	if result and result.Instance then
		return tonumber(result.Instance.Name)
	else
		return nil
	end
end

function renderPreview(self)
	local x = self.Turn == player and self:GetHoveringColumn()
	local y = x and global.FindColumnBottom(self.Contents, x)
	--print(x,y,self.Turn)
	if not y or y > 6 then
		self.Preview.Transparency = 1
	else
		self.Preview.Transparency = .5
		self.Preview.Color = Rows.id_map.Color[self.MyId]
		self.Preview.CFrame = self.Board.CFrame * CFrame.new(Rows.ToOffset(Vector2.new(x,y)))
	end
end

function setBeamTransparency(self, transparency)
	if not self.Beam then
		warn('self.Beam is not defined for board',self.Board:GetFullName())
		return
	end
	if self.Beam.Transparency.Keypoints[2] and self.Beam.Transparency.Keypoints[2].Value == transparency then
		return
	end
	local sequence = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(.87, transparency),
		NumberSequenceKeypoint.new(1, 1)
	})
	self.Beam.Transparency = sequence
	-- print(transparency)
	return sequence
end

function drop(self)
	local x = self.Turn == player and self:GetHoveringColumn()
	if x then
		self:SendEvent('drop', x)
	end
end

function getOpponent(self)
	for _,pl in pairs(self.Players) do
		if pl ~= player then
			return pl
		end
	end
end

local gdir,use_x,use_y -- dont remove

function divide(num)
	if not gdir then
		warn('gdir is not defined',gdir,use_x,use_y,num)
		return 0
	end
	
	local x = use_x and num.X / gdir.X or 0
	local y = use_y and num.Y / gdir.Y or 0

	return x + y
end

function sortFunc(pos0, pos1)
	return divide(pos0) < divide(pos1)
end

function Rows.FindBeginning(found, direction)
	if not found or #found < 2 then
		return
	end

	local direction = (found[2] - found[1]).Unit
	
	use_x = direction.X ~= 0
	use_y = direction.Y ~= 0

	if math.random() > .5 then
		direction = -direction
	end

	gdir = direction

	local sorted = util.TableCopy(found)
	table.sort(sorted, sortFunc)
	
	return sorted[1], sorted[#sorted], sorted
end

function getAnimation(winner)
	local anims = winner and (winner == player and script.WinAnims:GetChildren() or script.LoseAnims:GetChildren()) or script.TieAnims:GetChildren()
	return anims[math.random(1,#anims)]
end

do
	local cf_start = CFrame.new(-6.26635075, 2.40788317, -19.1258068, -0.952086329, 0.0264850575, -0.304680407, 1.86264515e-09, 0.996243119, 0.0866007581, 0.305829376, 0.0824513957, -0.948509455)
	local cf_end = CFrame.new(-3.1311996, 1.47466159, -9.30601597, -0.911766708, 0.264434308, -0.314254761, 0.258325189, 0.964082778, 0.0617468357, 0.319295555, -0.0248812065, -0.947328568)

	local fov_start = 23
	local fov_end = 40

	local style = Enum.EasingStyle.Quart
	local duration = 2
	
	function camAnim(root)
		RunService:UnbindFromRenderStep('4R_CamAnim')
		local start = os.clock()
		RunService:BindToRenderStep('4R_CamAnim', Enum.RenderPriority.Last.Value + 100, function(delta)
			local prog = TweenService:GetValue(math.clamp((os.clock() - start) / 2, 0, 1), style, Enum.EasingDirection.Out)
			camera.CFrame = root.CFrame * cf_start:Lerp(cf_end, prog)
			camera.FieldOfView = util.NumberLerp(fov_start, fov_end, prog)
			camera.CameraType = Enum.CameraType.Scriptable
		end)
	end
end

function Rows.new(model)
	local update = model:WaitForChild('UpdateBoard')
	local event = model:WaitForChild('SendEvent')
	
	local contents = update.OnClientEvent:Wait()
	
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {model.Board.Columns}
	params.FilterType = Enum.RaycastFilterType.Whitelist
	params.IgnoreWater = true
	
	local preview = script.temp:Clone()
	preview.Material = Enum.Material.Glass
	preview.CastShadow = false
	preview.Transparency = 1
	preview.Name = 'Preview'
	preview.Parent = model
	
	local new = {
		Board = model.Board.BoardMesh,
		Model = model,
		Preview = preview,
		Beam = model.Board.BoardMesh.WinBeam,
		BeamTransparency = model.Board.BoardMesh.WinBeam.Trans,
		
		AddPiece = addPiece,
		RemovePiece = removePiece,
		RenderBoard = renderBoard,
		RenderPreview = renderPreview,
		SendEvent = sendEvent,
		GetHoveringColumn = getHoveringColumn,
		Drop = drop,
		GetOpponent = getOpponent,
		SetBeamTransparency = setBeamTransparency,
		
		Turn = nil,
		TurnId = nil,
		TurnTimeout = 0,
		MyId = nil,
		Players = {},
		Selected = 4,
		
		Contents = setmetatable(contents, ContentsMeta),
		Pieces = setmetatable({}, ContentsMeta),
		
		CommEvent = event,
		UpdateEvent = update,
		
		RaycastParams = params,
	}

	local self = new
	
	update.OnClientEvent:Connect(function(contents)
		self.Contents = setmetatable(global.DecodeStringray(contents), ContentsMeta)
		self:RenderBoard()
	end)

	self.BeamTransparency.Changed:Connect(function(trans)
		self:SetBeamTransparency(trans)
	end)
	
	event.OnClientEvent:Connect(function(name, ...)
		if name == 'turn' then
			local id,tplr,timeout = ...
			self.Turn = tplr
			self.TurnId = id
			self.TurnTimeout = timeout or 0
		elseif name == 'end' then
			local winner,found,winnerId,direction = ...
			warn(winner and (winner == player and 'W' or 'L') or 'T') 

			local players_end = util.TableCopy(self.Players)
			
			wait(2)

			local start, finish, foundSorted = Rows.FindBeginning(found)

			if start then
				self.Board.Connected:Play()
				self.Beam.Color = ColorSequence.new(Rows.id_map.Color[winnerId])
				local startOffset = Rows.ToOffset(start)
				local finishOffset = Rows.ToOffset(finish)
				local lookAt = CFrame.lookAt(startOffset, finishOffset)
				lookAt -= lookAt.p
				self.Beam.Attachment0.Position = startOffset
				self.Beam.Attachment1.Position = startOffset
				TweenService:Create(self.Beam.Attachment1, TweenInfo.new(.25, Enum.EasingStyle.Quart), {Position = finishOffset + (lookAt * CFrame.new(0, 0, -.4)).p}):Play()
				TweenService:Create(self.Beam.Attachment0, TweenInfo.new(.25, Enum.EasingStyle.Quart), {Position = startOffset + (lookAt * CFrame.new(0, 0, .4)).p}):Play()

				self.BeamTransparency.Value = 0
				TweenService:Create(self.BeamTransparency, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Value = 1}):Play()
			end
			
			thread:Wait(.2)
			
			for _,pos in pairs(found) do
				local piece = self.Pieces[pos.X][pos.Y]
				if piece then
					local par = script.Flare:Clone()
					par.Color = ColorSequence.new(Rows.id_map.Color[winnerId])
					par.Parent = piece
					par:Emit(par.Rate)
					piece.Material = Enum.Material.Neon
					piece.Color = Rows.id_map.WinColor[winnerId]
				end
			end
			
			thread:Wait(.8)
			
			if table.find(players_end, player) then
				local hum = player.Character and player.Character:FindFirstChild('Humanoid')
				if hum then
					local sitting = hum.SeatPart
					local conn = hum.StateChanged:Connect(function()
						sitting = nil
					end)
					ending:Play((winner == player and 'Win') or (winner and 'Lose') or 'Tie')
					local music = script.Music[(winner == player and 'WinMusic') or (winner and 'LoseMusic') or 'TieMusic']
					local sting = script.Music:FindFirstChild((winner == player and 'WinSting') or (winner and 'LoseSting') or 'TieSting')
					local stingStart = (winner == player and .3) or (winner and .1) or 0
					music.Volume = .5
					music.TimePosition = 0
					if sting then
						sting:Play()
						sting.TimePosition = stingStart
						delay(3.5,function()
							music:Play()
						end)
					else
						music:Play()
					end
					delay(3,function()
						conn:Disconnect()
						
						if sitting then
							local cf = sitting.CFrame * CFrame.new(self.MyId == 0 and 5 or -5, 0, 0)
							hum.WalkSpeed = 0
							hum.JumpPower = 0
							hum:ChangeState(Enum.HumanoidStateType.Running)
							wait()
							hum.Parent:SetPrimaryPartCFrame(cf)
							local anim = hum:LoadAnimation(getAnimation(winner))
							anim:Play()
							anim.Stopped:Connect(function()
								hum.WalkSpeed = 16
								hum.JumpPower = 50
								hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
							end)
						end

						for _,player in pairs(players_end) do
							local root = player.Character and player.Character.PrimaryPart
							if root then
								game.SoundService:PlayLocalSound(script.Music.boom)
								camAnim(root)
								wait(2)
							end
						end

						TweenService:Create(music, info4, {Volume = 0, Playing = false}):Play()
						fade_t1:Play()
						fade_t1.Completed:Wait()
						
						RunService:UnbindFromRenderStep('4R_CamAnim')
						camera.CameraType = Enum.CameraType.Custom
						camera.FieldOfView = 70

						fade_t2:Play()
						
					end)
				end
			end
		elseif name == 'player_added' then
			local added,id = ...
			table.insert(self.Players, added)
			if added == player then
				self.MyId = id
				ending:Preload()
				game.ContentProvider:PreloadAsync({script.Music})
			end
		elseif name == 'player_removed' then
			local removed = ...
			table.remove(self.Players, table.find(self.Players, removed))
			if removed == player then
				self.MyId = nil
			end
		end
	end)
	
	return self
end

return Rows