local ReplicatedStorage = game:GetService('ReplicatedStorage')

local inputs = {'_','_','_','_'}
local inputInd = 1
local allowInput = true

local gui = script.Parent
local inputDisplay = gui.Display
local keys = gui.Keys
local enterBtn = keys.Enter
local clearBtn = keys.Clear
local keypadObject = gui.Adornee

for _,key in pairs(keys:GetChildren()) do
	if tonumber(key.Name) then
		key.MouseButton1Click:Connect(function()
			if inputInd < 5 and allowInput then
				inputs[inputInd] = tonumber(v.Name)
				inputInd = inputInd + 1
				keypadObject.Input:Play()
				inputDisplay.Text = table.concat(inputs,' ')
			end
		end)
	end
end

enterBtn.MouseButton1Click:Connect(function()
	if not allowInput then return end
	allowInput = false
	local success = ReplicatedStorage.VerifyCode:InvokeServer(inputs)
	if success then
		inputDisplay.Text = 'ACCESS GRANTED'
		inputDisplay.TextColor3 = Color3.new(0,1,0)
		keypadObject.Success:Play()
	else
		inputDisplay.Text = 'ACCESS DENIED'
		inputDisplay.TextColor3 = Color3.new(1,0,0)
		keypadObject.Failed:Play()
		
		task.wait(3)
		
		inputInd = 1
		inputs = {'_','_','_','_'}
		inputDisplay.Text = table.concat(inputs,' ')
		inputDisplay.TextColor3 = Color3.new(0,1,0)
		allowInput = true
	end
end)

clearBtn.MouseButton1Click:Connect(function()
	if not allowInput then return end
	inputInd = 1
	inputs = {'_','_','_','_'}
	inputDisplay.TextColor3 = Color3.new(0,1,0)
	inputDisplay.Text = table.concat(inputs,' ')
	keypadObject.Clear:Play()
end)