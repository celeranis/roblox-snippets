local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local mode = ReplicatedStorage:WaitForChild('Mode')

if RunService:IsClient() then
	return function()
		
	end
else
	return function(plr)
		if plr.ObjectiveId.Value == 6 then
			plr.ObjectiveId.Value = 7
			script.Parent.Open:Play()
			ReplicatedStorage.Escape:FireClient(plr
			ServerStorage.Finish:Fire(1, plr)
			plr.SavedData.PrevDeath.Value = false
		else
			ReplicatedStorage.Subtitles:FireClient(plr, "It's locked.")
			script.Parent.LockedSound:Play()
			if plr.ObjectiveId.Value == 1 then
				plr.ObjectiveId.Value = 2
				
				for _,part in pairs(workspace.Labarynth:GetChildren()) do
					if part.Name == 'Block' then
						part:Destroy()
					end
				end
				
				task.spawn(function()
					for i = 1, mode.Value == 'double' and 2 or 1 do
						local gibbert = ServerStorage.GIBBERT:Clone()
						gibbert.Name = 'GIBBERT'..i
						gibbert.Parent = workspace
						RunService.Heartbeat:Wait()
						gibbert.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
						task.wait(5)
					end
				end)
				
				task.wait(3)
				plr.Objective.Value = 'FIND A KEY'
			end
		end
	end
end