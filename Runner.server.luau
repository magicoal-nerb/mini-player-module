--!strict

local MiniPlayerModule = require("./mini-player-module")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local CurrentCamera = assert(workspace.CurrentCamera)
local LocalPlayer = assert(Players.LocalPlayer)

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local Controller = MiniPlayerModule.Controller
local Camera = MiniPlayerModule.Camera
local Input = MiniPlayerModule.Input

local function characterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	Camera:setSubject(humanoid)
	Controller:setSubject(humanoid)
end

local function update(dt: number)
	debug.profilebegin("player-module::update")

	Camera:update(Input :: any, dt)
	Controller:update(Input :: any, dt)
	Input:update(dt)

	debug.profileend()
end

-- Initialize the playermodule's components
Input:addInputType(MiniPlayerModule.Keyboard)
Input:addInputType(MiniPlayerModule.Gamepad)
Input:addInputType(MiniPlayerModule.Touch)
Input:bind()

if LocalPlayer.Character then
	characterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(characterAdded)
Camera:changeState(Enum.CameraType.Custom)
RunService:BindToRenderStep(
	"rbx-camera-update",
	Enum.RenderPriority.Camera.Value,
	update
)

-- Remove the default scripts
CurrentCamera.CameraType = Enum.CameraType.Scriptable
for i, object in {
	"PlayerScriptsLoader",
	"PlayerModule",
	"CameraScript",
	"ControlScript",
} do
	local object = PlayerScripts:FindFirstChild(object)
	if object then
		object:Destroy()
	end	
end
