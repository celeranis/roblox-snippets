local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local HttpService = game:GetService('HttpService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Debris = game:GetService('Debris')

local plr = game.Players.LocalPlayer

local temp = script:WaitForChild('TempBullet')

local bullets = {}

local bulletParts = {}

RunService.RenderStepped:Connect(function(step)
	for id, bulletPart in pairs(bulletParts) do
		local bullet = bullets[id]
		if not bullet then
			bulletPart:Destroy()
			bulletParts[id] = nil
			continue
		end
		bulletPart.CFrame += (bullet.Direction * step)
		bullet.Position = bulletPart.Position
		for _,touching in bulletPart:GetTouchingParts() do
			if touching:IsA('BasePart') and v.CanCollide then
				bulletPart:Destroy()
				bullets[id] = nil
				break
			end
		end
	end
end)

local function spawnBullet(startpos,direction,despawn,size,color)
		
	local id = HttpService:GenerateGUID(false)
	
	local bulletPart = temp:Clone()
	bulletPart.Name = id
	bulletPart.CFrame = CFrame.new(startpos, startpos + direction)
	bulletPart.Color = color or Color3.fromRGB(255, 151, 102)
	bulletPart.Size = size or Vector3.new(.2, .2, 6.7)
	bulletPart.PointLight.Color = bulletPart.Color
	bulletPart.PointLight.Range = 8 + (bulletPart.Size.Magnitude / 2)
	bulletPart.Touched:Connect(function()end) -- GetTouchedParts doesn't work without... this, lol
	
	task.delay(despawn or 3, function()
		bulletPart:Destroy()
		bulletParts[id] = nil
		bullets[id] = nil
	end)
	
	bullets[id] = {
		Position = startpos,
		Direction = direction,
	}
	bulletParts[id] = bulletPart
	
	bulletPart.Parent = workspace.Bullets
	
end

ReplicatedStorage:WaitForChild('ServerBullet').OnClientEvent:Connect(spawnBullet)
ReplicatedStorage:WaitForChild('LocalBullet').Event:Connect(spawnBullet)

local random = Random.new()

ReplicatedStorage.BulletHit.OnClientEvent:Connect(function(pos,from,color)
	
	if plr:DistanceFromCharacter(pos) < 256 then
	
		local attachment = Instance.new('Attachment')
		local particles = script.ParticleEmitter:Clone()
		particles.Parent = attachment
		
		attachment.Parent = workspace.Terrain
		attachment.WorldCFrame = CFrame.new(pos,from)
		
		particles.Color = ColorSequence.new(color)
		particles:Emit(10)
		
		Debris:AddItem(attachment, 2)
		
	end
	
end)