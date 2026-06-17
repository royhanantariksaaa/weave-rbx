--[=[
	@within Weave
	@module Profiler

	Visual in-game debug overlay for Weave performance metrics. Mounted
	automatically when `Weave.Debug = "overlay"`, or manually via
	`scope:Profiler()`.

	@return WeaveNode
]=]

local Players = game:GetService("Players")
local Debug = require(script.Parent.Parent.Core.Debug)

return function(_Scope, _Signal)
	return function(self)
		local isMounted = self.Value(true)
		local timer = self.Timer(0.1)

		local statsText = self.Computed(function(use)
			use(timer) -- Re-evaluate 10 times a second
			return Debug.Report()
		end)

		return self.Portal {
			Target = Players.LocalPlayer:WaitForChild("PlayerGui"),
			self.ScreenGui {
				Name = "WeaveProfilerOverlay",
				DisplayOrder = 999999,
				ResetOnSpawn = false,

				self.Show(isMounted, function(childScope)
					return childScope.Frame {
						Size = UDim2.fromOffset(300, 220),
						Position = UDim2.new(1, -16, 1, -16),
						AnchorPoint = Vector2.new(1, 1),
						BackgroundColor3 = Color3.fromRGB(20, 20, 25),
						BackgroundTransparency = 0.1,
						
						childScope.UICorner { CornerRadius = UDim.new(0, 8) },
						childScope.UIPadding {
							PaddingTop = UDim.new(0, 16),
							PaddingBottom = UDim.new(0, 16),
							PaddingLeft = UDim.new(0, 16),
							PaddingRight = UDim.new(0, 16),
						},

						childScope.TextLabel {
							Size = UDim2.new(1, 0, 0, 24),
							BackgroundTransparency = 1,
							Text = "⚡ Weave Profiler",
							TextColor3 = Color3.fromRGB(150, 200, 255),
							TextSize = 16,
							Font = Enum.Font.GothamBold,
							TextXAlignment = Enum.TextXAlignment.Left,
						},

						childScope.TextLabel {
							Size = UDim2.new(1, 0, 1, -24),
							Position = UDim2.fromOffset(0, 24),
							BackgroundTransparency = 1,
							Text = statsText,
							TextColor3 = Color3.fromRGB(220, 220, 220),
							TextSize = 13,
							Font = Enum.Font.Code,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Top,
						},

						childScope.TextButton {
							Size = UDim2.fromOffset(24, 24),
							Position = UDim2.new(1, 8, 0, -8),
							AnchorPoint = Vector2.new(1, 0),
							BackgroundColor3 = Color3.fromRGB(200, 60, 60),
							Text = "X",
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.GothamBold,
							[childScope.OnEvent "Activated"] = function()
								isMounted:Set(false)
								Debug.Enabled = false
							end,
							childScope.UICorner { CornerRadius = UDim.new(0, 4) }
						}
					}
				end)
			}
		}
	end
end
