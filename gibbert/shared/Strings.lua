return {
	challenges = {
		speedy = {
			icon = 'rbxassetid://5083466426',
			name = 'Speedy',
			desc = 'Both you and GIBBERT are much faster. Make sure you\'re always on your toes, because you only get a split second to react if he sees you.'
		},
		silent = {
			icon = 'rbxassetid://5219894736',
			name = 'Silent',
			desc = 'Did you hear something? No, because you\'re deaf. This challenge mutes all sounds from the game.'
		},
		dark = {
			icon = 'rbxassetid://5083466210',
			name = 'Dark',
			desc = 'Looks like you forgot to bring a torch. Hope you\'re fine with navigating the halls in total darkness.'
		},
		hardcore = {
			icon = 'rbxassetid://5216963104',
			name = 'Hardcore',
			desc = 'GIBBERT is faster than you, takes longer to lose you, and will spawn at a random location.'
		},
		double = {
			icon = 'rbxassetid://5083466287',
			name = 'Double Trouble',
			desc = 'There\'s two.'
		},
		stealthy = {
			icon = 'rbxassetid://5220143340',
			name = 'Stealthy',
			desc = 'Shhhhh... GIBBERT is listening. Don\'t let him hear you.'
		}
	},
	objectives = {
		'FIND A WAY OUT',
		'FIND A KEY',
		'FIND THE CODE',
		'FIND THE WEAPON',
		'DEFEAT HIM',
		'ESCAPE'
	},
	tips = {
		"GIBBERT will lose you if he can't see you for more than five seconds.",
		'GIBBERT moves very slowly until he finds a target.',
		'GIBBERT runs faster than you walk, but you can sprint slightly faster than he can run.',
		'GIBBERT cannot see through boxes. Use this to your advantage.',
		'If you hear a low-pitched scream-like sound, that means GIBBERT lost you.',
		'Avoid the red light at all costs.',
		'Subscribe to Tydium',
		'Press Q and E to peek around corners.'
	},
	boolean = {
		[true] = 'ON',
		[false] = 'OFF'
	},
	settings = {
		music = {
			name = 'Music',
			type = 'boolean',
			icon = 'rbxassetid://5300053693',
			default = true
		},
		stopwatch = {
			name = 'Stopwatch',
			type = 'boolean',
			icon = 'rbxassetid://5300047243',
			default = false
		},
		bobbing = {
			name = 'Camera Bobbing',
			type = 'boolean',
			icon = 'rbxassetid://5281250282',
			default = false
		}
	}
}