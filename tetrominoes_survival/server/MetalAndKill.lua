local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local maxh = 0
local start = os.clock()

local function metal(obj)
	if obj:IsA('BasePart') then
		obj.Material = Enum.Material.SmoothPlastic
		obj.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.Plastic)
	end
end
for _,v in pairs(script.Parent:GetDescendants()) do
	metal(v)
end
script.Parent.DescendantAdded:Connect(metal)

local hum = script.Parent:WaitForChild('Humanoid')
local root = script.Parent:WaitForChild('HumanoidRootPart')

local dead = false
local won = false
hum.Died:Connect(function()
	dead = true
	local plr = Players:GetPlayerFromCharacter(script.Parent)
	ReplicatedStorage.fin_server:Fire(plr, false, math.floor(maxh / 5), math.floor(os.clock()-start))
end)
RunService.Heartbeat:Connect(function()
	if not won and root.Position.Y > 450 then
		won = true
		local plr = Players:GetPlayerFromCharacter(script.Parent)
		ReplicatedStorage.fin_server:Fire(plr, true, math.floor(maxh / 5), math.floor(os.clock()-start))
		return
	end
	maxh = math.max(maxh,root.Position.Y)
end)