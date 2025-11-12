--!strict

local function createElement(
	class: string,
	props: { [string]: any },
	children: { [string]: Instance }?
): Instance
	local element = Instance.new(class)
	for key, value in props do
		element[key] = value
	end

	if children then
		for name, child in children do
			child.Name = name
			child.Parent = element
		end
	end

	return element
end

return function()
	return createElement("ScreenGui", {
		DisplayOrder = 6767,
		SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension,
		ClipToDeviceSafeArea = false,
	}, {
		ThumbstickFrame = createElement("Frame", {
			BackgroundTransparency = 1.0,
			Size = UDim2.fromOffset(70, 70),
			Position = UDim2.new(0, 25, 1, -90),
		}, {
			OuterImage = createElement("ImageLabel", {
				ImageRectSize = Vector2.one * 220,
				Image = "rbxasset://textures/ui/TouchControlsSheet.png",
				Size = UDim2.fromOffset(70, 70),
				BackgroundTransparency = 1.0,
			}),

			StickImage = createElement("ImageLabel", {
				ImageRectSize = Vector2.one * 111,
				ImageRectOffset = Vector2.xAxis * 220,
				Image = "rbxasset://textures/ui/TouchControlsSheet.png",

				AnchorPoint = Vector2.one * 0.5,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(35, 35),
				ZIndex = 2,

				BackgroundTransparency = 1.0,
			})
		}),

		JumpButton = createElement("ImageButton", {
			Image = "rbxasset://textures/ui/TouchControlsSheet.png",
			ImageRectOffset = Vector2.new(176, 222),
			ImageRectSize = Vector2.one * 174,
			
			Position = UDim2.new(1, -95, 1, -90),
			Size = UDim2.fromOffset(70, 70),
			
			BackgroundTransparency = 1.0,
		})
	})
end
