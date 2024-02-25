local tool = script.Parent
local handle = tool:WaitForChild('Handle')
local bulletStart = handle:WaitForChild('BulletStart')

local shootSound = handle:WaitForChild('Shoot')

local CollectionService = game:GetService('CollectionService')
local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local random = Random.new()

local prevShot = tick()

local bloom = .15
local damage = 5
local interval = 1.5

local function shoot(dir)
	prevShot = tick()
	
	local chr = tool.Parent
	local hum = chr:FindFirstChildOfClass('Humanoid')
	local head = chr:FindFirstChild('Head')
	if not hum or not head then return end
	
	local s = shootSound:Clone()
	s.Parent = shootSound.Parent
	s.PlaybackSpeed = s.PlaybackSpeed + random:NextNumber(-.25,.25)
	s:Play()
	game.Debris:AddItem(s,s.TimeLength)
	
	local startpos = bulletStart.WorldPosition
	
--	bulletStart.Sparkle:Emit(1)
	
	local humsHit = {}
	local headshots = {}
	
	for i = 1,10 do
		local bloomDir = Vector3.new(random:NextNumber(-bloom,bloom), random:NextNumber(-bloom,bloom), random:NextNumber(-bloom,bloom))
		local aimDir = (dir+bloomDir) * 256
		
		local ray = Ray.new(startpos,aimDir)
		local list = CollectionService:GetTagged('GIBBERT')
		table.insert(list, workspace.Labarynth)
		
		ReplicatedStorage.ServerBullet:FireAllClients(startpos,aimDir.Unit * 256, 1, Vector3.new(.2,.2,6.7), Color3.fromRGB(255,151,102))
		
		ReplicatedStorage.LocalBullet:Fire({
			Position = startpos,
			Damage = damage,
			HeadshotMultiplier = 2,
			List = list,
			Distance = 256,
			Direction = aimDir.Unit,
			Size = .25
		})
	end
end

function floorVector(v3)
	return {math.floor(v3.x), math.floor(v3.y), math.floor(v3.z)}
end

local idle
tool.Shoot.OnServerEvent:Connect(function(plr,dir)
	if (tick()-prevShot) >= interval and plr == Players:GetPlayerFromCharacter(tool.Parent) then
		shoot(dir)
	end
end)
tool.Equipped:Connect(function()
	handle.Equip:Play()
end)