local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local player = game.Players.LocalPlayer

function updateFrozen(froz)
	local mat = froz and Enum.Material.Ice or Enum.Material.Metal
	local prop = froz and PhysicalProperties.new(.919,0,.15,100,1) or PhysicalProperties.new(Enum.Material.Metal)
	
	for _,v in pairs(script.Pieces:GetChildren()) do
		v.Collision.Material = mat
		v.Collision.CustomPhysicalProperties = prop
	end
	
	local col = froz and Color3.new() or Color3.fromRGB(44, 44, 44)
	for _,v in pairs(workspace:GetChildren()) do
		if v:IsA('BasePart') and (v.Name == 'Floor' or v.Name == 'Wall') then
			v.Material = mat
			v.CustomPhysicalProperties = prop
			v.Color = col
		end
	end
end
ReplicatedStorage.Frozen.Changed:Connect(updateFrozen)
updateFrozen(ReplicatedStorage.Frozen.Value)

if not ReplicatedStorage.Started.Value then
	ReplicatedStorage.Started.Changed:Wait()
end

local SPAWN_INTERVAL = ReplicatedStorage.SPAWN_INTERVAL
local SPEED = ReplicatedStorage.SPEED
local CLEAR_INTERVAL = ReplicatedStorage.CLEAR_INTERVAL
local DISALBE_TRAILS = ReplicatedStorage.DISABLE_TRAILS

local active = {}

local p = script:WaitForChild('Pieces')

local lastSpawn = os.clock()
local lastClear = os.clock()

local start = game.ReplicatedStorage.StartedAt

local types = {
	p.I,
	p.J,
	p.L,
	p.O,
	p.S,
	p.T,
	p.Z
}

local count = ReplicatedStorage.Pieces

local rad90 = math.rad(90)

local region = Region3.new(Vector3.new(-77.5, -9.5, -77.5),Vector3.new(77.5, 600, 77.5))

local generateData = require(script.PieceData)
local data = generateData()

local recentSpawns = {}

local info = TweenInfo.new(.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)

function snap(num: number): number
	return math.floor((num / 5) + .5)
end

function isOccupied(pos: Vector3): boolean
	local x,y,z = snap(pos.X),snap(pos.Y),snap(pos.Z)
	local acid_level = (tick() - (start.Value + ReplicatedStorage.TimeOffset.Value)) - 240
	
	return pos.Y <= -8 or pos.Y <= acid_level or data[math.floor(x+.5)][math.floor(y+.5)][math.floor(z+.5)]
end
function occupy(pos: Vector3)
	local x,y,z = snap(pos.X),snap(pos.Y),snap(pos.Z)
	
	data[math.floor(x+.5)][math.floor(y+.5)][math.floor(z+.5)] = true
end

local downFive = Vector3.new(0,-5,0)
local downOne = Vector3.new(0,-1,0)

function isInGame(point)
    local relative = (region.CFrame:PointToObjectSpace(point) - region.CFrame:PointToObjectSpace(region.CFrame.p)) / region.Size
    return -0.5 <= relative.X and relative.X <= 0.5
       and -0.5 <= relative.Y and relative.Y <= 0.5
       and -0.5 <= relative.Z and relative.Z <= 0.5
end

function getTarget(start_pos, piece)
	local pos = Vector3.new()
	
	repeat
		pos += downFive
		for _,v in pairs(piece:GetChildren()) do
			local ppos = v.Position + pos
			if v.Name == 'Part' and isOccupied(ppos) then
				return pos - downFive
			end
		end
	until (pos.Y + start_pos.Y) <= -8
	
	return pos
end

local previews = {}
--local previewHighlights = {}

local function newPiece()
	lastSpawn += SPAWN_INTERVAL.Value
	
	local pid = math.random(1,7)
	local piece = types[pid]:Clone()
	local ori = CFrame.fromOrientation(math.random(0,3) * rad90, math.random(0,3) * rad90, math.random(0,3) * rad90)
	local start_pos = Vector3.new(math.random(-15,16), 110, math.random(-15,16)) * 5
	local cf = ori + start_pos
	
	piece:SetPrimaryPartCFrame(cf)
	
	for _,v in pairs(piece:GetChildren()) do
		if v.Name == 'Part' and (not isInGame(v.Position) or isOccupied(v.Position)) then
			spawn(newPiece)
			return
		end
	end
	
	local target = getTarget(start_pos, piece)
	for _,v in pairs(piece:GetChildren()) do
		if v.Name == 'Part' then
			occupy(v.Position + target)
		end
	end
	
	if DISALBE_TRAILS.Value then
		for _,v in pairs(piece:GetDescendants()) do
			if v:IsA('Trail') then
				v.Enabled = false
			end
		end
	end
	
	local preview = piece.Collision:Clone()
	preview.CFrame = cf + target - (cf.p - preview.Position)
	preview.Name = 'PiecePreview'
	preview.CanCollide = false
	preview.Material = Enum.Material.Glass
	preview.Transparency = 1
	TweenService:Create(preview, info, {Transparency = .75}):Play()
	--preview.Color = Color3.new(1,0,0)
	preview:ClearAllChildren()
	previews[piece] = preview
	--previewHighlights[piece] = highlight
	preview.Parent = workspace.PiecePreviews
	
	piece.Parent = workspace.Pieces
	active[piece] = {
		target = cf + target,
		start = os.clock(),
		start_pos = cf
	}
end

RunService.Heartbeat:Connect(function(delta)	
	if not ReplicatedStorage.Started.Value then return end
	
	local now = os.clock()
	while now - lastSpawn > SPAWN_INTERVAL.Value do
		newPiece()
	end
	
	local speed_real = delta * SPEED.Value
	
	local chr = player.Character
	local root = chr and chr.PrimaryPart
	
	for p,info in pairs(active) do
		
		local target = info.target
		local start = info.start
		local start_pos = info.start_pos
		
		if not p.Parent then active[p] = nil continue end
		
		local cf = p.Collision.CFrame + (downOne * SPEED.Value * delta)
		
		local diff = target.p.Y - cf.p.Y 
		local finished = diff >= 0
		if finished then
			active[p] = nil
			p.PrimaryPart.CFrame = target
			p.PrimaryPart = p.Collision
			p.Collision.Name = 'CollisionSafe'
			for _,v in pairs(p:GetChildren()) do
				if v.Name == 'Part' then
					v:Destroy()
				end
			end
			
			count.Value += 1
			p.CollisionSafe.Placed:Play()
			
			if root.Position.Y < 400 and game.ReplicatedStorage.Started.Value then
				for _,v in pairs(p.CollisionSafe:GetTouchingParts()) do
					if v == root then
						chr.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
					end
				end
			end
			
			if previews[p] then
				previews[p]:Destroy()
				previews[p] = nil
			end
		else
			p.Collision.CFrame = cf
		end
	end	
end)

DISALBE_TRAILS.Changed:Connect(function(disabled)
	for piece in pairs(active) do
		for _,desc in pairs(piece:GetDescendants()) do
			if desc:IsA('Trail') then
				desc.Enabled = not disabled
			end
		end
	end
end)

ReplicatedStorage.Reset.OnClientEvent:Connect(function()
	workspace.Pieces:ClearAllChildren()
	workspace.PiecePreviews:ClearAllChildren()
	
	active = {}
	previews = {}
	data = generateData()
	
	lastSpawn = os.clock()
	lastClear = os.clock()
	
	ReplicatedStorage.Pieces.Value = 0
end)

ReplicatedStorage.Started.Changed:Connect(function()
	lastSpawn = os.clock()
	lastClear = os.clock()
end)

spawn(function()
	while wait(CLEAR_INTERVAL.Value) do
		local diff = (tick() - (start.Value + ReplicatedStorage.TimeOffset.Value)) - 240
		for _,v in pairs(workspace.Pieces:GetChildren()) do
			if v.PrimaryPart.Position.Y + 10 < diff then
				v:Destroy()
			end
		end
	end
end)