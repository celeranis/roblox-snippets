local camera = workspace.CurrentCamera
local ContextActionService = game:GetService('ContextActionService')
local RunService = game:GetService('RunService')
local humanoid = script.Parent:WaitForChild('Humanoid')
local head = script.Parent:WaitForChild('Head')

local left_keys = {
	Enum.KeyCode.Q,
	Enum.KeyCode.ButtonL1
}
local right_keys = {
	Enum.KeyCode.E,
	Enum.KeyCode.ButtonR1,
}

local cframes = {
	PeekRight = CFrame.fromOrientation(0, 0, math.rad(-10)) + Vector3.new(2, 0, 0),
	PeekLeft = CFrame.fromOrientation(0, 0, math.rad(10)) + Vector3.new(-2, 0, 0)
}

local empty = CFrame.new()
local current = empty
local target = empty
local caction = nil

local begin = Enum.UserInputState.Begin
local ends = Enum.UserInputState.End

RunService:BindToRenderStep('CameraPeek', Enum.RenderPriority.Camera.Value + 2, function(delta)
	current = current:Lerp(target,delta * 5)
	camera.CFrame *= current
end)

function processInput(action, state, input)
	local cf = cframes[action]
	if not cf then warn('no cf for action', action) return end
	if state == begin then
		target = cf
		if not caction then
			humanoid.WalkSpeed /= 3
		end
		caction = action
	elseif state == ends and caction == action then
		caction = nil
		target = empty
		humanoid.WalkSpeed *= 3
	end
end

ContextActionService:BindAction('PeekLeft', processInput, true, unpack(left_keys))
ContextActionService:BindAction('PeekRight', processInput, true, unpack(right_keys))