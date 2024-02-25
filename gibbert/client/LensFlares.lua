local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')

local cam = workspace.CurrentCamera
local player = Players.LocalPlayer

script.Parent.Parent = player:WaitForChild('PlayerGui')

local flares = {}

local function getBaseCharacter()
	if not player.Character then return {} end
	local child = {}
	for _,limb in pairs(player.Character:GetChildren()) do
		if limb:IsA('BasePart') then
			child[#child + 1] = limb
		end
	end
	child[#child + 1] = workspace.ViewBlocks
	return child
end

local function isObstructed(pos)
	local part = workspace:FindPartOnRayWithIgnoreList(Ray.new(cam.CFrame.p, pos - cam.CFrame.p), getBaseCharacter())
	return part ~= nil
end

local normals = {
	Vector3.new(0, 0, 0),
	Vector3.new(0, 1, 0),
	Vector3.new(0, -1, 0),
	Vector3.new(1, 0, 0),
	Vector3.new(-1, 0, 0)
}

RunService.RenderStepped:Connect(function()
	for adornee,gui in pairs(flares) do
		local bad = 0
		for _,offset in ipairs(normals) do
			if isObstructed(adornee.WorldPosition + cam.CFrame:VectorToWorldSpace(offset)) then
				bad = bad + 1
			end
		end
		local trans = bad / 5
		gui.Flare.ImageTransparency = trans
		gui.Outer.ImageTransparency = .95 + (trans * .05)
	end
end)

local function setupFlare(adornee)
	local gui = script.Temp:Clone()
	gui.Enabled = true
	gui.Adornee = adornee
	gui.Parent = script.Active
	flares[adornee] = gui
end

CollectionService:GetInstanceAddedSignal('LensFlare'):Connect(function(new)
	setupFlare(new)
end)
CollectionService:GetInstanceRemovedSignal('LensFlare'):Connect(function(remove)
	flares[remove]:Destroy()
	flares[remove] = nil
end)
for _,new in pairs(CollectionService:GetTagged('LensFlare')) do
	setupFlare(new)
end