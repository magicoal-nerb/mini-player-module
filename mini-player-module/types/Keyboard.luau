--!strict

-- Keyboard.lua
-- hi keyboard combination :D
-- poopbarrel/magicoal_nerb :^)

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Camera = require("../Camera")

local KEYBOARD_SENSITIVTY = Vector2.new(1, 0.77) * math.rad(0.5)
local KEYBOARD_INPUTS = {
	[Enum.KeyCode.W] = -Vector3.zAxis,
	[Enum.KeyCode.A] = -Vector3.xAxis,
	[Enum.KeyCode.S] = Vector3.zAxis,
	[Enum.KeyCode.D] = Vector3.xAxis,
	
	[Enum.KeyCode.Up] = -Vector3.zAxis,
	[Enum.KeyCode.Down] = Vector3.zAxis,
}

local Keyboard = {}
Keyboard.__index = Keyboard

export type Keyboard = typeof(setmetatable({} :: {	
	wishDirection: Vector3,
	wishShiftlock: boolean,
	wishPanning: boolean,
	wishJump: boolean,
	
	wishAngle: Vector2,
	wishZoom: number,
}, Keyboard))

function Keyboard.bind(self: Keyboard)
	-- WASD movement
	ContextActionService:BindActionAtPriority(
		"rbx-move",
		function(_, state, object)
			local input = KEYBOARD_INPUTS[object.KeyCode]
			if state == Enum.UserInputState.Begin then
				self.wishDirection -= (self.wishDirection:Dot(input) - 1) * input
			elseif state == Enum.UserInputState.End then
				self.wishDirection -= math.max(self.wishDirection:Dot(input), 0.0) * input
			end
		end,
		
		false,
		math.huge,
		
		Enum.KeyCode.W,
		Enum.KeyCode.A,
		Enum.KeyCode.S,
		Enum.KeyCode.D,
		Enum.KeyCode.Up,
		Enum.KeyCode.Down
	)
	
	-- Camera panning
	ContextActionService:BindActionAtPriority(
		"rbx-camera-pan",
		function(_, state, object)
			self.wishPanning = state == Enum.UserInputState.Begin
		end,
		
		false,
		math.huge,
		
		Enum.UserInputType.MouseButton2,
		Enum.UserInputType.MouseButton3
	)
	
	-- Jump movement
	ContextActionService:BindActionAtPriority(
		"rbx-jump",
		function(_, state, object)
			self.wishJump = state == Enum.UserInputState.Begin
		end,
		
		false,
		math.huge,
		
		Enum.KeyCode.Space
	)
	
	-- Moving the camera around
	ContextActionService:BindActionAtPriority(
		"rbx-move-camera",
		function(name, state: Enum.UserInputState, input: InputObject)
			local delta = input.Delta
			self.wishAngle = Vector2.new(delta.X, -delta.Y) * KEYBOARD_SENSITIVTY
			return Enum.ContextActionResult.Pass
		end,
		
		false,
		math.huge,
		
		Enum.UserInputType.MouseMovement
	)
	
	-- Zooming the camera around
	ContextActionService:BindActionAtPriority(
		"rbx-zoom-camera",
		function(name, state: Enum.UserInputState, input: InputObject)
			self.wishZoom = -input.Position.Z
			return Enum.ContextActionResult.Sink
		end,
		
		false,
		math.huge,
		
		Enum.UserInputType.MouseWheel
	)
	
	-- Shiftlock
	ContextActionService:BindActionAtPriority(
		"rbx-shiftlock",
		function(name, state: Enum.UserInputState, input: InputObject)
			if state ~= Enum.UserInputState.Begin then
				-- the key was not held down, so
				-- pass through this
				return Enum.ContextActionResult.Pass
			end
			
			-- toggle shiftlock
			self.wishShiftlock = not self.wishShiftlock
			return Enum.ContextActionResult.Sink
		end,
		
		false,
		math.huge,
		
		Enum.KeyCode.LeftShift,
		Enum.KeyCode.RightShift
	)
end

function Keyboard.unbind(self: Keyboard)
	-- water melon sugar High
	ContextActionService:UnbindAction("rbx-move-camera")
	ContextActionService:UnbindAction("rbx-zoom-camera")
	ContextActionService:UnbindAction("rbx-move")
	ContextActionService:UnbindAction("rbx-jump")
end

function Keyboard.update(self: Keyboard)
	self.wishAngle = Vector2.zero
	self.wishZoom = 0

	-- Set mouse behavior
	local lockCenter = Camera:getCurrentZoom() <= 0.5 or self.wishShiftlock
	UserInputService.MouseBehavior = if lockCenter then Enum.MouseBehavior.LockCenter
		elseif self.wishPanning then Enum.MouseBehavior.LockCurrentPosition
		else Enum.MouseBehavior.Default
end

return setmetatable({
	connections = {},
	
	wishShiftlock = false,
	wishPanning = false,
	wishJump = false,
	
	wishDirection = Vector3.zero,
	wishAngle = Vector2.zero,
	wishZoom = 0.0,
}, Keyboard) :: Keyboard