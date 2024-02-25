local CollectionService = game:GetService('CollectionService')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
local player = game.Players.LocalPlayer
local RowsClient = require(script.RowsClient)
local util = require(game.ReplicatedStorage.util)
local camera = workspace.CurrentCamera
local depthOfField = game.Lighting:WaitForChild('MinigameDOF')

local timer = script.Parent.Timer
local timerPercent = timer.Percentage

local active = nil

function getHumanoid(pl)
	pl = pl or player
	return pl.Character and pl.Character:FindFirstChild('Humanoid')
end

local close = {}

function disableCam()
	wait()
	
	util.Toggle(player.Character, true, true)
	depthOfField.Enabled = false
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	
	for player in pairs(close) do
		if not player.Character then continue end
		for _,part in pairs(player.Character:GetDescendants()) do
			if part:IsA('BasePart') then
				part.LocalTransparencyModifier = 0
			end
		end
	end
	
	--util.TogglePets(true)
	util.ToggleProjectiles(true)
	util.ToggleClones(true)
	util.ToggleEffects(true)
	util.ToggleExplosions(true)
	
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
end

function setup(model)
	local obj = RowsClient.new(model)
	obj.CommEvent.OnClientEvent:Connect(function(name, ...)
		RunService.Heartbeat:Wait()
		if name == 'player_added' then
			local added = ...
			
			local hum = getHumanoid()
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, (active ~= obj and added ~= player) or #obj.Players < 2)
			end
			
			if added == player then
				if active then
					warn('Overriding active RowsClient with another')
				end
				active = obj
			end
			
			if active == obj and #obj.Players > 1 then
				util.Toggle(player.Character, false, true)
				--util.TogglePets(false)
				util.ToggleProjectiles(false)
				util.ToggleClones(false)
				util.ToggleEffects(false)
				util.ToggleExplosions(false)
				
				depthOfField.Enabled = true
				depthOfField.FocusDistance = 10
				depthOfField.InFocusRadius = 0
				depthOfField.NearIntensity = 1
				depthOfField.FarIntensity = 1
				
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
				
				hum:UnequipTools()
			end
		elseif name == 'player_removed' then
			local removed = ...
			
			local hum = getHumanoid()
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, active ~= obj or removed == player or #obj.Players < 2)
			end
			
			if removed == player then
				if active == obj then
					active = nil
					disableCam()
				else
					warn('Recieved RowsClient deactivated event for an inactive RowsClient object')
				end
			elseif active == obj and #obj.Players < 2 then
				disableCam()
			end
		end
	end)
end

for _,v in pairs(CollectionService:GetTagged('RowsArcade')) do
	setup(v)
end
CollectionService:GetInstanceAddedSignal('RowsArcade'):Connect(setup)

RunService:BindToRenderStep('4R_ClientRender', Enum.RenderPriority.Last.Value + 100, function()
	if active and #active.Players > 1 then
		active:RenderPreview()
		camera.CameraType = Enum.CameraType.Scriptable -- roblox still hasnt fixed the camera mode bug/exploitfshfudsocmcr875ytr
		camera.CFrame = active.Board.CFrame * RowsClient.id_map.CameraOffset[active.MyId]
		camera.FieldOfView = 30

		timerPercent.Value = math.max(active.TurnTimeout - (os.time() + (os.clock() % 1) - 1), 1)
		
		for _,player in pairs(game.Players:GetPlayers()) do
			if not table.find(active.Players, player) then
				local root = player.Character and player.Character.PrimaryPart
				if not root then continue end
				local dist = (camera.CFrame.p - root.Position).Magnitude
				if not (dist > 11 and close[player]) then
					local trans = math.clamp(util.Map(dist, 8, 11, 1, 0), 0, 1)
					close[player] = dist > 11 or nil
					for _,part in pairs(player.Character:GetDescendants()) do
						if part:IsA('BasePart') then
							part.LocalTransparencyModifier = trans
						end
					end
				end
			end
		end
	end
	script.Parent.Waiting.Visible = active and #active.Players < 2
	timer.Visible = active and active.Turn == player and #active.Players >= 2
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not active then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.DPadDown or input.KeyCode == Enum.KeyCode.ButtonX then
		active:Drop()
	elseif input.KeyCode == Enum.KeyCode.DPadLeft then
		active.Selected = math.clamp(active.Selected - 1, 1, 7)
	elseif input.KeyCode == Enum.KeyCode.DPadRight then
		active.Selected = math.clamp(active.Selected + 1, 1, 7)
	end
end)

local exitPrompt = {
	Title = 'Confirm Exit',
	Body = "Are you sure you want to exit this minigame? This will count as a loss and you will recieve no reward.",
	Icon = 'rbxassetid://5487218580',
	Button0 = 'EXIT',
	Button1 = 'Cancel'
}

UserInputService.JumpRequest:Connect(function()
	if not active then return end
	local hum = getHumanoid()
	if not hum or hum:GetStateEnabled(Enum.HumanoidStateType.Jumping) then return end
	local confirmed = game.ReplicatedStorage.ClientPrompt:Invoke(exitPrompt)
	local seat = hum.SeatPart
	if confirmed and seat then
		local cf = seat.CFrame * CFrame.new(5, 0, 0)
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		hum:ChangeState(Enum.HumanoidStateType.Running)
		hum.Parent:SetPrimaryPartCFrame(cf)
	end
end)