local RunService = game:GetService('RunService')
local acidTexture = workspace:WaitForChild('Acid'):WaitForChild('Texture')
local timeOffset = game.ReplicatedStorage.TimeOffset
local startedAt = game.ReplicatedStorage.StartedAt
local isStarted = game.ReplicatedStorage.Started
local hard = game.ReplicatedStorage.Hard
local prevStep = 0
RunService.RenderStepped:Connect(function()
	local now = (math.floor(tick()/0.04)%24)+1
	if now ~= prevStep then
		acidTexture.Texture = 'rbxasset://textures/water/normal_'..((now<10 and '0'..now) or now)..'.dds'
		prevStep = now
	end
	local now = not isStarted.Value and 0 or (tick()-timeOffset.Value) * (hard.Value and 4 or 1.5)
	workspace.Acid.CFrame = CFrame.new(0, (now - (startedAt.Value * (hard.Value and 4 or 1.5))) - (hard.Value and 244 or 94), 0)
end)