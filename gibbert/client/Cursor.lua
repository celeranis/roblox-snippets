local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')
local TweenService = game:GetService('TweenService')
local ContextActionService = game:GetService('ContextActionService')
local camera = workspace.CurrentCamera
local player = game.Players.LocalPlayer

local il = script.Parent:WaitForChild('ImageLabel')
local tl = script.Parent:WaitForChild('TextLabel')

local lastRay = tick()

local en = game.ReplicatedStorage:WaitForChild('CursorEnabled')

local part

local function onInteraction(name,state,input)
	if state ~= Enum.UserInputState.Begin or not part then return Enum.ContextActionResult.Pass end
	if input.UserInputType ~= Enum.UserInputType.Touch then
		local tpa = player:GetMouse().Target
		if not tpa:FindFirstChild('ActionEvent') then return Enum.ContextActionResult.Pass end
		require(tpa.ActionEvent)()
		game.ReplicatedStorage.Interact:FireServer(tpa)
		return Enum.ContextActionResult.Pass
	else
		if not part:FindFirstChild('ActionEvent') then return Enum.ContextActionResult.Pass end
		require(part.ActionEvent)()
		game.ReplicatedStorage.Interact:FireServer(part)
		return Enum.ContextActionResult.Sink
	end
end
local bound = false

local function updateCursor()
	if not en.Value then return false end
	local ray = Ray.new(camera.CFrame.p,camera.CFrame.LookVector*16)
	part = workspace:FindPartOnRay(ray,player.Character)
	
	local an = part and part:FindFirstChild('ActionName') and part.ActionName.Value
	part = an and part
	il.Image = an and 'rbxasset://textures/Cursors/Gamepad/Pointer.png' or 'rbxasset://textures/Cursors/Gamepad/PointerOver.png'
	tl.Text = an or ''
	
	return an
end

RunService.RenderStepped:Connect(function()
	if tick()-lastRay < .1 then return end
	lastRay = tick()
	local shouldBound = updateCursor()
	if shouldBound and not bound then
		ContextActionService:BindActionAtPriority('Interact',onInteraction,false,Enum.ContextActionPriority.High.Value,Enum.UserInputType.MouseButton1,Enum.UserInputType.Touch,Enum.KeyCode.ButtonR1)
		bound = true
	elseif not shouldBound and bound then
		ContextActionService:UnbindAction('Interact')
		bound = false
	end
end)

local tinfo = TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)

local ilAppear = TweenService:Create(il,tinfo,{ImageTransparency = 0})
local ilDisappear = TweenService:Create(il,tinfo,{ImageTransparency = 1})

local tlAppear = TweenService:Create(tl,tinfo,{TextTransparency = 0})
local tlDisappear = TweenService:Create(tl,tinfo,{TextTransparency = 1})

local function update(new)
	if new then
		ilAppear:Play()
		tlAppear:Play()
	else
		ilDisappear:Play()
		tlDisappear:Play()
	end
end
en.Changed:Connect(update)
update(en.Value)