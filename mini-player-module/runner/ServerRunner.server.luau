--!strict

export type InputContext = {[string]: InputAction}
export type PlayerContext = {
	character: Model?,
	humanoid: Humanoid?,
	inputs: InputContext
}

local PlayerContexts = {} :: { [Player]: PlayerContext }

local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local CONTEXT_GROUP = {
	Move = Enum.InputActionType.Direction3D,
	Jump = Enum.InputActionType.Bool,
}

local function createInputGroup(
	groupName: string,
	actions: {[string]: Enum.InputActionType},
	parent: Player
): InputContext
	local group = Instance.new("InputContext")
	for name, actionType in actions do
		local action = Instance.new("InputAction")
		action.Name = name
		action.Type = actionType
		action.Parent = group
	end

	group.Priority = 1000
	group.Name = groupName
	group.Parent = parent
	
	return group
end

local function playerAdded(player: Player)
	-- Create input contexts to provide
	-- to the player.
	local context = {
		character = nil,
		humanoid = nil,
		inputs = createInputGroup("InputContexts", CONTEXT_GROUP, player),
	} :: PlayerContext
	
	local connections = {}
	connections = {
		player.CharacterAdded:Connect(function()
			local character = player.Character :: Model
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			context.character = character
			context.humanoid = humanoid
		end),
	
		player.Destroying:Connect(function()
			-- Destroy this group's reference
			PlayerContexts[player] = nil
			
			for i, connection in connections do
				connection:Disconnect()
			end
		end)
	}
	
	local maybeCharacter = player.Character
	if maybeCharacter then
		context.character = maybeCharacter
		context.humanoid = maybeCharacter:FindFirstChildOfClass('Humanoid')
	end
	
	PlayerContexts[player] = context
end

local function stepPlayer(player: Player, context: PlayerContext)
	if not context.character then
		return
	end
	
	local humanoid = context.humanoid :: Humanoid
	local inputs = context.inputs
	humanoid:Move(inputs.Move:GetState())
	humanoid.Jump = inputs.Jump:GetState()
end

local function stepServer(dt: number)
	-- Go through all the players, and set their current
	-- state accordingly.
	for player, group in PlayerContexts do
		stepPlayer(player, group)
	end
end

for i, player in Players:GetPlayers() do
	task.defer(playerAdded, player)
end

RunService:BindToSimulation(stepServer, Enum.StepFrequency.Hz60)
Players.PlayerAdded:Connect(playerAdded)