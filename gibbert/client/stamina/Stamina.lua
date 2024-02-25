local character = script.Parent
local humanoid = character:WaitForChild('Humanoid')
local isSprinting = humanoid:WaitForChild('IsSprinting')
local currentStamina = script:WaitForChild('Stamina')
local RunService = game:GetService('RunService')

RunService.Stepped:Connect(function(_, int)
	if humanoid.MoveDirection.Magnitude > 0 then
		if isSprinting.Value then
			currentStamina.Value -= (int / 5)
			if currentStamina.Value <= .01 then
				isSprinting.Value = false
				humanoid.JumpPower = 0
				currentStamina.Value = -1
			end
		else
			currentStamina.Value += (int / 10)
		end
	else
		currentStamina.Value += (int / 3)
	end
end)

humanoid.Jumping:Connect(function(enter)
	if enter then
		currentStamina.Value = currentStamina.Value - .25
		if currentStamina.Value <= .01 then
			isSprinting.Value = false
			currentStamina.Value = -1
		end
	end
end)

isSprinting.Changed:Connect(function(sprinting)
	if currentStamina.Value <= 0 and sprinting then
		RunService.Stepped:Wait()
		isSprinting.Value = false
	end
end)