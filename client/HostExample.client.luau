
--[=[
	Host
	A sample script on how you would
	run a shader.
]=]

--!native

-- // Dependencies
local Client = game.Players.LocalPlayer
local RbxShader = require(game.ReplicatedStorage.RbxShader)

-- // Configurations
local CONFIGURATIONS = {
	InterlaceFactor = 2 ,
	DualAxisInterlacing = true ,
	ScreenDivision = 4 ,
	IsBlurred = false
}

local CANVAS_SIZE = Vector2.new(180, 120) -- try (192, 108) too!
local SHADER = script.Shaders.VoxelShader

local SCREEN = Instance.new('ScreenGui')
SCREEN.Parent = Client.PlayerGui
SCREEN.IgnoreGuiInset = true
SCREEN.ResetOnSpawn = false

RbxShader.new( SHADER.Name, SHADER, CONFIGURATIONS, script, SCREEN, CANVAS_SIZE)
RbxShader.run( SHADER.Name )

task.wait(5)

RbxShader.pause( SHADER.Name )

task.wait(5)

RbxShader.resume( SHADER.Name )