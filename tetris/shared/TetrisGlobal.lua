local TetrisGlobal = {}

local run: RunService = game:GetService('RunService')
local http: HttpService = game:GetService('HttpService')

function TetrisGlobal.getRotatedOffset(center: Vector2, offset: Vector2, amount: number): Vector2
	debug.profilebegin('getRotatedOffset')
	if amount == 0 then return offset + center end
	local dir = amount > 0 and 1 or -1
	
	local x = offset.X + center.X
	local y = offset.Y + center.Y
	
	for i = 1,math.abs(amount) do
		local diff = center - Vector2.new(x,y)
		x = center.X - (diff.Y * dir)
		y = center.Y + (diff.X * dir)
	end
	
	debug.profileend()
	return Vector2.new(x,y)
end

if run:IsServer() then
	local DataStoreService = game:GetService('DataStoreService')
	local BestDS = DataStoreService:GetDataStore('TetrisBest')
	local GlobalDS = DataStoreService:GetDataStore('global')
	
	TetrisGlobal.BestCache = {}
	function TetrisGlobal.getBest(plr)
		return TetrisGlobal.BestCache[plr] or BestDS:GetAsync(plr.UserId) or 0
	end
	
	TetrisGlobal.Leaderboard = GlobalDS:GetAsync('TetroLeaderboard')
	GlobalDS:OnUpdate('TetroLeaderboard',function(new)
		TetrisGlobal.Leaderboard = new
	end)
	
	game.Players.PlayerRemoving:Connect(function(plr)
		TetrisGlobal.BestCache[plr] = nil
	end)
	
	function TetrisGlobal.setBest(plr, score)
		local didSet = 0
		BestDS:UpdateAsync(plr.UserId,function(old)
			if old and old > score then
				warn('Old score',old,'is somehow higher than the target score, aborting...')
				didSet = old
				return nil
			end
			didSet = score
			return score
		end)
		TetrisGlobal.BestCache[plr] = didSet
	end
	
	function TetrisGlobal.addHighScore(score, id)
		GlobalDS:UpdateAsync('TetroLeaderboard',function(old)
			local new = {}
			local added = false
			for i,data in pairs(old) do
				if score > data[1] then
					new[i + 1] = data
					if not added then
						new[i] = {score,id}
						added = true
					end
				else
					new[i] = data
				end
			end
			
			if not added then
				new[#new + 1] = {score,id}
			end
			
			if #http:JSONEncode(new) > 4 * (10 ^ 6) then
				new[#new] = nil
			end
			
			TetrisGlobal.Leaderboard = new
			
			return new
		end)
	end
	
	game.ReplicatedStorage.GetLeaderPage.OnServerInvoke = function(plr, page)
		local pm1 = page and math.floor(page) - 1
		if not page or pm1 * 10 > #TetrisGlobal.Leaderboard or page < 1 then
			return {}
		else
			local res = {}
			for i = 1,10 do
				table.insert(res, TetrisGlobal.Leaderboard[i + (pm1 * 10)])
			end
			return res
		end
	end
	
	game.ReplicatedStorage.GetYourTetroPos.OnServerInvoke = function(invoker,plr)
		plr = plr or invoker
		for i,v in pairs(TetrisGlobal.Leaderboard) do
			if v[2] == plr.UserId then
				return i,v[1]
			end
		end
	end
end

TetrisGlobal.PieceData = require(script.PieceData)
TetrisGlobal.Rewards = require(script.Rewards)

return TetrisGlobal