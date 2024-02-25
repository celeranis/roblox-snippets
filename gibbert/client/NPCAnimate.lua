local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')
local camera = workspace.CurrentCamera

local nostop = {
	[Enum.HumanoidStateType.Jumping] = true
}
local running = {
	[Enum.HumanoidStateType.Running] = true,
	[Enum.HumanoidStateType.RunningNoPhysics] = true
}

local function setup(script)
	local humanoid = script.Parent:WaitForChild('Humanoid')
	local root = script.Parent:WaitForChild('HumanoidRootPart')
	
	local anims = {
		Climb = humanoid:LoadAnimation(script:WaitForChild('Climb')),
		Fall = humanoid:LoadAnimation(script:WaitForChild('Fall')),
		Jump = humanoid:LoadAnimation(script:WaitForChild('Jump')),
		Run = humanoid:LoadAnimation(script:WaitForChild('Run')),
		Walk = humanoid:LoadAnimation(script:WaitForChild('Walk')),
		Idle = humanoid:LoadAnimation(script:WaitForChild('Idle')),
	}
	local steps = {
		[anims.Run] = root:WaitForChild('FootstepRunning'),
		[anims.Walk] = root:WaitForChild('FootstepWalking'),
	}
	local states = {
		[Enum.HumanoidStateType.Climbing] = anims.Climb,
		[Enum.HumanoidStateType.Freefall] = anims.Fall,
		[Enum.HumanoidStateType.Jumping] = anims.Jump,
	}
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	
	RunService.Heartbeat:Connect(function()
		local currentSpeed = Vector3.new(root.Velocity.X,0,root.Velocity.Z).Magnitude
		if currentSpeed > 16 and script.Parent.Running.Value then
			
			local weight = (currentSpeed-16)/8
			
			anims.Run:AdjustWeight(weight)
			anims.Run:AdjustSpeed((weight*.5)+1)
			
			anims.Walk:AdjustWeight(math.max(1-weight,0))
			anims.Walk:AdjustSpeed((weight*.5)+1)
			
			anims.Idle:AdjustWeight(0)
			
		else
			
			local weight = math.min(currentSpeed,1)
			local speed = currentSpeed/16
		
			anims.Walk:AdjustWeight(weight)
			anims.Walk:AdjustSpeed(speed)
		
			anims.Idle:AdjustWeight(math.max(1-weight,0))
			
			anims.Run:AdjustWeight(0)
			
		end
	end)
	local function play(anim)
		if not anim.IsPlaying then
			anim:Play(.25)
		end
	end
	
	local function update(old,new)
		if states[old] and not nostop[old] then
			states[old]:Stop(.25)
		elseif running[old] and not running[new] then
			anims.Run:Stop(.25)
			anims.Walk:Stop(.25)
			anims.Idle:Stop(.25)
		end
		if running[new] then
			play(anims.Run)
			play(anims.Walk)
			play(anims.Idle)
		elseif states[new] and not states[new].IsPlaying then
			states[new]:Play(.25)
		end
	end
	
	for anim, sound in pairs(steps) do
		anim:GetMarkerReachedSignal('Step'):Connect(function()
			if anim.WeightCurrent < .05 then return end
			local stepSound = sound:Clone()
			stepSound.Name = stepSound.Name..'Temp'
			stepSound.Parent = sound.Parent
			if stepSound:FindFirstChild('Muffle') and workspace:FindPartOnRayWithWhitelist(Ray.new(camera.CFrame.p, sound.Parent.Position - camera.CFrame.p),{ workspace.Labarynth }) then
				stepSound.Muffle.Enabled = true
			end
			stepSound.Volume = math.clamp(anim.WeightCurrent,0,sound.Volume)
			stepSound:Play()
			game.Debris:AddItem(stepSound, stepSound.TimeLength / stepSound.PlaybackSpeed)
		end)
	end
	
	humanoid.StateChanged:Connect(update)
	update(Enum.HumanoidStateType.None,humanoid:GetState())
	
	task.wait(1)
	
	play(anims.Run)
	play(anims.Idle)
	play(anims.Walk)
end

for _,v in pairs(CollectionService:GetTagged('NPCAnim')) do
	setup(v)
end

CollectionService:GetInstanceAddedSignal('NPCAnim'):Connect(setup)