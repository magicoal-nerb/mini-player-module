local Camera = require("../Camera")

export type Camera = Camera.Camera

local Fixed = {} :: Camera.State

local getAngleBetweenXZ = Camera.getAngleBetweenXZ

function Fixed.update(
	self: Camera,
	subjectPosition: Vector3,
	input: Camera.Input,
	dt: number
)
	if not self.rootPart then
		return
	end

	local lastVec = subjectPosition - self.cframe.Position
	local y = getAngleBetweenXZ(lastVec, self.cframe.LookVector)

	-- Check for NaNs and if the angle is within the cutoff range
	if y == y then
		-- Add to angle
		input.wishAngle += Vector2.xAxis * y
	end
end

Fixed.getCameraCFrame = Camera.getCameraCFrame

return Camera.bindState(Enum.CameraType.Fixed, Fixed)
