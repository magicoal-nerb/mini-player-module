-- mini-player-module.lua
-- thanks you for using!! :3
-- this is a typed, minimalist reimplementation of the player module 
-- and the animate script!! starter code is stored in the root of the repo!!

-- moreover, i recreated the old roblox camera types instead
-- because those have much more interesting behavior
-- magicoal_nerb/poopbarrel

local ConstrainedSpring = require("@self/ConstrainedSpring")
local Controller = require("@self/Controller")
local Camera = require("@self/Camera")
local Input = require("@self/Input")

export type ConstrainedSpring = ConstrainedSpring.ConstrainedSpring
export type Controller = Controller.Controller
export type Camera = Camera.Camera
export type Input = Input.Input

return {
	-- util
	ConstrainedSpring = ConstrainedSpring,
	
	-- classes
	Controller = Controller,
	Camera = Camera,
	
	-- inputs
	Input = Input,
	
	-- camera states
	Orbital = require("@self/states/Orbital"),
	Follow = require("@self/states/Follow"),
	Custom = require("@self/states/Custom"),
	Attach = require("@self/states/Attach"),
	Track = require("@self/states/Track"),
	Watch = require("@self/states/Watch"),
	
	-- input types
	Keyboard = require("@self/types/Keyboard"),
	Gamepad = require("@self/types/Gamepad"),
	Touch = require("@self/types/Touch"),
}