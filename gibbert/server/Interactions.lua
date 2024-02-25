local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

ReplicatedStorage.Interact.OnServerEvent:Connect(function(plr,obj)
	if obj and obj:IsA('BasePart') and obj:FindFirstChild('ActionEvent') and plr:DistanceFromCharacter(obj.Position) <= 16+math.max(obj.Size.X,obj.Size.Y,obj.Size.Z) then
		require(obj.ActionEvent)(plr)
	end
end)

local generated = false
local correct = {}

ReplicatedStorage.VerifyCode.OnServerInvoke = function(plr, code)
	if not generated or plr.ObjectiveId.Value ~= 3 then return false end
	
	for i = 1,4 do
		if correct[i] ~= code[i] then
			return false
		end
	end
	
	workspace.WeaponDoor.Locked.Value = false
	plr.ObjectiveId.Value = 4
	plr.Objective.Value = 'FIND THE WEAPON'
	
	return true
end

ServerStorage.GenerateCode.Event:Connect(function()
	generated = true
	correct = {math.random(0,9), math.random(0,9), math.random(0,9), math.random(0,9)}
	ServerStorage.Code.Value = table.concat(correct)
end)