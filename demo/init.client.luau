
--[=[
	An example that shows how a constScript
	would host a shader program with RbxShader.

	Learn more about the engine via:
	https://github.com/AnotherSubatomo/RbxShader
]=]

--!strict
--!optimize 2
--!native

const Client = game:GetService 'Players' .LocalPlayer
const ReplicatedStorage = game.ReplicatedStorage
const RbxShader = require(ReplicatedStorage:WaitForChild 'RbxShader')
const Shaders = ReplicatedStorage:WaitForChild 'Shaders'

-- Usual test resolution: 276, 184
-- Middle test resolution: 300, 200
-- Stress test resolution: 360, 240
const RESOLUTION = Vector2.new(276, 184)
const SHADER = Shaders.MouseInput
const BLUR = true

const SHADER_CTX = RbxShader.new(SHADER, script, RESOLUTION)

const SCREEN = Instance.new 'ScreenGui'
SCREEN.Parent = Client.PlayerGui
SCREEN.IgnoreGuiInset = true
SCREEN.ResetOnSpawn = false
SCREEN.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

const BACKDROP = Instance.new 'Frame'
BACKDROP.BackgroundTransparency = 0
BACKDROP.BackgroundColor3 = Color3.fromRGB()
BACKDROP.Size = UDim2.fromScale(1, 1)
BACKDROP.ZIndex = -1
BACKDROP.Parent = SCREEN

const DISPLAY = RbxShader.createDisplay(SHADER_CTX, BLUR)
DISPLAY.AnchorPoint = Vector2.one * 0.5
DISPLAY.Position = UDim2.fromScale(0.5, 0.5)
DISPLAY.Size = UDim2.fromScale(1, 1)
DISPLAY.Parent = SCREEN

RbxShader.trackMouseInputs(SHADER_CTX, DISPLAY)

const RATIO = Instance.new 'UIAspectRatioConstraint'
RATIO.AspectRatio = RESOLUTION.X / RESOLUTION.Y
RATIO.Parent = DISPLAY

task.wait(3)

RbxShader.start(SHADER_CTX)