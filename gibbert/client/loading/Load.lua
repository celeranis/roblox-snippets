local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Lighting = game:GetService('Lighting')
local TweenService = game:GetService('TweenService')
local TeleportService = game:GetService('TeleportService')
local ContentProvider = game:GetService('ContentProvider')
local ReplicatedFirst = game:GetService('ReplicatedFirst')

local plr = Players.LocalPlayer
local strings = require(ReplicatedStorage:WaitForChild('Strings'))
local teleportGui = script.Teleporting

local fade = Lighting:WaitForChild('ColorCorrection')
fade.Brightness = -1
fade.Saturation = -1

teleportGui.Enabled = true
teleportGui.Parent = plr:WaitForChild('PlayerGui')
ReplicatedFirst:RemoveDefaultLoadingScreen()

local tdata = TeleportService:GetLocalPlayerTeleportData()

teleportGui.Tip.Text = (typeof(tdata) == 'table' and tdata.Tip and strings.tips[tdata.Tip]) or ''

local originalPositions = {}
for _, frame in teleportGui:GetChildren() do
	if frame:IsA('Frame') then
		originalPositions[frame] = {
			Position = frame.Position + UDim2.fromScale(-1,0),
		}
	end
end

local info = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local info1 = TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local info2 = TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

ContentProvider:PreloadAsync({workspace, plr, script, game.StarterPlayer, ReplicatedStorage, Lighting})

task.wait(1)

for _,frame in teleportGui:GetChildren() do
	if frame:IsA('Frame') then
		frame.Position = op[frame].Position + UDim2.fromScale(1,0)
		if frame.ClassName:find('Text') then
			frame.TextTransparency = op[frame].TextTransparency
		end
		local t1:TweenBase = TweenService:Create(frame, frame.ClassName:find('Text') and info1 or info, op[frame])
		task.delay(.5 - (frame.Position.Y.Scale / 2),function()
			t1:Play()
		end)
	end
end

TweenService:Create(fade, info2, { Brightness = 0,Saturation = 0 }):Play()
TweenService:Create(teleportGui.Tip, info2, { TextTransparency = 1 }):Play()
TweenService:Create(teleportGui.LoadingText, info2, { TextTransparency = 1 }):Play()

task.wait(5)

teleportGui.Enabled = false
teleportGui.Tip.TextTransparency = 0
teleportGui.LoadingText.TextTransparency = 0