local module = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

--[[
	Bullet properties:
	
	Position = The starting position of the bullet
	Direction = The direction the bullet is travelling in
	Damage = How much damage the bullet will deal
	HeadshotMultiplier = Multiply the damage by this if the hit part is a head
	Creator = The player that fired the bullet
	Ignore = The ignore list for rays
	Distance = The maximum distance the bullet can travel
	Size = Purely visual
--]]

function module:CreateBullet(b)
	local ray = Ray.new(b.Position,b.Direction.Unit * b.Distance)
	local part, pos = workspace:FindPartOnRayWithIgnoreList(ray,b.Ignore)
	
	ReplicatedStorage.LocalBullet:Fire(b.Position, pos)
	ReplicatedStorage.ServerBullet:FireServer(b)
end

return module