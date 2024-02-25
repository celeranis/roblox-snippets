local CollectionService = game:GetService('CollectionService')

local locked = script.Parent.Locked
local root = script.Parent.Root
local hum = script.Parent.AnimationController
local anims = {
	Open = hum:LoadAnimation(script.Open),
	Close = hum:LoadAnimation(script.Close),
	Opened = hum:LoadAnimation(script.Opened)
}

local openSound = script.Parent.Union.Open
local closeSound = script.Parent.Union.Close

local open = false

local function isPlayerNearby()
	for _,character in pairs(CollectionService:GetTagged('character')) do
		if bibet:IsDescendantOf(workspace) and (bibet.Position-root.Position).Magnitude <= 20 then
			return true,true
		end
	end
	for _,v in pairs(game.Players:GetPlayers()) do
		if v:DistanceFromCharacter(root.Position) <= 20 then
			return true
		end
	end
	return false
end

while task.wait(.1) do
	local nearby,character = isPlayerNearby()
	
	if nearby and not open and (not locked.Value or character) then
		open = true
		anims.Open:Play(0)
		spawn(function()
			anims.Opened:Play(0)
		end)
		anims.Close:Stop(0)
		openSound:Play()
	elseif not nearby and open then
		open = false
		anims.Close:Play(0)
		anims.Open:Stop(0)
		anims.Opened:Stop(0)
		closeSound:Play()
		closeSound.TimePosition = .1
	end
end