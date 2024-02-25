--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')

local strings = require(ReplicatedStorage:WaitForChild('Strings'))
local info = TweenInfo.new(1,Enum.EasingStyle.Quart)
local info1 = TweenInfo.new(1.5,Enum.EasingStyle.Quart)
local originalPositions = {}

ReplicatedStorage.Teleporting.Event:Connect(function(tipid: number)
	script.Parent.Tip.Text = strings.tips[tipid] or ''
	for _,obj in pairs(script.Parent:GetChildren()) do
		if obj:IsA('GuiObject') then
			obj.Position = originalPositions[obj].Position + UDim2.fromScale(1,0)
			if obj.ClassName:find('Text') then
				obj.TextTransparency = originalPositions[obj].TextTransparency
			end
			local t1:TweenBase = TweenService:Create(obj, obj.ClassName:find('Text') and info1 or info,originalPositions[obj])
			delay(.5 - (obj.Position.Y.Scale / 2), function()
				t1:Play()
			end)
		end
	end
	script.Parent.Enabled = true
end)

for _,obj in pairs(script.Parent:GetChildren()) do
	if obj:IsA('GuiObject') then
		originalPositions[obj] = {
			Position = obj.Position,
			TextTransparency = nil,
		}
		if obj.ClassName:find('Text') then
			originalPositions[obj].TextTransparency = obj.TextTransparency
		end
	end
end