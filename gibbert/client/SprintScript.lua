-- Configuration

local FoVEffects = true -- If enabled, the camera's FoV will increase slightly while running. Default is true.
local SprintFov = 85 -- The Camera's Field of View while sprinting. This only changes if FovEffects is true. Default is 85.
local WalkFov = 70 -- The Camera's Field of View while walking. This only changes if FovEffects is true. Default is 70.
local FoVEffectTweenTime = 0.5 -- The time in seconds it takes for the camera FieldOfView to switch between the SprintFov and WalkFov. This only changes if FovEffects is true. Default is 0.5.
local FoVEffectTweenEasingStyle = Enum.EasingStyle.Quart -- The type of transition used for the FoV tweening. Default is Quad.
local FoVEffectTweenEasingDirection = Enum.EasingDirection.InOut -- The type of transition used for the FoV tweening. Default is InOut.
local DisablePortraitFoV = false -- Disables FoV if your device orientation is set to Portrait. I don't know why you'd use this but someone asked me to add it so ok

local SpeedChangeMode = "Multiply" -- Options: "Set", "Add", and "Multiply". Default is Multiply.

--[[ 
	Speed Change mode extra info: 
	
	"Multiply" is the recommended mode. It respects both high and low walkspeeds.
	"Add" respects mainly low walkspeeds. When interacting with a high walkspeed, it will barely make a difference.
	"Set" is not recommended, because it will change your walkspeed to the same thing no matter what your base walkspeed is. So if you have a lot of walkspeed and press shift, it just slows you down.
--]]

local WalkSpeed = 16 -- Default is 16.

local SpeedChangeMultiplier = 1.5 -- Only used for "Multiply" mode. Default is 2.

local SpeedChangeAmount = 16 -- Only used for "Add" mode. Default is 16.

local RunSpeed = 32 -- Only used for "Set" mode. Default is 32.

local IgnoreIfAt0Walkspeed = true -- If the player has 0 walkspeed, the script will not change their walkspeed. Default is true.

local SprintKeys = {Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3} -- The button PC users have to press to sprint. Default is LeftShift (for PC) and ButtonL3 (for Console).

local OverrideShiftLockSwitch = true -- If a SprintKey is LeftShift or RightShift, ShiftLockSwitch will be disabled for that button. You can always press the opposite shift key to use shift lock switch.


-- Code
local ContextActionService = game:GetService('ContextActionService')
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService('TweenService')
local humanoid = script.Parent:WaitForChild("Humanoid")
local sprinting = Instance.new('BoolValue', humanoid)
local addFov = Instance.new('NumberValue', workspace.CurrentCamera)
addFov.Name = 'AddFoV'
sprinting.Name = 'IsSprinting'
workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
	addFov.Parent = workspace.CurrentCamera
end)

local SprintStartTween = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(FoVEffectTweenTime, FoVEffectTweenEasingStyle, FoVEffectTweenEasingDirection),{ FieldOfView = SprintFov })
local SprintEndTween = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(FoVEffectTweenTime, FoVEffectTweenEasingStyle, FoVEffectTweenEasingDirection),{ FieldOfView = WalkFov })

local function update()
	if sprinting.Value then
		if not DisablePortraitFoV or game.Players.LocalPlayer.PlayerGui.ScreenOrientation ~= Enum.ScreenOrientation.Portrait then
			SprintStartTween:Play()
		end
		humanoid.WalkSpeed = (SpeedChangeMode:lower() == 'multiply' and humanoid.WalkSpeed * SpeedChangeMultiplier) or (SpeedChangeMode:lower() == 'add' and humanoid.WalkSpeed + SpeedChangeAmount) or (SpeedChangeMode:lower() == 'set' and RunSpeed)
		ContextActionService:SetTitle('Sprint','Walk')
	else
		if not DisablePortraitFoV or game.Players.LocalPlayer.PlayerGui.ScreenOrientation ~= Enum.ScreenOrientation.Portrait then
			SprintEndTween:Play()
		end
		humanoid.WalkSpeed = (SpeedChangeMode:lower() == 'multiply' and humanoid.WalkSpeed / SpeedChangeMultiplier) or (SpeedChangeMode:lower() == 'add' and humanoid.WalkSpeed - SpeedChangeAmount) or (SpeedChangeMode:lower() == 'set' and WalkSpeed)
		ContextActionService:SetTitle('Sprint','Sprint')
	end
end

local function actionhandler(_, toggle)
	if not sprinting then warn('Attempt to toggle sprint failed because the Sprinting BoolValue was destroyed') return end
	sprinting.Value = (toggle == Enum.UserInputState.Begin and true) or (toggle ~= Enum.UserInputState.End and sprinting.Value) or false
end

ContextActionService:BindAction('Sprint',actionhandler,true,unpack(SprintKeys))
ContextActionService:SetPosition('Sprint',UDim2.new(0.25,0,.5,0))
ContextActionService:SetTitle('Sprint','Sprint')
ContextActionService:SetDescription('Sprint','Toggles sprinting')
sprinting.Changed:Connect(update)

-- Created by realhigbead, 2019.