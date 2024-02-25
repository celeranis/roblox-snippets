local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

ReplicatedStorage.LocalBullet.Event:Connect(function(bullet)
	local ray = Ray.new(bullet.Position, bullet.Direction.Unit * bullet.Distance)
	
	local part = workspace:FindPartOnRayWithWhitelist(ray, bullet.List)
	if not part then return end
	
	local model = part:FindFirstAncestorOfClass('Model')
	if not model then return end
	
	local humanoid = model:FindFirstChildOfClass('Humanoid')
	if not humanoid then return end
		
	if Players:GetPlayerFromCharacter(model) then return end
	
	local dealt = part.Name ~= 'Head' and bullet.Damage or bullet.Damage * bullet.HeadshotMultiplier
	humanoid:TakeDamage(dealt)
	
	if bullet.Creator then
		ReplicatedStorage.Hitmarker:FireClient(bullet.Creator, part, dealt, part.Name == 'Head')
	end
end)