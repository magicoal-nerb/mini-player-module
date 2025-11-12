local Camera = require("../Camera")

export type Camera = Camera.Camera

local Track = {} :: Camera.State

function Track.update(
	self: Camera,
	subjectPosition: Vector3,
	input: Camera.Input,
	dt: number
)
	-- pass :3
end

Track.getCameraCFrame = Camera.getCameraCFrame

return Camera.bindState(Enum.CameraType.Track, Track)