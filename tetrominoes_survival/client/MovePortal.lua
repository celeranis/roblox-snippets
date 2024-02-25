local RunService = game:GetService('RunService')

local util = require(game.ReplicatedStorage.util)

local spinSpeed = math.rad(-90)

local black = Color3.new()
local base_color = Color3.fromRGB(255, 100, 500)

local portals = {}
for i = 1, 6 do
	local p = workspace:WaitForChild('PortalDecal'..i)
	table.insert(portals, p)
	p.CFrame *= CFrame.fromOrientation(0,0,math.rad(60) * i)
	
	local sizeXY = util.NumberLerp(400,200,(i-1)/5)
	p.Size = Vector3.new(sizeXY,sizeXY,.05)
	
	p.Decal.Color3 = base_color:Lerp(black, (i-1)/6)
end

RunService.RenderStepped:Connect(function(delta)
	for i, portal in portals do
		local speed = spinSpeed * (1-((i-1) / 7))
		portal.CFrame *= CFrame.fromOrientation(0,0,speed * delta)
	end
end)