local uis = game:GetService('UserInputService')

local select_nav = {
	Menu = {
		'Play',
		'Leaderboard',
		'Quit'
	},
	Paused = {
		'Resume',
		'Quit'
	},
	LevelSelect = {
		'Begin',
	},
	Leaderboard = {
		'Close'
	}
}

local img_keyboardKey = 'rbxassetid://5408770671'
local img_controllerKey = 'rbxassetid://5519558230'

--[[
	Returns a list of available controls associated with the current input method
	to be displayed in the bottom right corner of the screen.
]]
return function(obj)
	local controls = {}
	local controller = uis:GetLastInputType() == Enum.UserInputType.Gamepad1
	
	if obj.State == 'Game' then
		if obj.CurrentPiece and not obj.Locked then
			if controller then
				table.insert(controls, {
					Name = 'Left',
					Label = 'Move',
					Key = 'L',
					Img = 'rbxassetid://5519616359'
				})
			else
				table.insert(controls, {
					Name = 'Left',
					Label = 'Move Left',
					Key = 'A',
					Img = img_keyboardKey
				})
				table.insert(controls, {
					Name = 'Right',
					Label = 'Move Right',
					Key = 'D',
					Img = img_keyboardKey
				})
				table.insert(controls, {
					Name = 'Down',
					Label = 'Move Down',
					Key = 'S',
					Img = img_keyboardKey
				})
			end
			table.insert(controls, {
				Name = 'RotateClock',
				Label = 'Rotate',
				Key = controller and 'RT' or 'E',
				Img = img_keyboardKey
			})
			table.insert(controls, {
				Name = 'RotateCounter',
				Label = 'Rotate Back',
				Key = controller and 'LT' or 'Q',
				Img = img_keyboardKey
			})
			table.insert(controls, {
				Name = 'QuickDrop',
				Label = 'Quick Drop',
				Key = controller and 'Y' or 'W',
				Img = controller and img_controllerKey or img_keyboardKey
			})
			if obj.AllowHold then
				table.insert(controls, {
					Name = 'Hold',
					Label = 'Hold Piece',
					Key = controller and 'X' or 'R',
					Img = controller and img_controllerKey or img_keyboardKey
				})
			end
		end
		table.insert(controls, {
			Name = 'Pause',
			Label = 'Pause',
			Key = controller and 'B' or 'F',
			Img = controller and img_controllerKey or img_keyboardKey
		})
	else
		if obj.State == 'Paused' then
			table.insert(controls, {
				Name = 'Pause',
				Label = 'Unpause',
				Key = controller and 'B' or 'F',
				Img = controller and img_controllerKey or img_keyboardKey
			})
		end
		local snav = select_nav[obj.State]
		if snav then
			if controller then
				if #snav > 1 then
					table.insert(controls, {
						Name = 'Left',
						Label = 'Move',
						Key = '',
						Img = 'rbxassetid://5519616279'
					})
				end
			else
				if snav[obj.SelectionId + 1] then
					table.insert(controls, {
						Name = 'Down',
						Label = 'Down',
						Key = 'S',
						Img = img_keyboardKey
					})
				end
				if snav[obj.SelectionId - 1] then
					table.insert(controls, {
						Name = 'Up',
						Label = 'Up',
						Key = 'W',
						Img = img_keyboardKey
					})
				end
			end
			if obj.Selection then
				table.insert(controls, {
					Name = 'Select',
					Label = 'Select',
					Key = controller and 'A' or 'X',
					Img = controller and img_controllerKey or img_keyboardKey
				})
			end
		end
	end
	
	return controls
end