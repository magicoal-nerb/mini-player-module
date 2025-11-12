local Camera = require("../Camera")

export type Camera = Camera.Camera

local Watch = {} :: Camera.State
Watch.focus = Vector3.zero

function Watch.getCameraCFrame(
	self: Camera,
	input: Camera.Input
): CFrame
	-- camera cframe
	return self.cframe
end

function Watch.update(
	self: Camera,
	subjectPosition: Vector3,
	input: Camera.Input,
	dt: number
)
	if not self.rootPart then
		return
	end
	
	-- Disable zoom input
	if input.wishAngle == Vector2.zero
	and input.wishZoom == 0 then
		-- Maintain the camera angle
		-- Check for NaNs and if the angle is within the cutoff range
		local lastVec = subjectPosition - self.cframe.Position
		local unit = lastVec.Unit
		
		-- Calculate the angular rotation
		local xz = math.sqrt(unit.X * unit.X + unit.Z * unit.Z)
		self.currentAngle = Vector2.new(
			-math.atan2(-unit.X, -unit.Z),
			math.atan2(unit.Y, xz)
		)
		
		-- Set cframe and other parameters incase
		-- we swap back to input
		local rotation = Camera.getAngleQuat(self.currentAngle)
		self.cframe = CFrame.new(self.cframe.Position) * rotation
		self.zoom.x = lastVec.Magnitude
	else
		-- We have input, so we must
		-- update the cframe
		local direction = Camera.getSphericalVector(self.currentAngle)
		self.cframe = CFrame.new(subjectPosition + direction * self.zoom.x)
			* Camera.getAngleQuat(self.currentAngle)
	end
end

return Camera.bindState(Enum.CameraType.Watch, Watch)