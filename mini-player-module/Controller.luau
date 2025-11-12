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
	subject: Humanoid?
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

function Controller.setSubject(
	self: Controller,
	subject: Humanoid
)
	self.subject = subject
end

function Controller.update(
	self: Controller,
	input: Input,
	dt: number
)
	if not self.subject then
		-- Don't update movement
		-- without a humanoid
		return
	end
	
	local wishPlane = quaternionXZ(CurrentCamera.CFrame.Rotation)
	local wishDirection = input.wishDirection
	
	if wishDirection.Magnitude > 1e-2 then
		-- Player is currently moving
		self.subject:Move(wishPlane * wishDirection, false)
	else
		-- Player is idling
		self.subject:Move(Vector3.zero, false)
	end
	
	self.subject.Jump = input.wishJump
end

return setmetatable({}, Controller) :: Controller