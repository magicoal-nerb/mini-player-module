--!strict

-- Controller.lua
-- poopbarrel/magicoal_nerb :^)

local CurrentCamera = assert(workspace.CurrentCamera)
local Players = game:GetService("Players")

local Controller = {}
Controller.__index = Controller

export type Input = {
	wishShiftlock: boolean,
	wishDirection: Vector3,
	wishAngle: Vector2,
	wishJump: boolean,
	wishZoom: number,
	
	subject: Humanoid,
	
	bind: (self: Input) -> (),
	unbind: (self: Input) -> (),
	update: (self: Input) -> (),
}

export type Controller = typeof(setmetatable({} :: {
	subject: Humanoid?,
	jump: InputAction,
	move: InputAction,
}, Controller))

local function quaternionXZ(quat: CFrame): CFrame
	-- Project the quaternion onto the XZ plane
	-- making it only the y rotation
	local up = quat.UpVector
	return CFrame.new(
		0, 0, 0, 
		-up.Z, 0, up.X, up.Y+1
	) * quat
end

function Controller.getWishDirection(
	self: Controller,
	input: Input
): Vector3
	local wishPlane = quaternionXZ(CurrentCamera.CFrame.Rotation)
	local wishDirection = input.wishDirection

	if wishDirection.Magnitude > 1e-2 then
		return wishPlane * wishDirection
	else
		return Vector3.zero
	end
end

function Controller.setContext(self: Controller, context: InputContext)
	self.jump = context:WaitForChild("Jump") :: InputAction
	self.move = context:WaitForChild("Move") :: InputAction
end

function Controller.setSubject(
	self: Controller,
	subject: Humanoid
)
	self.subject = subject
end

function Controller.update(self: Controller, input: Input)
	local wishDirection = self:getWishDirection(input)
	InputContexts.Jump:Fire(input.wishJump)
	InputContexts.Move:Fire(wishDirection)
end

function Controller.step(self: Controller, dt: number)
	local subject = self.subject
	if not subject then
		return
	end

	-- Get the current state of these
	subject.Jump = self.jump:GetState()
	subject:Move(self.move:GetState(), false)
end

return Controller