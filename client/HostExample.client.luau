
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
	ScreenDivision = 16
}

local CANVAS_SIZE = Vector2.new(180, 120)
local SHADER = script.Shaders.GravitySucks

local SCREEN = Instance.new('ScreenGui')
SCREEN.Parent = Client.PlayerGui
SCREEN.IgnoreGuiInset = true
SCREEN.ResetOnSpawn = false

RbxShader.new( script , SCREEN , CANVAS_SIZE , CONFIGURATIONS , SHADER , SHADER.Name )
RbxShader.run( SHADER.Name )

task.wait(5)

RbxShader.stop( SHADER.Name )

task.wait(5)

RbxShader.run( SHADER.Name )