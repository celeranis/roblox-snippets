local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local TeleportService = game:GetService('TeleportService')

local button =  script.Parent.Frame.TextButton

local info = TweenInfo.new(2, Enum.EasingStyle.Quint)
local showTween = TweenService:Create(button.UIScale, info, {Scale = 1})
local showTween2 = TweenService:Create(button, info, {TextTransparency = 0})

game.ReplicatedStorage.GameOver.OnClientEvent:Connect(function()
	script.Parent.Enabled = true
	for _,v in pairs(game:GetDescendants()) do -- immediately force all sounds to stop
		pcall(function()
			if v:IsA('Sound') and v.Parent ~= script then
				v:Destroy()
			end
		end)
	end
	script.dead:Play()
	script.Metal:Play()
	button.UIScale.Scale = 2
	button.TextTransparency = 1
	button.Visible = true
	task.wait(5)
	script.Boom:Play()
	showTween:Play()
	showTween2:Play()
	task.wait(2)
	UserInputService.MouseIconEnabled = true
end)

local teleporting = false

button.Activated:Connect(function()
	if teleporting then return end
	teleporting = true
	TeleportService:Teleport(4937864693, game.Players.LocalPlayer)
end)