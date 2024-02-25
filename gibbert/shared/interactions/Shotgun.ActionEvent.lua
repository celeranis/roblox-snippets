local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

if RunService:IsClient() then
	return function()
		
	end
else
	local ServerStorage = game:GetService('ServerStorage')
	
	return function(plr)
		if plr.ObjectiveId.Value == 4 then
			ReplicatedStorage.Subtitles:FireClient(plr,'This ought to do.')
			plr.ObjectiveId.Value = 5
			pcall(function()
				local tool = plr.Character:FindFirstChildOfClass('Tool')
				if tool then
					tool.Parent = plr.Backpack
				end
			end)
			ServerStorage.Shotgun:Clone().Parent = plr.Character
			script.Parent.Transparency = 1
			pcall(function()
				script.Parent.ActionName:Destroy()
			end)
			task.wait(3)
			plr.Objective.Value = 'DEFEAT HIM'
			ReplicatedStorage.BeginFinale:FireClient(plr)
		end
	end
end