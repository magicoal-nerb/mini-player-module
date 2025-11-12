local Camera = require("../Camera")

export type Camera = Camera.Camera

local Attach = {} :: Camera.State

local getAngleBetweenXZ = Camera.getAngleBetweenXZ

function Attach.update(
	self: Camera,
	subjectPosition: Vector3,
	input: Camera.Input,
	dt: number
)
	if not self.rootPart then
		return
	end
	
	local rootCoord = self.rootPart.CFrame
	local lastVec = rootCoord.LookVector
	local y = getAngleBetweenXZ(lastVec, self.cframe.LookVector)

	-- Check for NaNs and if the angle is within the cutoff range
	input.wishAngle *= Vector2.yAxis
	
	if y == y then
		-- Add to angle
		input.wishAngle += Vector2.xAxis * y
	end
end

Attach.getCameraCFrame = Camera.getCameraCFrame

return Camera.bindState(Enum.CameraType.Attach, Attach)