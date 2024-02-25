local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local humanoid = script.Parent:WaitForChild('Humanoid')
local root = script.Parent:WaitForChild('HumanoidRootPart')

local dead = false
RunService.Heartbeat:Connect(function()
	if dead or root.Position.Y > 400 or not ReplicatedStorage.Started.Value then return end
	
	for _,v in pairs(root:GetTouchingParts()) do
		if v.Parent == script.Parent then continue end
		--print(v.Name)
		if v.Name == 'Collision' then
			dead = true
			humanoid:ChangeState(Enum.HumanoidStateType.Dead,true)
			print('dead')
			break
		end
	end
end)