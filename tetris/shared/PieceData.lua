type Block = {
	Position: Vector2,
	Id: number,
}
type Piece = {
	Color: Color3,
	Center: number,
	AllowRotate: boolean,
	Preview: string,
	BlockPositions: {[number]: Vector2}
}

return {
	[0] = {
		Color = Color3.new(.8,.8,.8)
	},
	{ -- J
		Color = Color3.new(0.1, 0.5, 1),
		Center = 3,
		AllowRotate = true,
		Preview = 'rbxassetid://5504565370',
		BlockPositions = {
			Vector2.new(-1, 1),
			Vector2.new(-1, 0),
			Vector2.new(0, 0),
			Vector2.new(1, 0)
		}
	},
	{ -- L
		Color = Color3.new(1, 0.5, 0),
		Center = 3,
		AllowRotate = true,
		Preview = 'rbxassetid://5504565525',
		BlockPositions = {
			Vector2.new(1, 1),
			Vector2.new(1, 0),
			Vector2.new(0, 0),
			Vector2.new(-1, 0)
		}
	},
	{ -- O
		Color = Color3.new(1, 1, 0),
		Center = 1,
		AllowRotate = false,
		Preview = 'rbxassetid://5504566147',
		BlockPositions = {
			Vector2.new(0, 0),
			Vector2.new(1, 0),
			Vector2.new(0, -1),
			Vector2.new(1, -1)
		}
	},
	{ -- T
		Color = Color3.new(1, 0, 1),
		Center = 2,
		AllowRotate = true,
		Preview = 'rbxassetid://5504566022',
		BlockPositions = {
			Vector2.new(0, 1),
			Vector2.new(0, 0),
			Vector2.new(1, 0),
			Vector2.new(-1, 0)
		}
	},
	{ -- I
		Color = Color3.new(0, 1, 1),
		Center = 2,
		AllowRotate = true,
		Preview = 'rbxassetid://5504566307',
		BlockPositions = {
			Vector2.new(-1, 0),
			Vector2.new(0, 0),
			Vector2.new(1, 0),
			Vector2.new(2, 0)
		}
	},
	{ -- Z
		Color = Color3.new(1, 0, 0),
		Center = 2,
		AllowRotate = true,
		Preview = 'rbxassetid://5504565798',
		BlockPositions = {
			Vector2.new(-1, 0),
			Vector2.new(0, 0),
			Vector2.new(0, -1),
			Vector2.new(1, -1)
		}
	},
	{ -- S
		Color = Color3.new(0, 1, 0),
		Center = 2,
		AllowRotate = true,
		Preview = 'rbxassetid://5504565664',
		BlockPositions = {
			Vector2.new(1, 0),
			Vector2.new(0, 0),
			Vector2.new(0, -1),
			Vector2.new(-1, -1)
		}
	}
}