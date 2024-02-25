local EndingText = {}

EndingText.Anims = {
	Win = {
		{
			img = 'rbxassetid://5705841671', -- Y
		},
		{
			img = 'rbxassetid://5705841370', -- O
			gap = .065
		},
		{
			img = 'rbxassetid://5705841477', -- U
			gap = .065
		},
		{
			img = 'rbxassetid://5705841556', -- W
			gap = .11
		},
		{
			img = 'rbxassetid://5705841198', -- I
			gap = .065
		},
		{
			img = 'rbxassetid://5705841286', -- N
			gap = .05
		},
		{
			img = 'rbxassetid://5705841125', -- !
			gap = .05
		}
	},
	Lose = {
		{
			img = 'rbxassetid://5705840804', -- Y
		},
		{
			img = 'rbxassetid://5705840524', -- O
			gap = .06
		},
		{
			img = 'rbxassetid://5705840726', -- U
			gap = .065
		},
		{
			img = 'rbxassetid://5705840422', -- L
			gap = .1
		},
		{
			img = 'rbxassetid://5705840524', -- O
			gap = .06
		},
		{
			img = 'rbxassetid://5705840636', -- S
			gap = .065
		},
		{
			img = 'rbxassetid://5706012916', -- E
			gap = .06
		},
	},
	Tie = {
		{
			img = 'rbxassetid://5705841046' -- T
		},
		{
			img = 'rbxassetid://5705840972', -- I
			gap = .05
		},
		{
			img = 'rbxassetid://5705840884', -- E
			gap = .05
		}
	}
}

local frame = script.Parent.Parent.Parent.Ending
local size = UDim2.fromScale(.1, .1)
local zerosize = UDim2.new()
local anchor = Vector2.new(.5, .5)

local thread = require(game.ReplicatedStorage.Thread)

function totalGap(anim)
	local total = 0
	for _,v in pairs(anim) do
		total += v.gap or 0
	end
	return total
end

function EndingText:Preload()
	local images = {}
	for _,v in pairs(self.Anims) do
		for _,v in pairs(v) do
			table.insert(images, v.img)
		end
	end
	game.ContentProvider:PreloadAsync(images)
end

function EndingText:Play(anim)
	if typeof(anim) == 'string' then
		anim = self.Anims[anim]
	end
	assert(anim, 'Invalid anim')
	local pos = .5 + (totalGap(anim) / -2)
	for _,letter in pairs(anim) do
		pos += letter.gap or 0
		
		local label = Instance.new('ImageLabel')
		label.Image = letter.img
		label.Position = UDim2.fromScale(pos, .6)
		label.BackgroundTransparency = 1
		label.AnchorPoint = anchor
		label.Size = zerosize
		label.Parent = frame

		label:TweenSizeAndPosition(size, UDim2.fromScale(pos, .5), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .5, true)

		delay(2,function()
			label:TweenSize(zerosize, Enum.EasingDirection.In, Enum.EasingStyle.Quart, .5, true)
			thread:Wait(.5)
			label:Destroy()
		end)

		thread:Wait(.05)
	end
end

return EndingText