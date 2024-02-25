local RunService = game:GetService('RunService')

if RunService:IsClient() then
	return function()
		
	end
else
	local Debris = game:GetService('Debris')
	local key = script.Parent
	
	return function(plr)
		if plr.ObjectiveId.Value == 5 then
			plr.ObjectiveId.Value = 6
			plr.Objective.Value = 'ESCAPE'
			
			key.Collect:Play()
			key.AmbientSparkles:Emit(20)
			for _,obj in pairs(key:GetDescendants()) do
				if obj:IsA('ParticleEmitter') then
					obj.Enabled = false
				end
			end
			key.Transparency = 1
			Debris:AddItem(key, 7)
		end
	end
end