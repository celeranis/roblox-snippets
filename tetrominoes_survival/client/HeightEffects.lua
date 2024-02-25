local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SoundService = game:GetService('SoundService')

local root = script.Parent:WaitForChild('HumanoidRootPart')
local humanoid = script.Parent:WaitForChild('Humanoid')
local util = require(ReplicatedStorage:WaitForChild('util'))

local theme = SoundService:WaitForChild('Theme')
local running = ReplicatedStorage:WaitForChild('Started')

function getProg(y, min, max)
	return (math.clamp(root.Position.Y, min, max) - min) / (max - min)
end

local maxy = 0

theme.EQ.HighGain = 0
theme.EQ.MidGain = 0
theme.Volume = .75
theme.PlaybackSpeed = 1
theme:Stop()
SoundService.PlacedSounds.Volume = 1

RunService.Heartbeat:Connect(function()
	local y = root.Position.Y
	maxy = math.max(maxy,y)
	
	local eqprog = TweenService:GetValue(getProg(y, 350, 450),Enum.EasingStyle.Quart,Enum.EasingDirection.In)
	workspace.Gravity = util.NumberLerp(196.2, -69, eqprog)
	
	theme.EQ.LowGain = eqprog * -80
	theme.EQ.MidGain = eqprog * -40
	theme.Reverb.WetLevel = util.NumberLerp(-80, 0, eqprog)
	theme.Reverb.DecayTime = util.NumberLerp(0.1, 20, eqprog)
	theme.Reverb.DryLevel = eqprog * -20
	
	game.Lighting.ColorCorrection.Brightness = eqprog
	
	if theme.TimePosition > 132 then
		theme.TimePosition = theme.TimeLength
	end
end)
if not running.Value then
	running.Changed:Wait()
end

--game.SoundService.ThemeStart:Play()
--wait(12.75)
--game.SoundService.ThemeStart:Stop()
--if humanoid.Health <= 0 then return end

theme:Play()
theme.TimePosition = 1
theme.DidLoop:Connect(function()
	theme.PlaybackSpeed = util.NumberLerp(1, 1.5, getProg(maxy, 0, 400))
	theme.TimePosition = 1
end)
local sinfo = TweenInfo.new(4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
humanoid.Died:Connect(function()
	TweenService:Create(theme.EQ,TweenInfo.new(3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{HighGain = -80,MidGain = -40}):Play()
	TweenService:Create(theme,sinfo,{Volume = 0, PlaybackSpeed = 0}):Play()
	TweenService:Create(game.SoundService.PlacedSounds,sinfo,{Volume = 0}):Play()
end)