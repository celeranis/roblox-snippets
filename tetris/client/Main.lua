local CollectionService = game:GetService('CollectionService')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local ContextActionService = game:GetService('ContextActionService')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local GuiService = game:GetService('GuiService')
local me = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ScreenGui = script.Parent
local depthOfField = game.Lighting:WaitForChild('MinigameDOF')

local Tetris = require(script.TetrisClient)
local controls = require(script.TetrisClient.Controls)
local util = require(game.ReplicatedStorage.util)
local anims = require(script.TetrisClient.InteractAnims)

local playing = nil

local moving = Vector2.new()

local guis = {}

local moveKeys = {
	MoveDown = Vector2.new(0, -1),
	MoveLeft = Vector2.new(-1, 0),
	MoveRight = Vector2.new(1, 0)
}

function rotate(action, state)
	if UserInputService:GetFocusedTextBox() or not playing or playing.State ~= 'Game' or not playing.CurrentPiece or (state and state ~= Enum.UserInputState.Begin) then 
		return Enum.ContextActionResult.Pass 
	end
	playing:Rotate(action == 'RotateClock' and 1 or -1)
	
	return Enum.ContextActionResult.Sink
end

function quickDrop(action, state, input)
	if UserInputService:GetFocusedTextBox() or not playing or (state and state ~= Enum.UserInputState.Begin) then return Enum.ContextActionResult.Pass end
	
	if playing.State == 'Game' then
		if not playing.CurrentPiece then --[[warn('none piece current')]] return end
		playing:QuickDrop()
	else
		playing:Navigate(-1)
	end
	
	return Enum.ContextActionResult.Sink
end

function checkKeys(keys)
	debug.profilebegin('CheckKeys')
	for _,v in pairs(keys) do
		if util.IsKeyDown(v) then
			return true
		end
	end
	debug.profileend()
	return false
end

function pause(set,state)
	if not playing or (state and state ~= Enum.UserInputState.Begin) then return Enum.ContextActionResult.Pass end
	playing:Pause()
	return Enum.ContextActionResult.Sink
end

function forcePause()
	playing:Pause(true)
end

local thumb_moving = {
	MoveDown = false,
	MoveLeft = false,
	MoveRight = false
}

function move()
	if UserInputService:GetFocusedTextBox() or not playing or not playing.CurrentPiece or playing.State ~= 'Game' then return end
	local do_move = false
	local move_by = Vector2.new()
	
	local anms = anims()
	
	for name, dir in pairs(moveKeys) do
		local playing = thumb_moving[name] or checkKeys(controls[name])
		--setPlaying(anms[name], playing)
		if playing then
			move_by += dir
			do_move = true
			--warn(name)
		end
	end
	
	--setPlaying(anms.MoveUp, checkKeys(controls.QuickDrop))
	
	if do_move then
		playing:Move(move_by, false)
	end
	
	return do_move
end

function hold()
	playing:Hold()
end

local last_grav = 0
local next_move = 0

RunService.Heartbeat:Connect(function()
	if not playing then return end
	
	if playing.State == 'Game' then
	
		if playing.CurrentPiece then
			
			debug.profilebegin('UpdateCurrentPiece')
			
			local now = os.clock()
			
			if now >= last_grav + (.8 ^ playing.Level) then
				last_grav = now
				--print('grav')
				playing:Move(Vector2.new(0,-1), true)
			end
			
			if now >= next_move then
				local did_move = move()
				if did_move then
					next_move = now + .05
				end
			end
			
			debug.profileend()
			
		end
		
	end
end)

function moveBegan(action, state, input)
	if not playing or UserInputService:GetFocusedTextBox() or state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	
	if playing.State == 'Game' then
		move()
		next_move = os.clock() + .1
	else
		--print(input.KeyCode.Name)
		if not input or not table.find(controls.MoveDown,input.KeyCode) then return Enum.ContextActionResult.Pass end
		--print('yes')
		playing:Navigate(1)
	end
	
	return Enum.ContextActionResult.Pass
end

function selectButton(_,state)
	if not playing or state ~= Enum.UserInputState.Begin then return end
	playing:Select()
end

local dpad = {
	[Enum.KeyCode.DPadDown] = moveBegan,
	[Enum.KeyCode.DPadLeft] = moveBegan,
	[Enum.KeyCode.DPadRight] = moveBegan,
	[Enum.KeyCode.DPadUp] = quickDrop
}

local all_move = {}
for _,v in pairs(controls.MoveDown) do
	if dpad[v] then continue end
	table.insert(all_move,v)
end
for _,v in pairs(controls.MoveLeft) do
	if dpad[v] then continue end
	table.insert(all_move,v)
end
for _,v in pairs(controls.MoveRight) do
	if dpad[v] then continue end
	table.insert(all_move,v)
end

local actions = {
	Pause = {pause, false, Enum.ContextActionPriority.Default.Value + 2, unpack(controls.Pause)},
	RotateClock = {rotate, false, Enum.ContextActionPriority.Default.Value + 2, unpack(controls.RotateClock)},
	RotateCounter = {rotate, false , Enum.ContextActionPriority.Default.Value + 1, unpack(controls.RotateCounter)},
	QuickDrop = {quickDrop, false , Enum.ContextActionPriority.Default.Value + 1, unpack(controls.QuickDrop)},
	MoveBegan = {moveBegan, false, Enum.ContextActionPriority.Default.Value + 3, unpack(all_move)},
	HoldPiece = {hold, false, Enum.ContextActionPriority.Default.Value + 1, unpack(controls.Hold)},
	Select = {selectButton, false, Enum.ContextActionPriority.Default.Value, unpack(controls.Select)},
}
local conns = {}

function setup(screen)
	local gui = script.TempGui:Clone()
	gui.Adornee = screen
	gui.Name = 'ActiveGui'
	gui.Enabled = true
	gui.Parent = script.Parent
	
	local tetris = Tetris.new(screen, gui)
	
	screen.CurrentPlayer.Changed:Connect(function(plr)
		if plr == me then
			playing = tetris
			
			Camera.CameraType = Enum.CameraType.Scriptable
			local enter_tween = TweenService:Create(Camera,TweenInfo.new(2,Enum.EasingStyle.Quart),{CFrame = screen.CFrame * CFrame.new(0,0,-5) * CFrame.fromOrientation(0,math.pi,0), FieldOfView = 50})
			enter_tween:Play()
			
			plr.Character.PrimaryPart.Anchored = true
			plr.Character.Humanoid.JumpPower = 0
			plr.Character.Humanoid.WalkSpeed = 0
			
			game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
			UserInputService.ModalEnabled = true
			
			util.ToggleAll(false)
			util.Toggle(plr.Character,false,true)
			
			for name,params in pairs(actions) do
				ContextActionService:BindActionAtPriority(name,unpack(params))
			end
			
			for _,v in pairs(gui:GetDescendants()) do
				if v:IsA('TextButton') then
					table.insert(conns, v.Activated:Connect(function()
						tetris:Select(v.Name)
					end))
				end
			end
			table.insert(conns, UserInputService.TextBoxFocused:Connect(forcePause))
			table.insert(conns, GuiService.MenuOpened:Connect(forcePause))
			table.insert(conns, UserInputService.WindowFocusReleased:Connect(forcePause))
			table.insert(conns, UserInputService.GamepadDisconnected:Connect(forcePause))
			table.insert(conns, plr.Character.ChildAdded:Connect(function(child)
				if child:IsA('Tool') then
					RunService.Heartbeat:Wait()
					child.Parent = plr.Backpack
				end
			end))
			table.insert(conns, RunService.RenderStepped:Connect(function()
				if enter_tween.PlaybackState == Enum.PlaybackState.Playing then return end
				Camera.CameraType = Enum.CameraType.Scriptable
				Camera.CFrame = screen.CFrame * CFrame.new(0,0,-5) * CFrame.fromOrientation(0,math.pi,0)
				Camera.FieldOfView = 50
				
				depthOfField.Enabled = true
				depthOfField.FocusDistance = 5
			end))
			table.insert(conns, UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Thumbstick1 then
					local pos = input.Position
					local b4 = {}
					for i,v in pairs(thumb_moving) do
						b4[i] = v
					end
					thumb_moving.MoveDown = pos.Y < -.75
					thumb_moving.MoveLeft = pos.X < -.75
					thumb_moving.MoveRight = pos.X > .75
					for i,v in pairs(thumb_moving) do
						if v and v ~= b4[i] then
							move()
							next_move = os.clock() + .1
						end
					end
				end
			end))
			local touchStart = nil
			local lastMove = nil
			table.insert(conns, UserInputService.InputBegan:Connect(function(input,gp)
				if dpad[input.KeyCode] then
					dpad[input.KeyCode]('GamepadMove', input.UserInputState, input)
				elseif input.UserInputType == Enum.UserInputType.Touch then
					touchStart = input.Position
					lastMove = touchStart
				end
			end))
			table.insert(conns, UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch and touchStart then
					local pos = input.Position
					local diff = pos - lastMove
					if diff.X >= 15 then
						playing:Move(Vector2.new(1,0))
						lastMove = pos
					elseif diff.X <= -15 then
						playing:Move(Vector2.new(-1,0))
						lastMove = pos
					end
					if diff.Y >= 10 then
						playing:Move(Vector2.new(0,-1))
						lastMove = pos
					end
				end
			end))
			table.insert(conns, UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then
					touchStart = nil
					lastMove = nil
				end
			end))
			for _,v in pairs(ScreenGui.MobileControls:GetDescendants()) do
				if v:IsA('ImageButton') then
					table.insert(conns, v.MouseButton1Down:Connect(function()
						for _,name in pairs(v.Name:split('&')) do
							local action = actions[name]
							if action then
								action[1]('MobileAction', Enum.UserInputState.Begin)
							end
							if thumb_moving[name] ~= nil then
								thumb_moving[name] = true
							end
						end
					end))
					for _,name in pairs(v.Name:split('&')) do
						if thumb_moving[name] ~= nil then
							table.insert(conns, v.MouseButton1Up:Connect(function()
								thumb_moving[name] = false
							end))
						end
					end
				end
			end
			for _,v in pairs(plr.Character.Humanoid:GetPlayingAnimationTracks()) do
				v:Stop()
			end
			anims().Idle:Play()
			gui.AlwaysOnTop = true
		elseif tetris == playing then
			playing:UpdateControls()
			playing = nil
			
			for _,connection in pairs(conns) do
				connection:Disconnect()
			end
			for name in pairs(actions) do
				ContextActionService:UnbindAction(name)
			end
			
			TweenService:Create(Camera,TweenInfo.new(2,Enum.EasingStyle.Quart),{CFrame = CFrame.lookAt((me.Character.Head.CFrame * CFrame.new(.15, 4 ,12.45)).p,me.Character.Head.Position), FieldOfView = 70}):Play()
			util.ToggleAll(true)
			util.Toggle(me.Character,true,true)
			
			RunService.RenderStepped:Wait()
			
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			depthOfField.Enabled = false
			
			game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,true)
			UserInputService.ModalEnabled = false
			anims().Idle:Stop()
			gui.AlwaysOnTop = false
			
			wait(2)
			
			if screen.CurrentPlayer.Value ~= me then
				me.Character.PrimaryPart.Anchored = false
				me.Character.Humanoid.JumpPower = 50
				me.Character.Humanoid.WalkSpeed = 16
			end
		end
	end)
end

for _,v in pairs(CollectionService:GetTagged('TetroScreen')) do
	setup(v)
end
CollectionService:GetInstanceAddedSignal('TetroScreen'):Connect(setup)
CollectionService:GetInstanceRemovedSignal('TetroScreen'):Connect(function(screen)
	if guis[screen] then
		guis[screen]:Destroy()
	end
end)