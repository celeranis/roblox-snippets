local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')
local player = game.Players.LocalPlayer
local anthems = {}

local function numberLerp(min,max,alpha)
	return min + ((max - min) * alpha)
end

RunService.Heartbeat:Connect(function()
	for anthem, data in pairs(anthems) do
		
		local prog = numberLerp(data.from,data.to,(tick()-data.start)/(data.time-data.start))
		if (data.time-tick()) < .1 then
			data.from = data.to
			data.to = math.random()
			data.time = tick() + (math.random() * 10)
			data.start = tick()
		end
		
		if not anthem.Parent or not data.RunService then continue end
		if data.RunService.Value then
			anthem.dis.Level = .9
			anthem.Volume = 1
			local distanceFactor = math.clamp((50 - player:DistanceFromCharacter(anthem.Parent.Position)) / 15, .75, 3.5)
			local progLerped = numberLerp(.5, 1.5, prog)
			anthem.PlaybackSpeed = progLerped * distanceFactor
			if not data.prevRunning then
				script.Noticed:Play()
			end
		else
			anthem.Volume = .25
			anthem.dis.Level = 0
			anthem.PlaybackSpeed = numberLerp(.1, 1, prog)
		end
		data.prevRunning = data.RunService.Value
		
	end
end)

local function setup(anthem)
	anthems[anthem] = {
		from = 0,
		to = math.random(),
		time = tick() + (math.random() * 10),
		start = tick(),
		RunService = anthem.Parent.Parent:WaitForChild('Running'),
		prevRunning = false
	}
	anthem:Play()
end
for _,anthem in pairs(CollectionService:GetTagged('Anthem')) do
	setup(anthem)
end
CollectionService:GetInstanceAddedSignal('Anthem'):Connect(setup)
CollectionService:GetInstanceRemovedSignal('Anthem'):Connect(function(anthem)
	anthems[anthem] = nil
end)