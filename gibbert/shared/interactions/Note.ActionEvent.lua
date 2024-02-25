local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

if RunService:IsClient() then
	local Players = game:GetService('Players')
	local UserInputService = game:GetService('UserInputService')
	local TweenService = game:GetService('TweenService')
	
	local plr = Players.LocalPlayer
	local humanoid = plr.Character and plr.Character:FindFirstChild('Humanoid')
	local note = plr:WaitForChild('PlayerGui'):WaitForChild('Note')
	
	local styleQuartOut = TweenInfo.new(1, Enum.EasingStyle.Quart)
	local styleQuartIn = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	local styleSineIO = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	
	local text_in = { TextTransparency = .25 }
	local text_out = { TextTransparency = 1 }
	
	local frameFlyIn = TweenService:Create(note.Frame, styleQuartOut, { Position = UDim2.fromScale(.5,.5), Rotation = 4 })
	local frameFlyOut = TweenService:Create(note.Frame, styleQuartIn, { Position = UDim2.fromScale(.5,.25), Rotation = 14 })
	
	local frameFadeIn = TweenService:Create(note.Frame, styleSineIO, { BackgroundTransparency = 0 })
	local frameFadeOut = TweenService:Create(note.Frame, styleSineIO, { BackgroundTransparency = 1 })
	local closeFadeIn = TweenService:Create(note.Frame.Close, styleSineIO, { BackgroundTransparency = .9, TextTransparency = 0 })
	local closeFadeOut = TweenService:Create(note.Frame.Close, styleSineIO, { BackgroundTransparency = 1, TextTransparency = 1 })
	local sorryFadeIn = TweenService:Create(note.Frame.Sorry, styleSineIO, text_in)
	local sorryFadeOut = TweenService:Create(note.Frame.Sorry, styleSineIO, text_out)
	local bodyFadeIn = TweenService:Create(note.Frame.Body, styleSineIO, text_in)
	local bodyFadeOut = TweenService:Create(note.Frame.Body, styleSineIO, text_out)
	local glFadeIn = TweenService:Create(note.Frame.gl, styleSineIO, text_in)
	local glFadeOut = TweenService:Create(note.Frame.gl, styleSineIO, text_out)
	local disableAll = TweenService:Create(note, styleSineIO, { Enabled = false })
	
	local preTween = {
		[note.Frame] = {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(.5,.75),
			Rotation = -4
		},
		[note.Frame.Close] = {
			BackgroundTransparency = 1,
			TextTransparency = 1
		},
		[note.Frame.Sorry] = text_out,
		[note.Frame.Body] = text_out,
		[note.Frame.gl] = text_out,
		[note] = {
			Enabled = true
		}
	}
	
	return function()
		humanoid.IsSprinting.Value = false
		humanoid.WalkSpeed = 0
		
		for obj,properties in pairs(preTween) do
			for name,val in pairs(properties) do
				obj[name] = val
			end
		end
		
		note.Open:Play()
		UserInputService.MouseIconEnabled = true
		
		frameFlyIn:Play()
		frameFadeIn:Play()
		closeFadeIn:Play()
		sorryFadeIn:Play()
		bodyFadeIn:Play()
		glFadeIn:Play()
		
		note.Frame.Close.Activated:Wait()
		
		frameFlyOut:Play()
		frameFadeOut:Play()
		closeFadeOut:Play()
		sorryFadeOut:Play()
		bodyFadeOut:Play()
		glFadeOut:Play()
		disableAll:Play()
		
		UserInputService.MouseIconEnabled = false
		note.Close:Play()
		humanoid.WalkSpeed = ReplicatedStorage.Mode.Value == 'speedy' and 64 or 16
	end
else
	local ServerStorage = game:GetService('ServerStorage')
	
	return function(plr)
		if plr.ObjectiveId.Value == 2 then
			ReplicatedStorage.Subtitles:FireClient(plr,"That can't be good.")
			plr.ObjectiveId.Value = 3
			ServerStorage.GenerateCode:Fire()
			task.wait(3)
			plr.Objective.Value = 'FIND THE CODE'
		end
	end
end