--!strict

-- Touch
-- magicoal_nerb :3

local createTouchGui = require("../util/createTouchGui")

local TouchGui = createTouchGui()
local BaseThumbstickPosition = TouchGui.ThumbstickFrame.Position

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Touch = {}
Touch.__index = Touch

export type Input = typeof(setmetatable({} :: {
	lastPinchDiameter: number?,
	
	wishDirection: Vector3,
	wishAngle: Vector2,
	wishJump: boolean,
	wishZoom: number,

	bind: (self: Input) -> (),
	unbind: (self: Input) -> (),
	update: (self: Input) -> (),

	touchPanConnections: { RBXScriptConnection }?,
	inputs: { [InputObject]: boolean },
	connections: { RBXScriptConnection },
	
	dragConnection: RBXScriptConnection?,	
	moveInputObject: InputObject?,
	jumpInputObject: InputObject?,
	panInputObject: InputObject?,
}, Touch))

function Touch.update(self: Input, dt: number)
	self.wishAngle = Vector2.zero
	self.wishZoom = 0.0
end

function Touch.touchBegan(self: Input, input: InputObject, sunk: boolean)
	self.inputs[input] = true
	self.panInputObject = input
end

function Touch.touchChanged(self: Input, input: InputObject, sunk: boolean)
	-- collect unsunk touches
	local unsunkTouches = {}
	for touch, sunk in self.inputs do
		if touch ~= self.moveInputObject
			and touch ~= self.jumpInputObject then
			table.insert(unsunkTouches, touch)
		end
	end

	-- 2 fingers: pinch
	local length = #unsunkTouches
	if length == 1 then
		local inputObject = unsunkTouches[1]
		local delta = inputObject.Delta
		self.wishAngle = Vector2.new(delta.X, -delta.Y * 0.66)
			* math.rad(1)
	elseif length == 2 then
		local pinchDiameter = (unsunkTouches[1].Position - unsunkTouches[2].Position).Magnitude

		if self.lastPinchDiameter then
			local diff = pinchDiameter - self.lastPinchDiameter
			if math.abs(diff) > 10 then
				-- If the user moved far enough, we will
				-- update the pinch diameter
				self.wishZoom = -math.sign(diff)
				self.lastPinchDiameter = pinchDiameter
			end
		else
			-- Initialize for a point of comparison
			self.lastPinchDiameter = pinchDiameter
		end
	else
		-- Can't do this
		self.lastPinchDiameter = nil
	end
end

function Touch.touchEnded(self: Input, input: InputObject, sunk: boolean)
	self.inputs[input] = nil
	if self.panInputObject == input then
		-- Set to another input if that still
		-- exists
		self.panInputObject = select(1, next(self.inputs, nil))
	end
end

function Touch.bind(self: Input)
	if not UserInputService.TouchEnabled then
		return
	end

	local parent = LocalPlayer.PlayerGui
	TouchGui.Parent = parent
	
	local jumpButton = TouchGui.JumpButton
	local thumbstick = TouchGui.ThumbstickFrame
	local stick = thumbstick.StickImage
	local connection

	self.touchPanConnections = {
		-- For touch pinching
		UserInputService.InputChanged:Connect(function(input: InputObject, sunk: boolean)
			if input.UserInputType == Enum.UserInputType.Touch then
				-- Touch changed
				self:touchChanged(input, sunk)
			end
		end),
		
		UserInputService.InputEnded:Connect(function(input: InputObject, sunk: boolean)
			if input.UserInputType == Enum.UserInputType.Touch then
				-- Call the generic touch ended function first incase
				-- something errors
				self:touchEnded(input, sunk)
			end
			
			if input == self.moveInputObject and self.dragConnection then			
				-- If this input came from the movement touch, we have to
				-- close the connection
				self.dragConnection = self.dragConnection:Disconnect()
				self.moveInputObject = nil

				stick.Position = UDim2.new(0.5, 0, 0.5, 0)
				thumbstick.Position = BaseThumbstickPosition
				self.wishDirection = Vector3.zero
			elseif input == self.jumpInputObject then
				-- Released the jump button
				jumpButton.ImageRectOffset = Vector2.new(176, 222)
				self.wishJump = false
				self.jumpInputObject = nil
			end
		end),

		UserInputService.InputBegan:Connect(function(input: InputObject, sunk: boolean)
			if input.UserInputType == Enum.UserInputType.Touch then
				-- Call touch began
				self:touchBegan(input, sunk)
			end
		end),
	}

	self.connections = {
		thumbstick.InputBegan:Connect(function(inputObject: InputObject)
			-- Begin the movement
			if inputObject.UserInputType ~= Enum.UserInputType.Touch
				or inputObject.UserInputState ~= Enum.UserInputState.Begin then
				return
			end

			-- Set thumbstick position
			local absoluteSize = thumbstick.AbsoluteSize*0.5
			local position = inputObject.Position
			thumbstick.Position = UDim2.fromOffset(
				position.X - absoluteSize.X, 
				position.Y - absoluteSize.Y
			)

			-- Update directions and drig
			self.wishDirection = Vector3.zero
			self.moveInputObject = inputObject
			self:thumbstickDrag(Vector2.new(position.X, position.Y))
		end),
		
		jumpButton.InputBegan:Connect(function(inputObject: InputObject)
			if inputObject.UserInputType == Enum.UserInputType.Touch
				and inputObject.UserInputState == Enum.UserInputState.Begin then
				-- Create jump input object to track where
				-- our jump was
				self.jumpInputObject = inputObject
				self.wishJump = true
				jumpButton.ImageRectOffset = Vector2.new(0, 222)
			end
		end),
	}
end

function Touch.thumbstickDrag(self: Input, origin: Vector2)
	local thumbstick = TouchGui.ThumbstickFrame
	local stick = thumbstick.StickImage

	local outerSize = thumbstick.AbsoluteSize
	local radius = math.max(outerSize.X, outerSize.Y)*0.5
	
	self.dragConnection = UserInputService.TouchMoved:Connect(function(inputObject: InputObject)
		-- Check for the input object
		if inputObject ~= self.moveInputObject then
			return
		end

		-- Calculate distance from the object
		local position = inputObject.Position
		local delta = Vector2.new(
			position.X - origin.X, 
			position.Y - origin.Y
		)
		
		local magnitude = delta.Magnitude
		if magnitude < 10 then
			-- Goofy ahh deadzone
			delta = Vector2.zero
		elseif magnitude > radius then
			-- Otherwise, just go forward manee
			delta = delta.Unit * radius
		end
		
		self.wishDirection = Vector3.new(delta.X/radius, 0, delta.Y/radius)
		stick.Position = UDim2.new(0.5, delta.X, 0.5, delta.Y)
	end)
end

function Touch.unbind(self: Input)
	if not self.touchPanConnections then
		return
	end
	
	-- Remove the gui
	TouchGui = TouchGui:Destroy()
	
	for _, connection in self.connections do
		-- Remove the touch connections
		connection:Disconnect()
	end

	if self.dragConnection then
		self.dragConnection = self.dragConnection:Disconnect()
	end

	self.moveInputObject = nil
	table.clear(self.connections)
	
	-- If connections existed, remove it
	for _, connection in self.touchPanConnections do
		connection:Disconnect()
	end
end

return setmetatable({
	inputs = {},
	
	wishDirection = Vector3.zero,
	wishAngle = Vector2.zero,
	wishJump = false,
	wishZoom = 0.0,
} :: {}, Touch) :: Input