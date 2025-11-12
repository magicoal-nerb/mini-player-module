local Camera = require("../Camera")

export type Camera = Camera.Camera

local Orbital = {} :: Camera.State

local function getAngleBetweenXZ(v1: Vector3, v2: Vector3): number
	-- atan2((v1 x v2)_x, (v1 x v2)_z) given that the y column for {v1, v2} is 0'd out
	return math.atan2(v2.X*v1.Z - v2.Z*v1.X, v2.X*v1.X + v2.Z*v1.Z)
end

function Orbital.update(
	self: Camera,
	subjectPosition: Vector3,
	input: Camera.Input,
	dt: number
)
	if not self.rootPart then
		return
	end

	-- Disable zoom input
	input.wishZoom *= 0.0

	-- Maintain the camera angle
	-- Check for NaNs and if the angle is within the cutoff range
	local lastVec = subjectPosition - self.cframe.Position
	local y = getAngleBetweenXZ(lastVec, self.cframe.LookVector)
	if y == y then
		-- Add to angle
		input.wishAngle += Vector2.xAxis * y
	end

	-- Set pitch aswell
	local unit = lastVec.Unit
	local xz = math.sqrt(unit.X * unit.X + unit.Z * unit.Z)
	local x = math.atan2(unit.Y, xz) - self.currentAngle.Y
	input.wishAngle += Vector2.yAxis * x
end

Orbital.getCameraCFrame = Camera.getCameraCFrame

return Camera.bindState(Enum.CameraType.Orbital, Orbital)