local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local player = game.Players.LocalPlayer

local gui = script.Parent
local objectiveText = gui:WaitForChild('Objective')
local objectiveCorner = gui:WaitForChild('ObjectiveCorner')
local objectiveLabel = gui:WaitForChild('ObjectiveLabel')
local subtitles = gui:WaitForChild('Subtitles')
local objectiveScale = objectiveText:WaitForChild('UIScale')

local fade1s = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local fadehs = TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local quartOut = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local quartIn = TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
local textInvis = { TextTransparency = 1 }
local textTrans = { TextTransparency = .5 }
local textVis = { TextTransparency = 0 }

local cornerFadeOut = TweenService:Create(objectiveCorner, fade1s, textInvis)
local cornerFadeIn = TweenService:Create(objectiveCorner, fade1s, textTrans)

local cornerLabelFadeOut = TweenService:Create(objectiveLabel, fade1s, textInvis)
local cornerLabelFadeIn = TweenService:Create(objectiveLabel, fade1s, textTrans)

local subtitleFadeIn = TweenService:Create(subtitles, fadehs, textVis)
local subtitleFadeOut = TweenService:Create(subtitles, fade1s, textInvis)

local objectiveTextFadeIn = TweenService:Create(objectiveText, quartOut, textVis)
local objectiveTextFadeOut = TweenService:Create(objectiveText, quartIn, textInvis)
local objectiveTextScaleNormal = TweenService:Create(objectiveScale, quartOut, { Scale = 1 })
local objectiveTextScaleDown = TweenService:Create(objectiveScale, quartIn, { Scale = .5 })

local objectiveValue = player:WaitForChild('Objective')

local cursorEnabled = ReplicatedStorage:WaitForChild('CursorEnabled')

local start = tick()

local function updateObjective(new)
	cornerFadeOut:Play()
	cornerLabelFadeOut:Play()
	
	cursorEnabled.Value = false
	
	task.wait(1)
	
	objectiveText.TextTransparency = 1
	objectiveScale.Scale = 1.5
	objectiveText.Text = new
	
	objectiveTextFadeIn:Play()
	objectiveTextScaleNormal:Play()
	
	script.Boom:Play()
	
	task.wait(4)
	
	objectiveTextFadeOut:Play()
	objectiveTextScaleDown:Play()
	
	objectiveCorner.Text = new
	cornerFadeIn:Play()
	cornerLabelFadeIn:Play()
	
	task.wait(1)
	
	cursorEnabled.Value = true
end

local function showSubtitles(text)
	subtitles.Text = text
	subtitleFadeIn:Play()
	task.wait(4)
	subtitleFadeOut:Play()
end

local stopwatch = script.Parent:WaitForChild('Stopwatch')
stopwatch.Visible = player:WaitForChild('SavedData').Settings.stopwatch.Value
local hform = '%s:%s:%s'
local mform = '%s:%s'
RunService.RenderStepped:Connect(function()
	if not stopwatch.Visible then return end
	local elapsed = tick()-start
	local h = math.floor(elapsed/3600)
	elapsed = elapsed - (h*3600)
	local m = math.floor(elapsed/60)
	elapsed = elapsed - (m*60)
	local s = math.floor(elapsed)
	if h>0 then
		stopwatch.Text = hform:format(
			h < 10 and '0'..h or h,
			m < 10 and '0'..m or m,
			s < 10 and '0'..s or s
		)
	else
		stopwatch.Text = mform:format(
			m < 10 and '0'..m or m,
			s < 10 and '0'..s or s
		)
	end
	local ms = math.floor((elapsed-s)*100)
	stopwatch.Decimal.Text = (ms<10 and '.0' or '.')..ms
end)

task.wait(8)

updateObjective(objectiveValue.Value)
objectiveValue.Changed:Connect(updateObjective)
ReplicatedStorage.Subtitles.OnClientEvent:Connect(showSubtitles)