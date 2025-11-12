local Camera = require("../Camera")

export type Camera = Camera.Camera

local Custom = {} :: Camera.State

local getAngleBetweenXZ = Camera.getAngleBetweenXZ

function Custom.update(
	self: Camera,
	subjectPosition: Vector3,
	input: Camera.Input,
	dt: number
)
	-- pass :3
end

Custom.getCameraCFrame = Camera.getCameraCFrame

return Camera.bindState(Enum.CameraType.Custom, Custom)