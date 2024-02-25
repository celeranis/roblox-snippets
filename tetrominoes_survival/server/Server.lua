local Lighting = game:GetService('Lighting')
local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local SPAWN_INTERVAL = ReplicatedStorage.SPAWN_INTERVAL
local SPEED = ReplicatedStorage.SPEED
local CLEAR_INTERVAL = ReplicatedStorage.CLEAR_INTERVAL
local DISALBE_TRAILS = ReplicatedStorage.DISABLE_TRAILS

local m = os.clock()
local conns = {}

local mode = 'Normal'

local function startgame(retry, newmode)
	for i,v in pairs(conns) do
		v:Disconnect()
		conns[i] = nil
	end
	
	mode = newmode or mode
	
	local hard = mode == 'Hard'
	ReplicatedStorage.Frozen.Value = mode == 'Frozen'
	ReplicatedStorage.Hard.Value = hard
	
	local now = os.clock()
	m = now
	
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.FogEnd = 0
	
	SPAWN_INTERVAL.Value = .5
	SPEED.Value = 150
	CLEAR_INTERVAL.Value = 10
	DISALBE_TRAILS.Value = true
	ReplicatedStorage.Started.Value = false
	ReplicatedStorage.ShowMap.Value = false
	if retry then
		ReplicatedStorage.Reset:FireAllClients()
	end
	
	for _,v in pairs(Players:GetPlayers()) do
		v:LoadCharacter()
		CollectionService:RemoveTag(v,'gg')
	end
	local conn = Players.PlayerAdded:Connect(function(v)
		v:LoadCharacter()
	end)
	
	delay(10,function()
		if m ~= now then return end
		ReplicatedStorage.DisplayNotif:FireAllClients('Reach the exit portal above to escape!')
		ReplicatedStorage.DisplayNotif:FireAllClients('Avoid being crushed by the tetrominoes!')
		
		wait(17.75)
		if m ~= now then return end
		
		SPAWN_INTERVAL.Value = hard and .03 or .05
		SPEED.Value = hard and 420 or 250
		DISALBE_TRAILS.Value = false
		ReplicatedStorage.ShowMap.Value = true
		conn:Disconnect()
		
		wait(42)
		if m ~= now then return end
		
		ReplicatedStorage.DisplayNotif:FireAllClients('The acid is rising!','Warning',10)
	end)
	
	wait(10)
	ReplicatedStorage.LocalTween:FireAllClients(Lighting,5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,{EnvironmentDiffuseScale = 1,EnvironmentSpecularScale = 1})
	ReplicatedStorage.LocalTween:FireAllClients(Lighting,5,Enum.EasingStyle.Exponential,Enum.EasingDirection.In,{FogEnd = 10000})
	wait(5)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.FogEnd = 10000
	
	local lava_speed = hard and 4 or 1.5
	local lava_start = hard and 240 or 90
	
	local start = elapsedTime() * lava_speed
	ReplicatedStorage.StartedAt.Value = tick()
	ReplicatedStorage.Started.Value = true
	
	
	table.insert(conns,RunService.Heartbeat:Connect(function(step)
		if not ReplicatedStorage.Started.Value then return end
		local diff = (elapsedTime() * lava_speed) - start
		for _,v in pairs(Players:GetPlayers()) do
			if CollectionService:HasTag(v,'gg') then continue end
			local root = v.Character and v.Character:FindFirstChild('UpperTorso')
			local hum = v.Character and v.Character:FindFirstChild('Humanoid')
			if root and root.Position.Y <= diff - lava_start and hum.Health > 0 then
				hum.Health = 0
			end
		end
	end))
end
--startgame()
ReplicatedStorage.Start.OnServerEvent:Connect(startgame)