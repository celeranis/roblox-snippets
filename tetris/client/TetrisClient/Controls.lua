--[[
	This module is used to store all the possible inputs
	associated with different actions.
]]
return {
	Pause = {
		Enum.KeyCode.P,
		Enum.KeyCode.F,
		Enum.KeyCode.ButtonB,
	},
	MoveDown = {
		Enum.KeyCode.S,
		Enum.KeyCode.Down,
		Enum.KeyCode.DPadDown,
	},
	MoveLeft = {
		Enum.KeyCode.A,
		Enum.KeyCode.Left,
		Enum.KeyCode.DPadLeft
	},
	MoveRight = {
		Enum.KeyCode.D,
		Enum.KeyCode.Right,
		Enum.KeyCode.DPadRight
	},
	QuickDrop = {
		Enum.KeyCode.W,
		Enum.KeyCode.Up,
		Enum.KeyCode.ButtonY,
		Enum.KeyCode.Space
	},
	Select = {
		Enum.KeyCode.X,
		Enum.KeyCode.Space,
		Enum.KeyCode.Return,
		Enum.KeyCode.ButtonA,
		Enum.KeyCode.Return
	},
	Hold = {
		Enum.KeyCode.R,
		Enum.KeyCode.H,
		Enum.KeyCode.RightShift,
		Enum.KeyCode.ButtonX,
	},
	RotateClock = {
		Enum.KeyCode.E,
		Enum.KeyCode.Up,
		Enum.KeyCode.ButtonR1,
		Enum.KeyCode.ButtonR2
	},
	RotateCounter = {
		Enum.KeyCode.Q,
		Enum.KeyCode.LeftControl,
		Enum.KeyCode.ButtonL1,
		Enum.KeyCode.ButtonL2
	},
}