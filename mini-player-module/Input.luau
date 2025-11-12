-- Input
-- Amalgum of all of the other input types
-- that are combined together :P
-- magicoal_nerb

local Input = {}
Input.__index = Input

export type InputType = {
	wishDirection: Vector3,
	wishShiftlock: boolean,
	wishAngle: Vector2,
	wishJump: boolean,
	wishZoom: number,
	
	bind: (self: InputType) -> (),
	unbind: (self: InputType) -> (),
	update: (self: InputType, dt: number) -> (),
}

export type Input = typeof(setmetatable({} :: {
	wishShiftlock: boolean,
	wishDirection: Vector3,
	wishAngle: Vector2,
	wishJump: boolean,
	wishZoom: number,
	
	inputTypes: { InputType }
}, Input))

function Input.update(self: Input, dt: number)
	-- reset state
	self.wishShiftlock = false
	self.wishJump = false
	self.wishDirection *= 0.0
	self.wishAngle *= 0.0
	self.wishZoom = 0
	
	for i, inputType in self.inputTypes do
		-- add the states of the other input
		-- types onto our final state
		self.wishShiftlock = self.wishShiftlock or inputType.wishShiftlock
		self.wishJump = self.wishJump or inputType.wishJump
		self.wishDirection += inputType.wishDirection
		self.wishAngle += inputType.wishAngle
		self.wishZoom += inputType.wishZoom
		
		inputType:update(dt)
	end
end

function Input.addInputType(self: Input, input: InputType)
	-- adds the input
	table.insert(self.inputTypes, input)
end

function Input.bind(self: Input)
	-- bound
	for i, input in self.inputTypes do
		input:bind()
	end
end

function Input.unbind(self: Input)
	-- unbound
	for i, input in self.inputTypes do
		input:unbind()
	end
end

return setmetatable({
	wishDirection = Vector3.zero,
	wishShiftlock = false,
	wishAngle = Vector2.zero,
	wishJump = false,
	wishZoom = 0.0,

	inputTypes = {}
}, Input) :: Input