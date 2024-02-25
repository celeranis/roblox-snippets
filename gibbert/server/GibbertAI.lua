-- services
local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')
local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Pathfinder = require(game.ServerScriptService.Pathfinder)

-- character
local chr = script.Parent
local humanoid = chr:WaitForChild('Humanoid')
local root = chr:WaitForChild('HumanoidRootPart')
local head = chr:WaitForChild('Head')

-- config
local lookEvery = .1
local recomputeEvery = .25
local maxTimeout = 50
local last

-- definitions
local lastLook = 0 
local lastRecompute = 0
local following = nil
local wanderingTo = nil
local waypointIndex = 1
local waypoints = {}
local timeout = maxTimeout
local prevFollowing = nil

local function getClosest(players)
	local dist,plr = math.huge,nil
	for _,v in pairs(players) do
		if v:DistanceFromCharacter(root.Position) < dist then
			plr = v
		end
	end
	return plr,dist
end

local function look()
	local visible = {}
	
	if humanoid.Health <= 0 then following = nil return end
	
	for _,plr in pairs(game.Players:GetPlayers()) do
		
		local playerCharacter = plr.Character
		local playerHumanoid = playerCharacter and playerCharacter:FindFirstChild('Humanoid')
		local playerRoot = playerCharacter and playerCharacter:FindFirstChild('HumanoidRootPart')
		
		if not playerHumanoid or not playerRoot then continue end
		
		local dir = (playerRoot.Position - head.Position)
		local viewP = root.CFrame.LookVector:Dot(dir.Unit)
		
		if viewP < .25 then continue end
		
		local ray = Ray.new(head.Position,dir)
		local part = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Labarynth, playerRoot,workspace.Boxes, workspace.ViewBlocks})
		
		if part == playerRoot then
			visible[#visible + 1] = plr
		end
		
	end
	
	if #visible <= 0 then
		timeout = timeout - 1
		if timeout <= 0 and following then
			following = nil
			root.Scream:Play()
		end
		return
	end
	
	timeout = maxTimeout
	following = getClosest(visible).Character.PrimaryPart
	
	if prevFollowing ~= following then
		prevFollowing = following
	end
	
end

local function recomputeFollowing()
	
	if humanoid.Health <= 0 then return end
	
	waypoints = Pathfinder:FindPath(root.Position,following.Position) or {following.Position}
	
	if (root.Position - waypoints[#waypoints]).Magnitude <= 3 then
		waypoints = {following.Position}
	end
	
	waypointIndex = math.min(2, #waypoints)
	
end

local challenge = ReplicatedStorage.Mode

RunService.Heartbeat:Connect(function()
	if humanoid.Health <= 0 then return end
	
	if tick() >= lastLook+lookEvery then
		look()
		lastLook = tick()
	end
	
	if waypoints[waypointIndex] and (root.Position - waypoints[waypointIndex]).Magnitude <= 3 then
		waypointIndex = waypointIndex + 1
	end
	
	local speedy = challenge.Value == 'speedy'
	
	if following and following.Parent then
		humanoid.WalkSpeed = speedy and 90 or 22
		chr.Running.Value = true
		if tick() >= lastRecompute + recomputeEvery or not waypoints[waypointIndex] then
			recomputeFollowing()
			lastRecompute = tick()
		end
	else
		humanoid.WalkSpeed = speedy and 72 or 8
		chr.Running.Value = false
		if not waypoints[waypointIndex] then
			wanderingTo = Pathfinder:GetFullRandomNode(root.Position).Position
			waypoints = Pathfinder:FindPath(root.Position,wanderingTo) or {root.Position}
			waypointIndex = 1
		end
	end
	
	humanoid:Move(waypoints[waypointIndex]-root.Position)
end)

chr.Hitbox.Touched:Connect(function(h)
	if humanoid.Health <= 0 then return end
	
	local thum = h.Parent and h.Parent:FindFirstChild('Humanoid')
	if thum and not CollectionService:HasTag(thum,'gibhum') then
		thum.Health = 0
	end
end)

humanoid:GetPropertyChangedSignal('Health'):Connect(function()
	if humanoid.Health <= 0 then return end
	
	following = game.Players:GetPlayers()[1].Character.PrimaryPart
end)

humanoid.Died:Connect(function()
	root.Dead:Play()
	root.Scream:Play()
	root.Anthem:Destroy()
	humanoid.WalkSpeed = 0
	root.Sounds.Disabled = true
	chr.Hitbox:Destroy()
	chr.Key:Destroy()
	ReplicatedStorage.GibbertDead:FireAllClients()
	
	local key = game.ServerStorage.Key:Clone()
	key.Position = root.Position
	key.Parent = workspace
	
	root.Beam:Destroy()
	chr.Stare.Handle.REye:Destroy()
	chr.Stare.Handle.LEye:Destroy()
	
	wait(1)
	key.Shine:Play()
end)