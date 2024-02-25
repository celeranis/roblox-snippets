local DataStores = game:GetService('DataStoreService')
local RewardDS = DataStores:GetDataStore('SavedReward')
local CollectionService = game:GetService('CollectionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeleportService = game:GetService('TeleportService')

local lose_time_mult = .25
local win_time_mult = -.5

local lose_base = 32
local win_base = 4092

local height_mult = 3
local maxim_height = 100

local win_min = 3148
local max = 4096

local mode_multipliers = {
	Normal = .5,
	Frozen = .75,
	Hard = 1
}

local wins = {}

ReplicatedStorage.fin_server.Event:Connect(function(plr: Player, win: boolean, max_height: number, elapsed: number)
	if CollectionService:HasTag(plr,'gg') then return end
	CollectionService:AddTag(plr,'gg')
	
	local mode = (ReplicatedStorage.Hard.Value and 'Hard') or (ReplicatedStorage.Frozen.Value and 'Frozen') or 'Normal'
	
	local base = win and win_base or lose_base
	local height = win and 0 or math.clamp(max_height,0,maxim_height) * height_mult
	local time = elapsed * (win and win_time_mult or lose_time_mult)
	
	local reward = math.floor(math.clamp(base + height + time, win and win_min or 0, max) * (mode_multipliers[mode] or .5))
	
	--print(reward,base,height,math.floor(time),max_height)
	
	RewardDS:IncrementAsync(plr.UserId,reward)
	
	ReplicatedStorage.fin:FireClient(plr,{
		win = win,
		
		Elapsed = os.date('%M:%S',elapsed),
		Lines = win and 90 or max_height,
		Reward = reward
	})
	
	if win then
		if not wins[plr] then
			wins[plr] = {}
		end
		wins[plr][mode] = (wins[plr][mode] or 0) + 1
	end
end)

ReplicatedStorage.BackToHangout.OnServerEvent:Connect(function(plr)
	local joinData = plr:GetJoinData()
	TeleportService:Teleport(joinData.SourceGameId == game.GameId and joinData.SourcePlaceId or 4560236409, plr, {from = 'tetsurv', wins = wins[plr]}, ReplicatedStorage.black)
end)

spawn(function()
	while true do
		ReplicatedStorage.CalibrateTimes:FireAllClients(tick())
		wait(10)
	end
end)