--!strict

-- Gamepad.lua
-- hi Gamepad combination :D
-- poopbarrel/magicoal_nerb :^)

local UserGameSettings = UserSettings():GetService("UserGameSettings")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local Camera = require("../Camera")

local Gamepad = {}
Gamepad.__index = Gamepad

local K_CURVATURE = 2 -- amount of upwards curvature (0 is flat)
local K_DEADZONE = 0.1 -- deadzone

export type Input = typeof(setmetatable({} :: {
	gamepadDirection: Vector2,
	gamepadZoom: number,
	
	wishDirection: Vector3,
	wishAngle: Vector2,
	wishJump: boolean,
	
	zoomTimer: number,
	wishZoom: number,

	bind: (self: Input) -> (),
	unbind: (self: Input) -> (),
	update: (self: Input) -> (),

	connections: { RBXScriptConnection },
}, Gamepad))

local function thumbstickCurve(x: number): number
	-- remove sign, apply linear deadzone
	local fDeadzone = (math.abs(x) - K_DEADZONE)/(1 - K_DEADZONE)

	-- apply exponential curve and scale to fit in [0, 1]
	local fCurve = (math.exp(K_CURVATURE*fDeadzone) - 1)/(math.exp(K_CURVATURE) - 1)

	-- reapply sign and clamp
	return math.sign(x) * math.clamp(fCurve, 0, 1)
end

function Gamepad.bind(self: Input)
	-- WASD movement
	ContextActionService:BindActivate(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonR2)
	ContextActionService:BindActionAtPriority(
		"rbx-move-gamepad",
		function(_, state, object: InputObject)
			if state == Enum.UserInputState.Change
				or state == Enum.UserInputState.Begin then
				local position = object.Position
				self.wishDirection = Vector3.new(thumbstickCurve(position.X), 0, -thumbstickCurve(position.Y))
			elseif state == Enum.UserInputState.End then
				self.wishDirection = Vector3.zero
			end
		end,

		false,
		math.huge,

		Enum.KeyCode.Thumbstick1
	)

	-- Pan camera
	ContextActionService:BindActionAtPriority(
		"rbx-zoom-camera-gamepad",
		function(_, state, object: InputObject)
			if state == Enum.UserInputState.Begin then
				-- Began input
				self.zoomTimer = -1
				self.gamepadZoom = if object.KeyCode == Enum.KeyCode.DPadUp
					then -1
					else 1
			elseif state == Enum.UserInputState.End then
				self.gamepadZoom = 0
			end
		end,

		false,
		math.huge,

		Enum.KeyCode.DPadUp,
		Enum.KeyCode.DPadDown
	)
	
	-- Move camera
	ContextActionService:BindActionAtPriority(
		"rbx-pan-camera-gamepad",
		function(_, state, object: InputObject)
			local position = object.Position
			local angle = Vector2.new(
				thumbstickCurve(position.X),
				thumbstickCurve(position.Y)
			)
			
			if state == Enum.UserInputState.Change
				or state == Enum.UserInputState.Begin then
				-- Began input
				self.gamepadDirection = angle
			else
				-- Ended input
				self.gamepadDirection = Vector2.zero
			end
		end,

		false,
		math.huge,

		Enum.KeyCode.Thumbstick2
	)
	
	-- Jump movement
	ContextActionService:BindActionAtPriority(
		"rbx-jump-gamepad",
		function(_, state, object)
			self.wishJump = state == Enum.UserInputState.Begin
		end,
		false,
		math.huge,
		Enum.KeyCode.ButtonA
	)
end

function Gamepad.unbind(self: Input)
	-- water melon sugar High
	ContextActionService:UnbindAction("rbx-pan-camera-gamepad")
	ContextActionService:UnbindAction("rbx-move-gamepad")
	ContextActionService:UnbindAction("rbx-jump-gamepad")
end

function Gamepad.update(self: Input, dt: number)
	-- Updates it to be 0 I suppose?
	self.wishZoom = 0.0
	self.wishAngle = self.gamepadDirection * dt
	if self.gamepadZoom == 0 then
		return
	elseif self.zoomTimer == -1 then
		self.zoomTimer = -0.3
		self.wishZoom = self.gamepadZoom
	elseif self.zoomTimer < 0.05 then
		self.zoomTimer += dt
	else
		self.zoomTimer = 0
		self.wishZoom = self.gamepadZoom
	end
end

return setmetatable({
	gamepadDirection = Vector2.zero,
	gamepadZoom = 0.0,
	zoomTimer = 0.0,
	
	connections = {},
	wishDirection = Vector3.zero,
	wishAngle = Vector2.zero,	
	wishJump = false,
	wishZoom = 0.0,
}, Gamepad) :: Input
