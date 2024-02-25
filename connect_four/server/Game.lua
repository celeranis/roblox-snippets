local model = script.Parent

local red_stool = model.RedStool
local yellow_stool = model.YellowStool

local red_seat = red_stool.Seat
local yellow_seat = yellow_stool.Seat

local red_cushion = red_stool.Cushion
local yellow_cushion = yellow_stool.Cushion

local yellow_player = nil
local red_player = nil

local prompt = game.ReplicatedStorage.ShowPrompt
local global = require(game.ReplicatedStorage.RowsGlobal)
local thread = require(game.ReplicatedStorage.Thread)

local turn = nil
local turnId = nil
local in_game = false
local turn_timeout = 0
local numdropped = 0
local accepting_players = true
local open_columns = {1, 2, 3, 4, 5, 6, 7}

local prompt_data = {
	Title = 'Play Minigame',
	Body = 'Would you like to play "4 in a row"?',
	Icon = 'rbxassetid://4976318800',
	Button0 = 'PLAY',
	Button1 = 'No thanks'
}
local prompt_body_form = 'Would you like to play "4 in a row" with %s?'
local prompt_body_noopp = 'Would you like to play "4 in a row"?'

local ContentsMeta = {
	__index = function(tab,key)
		if typeof(key) ~= 'number' then
			error('Invalid key "'..typeof(key)..' '..tostring(key)..'"',2)
		end
		local new = table.create(6,nil)
		tab[key] = new
		return new
	end
}
local contents = setmetatable({}, ContentsMeta)

function getPlayer(seat)
	return game.Players:GetPlayerFromCharacter(seat.Occupant and seat.Occupant.Parent or nil)
end

function sendEvent(...)
	model.SendEvent:FireAllClients(...)
end

function updateBoard()
	model.UpdateBoard:FireAllClients(contents)
end

function checkDirection(start: Vector2, direction: Vector2, check_id: number)
	local found = {start}
	local pos = start
	
	if not check_id then
		warn('check_id was nil, aborting...')
		return 1,found
	end
	
	repeat
		pos += direction
		local occupant = contents[pos.X][pos.Y]
		if occupant == check_id then
			table.insert(found, pos)
		else
			break
		end
	until #found >= 4
	
	if #found < 4 then
		pos = start
		repeat
			pos -= direction
			local occupant = contents[pos.X][pos.Y]
			if occupant == check_id then
				table.insert(found, pos)
			else
				break
			end
		until #found >= 4
	end
	
	return #found >= 4, found
end

local check_directions = {
	Vector2.new(1, 0),
	Vector2.new(1, 1),
	Vector2.new(0, 1),
	Vector2.new(1, -1)
}

function startGame()
	if in_game then return end
	
	red_player = getPlayer(red_seat)
	yellow_player = getPlayer(yellow_seat)
	
	if not red_player or not yellow_player then return end
	
	in_game = true
	accepting_players = false
	turnId = 0
	numdropped = 0
	turn = red_player
	contents = setmetatable({},ContentsMeta)
	open_columns = {1, 2, 3, 4, 5, 6, 7}
	
	updateBoard()
	wait(2)
	
	turn_timeout = os.time() + 15
	local timeout_now = turn_timeout
	sendEvent('turn', turnId, turn, turn_timeout)
	
	delay(15, function()
		if in_game and timeout_now == turn_timeout then
			handleEvent(turn, 'drop', open_columns[math.random(1,#open_columns)])
		end
	end)
end

function processReward(plr, winner)
	thread:Spawn(function()
		local dropped16 = numdropped > 15
		local reward = winner and (winner == plr and (dropped16 and 70 or 20) or (dropped16 and 10 or 3)) or 25
		
		print('Rewarding',plr,'with',reward,'noobits from Four in a Row')
		local suc,err = pcall(function()
			game.ReplicatedStorage.RewardClaim:InvokeClient(plr, reward) -- Yields until the client clicks on "Claim"
			-- This may produce an error if the player leaves before clicking Claim, but it will be properly handled.
		end)

		plr:WaitForChild('leaderstats').Noobits.Value += reward
		if not suc then
			warn('Error while rewarding',plr,'-',err)
			game.ReplicatedStorage.Notifiaction:FireClient(plr,'Alert','An error may have occurred while claiming your reward.')
		end
	end)
end

function gameOver(winnerId, found)
	turn = nil
	turnId = nil
	in_game = false
	
	local rplr = red_player
	local yplr = yellow_player
	local winner = (winnerId == 0 and red_player) or (winnerId == 1 and yellow_player) or nil
	
	sendEvent('turn')
	sendEvent('end', winner, found or {}, winnerId)

	wait(10)

	processReward(rplr, winner)
	processReward(yplr, winner)

	wait(1)
	
	accepting_players = true
end

local prompting = {}
function setupTouched(cushion)
	local red = cushion == red_cushion
	local seat = red and red_seat or yellow_seat
	cushion.Touched:Connect(function(hit)
		local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
		local hum = hit.Parent:FindFirstChild('Humanoid')
		if in_game or not accepting_players or not plr or seat.Occupant or prompting[plr] or plr.InArcadeGame.Value or not hum or hum.Health <= 0 then return end
		
		prompting[plr] = true
		
		local opponent = getPlayer(red and yellow_seat or red_seat)
		prompt_data.Body = opponent and prompt_body_form:format(opponent.DisplayName) or prompt_body_noopp
		
		local success, confirmed = pcall(prompt.InvokeClient, prompt, plr, prompt_data)
		
		if not success then
			warn('Minigame confirmation prompt failed for', plr, 'with error', confirmed)
			return
		end
		
		if hum and confirmed and not seat.Occupant and hit:IsDescendantOf(game) and accepting_players and hum.Health > 0 then
			if (hit.Parent.PrimaryPart.Position - cushion.Position).Magnitude > 15 then
				game.ReplicatedStorage.Notifiaction:FireClient(plr, 'Alert', "You're too far away! Move closer to the game to play.", 5)
				prompting[plr] = nil
				return
			end
			
			plr.InArcadeGame.Value = true
			seat:Sit(hit.Parent.Humanoid)
			
			sendEvent('player_added', plr, red and 0 or 1)

			if red then
				red_player = plr
			else
				yellow_player = plr
			end

			if opponent then
				startGame()
			end
		end
		
		prompting[plr] = nil
	end)
	seat:GetPropertyChangedSignal('Occupant'):Connect(function()
		local plr = (red and red_player) or (not red and yellow_player)
		if not seat.Occupant and plr then
			local id = red and 0 or 1
			plr.InArcadeGame.Value = false
			sendEvent('player_removed', plr, id)
			if in_game then
				gameOver(1 - id)
			end
		end
	end)
end

function handleEvent(plr, name, ...)
	if plr ~= red_player and plr ~= yellow_player then return end

	if name == 'drop' then
		local x = ...
		if plr ~= turn or typeof(x) ~= 'number' or x < 1 or x > 7 then
			return
		end

		local y = global.FindColumnBottom(contents, x)
		if y >= 6 then
			table.remove(open_columns, table.find(open_columns, y))
			if y > 6 then
				return
			end
		end

		contents[x][y] = turnId
		local pos = Vector2.new(x,y)
		local win = false
		local found = nil
		for _,direction in pairs(check_directions) do
			win,found = checkDirection(pos, direction, turnId)
			if win then
				break
			end
		end
		numdropped += 1
		updateBoard()
		
		if win then
			gameOver(turnId, found)
		else
			local tie = true
			for x = 1,7 do
				for y = 1,6 do
					if not contents[x][y] then
						tie = false
					end
				end
			end
			if tie then
				gameOver()
				return
			end
			turnId = 1 - turnId
			turn = turnId == 0 and red_player or yellow_player
			turn_timeout = os.time() + 15
			local timeout_now = turn_timeout
			sendEvent('turn', turnId, turn, turn_timeout)
			delay(15, function()
				if in_game and timeout_now == turn_timeout then
					handleEvent(turn, 'drop', open_columns[math.random(1,#open_columns)])
				end
			end)
		end
	end
end

setupTouched(yellow_cushion)
setupTouched(red_cushion)

model.SendEvent.OnServerEvent:Connect(handleEvent)

game.Players.PlayerAdded:Connect(function(plr)
	model.UpdateBoard:FireClient(plr, contents)
	if red_player then
		model.SendEvent:FireClient(plr, 'player_added', red_player, 0)
	end
	if yellow_player then
		model.SendEvent:FireClient(plr, 'player_added', yellow_player, 1)
	end
end)