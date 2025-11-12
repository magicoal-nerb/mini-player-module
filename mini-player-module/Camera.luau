--!strict

-- Camera.lua
-- Main camera system
-- poopbarrel/magicoal_nerb :^)

local CAMERA_MAX_ANGLE = math.rad(90)
local CAMERA_INVIS_SPEED = 2.8
local CAMERA_MAX_ZOOM = 400
local CAMERA_CUTOFF = 0.4

local K_E = math.exp(1)
local K_ROOT = 1 + (1 - 2*K_E) / (math.pi*math.pi)

-- e^(-x * dt) = 0.9 ; dt = 1/30
-- -x/30 = ln(0.9)
-- x = -ln(0.9) * 30
local K_INV_ROOT = 1.0 / K_ROOT
local VEC_XZ = Vector3.new(1, 0, 1)

local UserInputService = game:GetService("UserInputService")
local ConstrainedSpring = require("./ConstrainedSpring")
local CurrentCamera = assert(workspace.CurrentCamera)

local CameraTypes = {} :: { [Enum.CameraType]: State }
local Camera = {}
Camera.__index = Camera

export type State = {
	-- update state
	update: (self: Camera, subjectPosition: Vector3, input: Input, dt: number) -> (),

	-- getCameraCFrame
	getCameraCFrame: (self: Camera, input: Input) -> CFrame,
}

export type Input = {
	-- where we are shift locking
	wishShiftlock: boolean,
	
	-- where we want to pan
	wishPanning: boolean,

	-- where we wish to go to
	wishDirection: Vector3,

	-- where we wish to look
	wishAngle: Vector2,

	-- where we wish to jump
	wishJump: boolean,

	-- where we wish to zoom
	wishZoom: number,

	bind: (self: Input) -> (),
	unbind: (self: Input) -> (),
	update: (self: Input) -> (),
}

export type Camera = typeof(setmetatable({} :: {
	rootPart: BasePart,
	state: State,
	
	raycastParams: RaycastParams,
	transparency: number,
	connections: { RBXScriptConnection },
	limbs: { BasePart },
	
	zoom: ConstrainedSpring.ConstrainedSpring,
	
	currentAngle: Vector2,
	cframe: CFrame,
}, Camera))

local function getAngleBetweenXZ(v1: Vector3, v2: Vector3): number
	-- atan2((v1 x v2)_x, (v1 x v2)_z) given that the y column for {v1, v2} is 0'd out
	return math.atan2(v2.X*v1.Z - v2.Z*v1.X, v2.X*v1.X + v2.Z*v1.Z)
end

local function getAngleQuat(angle: Vector2): CFrame
	-- Converts a 2D angle(wrt to Y, X) to a CFrame rotation

	-- q1 = -j * sin(x) + cos(x)
	-- q0 = i * sin(y) + cos(y)
	-- q1 * q0 = -ji*sin(x)sin(y) - j*sin(x)cos(y) + i*sin(y)cos(x) + cos(x)cos(y)
	-- btw: -ji = k

	local halfAngle = angle * 0.5
	local sx = math.sin(halfAngle.X)
	local cx = math.cos(halfAngle.X)
	local sy = math.sin(halfAngle.Y)
	local cy = math.cos(halfAngle.Y)

	return CFrame.new(0, 0, 0, sy*cx, -sx*cy, sx*sy, cx*cy)
end

local function getSphericalVector(angle: Vector2): Vector3
	-- Gets a R^3 vector from spherical coordinates
	local pitch = angle.Y
	local yaw = angle.X

	local phi = math.cos(pitch)
	local sin = -math.sin(yaw)
	local cos = math.cos(yaw)

	return Vector3.new(
		sin*phi,
		-math.sin(pitch),
		cos*phi
	)
end

function Camera.bindState(enum: Enum.CameraType, state: State): State
	-- Binds a camera state
	CameraTypes[enum] = state
	return state
end

function Camera.getMinimumZoom(self: Camera): number
	-- Compute new state
	local maximum = math.max(self.zoom.x, self.zoom.goal) + 1
	local subjectPosition = self:getSubjectPosition()

	local delta = getSphericalVector(self.currentAngle) * maximum
	if delta.Magnitude > 0.5 then
		delta += delta.Unit
	end

	repeat
		-- Check for transluscent objects
		local result = workspace:Spherecast(
			subjectPosition,
			0.25,
			delta,
			self.raycastParams
		)

		if result and result.Instance.Transparency < 0.3 then
			-- OK!
			return result.Distance
		elseif result then
			-- Then, add this to the ignore list
			self.raycastParams:AddToFilter(result.Instance)
		end
	until not result

	return maximum
end

function Camera.getCameraCFrame(
	self: Camera,
	input: Input
): CFrame
	-- Our final camera CFrame
	local subject = self:getSubjectPosition()
	local angle = self.currentAngle

	local direction = getSphericalVector(angle)
	if input.wishShiftlock and self.zoom.goal > self.zoom.minValue then
		-- special case, where we're shiftlocked and not in first
		-- person
		return CFrame.new(subject + direction * self.zoom.x)
			* getAngleQuat(angle)
			* CFrame.new(1.5, 0, 0)
	else
		-- base case, where it's just normally looking at the place
		return CFrame.new(subject + direction * self.zoom.x)
			* getAngleQuat(angle)
	end
end

function Camera.getSubjectPosition(self: Camera): Vector3
	if self.rootPart then
		return self.rootPart.Position + Vector3.yAxis * 1.5
	else
		return Vector3.zero
	end
end

function Camera.setSubject(
	self: Camera,
	what: Model | BasePart | Humanoid
)
	if what:IsA("Humanoid") then
		-- It's a humanoid, it's definitely a player
		self:setRootPart(what.RootPart)
	elseif what:IsA("Model") then
		-- It's a model, we might be getting a character
		-- or some other model here!
		local humanoid = what:FindFirstChildOfClass("Humanoid")
		if humanoid then
			self:setRootPart(what:FindFirstChild("Head") :: BasePart)
		else
			error(`Model doesn't have a humanoid!`)
		end
	elseif what:IsA("BasePart") then
		-- It's a part, set focus to the part
		self:setRootPart(what)
	else
		-- Invalid instance
		error(`Camera got invalid instance: '{what.ClassName}'`)
	end
end

local CAMERA_WHITELIST = {
	["LowerTorso"] = true,
	["UpperTorso"] = true,
	
	["LeftLowerLeg"] = true,
	["RightLowerLeg"] = true,
	["LeftUpperLeg"] = true,
	["RightUpperLeg"] = true,
	["LeftFoot"] = true,
	["RightFoot"] = true,
	
	["Right Leg"] = true,
	["Left Leg"] = true,
	["Torso"] = true,
}

local CAMERA_ACCESSORY = {
	[Enum.AccessoryType.Hat] = true,
	[Enum.AccessoryType.Face] = true,
	[Enum.AccessoryType.Neck] = true,
	[Enum.AccessoryType.Hair] = true,
	[Enum.AccessoryType.Eyebrow] = true,
	[Enum.AccessoryType.Eyelash] = true,
}

function Camera.setRootPart(
	self: Camera,
	rootPart: BasePart?
)
	assert(rootPart, `RootPart does not exist!`)
	table.clear(self.limbs)

	local raycastParams = RaycastParams.new()
	local character = assert(rootPart.Parent)
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.RespectCanCollide = true

	-- Get avaliable limbs
	local function addLimb(limb: Instance)
		if limb:IsA("BasePart")
			and limb.Transparency ~= 1 then
			--and not CAMERA_WHITELIST[limb.Name] then
			table.insert(self.limbs, limb)
		elseif limb:IsA("Accessory") then
			--and CAMERA_ACCESSORY[limb.AccessoryType] then
			table.insert(
				self.limbs,
				limb:WaitForChild("Handle") :: BasePart
			)
		end
	end
	
	for _, limb in character:GetChildren() do
		addLimb(limb)
	end

	self.connections = {
		character.ChildAdded:Connect(function(limb)
			addLimb(limb)
		end)
	}

	self.raycastParams = raycastParams
	self.rootPart = rootPart
end

function Camera.panCameraZoom(self: Camera, velocity: number)    
	-- Get camera state
	local direction = getSphericalVector(self.currentAngle)

	-- In ROBLOX's camera zoom logic: f''(x) = max(f(x)/3.3 + 0.5, 1) * sign(velocity)
	-- Our approach is to handle each part of the piecewise function into
	-- four cases, each combination being the direction and if the function is
	-- below the maximum interval.
	local zoom = self.zoom.goal
	if velocity > 0 then
		if zoom < 1.65 then
			-- In this case, we do f''(x) = 1 => f'(x) = x*c1 => f(x) = 1/2*x^2*c1 + c2
			-- F(x) = 1/6 * x^3 * c1 + c2 * x
			-- F(1) - F(0) = 1/6 * c1 + c2
			local delta = velocity/6 + zoom
			zoom += delta * 0.5
		else
			-- The approximation of this is the following: f''(t) = f(t)/3.3 + 1/2
			-- f(t) ~= velocity*e^(root*t) + zoom*e^(-root*t) - 1.65 (solve the 2nd order NL ODE)
			-- F(t) = (velocity/root)*e^(root*t) - (zoom/root)e^(-root*t) - 1.65t
			-- F(1) - F(0) = ((velocity/root)*e^(root) - (zoom/root)e^(-root) - 1.65) - (velocity - zoom)/root
			local delta = (velocity * K_INV_ROOT) * math.exp(K_ROOT) 
			delta -= (zoom * K_INV_ROOT) * math.exp(-K_ROOT) + 1.65
			delta -= (velocity - zoom) * K_INV_ROOT

			zoom += delta * 0.5
		end
	elseif velocity < 0 then
		if zoom < 1.65 then
			-- In this case, we do f''(x) = 1 => f'(x) = x*c1 => f(x) = -1/2*x^2*c1 - c2
			-- F(x) = -1/6 * x^3 * c1 - c2 * x
			-- F(1) - F(0) = -1/6 * c1 - c2
			local delta = -velocity/6 - zoom
			zoom += delta * 0.5
		else
			-- The approximation of this is the following: f''(t) = -f(t)/3.3 - 1/2
			-- f(t) ~= velocity * sin(root*t) + zoom*cos(root*t) - 1.65 (solve the 2nd order NL ODE)
			-- F(t) = (velocity/root)*sin(root*t) + (zoom/root)*cos(root*t) - 1.65t
			-- F(1) - F(0) = (velocity/root)*sin(root) + (zoom/root)*cos(root) - (zoom/root) - 1.65
			-- F(1) - F(0) = (velocity/root)*sin(root) + (cos(root)-1) * (zoom/root) - 1.65
			local delta = (velocity * K_INV_ROOT) * math.sin(K_ROOT)
			delta += (math.cos(K_ROOT)-1) * (zoom * K_INV_ROOT) - 1.65
			zoom += delta * 0.5
		end
	end

	-- Set camera state
	self.zoom.goal = math.clamp(zoom, 0.25, CAMERA_MAX_ZOOM)
end

function Camera.updateZoom(self: Camera, dt: number)
	-- Update current zoom to not occlude opaque
	-- objects
	self.zoom.maxValue = self:getMinimumZoom()
	
	-- Get potential limb transparency
	local distance = self.zoom.x
	local transparency = if distance < 2.0
		then 1.0 - (distance - 0.5) / 1.5
		else 0.0
	
	transparency = self.transparency + math.clamp(
		transparency - self.transparency,
		-dt * CAMERA_INVIS_SPEED,
		dt * CAMERA_INVIS_SPEED
	)
	
	self.zoom:update(dt)
	if transparency == self.transparency then
		return
	end
	
	-- Set limb transparency
	for i, limb in self.limbs do
		limb.LocalTransparencyModifier = transparency
	end
	
	self.transparency = transparency
end

function Camera.getCurrentZoom(self: Camera): number
	return self.zoom.goal
end

function Camera.updateFollowCamera(
	self: Camera,
	subjectPosition: Vector3,
	input: Input,
	dt: number
)
	if not self.rootPart then
		return
	end

	local lastVec = subjectPosition - self.cframe.Position
	local y = getAngleBetweenXZ(lastVec, self.cframe.LookVector)

	-- Check for NaNs and if the angle is within the cutoff range
	if y == y and math.abs(y) > 1e-4 and math.abs(y) > CAMERA_CUTOFF * dt then
		-- Add to angle
		input.wishAngle += Vector2.xAxis * y
	end
end

function Camera.update(
	self: Camera,
	input: Input,
	dt: number
)
	if not self.state then
		-- No state, so do not
		-- compute anything here
		return
	end
	
	local subjectPosition = self:getSubjectPosition()
	if input.wishZoom ~= 0 then
		-- The camera was not occluded, allow zooming to occur
		self:panCameraZoom(input.wishZoom)
	end

	-- Update camera states
	self.state.update(
		self,
		subjectPosition,
		input,
		dt
	)

	-- Update look angle
	self:updateZoom(dt)
	self.currentAngle = Vector2.new(
		self.currentAngle.X + input.wishAngle.X,
		math.clamp(self.currentAngle.Y + input.wishAngle.Y, -CAMERA_MAX_ANGLE, CAMERA_MAX_ANGLE)
	)

	-- Finalize camera state
	local desiredCFrame = self.state.getCameraCFrame(self, input)
	CurrentCamera.CFrame = desiredCFrame
	CurrentCamera.Focus = desiredCFrame
	
	self.cframe = desiredCFrame
end

function Camera.changeState(self: Camera, enum: Enum.CameraType)
	-- Set state
	self.state = CameraTypes[enum]
end

Camera.getSphericalVector = getSphericalVector
Camera.getAngleBetweenXZ = getAngleBetweenXZ
Camera.getAngleQuat = getAngleQuat

return setmetatable({	
	raycastParams = RaycastParams.new(),
	zoom = ConstrainedSpring.new(4.5, 12.5, 0.5, 512),
	
	transparency = 0.0,
	connections = {},
	limbs = {},
	
	currentAngle = Vector2.zero,
	cframe = CFrame.identity,
}, Camera) :: Camera