--!strict

-- ConstrainedSpring.lua
-- Provided by ROBLOX, inside of the
-- PlayerModule.

local ConstrainedSpring = {}
ConstrainedSpring.__index = ConstrainedSpring

export type ConstrainedSpring = typeof(setmetatable({} :: {
	freq: number,
	x: number,
	v: number,
	minValue: number,
	maxValue: number,
	goal: number
}, ConstrainedSpring))

function ConstrainedSpring.new(freq: number, x: number, minValue: number, maxValue: number): ConstrainedSpring
	x = math.clamp(x, minValue, maxValue)
	return setmetatable({
		freq = freq, -- Undamped frequency (Hz)
		x = x, -- Current position
		v = 0, -- Current velocity
		minValue = minValue, -- Minimum bound
		maxValue = maxValue, -- Maximum bound
		goal = x, -- Goal position
	}, ConstrainedSpring)
end

function ConstrainedSpring.update(self: ConstrainedSpring, dt: number)
	local freq = self.freq * 2 * math.pi -- Convert from Hz to rad/s
	local x = self.x
	local v = self.v
	local minValue = self.minValue
	local maxValue = self.maxValue
	local goal = self.goal

	-- Solve the spring ODE for position and velocity after time t, assuming critical damping:
	--   2*f*x'[t] + x''[t] = f^2*(g - x[t])
	-- Knowns are x[0] and x'[0].
	-- Solve for x[t] and x'[t].

	local offset = goal - x
	local step = freq*dt
	local decay = math.exp(-step)

	local x1 = goal + (v*dt - offset*(step + 1))*decay
	local v1 = ((offset*freq - v)*step + v)*decay

	-- Constrain
	if x1 < minValue then
		x1 = minValue
		v1 = 0
	elseif x1 > maxValue then
		x1 = maxValue
		v1 = 0
	end

	self.x = x1
	self.v = v1

	return x1
end

return ConstrainedSpring