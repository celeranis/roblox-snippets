type AnimSet = {[string]: AnimationTrack}

local player: Player = game.Players.LocalPlayer
local cachedHumanoid: Humanoid? = nil
local cache: AnimSet = {}

--[[
	This module is responsible for loading and playing animations of
	the player's character interacting with the physical arcade machine.
]]

return function(): AnimSet
	local character: Model = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild('Humanoid') :: Humanoid
	
	if cachedHumanoid == humanoid then
		return cache
	end
	
	local anims: AnimSet = {}
	for _,v: Animation in pairs(script:GetChildren()) do
		anims[v.Name] = humanoid:WaitForChild('Animator'):LoadAnimation(v)
	end
	
	cache = anims
	cachedHumanoid = humanoid
	
	return anims
end