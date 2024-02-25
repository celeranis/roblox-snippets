local screenGui = script.Parent
local staminaLabel = screenGui:WaitForChild('TextLabel')
local outerFrame = screenGui:WaitForChild('Frame')
local innerFrame = outerFrame:WaitForChild('Frame')

local plr = game.Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local staminaValue = chr:WaitForChild('StaminaScript'):WaitForChild('Stamina')

local red = Color3.new(1)
local white = Color3.new(1,1,1)
local dred = Color3.fromRGB(170)
local grey = Color3.fromRGB(170, 170, 170)

local TweenService = game:GetService('TweenService')

local fadeOut_lab = TweenService:Create(staminaLabel, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { TextTransparency = 1 })
local fadeOut_out = TweenService:Create(outerFrame, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
local fadeOut_inn = TweenService:Create(innerFrame, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { BackgroundTransparency = 1 })

local fadeIn_lab = TweenService:Create(staminaLabel, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),{ TextTransparency = 0 })
local fadeIn_out = TweenService:Create(outerFrame, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),{ BackgroundTransparency = 0 })
local fadeIn_inn = TweenService:Create(innerFrame, TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In),{ BackgroundTransparency = 0 })

local function update()
	local currentStamina = staminaValue.Value
	if currentStamina >= .99 and staminaLabel.TextTransparency == 0 then
		fadeOut_lab:Play()
		fadeOut_inn:Play()
		fadeOut_out:Play()
	elseif currentStamina < .99 and staminaLabel.TextTransparency > 0 then
		fadeIn_lab:Play()
		fadeIn_inn:Play()
		fadeIn_out:Play()
	end
	innerFrame.Size = UDim2.fromScale(currentStamina >= 0 and currentStamina or math.abs(1 + currentStamina), 1)
	
	local lerpPercent = (currentStamina + 1) / 2
	innerFrame.BackgroundColor3 = currentStamina > 0 and red:Lerp(white, lerpPercent) or red
	outerFrame.BackgroundColor3 = currentStamina > 0 and dred:Lerp(grey, lerpPercent) or dred
	staminaLabel.TextColor3 = currentStamina > 0 and red:Lerp(white, lerpPercent) or red
end

staminaValue.Changed:Connect(update)
while task.wait(1) do update() end