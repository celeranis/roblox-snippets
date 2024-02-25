-- Fades beams out based on camera orientation

local FARTHEST = 25
local NEAREST = 5

local RunService = game:GetService('RunService')
local CollectionService = game:GetService('CollectionService')
local camera = workspace.CurrentCamera
local player = game.Players.LocalPlayer

local beams = {}

local function sequenceFade(sequence,alpha)
	-- roblox's support for the sequence datatypes is Poor
	
	alpha = math.clamp(alpha, 0, 1)
	
	local keyframes = {}
	for i,keyframe in pairs(sequence.Keypoints) do
		keyframes[i] = NumberSequenceKeypoint.new(keyframe.Time, 1 - ((1 - keyframe.Value) * alpha))
	end
	
	return NumberSequence.new(keyframes)
end

RunService.RenderStepped:Connect(function()
	for beam,trans in pairs(beams) do
		
		if not beam.Attachment0 then continue end
		
		local beamCFrame = beam.Attachment0.WorldCFrame
		local cameraCFrame = beamCFrame:VectorToWorldSpace(camera.CFrame.p - beamCFrame.p)
		
		local dist = math.abs(cameraCFrame.X)
		local alpha = (dist - NEAREST) / FARTHEST
		
		beam.Transparency = sequenceFade(trans, alpha)
		
	end
end)

CollectionService:GetInstanceAddedSignal('BetterBeam'):Connect(function(beam)
	beams[beam] = beam.Transparency
end)

CollectionService:GetInstanceRemovedSignal('BetterBeam'):Connect(function(beam)
	beams[beam] = nil
end)

for _,beam in CollectionService:GetTagged('BetterBeam') do
	beams[beam] = beam.Transparency
end