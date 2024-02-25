local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local humanoid = script.Parent:WaitForChild('Humanoid')
local root = script.Parent:WaitForChild('HumanoidRootPart')

local progress = 0
local targetVelocity = 0
local velocity = 0

local function numberLerp(min, max, alpha)
	return min + ((max - min) * alpha)
end

if player:WaitForChild('SavedData').Settings.bobbing.Value == false then return end

RunService.RenderStepped:Connect(function(delta)
	prog = prog + (delta * (math.max(root.Velocity.Magnitude, 2) / 2))
	targetVelocity = root.Velocity.Magnitude / 16
	velocity = numberLerp(velocity, targetVelocity, delta*5)
	local sin = (math.sin(prog)/2)
	local sin2 = sin * (math.clamp(velocity / 2, 0, 1))
	humanoid.CameraOffset = Vector3.new(0, sin / 3, 0):Lerp(Vector3.new(sin2, sin2 ^ 2, 0), math.clamp(velocity, 0, 1))
end)